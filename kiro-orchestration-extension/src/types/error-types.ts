/**
 * Error types and classification for the Kiro Orchestration Extension.
 * 
 * This module defines a comprehensive error hierarchy for handling various
 * types of errors that can occur during application development orchestration.
 */

/**
 * Error categories for classification and handling.
 */
export type ErrorCategory = 
  | 'validation'      // Input validation and data format errors
  | 'workspace'       // File system and workspace management errors
  | 'kiro'           // Kiro IDE integration and command execution errors
  | 'network'        // API communication and network-related errors
  | 'system'         // System resource and unexpected errors
  | 'timeout'        // Operation timeout errors
  | 'authentication' // Authentication and authorization errors
  | 'quota'          // Resource quota and limit errors
  | 'configuration'; // Configuration and setup errors

/**
 * Error severity levels for prioritization and handling.
 */
export type ErrorSeverity = 
  | 'low'      // Minor issues that don't prevent operation
  | 'medium'   // Issues that may impact functionality
  | 'high'     // Serious issues that prevent normal operation
  | 'critical'; // Critical failures that require immediate attention

/**
 * Recovery action types that can be taken for errors.
 */
export type RecoveryAction = 
  | 'retry'           // Retry the failed operation
  | 'user-input'      // Request user input or clarification
  | 'fallback'        // Use alternative approach or fallback method
  | 'restart'         // Restart the process or session
  | 'manual'          // Requires manual intervention
  | 'abort';          // Cannot be recovered, abort operation

/**
 * Base error interface for all orchestration errors.
 */
export interface OrchestrationError {
  /** Unique error identifier */
  readonly id: string;
  
  /** Error category for classification */
  readonly category: ErrorCategory;
  
  /** Error severity level */
  readonly severity: ErrorSeverity;
  
  /** Human-readable error message */
  readonly message: string;
  
  /** Technical error code for programmatic handling */
  readonly code: string;
  
  /** Whether the error is recoverable */
  readonly recoverable: boolean;
  
  /** Suggested recovery actions */
  readonly recoveryActions: readonly RecoveryAction[];
  
  /** Timestamp when the error occurred (ISO 8601 format) */
  readonly occurredAt: string;
  
  /** Component or service where the error originated */
  readonly source: string;
  
  /** Additional context information */
  readonly context: Record<string, unknown>;
  
  /** Stack trace or detailed error information */
  readonly details?: string;
  
  /** Underlying cause if this error wraps another error */
  readonly cause?: Error;
}

/**
 * Validation error for input validation failures.
 */
export interface ValidationError extends OrchestrationError {
  readonly category: 'validation';
  
  /** Field or parameter that failed validation */
  readonly field: string;
  
  /** Value that failed validation */
  readonly value: unknown;
  
  /** Validation rule that was violated */
  readonly rule: string;
}

/**
 * Workspace error for file system and workspace operations.
 */
export interface WorkspaceError extends OrchestrationError {
  readonly category: 'workspace';
  
  /** Path where the error occurred */
  readonly path: string;
  
  /** File system operation that failed */
  readonly operation: 'create' | 'read' | 'write' | 'delete' | 'copy' | 'move' | 'permissions';
  
  /** System error code if available */
  readonly systemErrorCode?: string;
}

/**
 * Kiro integration error for command execution and IDE interaction.
 */
export interface KiroError extends OrchestrationError {
  readonly category: 'kiro';
  
  /** Kiro command that failed */
  readonly command?: string;
  
  /** Command arguments */
  readonly args?: readonly string[];
  
  /** Exit code from the command */
  readonly exitCode?: number;
  
  /** Standard output from the command */
  readonly stdout?: string;
  
  /** Standard error from the command */
  readonly stderr?: string;
  
  /** Session ID where the error occurred */
  readonly sessionId?: string;
}

/**
 * Network error for API communication failures.
 */
export interface NetworkError extends OrchestrationError {
  readonly category: 'network';
  
