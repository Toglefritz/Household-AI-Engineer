/**
 * Factory functions for creating and manipulating DevelopmentJob objects.
 * 
 * This module provides utilities for creating, updating, and managing
 * development jobs with proper validation and state management.
 */

import { v4 as uuidv4 } from 'uuid';
import {
  DevelopmentJob,
  JobStatus,
  JobLogEntry,
  UserInteractionState,
  KiroSessionInfo,
  JobProgressInfo,
  UserRequestInfo,
  UserInputType,
} from './development-job';
import { JobPriority, DevelopmentPhase } from './application-metadata';
import { validateJobTransition } from './job-state-machine';

/**
 * Parameters for creating a new development job.
 */
export interface CreateDevelopmentJobParams {
  /** Associated application ID */
  applicationId: string;
  
  /** Natural language description of the desired application */
  userRequestDescription: string;
  
  /** Optional conversation context ID */
  conversationId?: string;
  
  /** Job priority (defaults to 'normal') */
  priority?: JobPriority;
  
  /** Job timeout in milliseconds (defaults to 30 minutes) */
  timeoutMs?: number;
  
  /** Enable debug logging (defaults to false) */
  debugLogging?: boolean;
  
  /** Maximum retry attempts (defaults to 3) */
  maxRetries?: number;
  
  /** User ID or identifier */
  userId?: string;
}

/**
 * Parameters for updating a development job.
 */
export interface UpdateDevelopmentJobParams {
  /** New job status */
  status?: JobStatus;
  
  /** Updated progress information */
  progress?: Partial<JobProgressInfo>;
  
  /** Kiro session information */
  kiroSession?: KiroSessionInfo;
  
  /** User interaction state */
  userInteraction?: UserInteractionState;
  
  /** Error information */
  error?: DevelopmentJob['error'];
  
  /** Additional log entries */
  logEntries?: JobLogEntry[];
  
  /** Increment retry count */
  incrementRetryCount?: boolean;
}

/**
 * Validation error for development job operations.
 */
export class DevelopmentJobValidationError extends Error {
  constructor(message: string, public readonly field: string, public readonly value: unknown) {
    super(message);
    this.name = 'DevelopmentJobValidationError';
  }
}

/**
 * Creates a new DevelopmentJob object with default values.
 * 
 * @param params - Parameters for creating the development job
 * @returns A new DevelopmentJob object
 * @throws DevelopmentJobValidationError if parameters are invalid
 */
export function createDevelopmentJob(params: CreateDevelopmentJobParams): DevelopmentJob {
  // Validate required parameters
  if (!params.applicationId || params.applicationId.trim().length === 0) {
    throw new DevelopmentJobValidationError(
      'Application ID is required and cannot be empty',
      'applicationId',
      params.applicationId
    );
  }
  
  if (!params.userRequestDescription || params.userRequestDescription.trim().length === 0) {
    throw new DevelopmentJobValidationError(
      'User request description is required and cannot be empty',
      'userRequestDescription',
      params.userRequestDescription
    );
  }
  
  const now: string = new Date().toISOString();
  const jobId: string = uuidv4();
  
  const job: DevelopmentJob = {
    id: jobId,
    applicationId: params.applicationId.trim(),
    status: 'queued',
    createdAt: now,
    updatedAt: now,
    userRequest: {
      description: params.userRequestDescription.trim(),
      conversationId: params.conversationId,
      priority: params.priority || 'normal',
      requestedAt: now,
      userId: params.userId,
    },
    progress: {
      percentage: 0,
      phase: 'requirements',
      phaseStartedAt: now,
      completedTasks: [],
    },
    logs: [
      createJobLogEntry('info', 'Development job created and queued for processing', 'JobFactory'),
    ],
    timeoutMs: params.timeoutMs || 1800000, // 30 minutes default
    debugLogging: params.debugLogging || false,
    retryCount: 0,
    maxRetries: params.maxRetries || 3,
  };
  
  return job;
}

/**
 * Updates an existing DevelopmentJob with new values.
 * 
 * @param currentJob - The current development job
 * @param updates - The updates to apply
 * @returns A new DevelopmentJob object with updates applied
 * @throws DevelopmentJobValidationError if updates are invalid
 */
