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

/**
 * Validation functions for command execution interfaces.
 */
export const CommandValidation = {
  /**
   * Validates an ExecuteCommandRequest.
   */
  isValidExecuteCommandRequest(obj: unknown): obj is ExecuteCommandRequest {
    if (typeof obj !== 'object' || obj === null) {
      return false;
    }
    
    const req = obj as Record<string, unknown>;
    
    // Command is required and must be a non-empty string
    if (typeof req.command !== 'string' || req.command.trim() === '') {
      return false;
    }
    
    // Args is optional but must be array of strings if present
    if (req.args !== undefined) {
      if (!Array.isArray(req.args) || !req.args.every(arg => typeof arg === 'string')) {
        return false;
      }
    }
    
    // WorkspacePath is optional but must be string if present
    if (req.workspacePath !== undefined && typeof req.workspacePath !== 'string') {
      return false;
    }
    
    return true;
  },

  /**
   * Validates a CommandResult.
   */
  isValidCommandResult(obj: unknown): obj is CommandResult {
    if (typeof obj !== 'object' || obj === null) {
      return false;
    }
    
    const result = obj as Record<string, unknown>;
    
    return (
      typeof result.success === 'boolean' &&
      typeof result.output === 'string' &&
      typeof result.executionTimeMs === 'number' &&
      typeof result.command === 'string' &&
      Array.isArray(result.args) &&
      result.args.every(arg => typeof arg === 'string') &&
      (result.error === undefined || typeof result.error === 'string') &&
      (result.exitCode === undefined || typeof result.exitCode === 'number')
    );
  },

  /**
   * Validates a KiroStatus.
   */
  isValidKiroStatus(obj: unknown): obj is KiroStatus {
    if (typeof obj !== 'object' || obj === null) {
      return false;
    }
    
    const status = obj as Record<string, unknown>;
    const validStatuses: KiroStatusType[] = ['ready', 'busy', 'unavailable'];
    
    return (
      validStatuses.includes(status.status as KiroStatusType) &&
      (status.currentCommand === undefined || typeof status.currentCommand === 'string') &&
      (status.version === undefined || typeof status.version === 'string')
    );
  }
};