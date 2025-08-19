/**
 * Factory functions for creating orchestration errors.
 * 
 * This module provides utilities for creating properly formatted error objects
 * with appropriate categorization, severity, and recovery information.
 */

import { v4 as uuidv4 } from 'uuid';
import {
  OrchestrationError,
  ErrorCategory,
  ErrorSeverity,
  RecoveryAction,
  ValidationError,
  WorkspaceError,
  KiroError,
  NetworkError,
  SystemError,
  TimeoutError,
  AuthenticationError,
  QuotaError,
  ConfigurationError,
} from './error-types';

/**
 * Base parameters for creating any orchestration error.
 */
interface BaseErrorParams {
  /** Human-readable error message */
  message: string;
  
  /** Technical error code */
  code: string;
  
  /** Error severity level */
  severity?: ErrorSeverity;
  
  /** Whether the error is recoverable */
  recoverable?: boolean;
  
  /** Suggested recovery actions */
  recoveryActions?: RecoveryAction[];
  
  /** Component or service where the error originated */
  source?: string;
  
  /** Additional context information */
  context?: Record<string, unknown>;
  
  /** Stack trace or detailed error information */
  details?: string;
  
  /** Underlying cause if this error wraps another error */
  cause?: Error;
}

/**
 * Creates a base orchestration error with common properties.
 * 
 * @param category - Error category
 * @param params - Error parameters
 * @returns Base orchestration error object
 */
function createBaseError(category: ErrorCategory, params: BaseErrorParams): OrchestrationError {
  return {
    id: uuidv4(),
    category,
    severity: params.severity || 'medium',
    message: params.message,
    code: params.code,
    recoverable: params.recoverable !== undefined ? params.recoverable : true,
    recoveryActions: params.recoveryActions || ['retry'],
    occurredAt: new Date().toISOString(),
    source: params.source || 'unknown',
    context: params.context || {},
    details: params.details,
    cause: params.cause,
  };
}

/**
 * Creates a validation error.
 * 
 * @param field - Field that failed validation
 * @param value - Value that failed validation
 * @param rule - Validation rule that was violated
 * @param params - Additional error parameters
 * @returns ValidationError object
 */
export function createValidationError(
  field: string,
  value: unknown,
  rule: string,
  params: Partial<BaseErrorParams> = {}
): ValidationError {
  const baseError = createBaseError('validation', {
    message: `Validation failed for field '${field}': ${rule}`,
    code: 'VALIDATION_FAILED',
    severity: 'medium',
    recoverable: false, // Validation errors typically require user input
    recoveryActions: ['user-input'],
    source: 'validator',
    ...params,
  });
  
  return {
    ...baseError,
    category: 'validation',
    field,
    value,
    rule,
  };
}

/**
 * Creates a workspace error.
 * 
 * @param path - Path where the error occurred
 * @param operation - File system operation that failed
 * @param params - Additional error parameters
 * @returns WorkspaceError object
 */
export function createWorkspaceError(
  path: string,
  operation: WorkspaceError['operation'],
  params: Partial<BaseErrorParams> & { systemErrorCode?: string } = {}
): WorkspaceError {
  const baseError = createBaseError('workspace', {
    message: `Workspace ${operation} operation failed: ${path}`,
    code: `WORKSPACE_${operation.toUpperCase()}_FAILED`,
    severity: 'high',
    recoverable: true,
    recoveryActions: ['retry', 'fallback'],
    source: 'workspace-manager',
    ...params,
  });
  
  return {
    ...baseError,
    category: 'workspace',
    path,
    operation,
    systemErrorCode: params.systemErrorCode,
  };
}

/**
 * Creates a Kiro integration error.
 * 
 * @param params - Error parameters including Kiro-specific information
 * @returns KiroError object
 */
export function createKiroError(
  params: Partial<BaseErrorParams> & {
    command?: string;
    args?: string[];
    exitCode?: number;
    stdout?: string;
    stderr?: string;
    sessionId?: string;
  } = {}
): KiroError {
  const command = params.command || 'unknown';
  const baseError = createBaseError('kiro', {
    message: `Kiro command failed: ${command}`,
    code: 'KIRO_COMMAND_FAILED',
    severity: 'high',
    recoverable: true,
    recoveryActions: ['retry', 'restart'],
    source: 'kiro-interface',
    ...params,
  });
  
  return {
    ...baseError,
    category: 'kiro',
    command: params.command,
    args: params.args,
    exitCode: params.exitCode,
    stdout: params.stdout,
    stderr: params.stderr,
    sessionId: params.sessionId,
  };
}

/**
 * Creates a network error.
 * 
 * @param params - Error parameters including network-specific information
 * @returns NetworkError object
 */
export function createNetworkError(
  params: Partial<BaseErrorParams> & {
    statusCode?: number;
    url?: string;
    method?: string;
    timeoutMs?: number;
    retryAttempts?: number;
  } = {}
): NetworkError {
  const baseError = createBaseError('network', {
    message: 'Network operation failed',
    code: 'NETWORK_ERROR',
    severity: 'medium',
    recoverable: true,
    recoveryActions: ['retry'],
    source: 'api-client',
    ...params,
  });
  
  return {
    ...baseError,
    category: 'network',
    statusCode: params.statusCode,
    url: params.url,
    method: params.method,
    timeoutMs: params.timeoutMs,
    retryAttempts: params.retryAttempts,
  };
}

/**
 * Creates a system error.
 * 
 * @param params - Error parameters including system-specific information
 * @returns SystemError object
 */
