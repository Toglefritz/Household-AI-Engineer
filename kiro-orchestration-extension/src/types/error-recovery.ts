/**
 * Error recovery strategies for the Kiro Orchestration Extension.
 * 
 * This module provides comprehensive error recovery mechanisms with
 * intelligent retry logic, fallback strategies, and user interaction handling.
 */

import {
  OrchestrationError,
  ErrorCategory,
  ErrorSeverity,
  RecoveryAction,
  ErrorRecoveryContext,
  RecoveryResult,
  SpecificOrchestrationError,
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
 * Interface for error recovery strategies.
 */
export interface ErrorRecoveryStrategy {
  /** 
   * Determines if this strategy can handle the given error.
   * 
   * @param error - The error to evaluate
   * @returns True if this strategy can handle the error
   */
  canHandle(error: OrchestrationError): boolean;
  
  /**
   * Determines if the error is recoverable using this strategy.
   * 
   * @param error - The error to evaluate
   * @param context - Recovery context information
   * @returns True if the error is recoverable
   */
  isRecoverable(error: OrchestrationError, context: ErrorRecoveryContext): boolean;
  
  /**
   * Attempts to recover from the error.
   * 
   * @param error - The error to recover from
   * @param context - Recovery context information
   * @returns Promise that resolves to the recovery result
   */
  recover(error: OrchestrationError, context: ErrorRecoveryContext): Promise<RecoveryResult>;
  
  /**
   * Gets the priority of this recovery strategy (higher numbers = higher priority).
   * 
   * @returns Priority value
   */
  getPriority(): number;
  
  /**
   * Provides a user-friendly error message for display.
   * 
   * @param error - The error to format
   * @returns User-friendly error message
   */
  getUserMessage(error: OrchestrationError): string;
  
  /**
   * Suggests corrective actions the user can take.
   * 
   * @param error - The error to provide suggestions for
   * @returns Array of suggested actions
   */
  getSuggestedActions(error: OrchestrationError): readonly string[];
}

/**
 * Base implementation of error recovery strategy.
 */
export abstract class BaseErrorRecoveryStrategy implements ErrorRecoveryStrategy {
  protected readonly maxRetryAttempts: number = 3;
  protected readonly baseRetryDelayMs: number = 1000;
  
  abstract canHandle(error: OrchestrationError): boolean;
  abstract getPriority(): number;
  abstract getUserMessage(error: OrchestrationError): string;
  abstract getSuggestedActions(error: OrchestrationError): readonly string[];
  
  public isRecoverable(error: OrchestrationError, context: ErrorRecoveryContext): boolean {
    // Check if we've exceeded maximum attempts
    if (context.attemptCount >= context.maxAttempts) {
      return false;
    }
    
    // Check if error is marked as recoverable
    if (!error.recoverable) {
      return false;
    }
    
    // Check if we have valid recovery actions
    return error.recoveryActions.length > 0;
  }
  
  public abstract recover(error: OrchestrationError, context: ErrorRecoveryContext): Promise<RecoveryResult>;
  
  /**
   * Calculates exponential backoff delay.
   * 
   * @param attemptCount - Number of attempts made
   * @returns Delay in milliseconds
   */
  protected calculateRetryDelay(attemptCount: number): number {
    return this.baseRetryDelayMs * Math.pow(2, attemptCount - 1);
  }
  
  /**
   * Creates a successful recovery result.
   * 
   * @param action - Recovery action taken
   * @param message - Success message
   * @param data - Additional data
   * @returns Successful recovery result
   */
  protected createSuccessResult(
    action: RecoveryAction,
    message: string,
    data?: Record<string, unknown>
  ): RecoveryResult {
    return {
      success: true,
      action,
      message,
      shouldRetry: false,
      data,
    };
  }
  
  /**
   * Creates a failed recovery result.
   * 
   * @param action - Recovery action attempted
   * @param message - Failure message
   * @param shouldRetry - Whether to retry
   * @param retryDelayMs - Delay before retry
   * @param error - New error if applicable
   * @returns Failed recovery result
   */
  protected createFailureResult(
    action: RecoveryAction,
    message: string,
    shouldRetry: boolean = false,
    retryDelayMs?: number,
    error?: OrchestrationError
  ): RecoveryResult {
    return {
      success: false,
      action,
      message,
      shouldRetry,
      retryDelayMs,
      error,
    };
  }
}

/**
 * Recovery strategy for validation errors.
 */
export class ValidationErrorRecoveryStrategy extends BaseErrorRecoveryStrategy {
  public canHandle(error: OrchestrationError): boolean {
    return error.category === 'validation';
  }
  
  public getPriority(): number {
    return 100;
  }
  
  public getUserMessage(error: OrchestrationError): string {
    const validationError = error as ValidationError;
    return `Invalid ${validationError.field}: ${validationError.message}`;
  }
  
  public getSuggestedActions(error: OrchestrationError): readonly string[] {
    const validationError = error as ValidationError;
    return [
      `Please provide a valid value for ${validationError.field}`,
      `Check that the ${validationError.field} meets the required format`,
      'Review the input requirements and try again',
    ];
  }
  
  public async recover(error: OrchestrationError, context: ErrorRecoveryContext): Promise<RecoveryResult> {
    // Validation errors typically require user input to correct
    return this.createFailureResult(
      'user-input',
      'Validation errors require corrected input from the user',
      false
    );
  }
}

/**
 * Recovery strategy for workspace errors.
 */
export class WorkspaceErrorRecoveryStrategy extends BaseErrorRecoveryStrategy {
  public canHandle(error: OrchestrationError): boolean {
    return error.category === 'workspace';
  }
  
  public getPriority(): number {
    return 90;
  }
  
  public getUserMessage(error: OrchestrationError): string {
    const workspaceError = error as WorkspaceError;
    return `Workspace error: ${error.message} (${workspaceError.path})`;
  }
  
  public getSuggestedActions(error: OrchestrationError): readonly string[] {
    const workspaceError = error as WorkspaceError;
    const actions = ['Check file system permissions', 'Ensure sufficient disk space'];
    
    switch (workspaceError.operation) {
      case 'create':
        actions.push('Verify the parent directory exists and is writable');
        break;
      case 'read':
        actions.push('Ensure the file exists and is readable');
        break;
      case 'write':
        actions.push('Check that the file is not locked by another process');
        break;
      case 'delete':
        actions.push('Verify the file is not in use by another application');
        break;
    }
    
    return actions;
  }
  
  public async recover(error: OrchestrationError, context: ErrorRecoveryContext): Promise<RecoveryResult> {
    const workspaceError = error as WorkspaceError;
    
    // Attempt different recovery strategies based on the operation
    switch (workspaceError.operation) {
      case 'create':
        return this.recoverCreateOperation(workspaceError, context);
      case 'permissions':
        return this.recoverPermissionsOperation(workspaceError, context);
      default:
        return this.createFailureResult(
          'retry',
          `Cannot automatically recover from ${workspaceError.operation} operation failure`,
          context.attemptCount < this.maxRetryAttempts,
          this.calculateRetryDelay(context.attemptCount)
        );
    }
  }
  
  private async recoverCreateOperation(error: WorkspaceError, context: ErrorRecoveryContext): Promise<RecoveryResult> {
    // For create operations, try to create parent directories
    return this.createFailureResult(
      'retry',
      'Attempting to create parent directories and retry',
      true,
      this.calculateRetryDelay(context.attemptCount)
    );
  }
  
  private async recoverPermissionsOperation(error: WorkspaceError, context: ErrorRecoveryContext): Promise<RecoveryResult> {
    // Permission errors typically require manual intervention
    return this.createFailureResult(
      'manual',
      'Permission errors require manual intervention to fix file system permissions',
      false
    );
  }
}

/**
 * Recovery strategy for Kiro integration errors.
 */
export class KiroErrorRecoveryStrategy extends BaseErrorRecoveryStrategy {
  public canHandle(error: OrchestrationError): boolean {
    return error.category === 'kiro';
  }
  
  public getPriority(): number {
    return 80;
  }
  
  public getUserMessage(error: OrchestrationError): string {
    const kiroError = error as KiroError;
    const command = kiroError.command ? ` (${kiroError.command})` : '';
    return `Kiro IDE error${command}: ${error.message}`;
  }
  
  public getSuggestedActions(error: OrchestrationError): readonly string[] {
    const kiroError = error as KiroError;
    const actions = ['Check Kiro IDE installation and configuration'];
    
    if (kiroError.exitCode !== undefined) {
      actions.push(`Command exited with code ${kiroError.exitCode}`);
    }
    
    if (kiroError.stderr) {
      actions.push('Check the error output for specific issues');
    }
    
    actions.push('Try restarting the Kiro session');
    
    return actions;
  }
  
  public async recover(error: OrchestrationError, context: ErrorRecoveryContext): Promise<RecoveryResult> {
    const kiroError = error as KiroError;
    
    // Different recovery strategies based on exit code
    if (kiroError.exitCode !== undefined) {
      switch (kiroError.exitCode) {
        case 1:
          // General error - retry with delay
          return this.createFailureResult(
            'retry',
            'Retrying Kiro command after delay',
            context.attemptCount < this.maxRetryAttempts,
            this.calculateRetryDelay(context.attemptCount)
          );
          
        case 127:
          // Command not found - restart session
          return this.createFailureResult(
            'restart',
            'Kiro command not found, attempting to restart session',
            true,
            this.calculateRetryDelay(context.attemptCount)
          );
          
        default:
          return this.createFailureResult(
            'retry',
            `Retrying after Kiro command failure (exit code: ${kiroError.exitCode})`,
            context.attemptCount < this.maxRetryAttempts,
            this.calculateRetryDelay(context.attemptCount)
          );
      }
    }
    
    // Default retry strategy
    return this.createFailureResult(
      'retry',
      'Retrying Kiro operation',
      context.attemptCount < this.maxRetryAttempts,
      this.calculateRetryDelay(context.attemptCount)
    );
  }
}

/**
 * Recovery strategy for network errors.
 */
export class NetworkErrorRecoveryStrategy extends BaseErrorRecoveryStrategy {
  public canHandle(error: OrchestrationError): boolean {
    return error.category === 'network';
  }
  
  public getPriority(): number {
    return 70;
  }
  
  public getUserMessage(error: OrchestrationError): string {
    const networkError = error as NetworkError;
    const status = networkError.statusCode ? ` (${networkError.statusCode})` : '';
    return `Network error${status}: ${error.message}`;
  }
  
  public getSuggestedActions(error: OrchestrationError): readonly string[] {
    const networkError = error as NetworkError;
    const actions = ['Check your internet connection'];
    
    if (networkError.statusCode) {
      switch (networkError.statusCode) {
        case 401:
          actions.push('Check authentication credentials');
          break;
        case 403:
          actions.push('Verify you have permission to access this resource');
          break;
        case 404:
          actions.push('Check that the requested resource exists');
          break;
        case 429:
          actions.push('Wait before making more requests (rate limited)');
          break;
        case 500:
        case 502:
        case 503:
          actions.push('Server error - try again later');
          break;
      }
    }
    
    actions.push('Check firewall and proxy settings');
    
    return actions;
  }
  
  public async recover(error: OrchestrationError, context: ErrorRecoveryContext): Promise<RecoveryResult> {
    const networkError = error as NetworkError;
    
    // Handle specific HTTP status codes
    if (networkError.statusCode) {
      switch (networkError.statusCode) {
        case 429: // Rate limited
          return this.createFailureResult(
            'retry',
            'Rate limited, waiting before retry',
            true,
            Math.max(this.calculateRetryDelay(context.attemptCount), 5000) // At least 5 seconds
          );
          
        case 500:
        case 502:
        case 503:
          // Server errors - retry with exponential backoff
          return this.createFailureResult(
            'retry',
            'Server error, retrying with backoff',
            context.attemptCount < this.maxRetryAttempts,
            this.calculateRetryDelay(context.attemptCount)
          );
          
        case 401:
        case 403:
          // Authentication/authorization errors - manual intervention needed
          return this.createFailureResult(
            'manual',
            'Authentication error requires manual intervention',
            false
          );
          
        default:
          return this.createFailureResult(
            'retry',
            `HTTP ${networkError.statusCode} error, retrying`,
            context.attemptCount < this.maxRetryAttempts,
            this.calculateRetryDelay(context.attemptCount)
          );
      }
    }
    
    // Network connectivity issues - retry with backoff
    return this.createFailureResult(
      'retry',
      'Network connectivity issue, retrying',
      context.attemptCount < this.maxRetryAttempts,
      this.calculateRetryDelay(context.attemptCount)
    );
  }
}

/**
 * Recovery strategy for timeout errors.
 */
export class TimeoutErrorRecoveryStrategy extends BaseErrorRecoveryStrategy {
  public canHandle(error: OrchestrationError): boolean {
    return error.category === 'timeout';
  }
  
  public getPriority(): number {
    return 60;
  }
  
  public getUserMessage(error: OrchestrationError): string {
    const timeoutError = error as TimeoutError;
    return `Operation timed out: ${timeoutError.operation} (${timeoutError.timeoutMs}ms)`;
  }
  
  public getSuggestedActions(error: OrchestrationError): readonly string[] {
    return [
      'Try increasing the timeout duration',
      'Check system performance and resource usage',
      'Consider breaking the operation into smaller parts',
      'Verify network connectivity if applicable',
    ];
  }
  
  public async recover(error: OrchestrationError, context: ErrorRecoveryContext): Promise<RecoveryResult> {
    // Timeout errors can often be retried with longer timeout
    return this.createFailureResult(
      'retry',
      'Retrying operation with extended timeout',
      context.attemptCount < this.maxRetryAttempts,
      this.calculateRetryDelay(context.attemptCount)
    );
  }
}

/**
 * Manager for coordinating error recovery strategies.
 */
export class ErrorRecoveryManager {
  private readonly strategies: ErrorRecoveryStrategy[] = [];
  
  constructor() {
    // Register default recovery strategies
    this.registerStrategy(new ValidationErrorRecoveryStrategy());
    this.registerStrategy(new WorkspaceErrorRecoveryStrategy());
    this.registerStrategy(new KiroErrorRecoveryStrategy());
    this.registerStrategy(new NetworkErrorRecoveryStrategy());
    this.registerStrategy(new TimeoutErrorRecoveryStrategy());
  }
  
  /**
   * Registers a new error recovery strategy.
   * 
   * @param strategy - The strategy to register
   */
  public registerStrategy(strategy: ErrorRecoveryStrategy): void {
    this.strategies.push(strategy);
    // Sort by priority (highest first)
    this.strategies.sort((a, b) => b.getPriority() - a.getPriority());
  }
  
  /**
   * Determines if an error is recoverable.
   * 
   * @param error - The error to evaluate
   * @param context - Recovery context
   * @returns True if the error is recoverable
   */
  public isRecoverable(error: OrchestrationError, context: ErrorRecoveryContext): boolean {
    const strategy = this.findStrategy(error);
    return strategy ? strategy.isRecoverable(error, context) : false;
  }
  
  /**
   * Attempts to recover from an error.
   * 
   * @param error - The error to recover from
   * @param context - Recovery context
   * @returns Promise that resolves to the recovery result
   */
  public async recover(error: OrchestrationError, context: ErrorRecoveryContext): Promise<RecoveryResult> {
    const strategy = this.findStrategy(error);
    
    if (!strategy) {
      return {
        success: false,
        action: 'abort',
        message: 'No recovery strategy available for this error type',
        shouldRetry: false,
      };
    }
    
    if (!strategy.isRecoverable(error, context)) {
      return {
        success: false,
        action: 'abort',
        message: 'Error is not recoverable',
        shouldRetry: false,
      };
    }
    
    return strategy.recover(error, context);
  }
  
  /**
   * Gets a user-friendly error message.
   * 
   * @param error - The error to format
   * @returns User-friendly error message
   */
  public getUserMessage(error: OrchestrationError): string {
    const strategy = this.findStrategy(error);
    return strategy ? strategy.getUserMessage(error) : error.message;
  }
  
  /**
   * Gets suggested corrective actions for an error.
   * 
   * @param error - The error to provide suggestions for
   * @returns Array of suggested actions
   */
  public getSuggestedActions(error: OrchestrationError): readonly string[] {
    const strategy = this.findStrategy(error);
    return strategy ? strategy.getSuggestedActions(error) : [];
  }
  
  /**
   * Finds the appropriate recovery strategy for an error.
   * 
   * @param error - The error to find a strategy for
   * @returns The recovery strategy or null if none found
   */
  private findStrategy(error: OrchestrationError): ErrorRecoveryStrategy | null {
    return this.strategies.find(strategy => strategy.canHandle(error)) || null;
  }
}