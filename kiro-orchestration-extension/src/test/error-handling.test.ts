/**
 * Unit tests for error handling types, recovery strategies, and factory functions.
 * 
 * This test suite ensures that all error handling functionality works correctly,
 * including error creation, classification, recovery strategies, and user messaging.
 */

import {
  OrchestrationError,
  ErrorCategory,
  ErrorSeverity,
  RecoveryAction,
  ValidationError,
  WorkspaceError,
  KiroError,
  NetworkError,
  TimeoutError,
} from '../types/error-types';
import {
  createValidationError,
  createWorkspaceError,
  createKiroError,
  createNetworkError,
  createTimeoutError,
  createAuthenticationError,
  createQuotaError,
  createConfigurationError,
  wrapError,
  createRecoveryContext,
} from '../types/error-factory';
import {
  ErrorRecoveryManager,
  ValidationErrorRecoveryStrategy,
  WorkspaceErrorRecoveryStrategy,
  KiroErrorRecoveryStrategy,
  NetworkErrorRecoveryStrategy,
  TimeoutErrorRecoveryStrategy,
} from '../types/error-recovery';

describe('Error Factory', () => {
  describe('createValidationError', () => {
    it('should create valid validation error', () => {
      const error = createValidationError('email', 'invalid-email', 'must be valid email format');
      
      expect(error.category).toBe('validation');
      expect(error.field).toBe('email');
      expect(error.value).toBe('invalid-email');
      expect(error.rule).toBe('must be valid email format');
      expect(error.code).toBe('VALIDATION_FAILED');
      expect(error.recoverable).toBe(false);
      expect(error.recoveryActions).toContain('user-input');
      expect(error.severity).toBe('medium');
      expect(error.id).toBeTruthy();
      expect(error.occurredAt).toBeTruthy();
    });
    
    it('should allow custom parameters', () => {
      const error = createValidationError('name', '', 'required', {
        severity: 'high',
        source: 'custom-validator',
        context: { formId: 'user-form' },
      });
      
      expect(error.severity).toBe('high');
      expect(error.source).toBe('custom-validator');
      expect(error.context.formId).toBe('user-form');
    });
  });
  
  describe('createWorkspaceError', () => {
    it('should create valid workspace error', () => {
      const error = createWorkspaceError('/path/to/file', 'create');
      
      expect(error.category).toBe('workspace');
      expect(error.path).toBe('/path/to/file');
      expect(error.operation).toBe('create');
      expect(error.code).toBe('WORKSPACE_CREATE_FAILED');
      expect(error.recoverable).toBe(true);
      expect(error.recoveryActions).toContain('retry');
      expect(error.severity).toBe('high');
    });
    
    it('should include system error code when provided', () => {
      const error = createWorkspaceError('/path/to/file', 'read', {
        systemErrorCode: 'ENOENT',
      });
      
      expect(error.systemErrorCode).toBe('ENOENT');
    });
  });
  
  describe('createKiroError', () => {
    it('should create valid Kiro error', () => {
      const error = createKiroError({
        command: 'kiro-spec-create',
        args: ['--type', 'webapp'],
        exitCode: 1,
        stderr: 'Command failed',
        sessionId: 'session-123',
      });
      
      expect(error.category).toBe('kiro');
      expect(error.command).toBe('kiro-spec-create');
      expect(error.args).toEqual(['--type', 'webapp']);
      expect(error.exitCode).toBe(1);
      expect(error.stderr).toBe('Command failed');
      expect(error.sessionId).toBe('session-123');
      expect(error.code).toBe('KIRO_COMMAND_FAILED');
      expect(error.recoverable).toBe(true);
    });
  });
  
  describe('createNetworkError', () => {
    it('should create valid network error', () => {
      const error = createNetworkError({
        statusCode: 500,
        url: 'https://api.example.com/test',
        method: 'POST',
        retryAttempts: 2,
      });
      
      expect(error.category).toBe('network');
      expect(error.statusCode).toBe(500);
      expect(error.url).toBe('https://api.example.com/test');
      expect(error.method).toBe('POST');
      expect(error.retryAttempts).toBe(2);
      expect(error.code).toBe('NETWORK_ERROR');
      expect(error.recoverable).toBe(true);
    });
  });
  
  describe('createTimeoutError', () => {
    it('should create valid timeout error', () => {
      const error = createTimeoutError('file-upload', 30000, 35000);
      
      expect(error.category).toBe('timeout');
      expect(error.operation).toBe('file-upload');
      expect(error.timeoutMs).toBe(30000);
      expect(error.elapsedMs).toBe(35000);
      expect(error.code).toBe('OPERATION_TIMEOUT');
      expect(error.message).toContain('file-upload');
      expect(error.message).toContain('30000ms');
    });
  });
  
  describe('createAuthenticationError', () => {
    it('should create valid authentication error', () => {
      const error = createAuthenticationError('expired', {
        authMethod: 'api-key',
      });
      
      expect(error.category).toBe('authentication');
      expect(error.credentialStatus).toBe('expired');
      expect(error.authMethod).toBe('api-key');
      expect(error.code).toBe('AUTHENTICATION_FAILED');
      expect(error.recoverable).toBe(true); // Expired credentials can be refreshed
    });
    
    it('should mark invalid credentials as non-recoverable', () => {
      const error = createAuthenticationError('invalid');
      
      expect(error.recoverable).toBe(false);
      expect(error.recoveryActions).toContain('manual');
    });
  });
  
  describe('createQuotaError', () => {
    it('should create valid quota error', () => {
      const error = createQuotaError('applications', 15, 10, 'apps');
      
      expect(error.category).toBe('quota');
      expect(error.resource).toBe('applications');
      expect(error.currentUsage).toBe(15);
      expect(error.quota).toBe(10);
      expect(error.unit).toBe('apps');
      expect(error.code).toBe('QUOTA_EXCEEDED');
      expect(error.recoverable).toBe(false);
      expect(error.message).toContain('15apps / 10apps');
    });
  });
  
  describe('wrapError', () => {
    it('should wrap generic Error into OrchestrationError', () => {
      const originalError = new Error('Something went wrong');
      originalError.stack = 'Error stack trace';
      
      const wrappedError = wrapError(originalError, 'system', 'test-component', {
        additionalInfo: 'test',
      });
      
      expect(wrappedError.category).toBe('system');
      expect(wrappedError.message).toBe('Something went wrong');
      expect(wrappedError.source).toBe('test-component');
      expect(wrappedError.code).toBe('WRAPPED_ERROR');
      expect(wrappedError.cause).toBe(originalError);
      expect(wrappedError.details).toBe('Error stack trace');
      expect(wrappedError.context.originalErrorName).toBe('Error');
      expect(wrappedError.context.additionalInfo).toBe('test');
    });
  });
  
  describe('createRecoveryContext', () => {
    it('should create valid recovery context', () => {
      const error = createValidationError('test', 'value', 'rule');
      const context = createRecoveryContext(error, 2, 5, ['retry'], { jobId: 'job-123' });
      
      expect(context.error).toBe(error);
      expect(context.attemptCount).toBe(2);
      expect(context.maxAttempts).toBe(5);
      expect(context.previousActions).toEqual(['retry']);
      expect(context.context.jobId).toBe('job-123');
      expect(context.elapsedMs).toBe(0);
    });
  });
});

