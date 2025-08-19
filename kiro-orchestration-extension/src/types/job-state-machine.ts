/**
 * Job state machine for managing development job lifecycle transitions.
 * 
 * This module provides utilities for managing valid state transitions,
 * validating job state changes, and ensuring proper job lifecycle management.
 */

import { JobStatus } from './development-job';

/**
 * Valid state transitions for development jobs.
 * 
 * This map defines which status transitions are allowed, ensuring that
 * jobs follow a proper lifecycle and preventing invalid state changes.
 */
export const VALID_JOB_TRANSITIONS: Record<JobStatus, readonly JobStatus[]> = {
  'queued': ['initializing', 'cancelled'],
  'initializing': ['developing', 'failed', 'cancelled'],
  'developing': ['waiting-input', 'testing', 'paused', 'failed', 'cancelled'],
  'waiting-input': ['developing', 'failed', 'cancelled'],
  'paused': ['developing', 'cancelled'],
  'testing': ['finalizing', 'developing', 'failed', 'cancelled'],
  'finalizing': ['completed', 'failed', 'cancelled'],
  'completed': [], // Terminal state - no transitions allowed
  'failed': [], // Terminal state - no transitions allowed
  'cancelled': [], // Terminal state - no transitions allowed
} as const;

/**
 * Terminal job statuses that cannot transition to other states.
 */
export const TERMINAL_JOB_STATUSES: readonly JobStatus[] = ['completed', 'failed', 'cancelled'] as const;

/**
 * Active job statuses that indicate the job is currently being processed.
 */
export const ACTIVE_JOB_STATUSES: readonly JobStatus[] = [
  'queued',
  'initializing',
  'developing',
  'waiting-input',
  'paused',
  'testing',
  'finalizing',
] as const;

/**
 * Job statuses that indicate the job has encountered an error or been stopped.
 */
export const ERROR_JOB_STATUSES: readonly JobStatus[] = ['failed', 'cancelled'] as const;

/**
 * Job statuses that indicate the job is actively running (not paused or waiting).
 */
export const RUNNING_JOB_STATUSES: readonly JobStatus[] = [
  'initializing',
  'developing',
  'testing',
  'finalizing',
] as const;

/**
 * Error thrown when an invalid job state transition is attempted.
 */
export class InvalidJobTransitionError extends Error {
  /**
   * Creates a new invalid job transition error.
   * 
   * @param fromStatus - The current job status
   * @param toStatus - The attempted new status
   * @param jobId - The ID of the job being transitioned
   */
  constructor(
    public readonly fromStatus: JobStatus,
    public readonly toStatus: JobStatus,
    public readonly jobId: string
  ) {
    super(`Invalid job transition from '${fromStatus}' to '${toStatus}' for job ${jobId}`);
    this.name = 'InvalidJobTransitionError';
  }
}

/**
 * Validates whether a job status transition is allowed.
 * 
 * @param fromStatus - Current job status
 * @param toStatus - Desired new status
 * @returns True if the transition is valid, false otherwise
 */
export function isValidJobTransition(fromStatus: JobStatus, toStatus: JobStatus): boolean {
  const allowedTransitions = VALID_JOB_TRANSITIONS[fromStatus];
  return allowedTransitions.includes(toStatus);
}

/**
 * Validates a job status transition and throws an error if invalid.
 * 
 * @param fromStatus - Current job status
 * @param toStatus - Desired new status
 * @param jobId - ID of the job being transitioned
 * @throws InvalidJobTransitionError if the transition is not valid
 */
export function validateJobTransition(fromStatus: JobStatus, toStatus: JobStatus, jobId: string): void {
  if (!isValidJobTransition(fromStatus, toStatus)) {
    throw new InvalidJobTransitionError(fromStatus, toStatus, jobId);
  }
}

/**
 * Checks if a job status is terminal (cannot transition to other states).
 * 
 * @param status - Job status to check
 * @returns True if the status is terminal, false otherwise
 */
