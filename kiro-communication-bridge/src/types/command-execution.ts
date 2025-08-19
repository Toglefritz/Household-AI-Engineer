/**
 * Command execution interfaces for the Kiro Communication Bridge.
 * 
 * This module defines the data structures used for executing commands
 * and managing communication between the Flutter frontend and Kiro IDE.
 */

/**
 * Request to execute a Kiro command.
 */
export interface ExecuteCommandRequest {
  /** Kiro command to execute */
  command: string;
  
  /** Optional command arguments */
  args?: string[];
  
  /** Optional workspace context path */
  workspacePath?: string;
}

/**
 * Response from command execution.
 */
export interface ExecuteCommandResponse {
  /** Whether command executed successfully */
  success: boolean;
  
  /** Command output */
  output: string;
  
  /** Error message if failed */
  error?: string;
  
  /** Execution time in milliseconds */
  executionTimeMs: number;
}

/**
 * Result of a command execution with detailed information.
 */
export interface CommandResult {
  /** Whether the command executed successfully */
  success: boolean;
  
  /** Command output text */
  output: string;
  
  /** Error message if command failed */
  error?: string;
  
  /** Execution time in milliseconds */
  executionTimeMs: number;
  
  /** Exit code from the command */
  exitCode?: number;
  
  /** Command that was executed */
  command: string;
  
  /** Arguments passed to the command */
  args: string[];
}

/**
 * Current status of Kiro IDE.
 */
export type KiroStatusType = 'ready' | 'busy' | 'unavailable';

/**
 * Kiro IDE status information.
 */
export interface KiroStatus {
  /** Current Kiro status */
  status: KiroStatusType;
  
  /** Currently executing command if busy */
  currentCommand?: string;
  
  /** Kiro version information */
  version?: string;
}

/**
 * Response for Kiro status queries.
 */
export interface KiroStatusResponse extends KiroStatus {
  /** List of available commands */
  availableCommands: string[];
  
  /** Timestamp when status was checked */
  timestamp: string;
}

/**
 * Represents a command execution in progress.
 */
export interface CommandExecution {
  /** Unique execution ID */
  id: string;
  
  /** Command being executed */
  command: string;
  
  /** Command arguments */
  args: string[];
  
  /** Workspace context */
  workspacePath?: string;
  
  /** Execution start time */
  startedAt: Date;
  
  /** Execution completion time */
  completedAt?: Date;
  
  /** Current status */
  status: 'running' | 'completed' | 'failed';
  
  /** Accumulated output */
  output: string;
  
  /** Error information if failed */
  error?: string;
}