describe('Error Recovery Strategies', () => {
  describe('ValidationErrorRecoveryStrategy', () => {
    let strategy: ValidationErrorRecoveryStrategy;
    
    beforeEach(() => {
      strategy = new ValidationErrorRecoveryStrategy();
    });
    
    it('should handle validation errors', () => {
      const error = createValidationError('email', 'invalid', 'format');
      expect(strategy.canHandle(error)).toBe(true);
      
      const networkError = createNetworkError();
      expect(strategy.canHandle(networkError)).toBe(false);
    });
    
    it('should provide user-friendly message', () => {
      const error = createValidationError('email', 'invalid', 'format');
      const message = strategy.getUserMessage(error);
      
      expect(message).toContain('email');
      expect(message).toContain('Invalid');
    });
    
    it('should provide suggested actions', () => {
      const error = createValidationError('password', 'weak', 'strength');
      const actions = strategy.getSuggestedActions(error);
      
      expect(actions.length).toBeGreaterThan(0);
      expect(actions.some(action => action.includes('password'))).toBe(true);
    });
    
    it('should not recover validation errors automatically', async () => {
      const error = createValidationError('name', '', 'required');
      const context = createRecoveryContext(error);
      
      const result = await strategy.recover(error, context);
      
      expect(result.success).toBe(false);
      expect(result.action).toBe('user-input');
      expect(result.shouldRetry).toBe(false);
    });
  });
  
  describe('NetworkErrorRecoveryStrategy', () => {
    let strategy: NetworkErrorRecoveryStrategy;
    
    beforeEach(() => {
      strategy = new NetworkErrorRecoveryStrategy();
    });
    
    it('should handle network errors', () => {
      const error = createNetworkError();
      expect(strategy.canHandle(error)).toBe(true);
    });
    
    it('should handle rate limiting with longer delay', async () => {
      const error = createNetworkError({ statusCode: 429 });
      const context = createRecoveryContext(error, 1);
      
      const result = await strategy.recover(error, context);
      
      expect(result.success).toBe(false);
      expect(result.action).toBe('retry');
      expect(result.shouldRetry).toBe(true);
      expect(result.retryDelayMs).toBeGreaterThanOrEqual(5000); // At least 5 seconds for rate limiting
    });
    
    it('should not retry authentication errors', async () => {
      const error = createNetworkError({ statusCode: 401 });
      const context = createRecoveryContext(error);
      
      const result = await strategy.recover(error, context);
      
      expect(result.success).toBe(false);
      expect(result.action).toBe('manual');
      expect(result.shouldRetry).toBe(false);
    });
    
    it('should retry server errors with backoff', async () => {
      const error = createNetworkError({ statusCode: 500 });
      const context = createRecoveryContext(error, 1);
      
      const result = await strategy.recover(error, context);
      
      expect(result.success).toBe(false);
      expect(result.action).toBe('retry');
      expect(result.shouldRetry).toBe(true);
      expect(result.retryDelayMs).toBeGreaterThan(0);
    });
  });
  
  describe('KiroErrorRecoveryStrategy', () => {
    let strategy: KiroErrorRecoveryStrategy;
    
    beforeEach(() => {
      strategy = new KiroErrorRecoveryStrategy();
    });
    
    it('should handle Kiro errors', () => {
      const error = createKiroError();
      expect(strategy.canHandle(error)).toBe(true);
    });
    
    it('should restart session for command not found', async () => {
      const error = createKiroError({ exitCode: 127 });
      const context = createRecoveryContext(error, 1);
      
      const result = await strategy.recover(error, context);
      
      expect(result.success).toBe(false);
      expect(result.action).toBe('restart');
      expect(result.shouldRetry).toBe(true);
    });
    
    it('should retry general errors', async () => {
      const error = createKiroError({ exitCode: 1 });
      const context = createRecoveryContext(error, 1);
      
      const result = await strategy.recover(error, context);
      
      expect(result.success).toBe(false);
      expect(result.action).toBe('retry');
      expect(result.shouldRetry).toBe(true);
    });
  });
  
  describe('TimeoutErrorRecoveryStrategy', () => {
    let strategy: TimeoutErrorRecoveryStrategy;
    
    beforeEach(() => {
      strategy = new TimeoutErrorRecoveryStrategy();
    });
    
    it('should handle timeout errors', () => {
      const error = createTimeoutError('test-operation', 5000, 6000);
      expect(strategy.canHandle(error)).toBe(true);
    });
    
    it('should retry timeout errors', async () => {
      const error = createTimeoutError('test-operation', 5000, 6000);
      const context = createRecoveryContext(error, 1);
      
      const result = await strategy.recover(error, context);
      
      expect(result.success).toBe(false);
      expect(result.action).toBe('retry');
      expect(result.shouldRetry).toBe(true);
    });
    
    it('should provide timeout-specific suggestions', () => {
      const error = createTimeoutError('file-upload', 30000, 35000);
      const actions = strategy.getSuggestedActions(error);
      
      expect(actions.some(action => action.includes('timeout'))).toBe(true);
      expect(actions.some(action => action.includes('performance'))).toBe(true);
    });
  });
});