export function updateDevelopmentJob(
  currentJob: DevelopmentJob,
  updates: UpdateDevelopmentJobParams
): DevelopmentJob {
  const now: string = new Date().toISOString();
  
  // Validate status transition if status is being updated
  if (updates.status && updates.status !== currentJob.status) {
    validateJobTransition(currentJob.status, updates.status, currentJob.id);
  }
  
  // Handle status-specific updates
  let statusSpecificUpdates: Partial<DevelopmentJob> = {};
  
  if (updates.status) {
    switch (updates.status) {
      case 'initializing':
        if (!currentJob.startedAt) {
          statusSpecificUpdates = { ...statusSpecificUpdates, startedAt: now };
        }
        break;
        
      case 'completed':
      case 'failed':
      case 'cancelled':
        statusSpecificUpdates = { ...statusSpecificUpdates, completedAt: now };
        break;
    }
  }
  
  // Merge log entries
  let updatedLogs = [...currentJob.logs];
  if (updates.logEntries && updates.logEntries.length > 0) {
    updatedLogs = [...updatedLogs, ...updates.logEntries];
  }
  
  // Create updated job
  const updatedJob: DevelopmentJob = {
    ...currentJob,
    ...statusSpecificUpdates,
    updatedAt: now,
    ...(updates.status && { status: updates.status }),
    ...(updates.progress && {
      progress: {
        ...currentJob.progress,
        ...updates.progress,
      },
    }),
    ...(updates.kiroSession && { kiroSession: updates.kiroSession }),
    ...(updates.userInteraction && { userInteraction: updates.userInteraction }),
    ...(updates.error && { error: updates.error }),
    logs: updatedLogs,
    ...(updates.incrementRetryCount && { retryCount: currentJob.retryCount + 1 }),
  };
  
  return updatedJob;
}

/**
 * Creates a new job log entry.
 * 
 * @param level - Log level
 * @param message - Log message
 * @param component - Component that generated the log
 * @param context - Additional context data
 * @returns A new JobLogEntry object
 */
export function createJobLogEntry(
  level: JobLogEntry['level'],
  message: string,
  component: string,
  context?: Record<string, unknown>
): JobLogEntry {
  if (!message || message.trim().length === 0) {
    throw new DevelopmentJobValidationError(
      'Log message is required and cannot be empty',
      'message',
      message
    );
  }
  
  if (!component || component.trim().length === 0) {
    throw new DevelopmentJobValidationError(
      'Log component is required and cannot be empty',
      'component',
      component
    );
  }
  
  return {
    timestamp: new Date().toISOString(),
    level,
    message: message.trim(),
    component: component.trim(),
    context,
  };
}

/**
 * Creates a Kiro session info object.
 * 
 * @param sessionId - Unique session identifier
 * @param workspacePath - Path to the workspace directory
 * @param processId - Optional process ID
 * @param currentCommand - Optional current command
 * @returns A new KiroSessionInfo object
 */
export function createKiroSessionInfo(
  sessionId: string,
  workspacePath: string,
  processId?: number,
  currentCommand?: string
): KiroSessionInfo {
  if (!sessionId || sessionId.trim().length === 0) {
    throw new DevelopmentJobValidationError(
      'Session ID is required and cannot be empty',
      'sessionId',
      sessionId
    );
  }
  
  if (!workspacePath || workspacePath.trim().length === 0) {
    throw new DevelopmentJobValidationError(
      'Workspace path is required and cannot be empty',
      'workspacePath',
      workspacePath
    );
  }
  
  const now: string = new Date().toISOString();
  
  return {
    sessionId: sessionId.trim(),
    workspacePath: workspacePath.trim(),
    processId,
    currentCommand,
    startedAt: now,
    lastActivityAt: now,
  };
}

/**
 * Creates a user interaction state object.
 * 
 * @param question - Question or prompt for the user
 * @param inputType - Type of input expected
 * @param choices - Available choices for choice-type inputs
 * @param timeoutMs - Timeout for user input
 * @returns A new UserInteractionState object
 */
