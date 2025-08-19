/**
 * Development job types and interfaces for the Kiro Communication Bridge Extension.
 * 
 * This module defines the data structures used to represent development jobs
 * throughout the orchestration system, including job state management and
 * lifecycle tracking.
 */

import { ApplicationMetadata, DevelopmentPhase, JobPriority } from './application-metadata';

/**
 * Development job status enumeration.
 * 
 * Represents the current state of a development job in the processing pipeline.
 */
export type JobStatus = 
  | 'queued'          // Job is queued and waiting to be processed
  | 'initializing'    // Job is being initialized and workspace is being set up
  | 'developing'      // Job is actively being developed by Kiro
  | 'waiting-input'   // Job is paused waiting for user input
  | 'paused'          // Job has been manually paused
  | 'testing'         // Job is in the testing phase
  | 'finalizing'      // Job is being finalized and packaged
  | 'completed'       // Job has completed successfully
  | 'failed'          // Job has failed and cannot continue
  | 'cancelled';      // Job was cancelled by user or system

/**
 * User input types for interactive development.
 */
export type UserInputType = 'text' | 'choice' | 'file' | 'confirmation';

/**
 * Log entry for job execution tracking.
 */
export interface JobLogEntry {
  /** Timestamp when the log entry was created (ISO 8601 format) */
  readonly timestamp: string;
  
  /** Log level */
  readonly level: 'debug' | 'info' | 'warn' | 'error';
  
  /** Log message */
  readonly message: string;
  
  /** Component that generated the log entry */
  readonly component: string;
  
  /** Additional context data */
  readonly context?: Record<string, unknown>;
}

/**
 * User interaction state for jobs requiring input.
 */
export interface UserInteractionState {
  /** Whether the job is currently waiting for user input */
  readonly waitingForInput: boolean;
  
  /** Question or prompt posed to the user */
  readonly question?: string;
  
  /** Type of input expected from the user */
  readonly inputType?: UserInputType;
  
  /** Available choices for choice-type inputs */
  readonly choices?: readonly string[];
  
  /** Timestamp when input was requested (ISO 8601 format) */
  readonly requestedAt?: string;
  
  /** Timeout for user input in milliseconds */
  readonly timeoutMs?: number;
}

/**
 * Kiro session information for active development.
 */
export interface KiroSessionInfo {
  /** Unique session identifier */
  readonly sessionId: string;
  
  /** Path to the workspace directory */
  readonly workspacePath: string;
  
  /** Process ID of the active Kiro command */
  readonly processId?: number;
  
  /** Current command being executed */
  readonly currentCommand?: string;
  
  /** Session start timestamp (ISO 8601 format) */
  readonly startedAt: string;
  
  /** Last activity timestamp (ISO 8601 format) */
  readonly lastActivityAt: string;
}

/**
 * Job progress tracking information.
 */
export interface JobProgressInfo {
  /** Current completion percentage (0-100) */
  readonly percentage: number;
  
  /** Current development phase */
  readonly phase: DevelopmentPhase;
  
  /** Timestamp when the current phase started (ISO 8601 format) */
  readonly phaseStartedAt: string;
  
  /** List of completed tasks */
  readonly completedTasks: readonly string[];
  
  /** Current task being executed */
  readonly currentTask?: string;
  
  /** Estimated time remaining in milliseconds */
  readonly estimatedRemainingMs?: number;
}

/**
 * Original user request information.
 */
export interface UserRequestInfo {
  /** Natural language description of the desired application */
  readonly description: string;
  
  /** Optional conversation context ID */
  readonly conversationId?: string;
  
  /** Job priority level */
  readonly priority: JobPriority;
  
  /** Timestamp when the request was made (ISO 8601 format) */
  readonly requestedAt: string;
  
  /** User ID or identifier (if available) */
  readonly userId?: string;
}

/**
 * Complete development job structure.
 * 
 * This interface represents all information about a development job managed
 * by the orchestration system, including its current state, progress, and
 * execution context.
 */
export interface DevelopmentJob {
  /** Unique job identifier */
  readonly id: string;
  
  /** Associated application ID */
  readonly applicationId: string;
  
  /** Current job status */
  readonly status: JobStatus;
  
  /** Job creation timestamp (ISO 8601 format) */
  readonly createdAt: string;
  
  /** Job start timestamp (ISO 8601 format) */
  readonly startedAt?: string;
  
  /** Job completion timestamp (ISO 8601 format) */
  readonly completedAt?: string;
  
  /** Last update timestamp (ISO 8601 format) */
  readonly updatedAt: string;
  
  /** Original user request information */
  readonly userRequest: UserRequestInfo;
  
  /** Current Kiro session information */
  readonly kiroSession?: KiroSessionInfo;
  
  /** Progress tracking information */
  readonly progress: JobProgressInfo;
  
  /** User interaction state */
  readonly userInteraction?: UserInteractionState;
  
  /** Job execution logs */
  readonly logs: readonly JobLogEntry[];
  
  /** Job timeout in milliseconds */
  readonly timeoutMs: number;
  
  /** Whether debug logging is enabled */
  readonly debugLogging: boolean;
  
  /** Number of retry attempts made */
  readonly retryCount: number;
  
  /** Maximum number of retry attempts allowed */
  readonly maxRetries: number;
  
  /** Error information if job failed */
  readonly error?: {
    /** Error message */
    readonly message: string;
    
    /** Error code */
    readonly code: string;
    
    /** Whether the error is recoverable */
    readonly recoverable: boolean;
    
    /** Timestamp when error occurred (ISO 8601 format) */
    readonly occurredAt: string;
    
    /** Stack trace or additional error details */
    readonly details?: string;
  };
}