describe('ErrorRecoveryManager', () => {
  let manager: ErrorRecoveryManager;
  
  beforeEach(() => {
    manager = new ErrorRecoveryManager();
  });
  
  it('should register strategies and sort by priority', () => {
    // Manager should have default strategies registered
    const validationError = createValidationError('test', 'value', 'rule');
    const networkError = createNetworkError();
    
    expect(manager.isRecoverable(validationError, createRecoveryContext(validationError))).toBe(false);
    expect(manager.isRecoverable(networkError, createRecoveryContext(networkError))).toBe(true);
  });
  
  it('should find appropriate strategy for error', () => {
    const validationError = createValidationError('test', 'value', 'rule');
    const message = manager.getUserMessage(validationError);
    
    expect(message).toContain('Invalid');
    expect(message).toContain('test');
  });
  
  it('should provide suggested actions', () => {
    const networkError = createNetworkError({ statusCode: 404 });
    const actions = manager.getSuggestedActions(networkError);
    
    expect(actions.length).toBeGreaterThan(0);
    expect(actions.some(action => action.includes('connection') || action.includes('resource'))).toBe(true);
  });
  
  it('should handle unknown error types', async () => {
    // Create an error with an unknown category
    const unknownError: OrchestrationError = {
      id: 'test-id',
      category: 'unknown' as ErrorCategory,
      severity: 'medium',
      message: 'Unknown error',
      code: 'UNKNOWN',
      recoverable: true,
      recoveryActions: ['retry'],
      occurredAt: new Date().toISOString(),
      source: 'test',
      context: {},
    };
    
    const result = await manager.recover(unknownError, createRecoveryContext(unknownError));
    
    expect(result.success).toBe(false);
    expect(result.action).toBe('abort');
    expect(result.message).toContain('No recovery strategy available');
  });
  
  it('should respect recovery context limits', () => {
    const error = createNetworkError();
    const context = createRecoveryContext(error, 5, 3); // Exceeded max attempts
    
    expect(manager.isRecoverable(error, context)).toBe(false);
  });
  
  it('should attempt recovery with appropriate strategy', async () => {
    const error = createTimeoutError('test-op', 1000, 1500);
    const context = createRecoveryContext(error, 1);
    
    const result = await manager.recover(error, context);
    
    expect(result.action).toBe('retry');
    expect(result.shouldRetry).toBe(true);
  });
});