export function createUserInteractionState(
  question: string,
  inputType: UserInputType,
  choices?: string[],
  timeoutMs?: number
): UserInteractionState {
  if (!question || question.trim().length === 0) {
    throw new DevelopmentJobValidationError(
      'Question is required and cannot be empty',
      'question',
      question
    );
  }
  
  if (inputType === 'choice' && (!choices || choices.length === 0)) {
    throw new DevelopmentJobValidationError(
      'Choices are required for choice-type inputs',
      'choices',
      choices
    );
  }
  
  return {
    waitingForInput: true,
    question: question.trim(),
    inputType,
    choices: choices ? [...choices] : undefined,
    requestedAt: new Date().toISOString(),
    timeoutMs,
  };
}

/**
 * Updates job progress with phase and task information.
 * 
 * @param currentJob - Current development job
 * @param percentage - New completion percentage (0-100)
 * @param phase - Current development phase
 * @param currentTask - Description of current task
 * @param completedTask - Optional task that was just completed
 * @param estimatedRemainingMs - Optional estimated time remaining
 * @returns Updated DevelopmentJob with new progress
 */
export function updateJobProgress(
  currentJob: DevelopmentJob,
  percentage: number,
  phase: DevelopmentPhase,
  currentTask?: string,
  completedTask?: string,
  estimatedRemainingMs?: number
): DevelopmentJob {
  if (percentage < 0 || percentage > 100) {
    throw new DevelopmentJobValidationError(
      'Progress percentage must be between 0 and 100',
      'percentage',
      percentage
    );
  }
  
  const now: string = new Date().toISOString();
  let completedTasks = [...currentJob.progress.completedTasks];
  
  // Add completed task if provided
  if (completedTask && !completedTasks.includes(completedTask)) {
    completedTasks.push(completedTask);
  }
  
  // Check if phase changed
  const phaseChanged = phase !== currentJob.progress.phase;
  
  const updatedProgress: JobProgressInfo = {
    percentage,
    phase,
    phaseStartedAt: phaseChanged ? now : currentJob.progress.phaseStartedAt,
    completedTasks,
    currentTask,
    estimatedRemainingMs,
  };
  
  const logEntries: JobLogEntry[] = [];
  
  // Log phase change
  if (phaseChanged) {
    logEntries.push(
      createJobLogEntry(
        'info',
        `Development phase changed from '${currentJob.progress.phase}' to '${phase}'`,
        'ProgressTracker',
        { previousPhase: currentJob.progress.phase, newPhase: phase }
      )
    );
  }
  
  // Log task completion
  if (completedTask) {
    logEntries.push(
      createJobLogEntry(
        'info',
        `Task completed: ${completedTask}`,
        'ProgressTracker',
        { completedTask, percentage }
      )
    );
  }
  
  return updateDevelopmentJob(currentJob, {
    progress: updatedProgress,
    logEntries,
  });
}

/**
 * Adds a log entry to a development job.
 * 
 * @param currentJob - Current development job
 * @param level - Log level
 * @param message - Log message
 * @param component - Component generating the log
 * @param context - Additional context
 * @returns Updated DevelopmentJob with new log entry
 */
export function addJobLogEntry(
  currentJob: DevelopmentJob,
  level: JobLogEntry['level'],
  message: string,
  component: string,
  context?: Record<string, unknown>
): DevelopmentJob {
  const logEntry = createJobLogEntry(level, message, component, context);
  
  return updateDevelopmentJob(currentJob, {
    logEntries: [logEntry],
  });
}

/**
 * Marks a job as failed with error information.
 * 
 * @param currentJob - Current development job
 * @param errorMessage - Error message
 * @param errorCode - Error code
 * @param recoverable - Whether the error is recoverable
 * @param details - Additional error details
 * @returns Updated DevelopmentJob marked as failed
 */
export function failDevelopmentJob(
  currentJob: DevelopmentJob,
  errorMessage: string,
  errorCode: string,
  recoverable: boolean = false,
  details?: string
): DevelopmentJob {
  const error: DevelopmentJob['error'] = {
    message: errorMessage,
    code: errorCode,
    recoverable,
    occurredAt: new Date().toISOString(),
    details,
  };
  
  const logEntry = createJobLogEntry(
    'error',
    `Job failed: ${errorMessage}`,
    'JobManager',
    { errorCode, recoverable, details }
  );
  
  return updateDevelopmentJob(currentJob, {
    status: 'failed',
    error,
    logEntries: [logEntry],
  });
}