  /** HTTP status code if applicable */
  readonly statusCode?: number;
  
  /** Request URL that failed */
  readonly url?: string;
  
  /** HTTP method used */
  readonly method?: string;
  
  /** Request timeout in milliseconds */
  readonly timeoutMs?: number;
  
  /** Number of retry attempts made */
  readonly retryAttempts?: number;
}

/**
 * System error for resource and unexpected failures.
 */
export interface SystemError extends OrchestrationError {
  readonly category: 'system';
  
  /** System resource that was exhausted or unavailable */
  readonly resource?: 'memory' | 'disk' | 'cpu' | 'network' | 'processes';
  
  /** Current resource usage if available */
  readonly resourceUsage?: Record<string, number>;
  
  /** System limits if available */
  readonly resourceLimits?: Record<string, number>;
}

/**
 * Timeout error for operations that exceed time limits.
 */
export interface TimeoutError extends OrchestrationError {
  readonly category: 'timeout';
  
  /** Operation that timed out */
  readonly operation: string;
  
  /** Timeout duration in milliseconds */
  readonly timeoutMs: number;
  
  /** Elapsed time before timeout in milliseconds */
  readonly elapsedMs: number;
}

/**
 * Authentication error for access control failures.
 */
export interface AuthenticationError extends OrchestrationError {
  readonly category: 'authentication';
  
  /** Authentication method that failed */
  readonly authMethod?: 'api-key' | 'token' | 'session';
  
  /** Whether the credentials were missing or invalid */
  readonly credentialStatus: 'missing' | 'invalid' | 'expired';
}

/**
 * Quota error for resource limit violations.
 */
export interface QuotaError extends OrchestrationError {
  readonly category: 'quota';
  
  /** Resource that exceeded quota */
  readonly resource: 'applications' | 'jobs' | 'storage' | 'requests';
  
  /** Current usage amount */
  readonly currentUsage: number;
  
  /** Maximum allowed quota */
  readonly quota: number;
  
  /** Unit of measurement */
  readonly unit: string;
}

/**
 * Configuration error for setup and configuration issues.
 */
export interface ConfigurationError extends OrchestrationError {
  readonly category: 'configuration';
  
  /** Configuration key that is invalid */
  readonly configKey?: string;
  
  /** Expected configuration format or value */
  readonly expectedFormat?: string;
  
  /** Actual configuration value */
  readonly actualValue?: unknown;
}

/**
 * Union type for all specific error types.
 */
export type SpecificOrchestrationError = 
  | ValidationError
  | WorkspaceError
  | KiroError
  | NetworkError
  | SystemError
  | TimeoutError
  | AuthenticationError
  | QuotaError
  | ConfigurationError;

/**
 * Error recovery context information.
 */
export interface ErrorRecoveryContext {
  /** Error that needs recovery */
  readonly error: OrchestrationError;
  
  /** Number of recovery attempts made */
  readonly attemptCount: number;
  
  /** Maximum recovery attempts allowed */
  readonly maxAttempts: number;
  
  /** Time elapsed since first recovery attempt */
  readonly elapsedMs: number;
  
  /** Previous recovery actions attempted */
  readonly previousActions: readonly RecoveryAction[];
  
  /** Additional context for recovery decision */
  readonly context: Record<string, unknown>;
}

/**
 * Result of an error recovery attempt.
 */
export interface RecoveryResult {
  /** Whether the recovery was successful */
  readonly success: boolean;
  
  /** Recovery action that was taken */
  readonly action: RecoveryAction;
  
  /** Message describing the recovery result */
  readonly message: string;
  
  /** Whether another recovery attempt should be made */
  readonly shouldRetry: boolean;
  
  /** Delay before next retry in milliseconds */
  readonly retryDelayMs?: number;
  
  /** Additional data from the recovery attempt */
  readonly data?: Record<string, unknown>;
  
  /** New error if recovery failed */
  readonly error?: OrchestrationError;
}