export function isTerminalJobStatus(status: JobStatus): boolean {
  return TERMINAL_JOB_STATUSES.includes(status);
}

/**
 * Checks if a job status indicates the job is active (not completed, failed, or cancelled).
 * 
 * @param status - Job status to check
 * @returns True if the status indicates an active job, false otherwise
 */
export function isActiveJobStatus(status: JobStatus): boolean {
  return ACTIVE_JOB_STATUSES.includes(status);
}

/**
 * Checks if a job status indicates an error or cancellation.
 * 
 * @param status - Job status to check
 * @returns True if the status indicates an error state, false otherwise
 */
export function isErrorJobStatus(status: JobStatus): boolean {
  return ERROR_JOB_STATUSES.includes(status);
}

/**
 * Checks if a job status indicates the job is currently running (not paused or waiting).
 * 
 * @param status - Job status to check
 * @returns True if the status indicates a running job, false otherwise
 */
export function isRunningJobStatus(status: JobStatus): boolean {
  return RUNNING_JOB_STATUSES.includes(status);
}

/**
 * Gets all valid next statuses for a given current status.
 * 
 * @param currentStatus - Current job status
 * @returns Array of valid next statuses
 */
export function getValidNextStatuses(currentStatus: JobStatus): readonly JobStatus[] {
  return VALID_JOB_TRANSITIONS[currentStatus];
}

/**
 * Gets a human-readable description of a job status.
 * 
 * @param status - Job status to describe
 * @returns Human-readable description of the status
 */
export function getJobStatusDescription(status: JobStatus): string {
  const descriptions: Record<JobStatus, string> = {
    'queued': 'Waiting in queue for processing',
    'initializing': 'Setting up workspace and initializing development environment',
    'developing': 'Actively developing the application using Kiro IDE',
    'waiting-input': 'Paused and waiting for user input or clarification',
    'paused': 'Manually paused by user or system',
    'testing': 'Running tests and quality assurance checks',
    'finalizing': 'Finalizing application and preparing for deployment',
    'completed': 'Successfully completed development',
    'failed': 'Development failed due to an error',
    'cancelled': 'Development was cancelled by user or system',
  };
  
  return descriptions[status];
}

/**
 * Determines the appropriate next status based on current status and conditions.
 * 
 * This function provides intelligent status progression based on the current
 * state and development phase.
 * 
 * @param currentStatus - Current job status
 * @param conditions - Conditions that might affect the next status
 * @returns Suggested next status or null if no automatic transition is appropriate
 */
export function suggestNextJobStatus(
  currentStatus: JobStatus,
  conditions: {
    hasError?: boolean;
    userInputRequired?: boolean;
    isPaused?: boolean;
    isComplete?: boolean;
    needsTesting?: boolean;
  } = {}
): JobStatus | null {
  // Handle error conditions first
  if (conditions.hasError) {
    return isValidJobTransition(currentStatus, 'failed') ? 'failed' : null;
  }
  
  // Handle completion
  if (conditions.isComplete) {
    return isValidJobTransition(currentStatus, 'completed') ? 'completed' : null;
  }
  
  // Handle user input requirement
  if (conditions.userInputRequired) {
    return isValidJobTransition(currentStatus, 'waiting-input') ? 'waiting-input' : null;
  }
  
  // Handle pause request
  if (conditions.isPaused) {
    return isValidJobTransition(currentStatus, 'paused') ? 'paused' : null;
  }
  
  // Handle normal progression
  switch (currentStatus) {
    case 'queued':
      return 'initializing';
      
    case 'initializing':
      return 'developing';
      
    case 'developing':
      return conditions.needsTesting ? 'testing' : 'finalizing';
      
    case 'waiting-input':
      return 'developing';
      
    case 'paused':
      return 'developing';
      
    case 'testing':
      return 'finalizing';
      
    case 'finalizing':
      return 'completed';
      
    default:
      return null;
  }
}