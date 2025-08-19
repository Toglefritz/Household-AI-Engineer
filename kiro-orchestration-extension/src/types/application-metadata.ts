/**
 * Application metadata types and interfaces for the Kiro Orchestration Extension.
 * 
 * This module defines the data structures used to represent application metadata
 * throughout the orchestration system, including validation and serialization.
 */

/**
 * Application development status enumeration.
 * 
 * Represents the current state of an application in the development lifecycle.
 */
export type ApplicationStatus = 
  | 'queued'          // Application is queued for development
  | 'developing'      // Application is currently being developed
  | 'waiting-input'   // Development is paused waiting for user input
  | 'paused'          // Development has been manually paused
  | 'completed'       // Application development is complete
  | 'failed'          // Application development has failed
  | 'cancelled';      // Application development was cancelled

/**
 * Development phase enumeration.
 * 
 * Represents the current phase of the development process.
 */
export type DevelopmentPhase = 
  | 'requirements'    // Analyzing and documenting requirements
  | 'design'          // Creating technical design and architecture
  | 'implementation'  // Writing code and implementing features
  | 'testing'         // Running tests and quality assurance
  | 'finalization';   // Final packaging and deployment preparation

/**
 * Job priority levels for development queue management.
 */
export type JobPriority = 'low' | 'normal' | 'high';

/**
 * Progress information for application development.
 * 
 * Tracks the current state and progress of the development process.
 */
export interface DevelopmentProgress {
  /** Completion percentage (0-100) */
  readonly percentage: number;
  
  /** Current development phase */
  readonly currentPhase: DevelopmentPhase;
  
  /** Description of current task being performed */
  readonly currentTask: string;
  
  /** Estimated completion timestamp (ISO 8601 format) */
  readonly estimatedCompletion?: string;
  
  /** List of completed milestones */
  readonly completedMilestones: readonly string[];
  
  /** List of remaining milestones */
  readonly remainingMilestones: readonly string[];
}

/**
 * Development job configuration settings.
 * 
 * Controls various aspects of how the development job is processed.
 */
export interface JobConfiguration {
  /** Priority level for job processing */
  readonly priority: JobPriority;
  
  /** Maximum development time in milliseconds */
  readonly timeoutMs: number;
  
  /** Whether debug logging is enabled for this job */
  readonly debugLogging: boolean;
}

/**
 * Error information for failed development operations.
 * 
 * Provides detailed information about errors that occur during development.
 */
export interface ApplicationError {
  /** Human-readable error message */
  readonly message: string;
  
  /** Error code for programmatic handling */
  readonly code: string;
  
  /** Whether the error is recoverable through retry or user action */
  readonly recoverable: boolean;
  
  /** Timestamp when the error occurred (ISO 8601 format) */
  readonly occurredAt: string;
  
  /** Additional context information for debugging */
  readonly context?: Record<string, unknown>;
}

/**
 * File paths within the application workspace.
 * 
 * Tracks important files generated during development.
 */
export interface ApplicationFiles {
  /** Path to the main application entry point */
  readonly mainFile?: string;
  
  /** Path to the README file */
  readonly readme?: string;
  
  /** Path to the package.json or equivalent configuration file */
  readonly packageFile?: string;
  
  /** Paths to key source files */
  readonly sourceFiles: readonly string[];
}

/**
 * Complete application metadata structure.
 * 
 * This interface represents all information about an application managed
 * by the orchestration system, including its current state, configuration,
 * and development progress.
 */
export interface ApplicationMetadata {
  /** Unique identifier for the application */
  readonly id: string;
  
  /** Human-readable application title */
  readonly title: string;
  
  /** Detailed description of the application's purpose and functionality */
  readonly description: string;
  
  /** Current development status */
  readonly status: ApplicationStatus;
  
  /** Timestamp when the application was created (ISO 8601 format) */
  readonly createdAt: string;
  
  /** Timestamp of the last status update (ISO 8601 format) */
  readonly updatedAt: string;
  
  /** Current development progress information */
  readonly progress: DevelopmentProgress;
  
  /** Development job configuration */
  readonly jobConfig: JobConfiguration;
  
  /** Error information if development failed */
  readonly error?: ApplicationError;
  
  /** Paths to important files within the workspace */
  readonly files: ApplicationFiles;
  
  /** Original user request that initiated this application */
  readonly userRequest: {
    /** Natural language description provided by user */
    readonly description: string;
    
    /** Optional conversation context ID */
    readonly conversationId?: string;
  };
}