export function createSystemError(
  params: Partial<BaseErrorParams> & {
    resource?: SystemError['resource'];
    resourceUsage?: Record<string, number>;
    resourceLimits?: Record<string, number>;
  } = {}
): SystemError {
  const baseError = createBaseError('system', {
    message: 'System resource error occurred',
    code: 'SYSTEM_ERROR',
    severity: 'critical',
    recoverable: false,
    recoveryActions: ['manual'],
    source: 'system',
    ...params,
  });
  
  return {
    ...baseError,
    category: 'system',
    resource: params.resource,
    resourceUsage: params.resourceUsage,
    resourceLimits: params.resourceLimits,
  };
}

/**
 * Creates a timeout error.
 * 
 * @param operation - Operation that timed out
 * @param timeoutMs - Timeout duration in milliseconds
 * @param elapsedMs - Elapsed time before timeout
 * @param params - Additional error parameters
 * @returns TimeoutError object
 */
export function createTimeoutError(
  operation: string,
  timeoutMs: number,
  elapsedMs: number,
  params: Partial<BaseErrorParams> = {}
): TimeoutError {
  const baseError = createBaseError('timeout', {
    message: `Operation '${operation}' timed out after ${timeoutMs}ms`,
    code: 'OPERATION_TIMEOUT',
    severity: 'medium',
    recoverable: true,
    recoveryActions: ['retry'],
    source: 'timeout-manager',
    ...params,
  });
  
  return {
    ...baseError,
    category: 'timeout',
    operation,
    timeoutMs,
    elapsedMs,
  };
}

/**
 * Creates an authentication error.
 * 
 * @param credentialStatus - Status of the credentials
 * @param params - Additional error parameters
 * @returns AuthenticationError object
 */
export function createAuthenticationError(
  credentialStatus: AuthenticationError['credentialStatus'],
  params: Partial<BaseErrorParams> & {
    authMethod?: AuthenticationError['authMethod'];
  } = {}
): AuthenticationError {
  const baseError = createBaseError('authentication', {
    message: `Authentication failed: credentials are ${credentialStatus}`,
    code: 'AUTHENTICATION_FAILED',
    severity: 'high',
    recoverable: credentialStatus !== 'invalid',
    recoveryActions: credentialStatus === 'expired' ? ['retry'] : ['manual'],
    source: 'auth-manager',
    ...params,
  });
  
  return {
    ...baseError,
    category: 'authentication',
    authMethod: params.authMethod,
    credentialStatus,
  };
}

/**
 * Creates a quota error.
 * 
 * @param resource - Resource that exceeded quota
 * @param currentUsage - Current usage amount
 * @param quota - Maximum allowed quota
 * @param unit - Unit of measurement
 * @param params - Additional error parameters
 * @returns QuotaError object
 */
export function createQuotaError(
  resource: QuotaError['resource'],
  currentUsage: number,
  quota: number,
  unit: string,
  params: Partial<BaseErrorParams> = {}
): QuotaError {
  const baseError = createBaseError('quota', {
    message: `Quota exceeded for ${resource}: ${currentUsage}${unit} / ${quota}${unit}`,
    code: 'QUOTA_EXCEEDED',
    severity: 'high',
    recoverable: false,
    recoveryActions: ['manual'],
    source: 'quota-manager',
    ...params,
  });
  
  return {
    ...baseError,
    category: 'quota',
    resource,
    currentUsage,
    quota,
    unit,
  };
}

/**
 * Creates a configuration error.
 * 
 * @param params - Error parameters including configuration-specific information
 * @returns ConfigurationError object
 */
export function createConfigurationError(
  params: Partial<BaseErrorParams> & {
    configKey?: string;
    expectedFormat?: string;
    actualValue?: unknown;
  } = {}
): ConfigurationError {
  const baseError = createBaseError('configuration', {
    message: 'Configuration error occurred',
    code: 'CONFIGURATION_ERROR',
    severity: 'high',
    recoverable: true,
    recoveryActions: ['manual'],
    source: 'config-manager',
    ...params,
  });
  
  return {
    ...baseError,
    category: 'configuration',
    configKey: params.configKey,
    expectedFormat: params.expectedFormat,
    actualValue: params.actualValue,
  };
}

/**
 * Wraps a generic Error into an OrchestrationError.
 * 
 * @param error - The generic error to wrap
 * @param category - Error category to assign
 * @param source - Source component
 * @param additionalContext - Additional context information
 * @returns OrchestrationError object
 */
export function wrapError(
  error: Error,
  category: ErrorCategory = 'system',
  source: string = 'unknown',
  additionalContext: Record<string, unknown> = {}
): OrchestrationError {
  return createBaseError(category, {
    message: error.message,
    code: 'WRAPPED_ERROR',
    severity: 'medium',
    recoverable: true,
    recoveryActions: ['retry'],
    source,
    context: {
      originalErrorName: error.name,
      ...additionalContext,
    },
    details: error.stack,
    cause: error,
  });
}

/**
 * Creates an error recovery context.
 * 
 * @param error - Error that needs recovery
 * @param attemptCount - Number of recovery attempts made
 * @param maxAttempts - Maximum recovery attempts allowed
 * @param previousActions - Previous recovery actions attempted
 * @param additionalContext - Additional context for recovery
 * @returns ErrorRecoveryContext object
 */
export function createRecoveryContext(
  error: OrchestrationError,
  attemptCount: number = 0,
  maxAttempts: number = 3,
  previousActions: RecoveryAction[] = [],
  additionalContext: Record<string, unknown> = {}
): import('./error-types').ErrorRecoveryContext {
  return {
    error,
    attemptCount,
    maxAttempts,
    elapsedMs: 0, // Will be calculated by the recovery manager
    previousActions,
    context: additionalContext,
  };
}