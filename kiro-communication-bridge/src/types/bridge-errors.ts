/**
 * Error handling types for the Kiro Communication Bridge.
 * 
 * This module defines error classes and types specific to the communication
 * bridge functionality, focusing on command execution, WebSocket communication,
 * and Kiro availability issues.
 */

/**
 * Base error class for all bridge-related errors.
 * 
 * Provides common error properties and methods for all bridge errors.
 */
export abstract class BridgeError extends Error {
  /** Unique error code for programmatic handling */
  public abstract readonly code: string;
  
  /** Whether this error can be recovered from */
  public abstract readonly recoverable: boolean;
  
  /** Timestamp when the error occurred */
  public readonly timestamp: string;
  
  /** Additional context information */
  public readonly context: Record<string, unknown>;

  constructor(
    message: string,
    context: Record<string, unknown> = {}
  ) {
    super(message);
    this.name = this.constructor.name;
    this.timestamp = new Date().toISOString();
    this.context = { ...context };
    
    // Ensure proper prototype chain for instanceof checks
    Object.setPrototypeOf(this, new.target.prototype);
  }

  /**
   * Returns a sanitized error message safe for client display.
   */
  public getSanitizedMessage(): string {
    // Remove sensitive information like file paths, internal details
    return this.message
      .replace(/\/[^\s]+/g, '[path]')  // Replace file paths
      .replace(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/g, '[ip]')  // Replace IP addresses
      .replace(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, '[email]');  // Replace emails
  }

  /**
   * Returns error information suitable for logging.
   */
  public toLogInfo(): Record<string, unknown> {
    return {
      name: this.name,
      code: this.code,
      message: this.message,
      recoverable: this.recoverable,
      timestamp: this.timestamp,
      context: this.context,
      stack: this.stack
    };
  }

  /**
   * Returns error information suitable for client response.
   */
  public toClientInfo(): Record<string, unknown> {
    return {
      code: this.code,
      message: this.getSanitizedMessage(),
      recoverable: this.recoverable,
      timestamp: this.timestamp
    };
  }
}

/**
 * Error thrown when Kiro command execution fails.
 */
export class CommandExecutionError extends BridgeError {
  public readonly code = 'COMMAND_EXECUTION_FAILED';
  public readonly recoverable = true;

  /** Command that failed */
  public readonly command: string;
  
  /** Command arguments */
  public readonly args: string[];
  
  /** Exit code from the failed command */
  public readonly exitCode?: number;
  
  /** Standard output from the command */
  public readonly stdout?: string;
  
  /** Standard error from the command */
  public readonly stderr?: string;

  constructor(
    command: string,
    args: string[],
    originalError: string,
    options: {
      exitCode?: number;
      stdout?: string;
      stderr?: string;
      context?: Record<string, unknown>;
    } = {}
  ) {
    super(`Command '${command}' failed: ${originalError}`, {
      command,
      args,
      ...options.context
    });
    
    this.command = command;
    this.args = args;
    this.exitCode = options.exitCode;
    this.stdout = options.stdout;
    this.stderr = options.stderr;
  }
}

/**
 * Error thrown when Kiro IDE is not available or not responding.
 */
export class KiroUnavailableError extends BridgeError {
  public readonly code = 'KIRO_UNAVAILABLE';
  public readonly recoverable = true;

  /** Reason why Kiro is unavailable */
  public readonly reason: 'not_installed' | 'not_running' | 'not_responding' | 'unknown';

  constructor(
    reason: 'not_installed' | 'not_running' | 'not_responding' | 'unknown' = 'unknown',
    context: Record<string, unknown> = {}
  ) {
    const messages = {
      not_installed: 'Kiro IDE is not installed or not found in PATH',
      not_running: 'Kiro IDE is not currently running',
      not_responding: 'Kiro IDE is not responding to commands',
      unknown: 'Kiro IDE is not available'
    };

    super(messages[reason], { reason, ...context });
    this.reason = reason;
  }
}

/**
 * Error thrown when WebSocket communication fails.
 */
export class WebSocketError extends BridgeError {
  public readonly code = 'WEBSOCKET_ERROR';
  public readonly recoverable = true;

  /** Type of WebSocket error */
  public readonly errorType: 'connection_failed' | 'send_failed' | 'invalid_message' | 'client_disconnected';
  
  /** WebSocket error code if available */
  public readonly wsCode?: number;
  
  /** WebSocket close reason if available */
  public readonly wsReason?: string;

  constructor(
    errorType: 'connection_failed' | 'send_failed' | 'invalid_message' | 'client_disconnected',
    originalError: string,
    options: {
      wsCode?: number;
      wsReason?: string;
      context?: Record<string, unknown>;
    } = {}
  ) {
    super(`WebSocket ${errorType.replace('_', ' ')}: ${originalError}`, {
      errorType,
      wsCode: options.wsCode,
      wsReason: options.wsReason,
      ...options.context
    });
    
    this.errorType = errorType;
    this.wsCode = options.wsCode;
    this.wsReason = options.wsReason;
  }
}

/**
 * Error thrown when request validation fails.
 */
export class ValidationError extends BridgeError {
  public readonly code = 'VALIDATION_FAILED';
  public readonly recoverable = false;

  /** Field that failed validation */
  public readonly field?: string;
  
  /** Value that failed validation */
  public readonly value?: unknown;
  
  /** Validation rule that was violated */
  public readonly rule?: string;

  constructor(
    message: string,
    options: {
      field?: string;
      value?: unknown;
      rule?: string;
      context?: Record<string, unknown>;
    } = {}
  ) {
    super(message, {
      field: options.field,
      rule: options.rule,
      ...options.context
    });
    
    this.field = options.field;
    this.value = options.value;
    this.rule = options.rule;
  }
}

/**
 * Error thrown when operation times out.
 */
export class TimeoutError extends BridgeError {
  public readonly code = 'OPERATION_TIMEOUT';
  public readonly recoverable = true;

  /** Operation that timed out */
  public readonly operation: string;
  
  /** Timeout duration in milliseconds */
  public readonly timeoutMs: number;
  
  /** Elapsed time before timeout in milliseconds */
  public readonly elapsedMs: number;

  constructor(
    operation: string,
    timeoutMs: number,
    elapsedMs: number,
    context: Record<string, unknown> = {}
  ) {
    super(
      `Operation '${operation}' timed out after ${elapsedMs}ms (limit: ${timeoutMs}ms)`,
      { operation, timeoutMs, elapsedMs, ...context }
    );
    
    this.operation = operation;
    this.timeoutMs = timeoutMs;
    this.elapsedMs = elapsedMs;
  }
}

/**
 * Type guard to check if an error is a BridgeError.
 */
export function isBridgeError(error: unknown): error is BridgeError {
  return error instanceof BridgeError;
}