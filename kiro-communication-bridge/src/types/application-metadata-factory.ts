/**
 * Factory functions for creating and manipulating ApplicationMetadata objects.
 * 
 * This module provides utilities for creating, updating, and serializing
 * application metadata with proper validation and immutability guarantees.
 */

import { v4 as uuidv4 } from 'uuid';
import {
  ApplicationMetadata,
  ApplicationStatus,
  DevelopmentPhase,
  JobPriority,
  DevelopmentProgress,
  JobConfiguration,
  ApplicationError,
  ApplicationFiles,
} from './application-metadata';
import { validateApplicationMetadata, MetadataValidationError } from './application-metadata-validator';

/**
 * Parameters for creating a new application metadata object.
 */
export interface CreateApplicationMetadataParams {
  /** Human-readable application title */
  title: string;
  
  /** Detailed description of the application's purpose */
  description: string;
  
  /** Original user request description */
  userRequestDescription: string;
  
  /** Optional conversation context ID */
  conversationId?: string;
  
  /** Job priority (defaults to 'normal') */
  priority?: JobPriority;
  
  /** Job timeout in milliseconds (defaults to 30 minutes) */
  timeoutMs?: number;
  
  /** Enable debug logging (defaults to false) */
  debugLogging?: boolean;
}

/**
 * Parameters for updating application metadata.
 */
export interface UpdateApplicationMetadataParams {
  /** New application status */
  status?: ApplicationStatus;
  
  /** Updated progress information */
  progress?: Partial<DevelopmentProgress>;
  
  /** Error information (for failed applications) */
  error?: ApplicationError;
  
  /** Updated file paths */
  files?: Partial<ApplicationFiles>;
  
  /** Updated job configuration */
  jobConfig?: Partial<JobConfiguration>;
}

/**
 * Creates a new ApplicationMetadata object with default values.
 * 
 * This function generates a complete metadata object for a new application
 * with sensible defaults and proper validation.
 * 
 * @param params - Parameters for creating the application metadata
 * @returns A new ApplicationMetadata object
 * @throws MetadataValidationError if the provided parameters are invalid
 */
export function createApplicationMetadata(params: CreateApplicationMetadataParams): ApplicationMetadata {
  // Validate required parameters
  if (!params.title || params.title.trim().length === 0) {
    throw new MetadataValidationError('Title is required and cannot be empty', 'title', params.title);
  }
  
  if (!params.description || params.description.trim().length === 0) {
    throw new MetadataValidationError('Description is required and cannot be empty', 'description', params.description);
  }
  
  if (!params.userRequestDescription || params.userRequestDescription.trim().length === 0) {
    throw new MetadataValidationError('User request description is required and cannot be empty', 'userRequestDescription', params.userRequestDescription);
  }
  
  const now: string = new Date().toISOString();
  const applicationId: string = uuidv4();
  
  const metadata: ApplicationMetadata = {
    id: applicationId,
    title: params.title.trim(),
    description: params.description.trim(),
    status: 'queued',
    createdAt: now,
    updatedAt: now,
    progress: {
      percentage: 0,
      currentPhase: 'requirements',
      currentTask: 'Initializing application development',
      completedMilestones: [],
      remainingMilestones: [
        'Requirements Analysis',
        'Technical Design',
        'Implementation',
        'Testing',
        'Finalization',
      ],
    },
    jobConfig: {
      priority: params.priority || 'normal',
      timeoutMs: params.timeoutMs || 1800000, // 30 minutes default
      debugLogging: params.debugLogging || false,
    },
    files: {
      sourceFiles: [],
    },
    userRequest: {
      description: params.userRequestDescription.trim(),
      conversationId: params.conversationId,
    },
  };
  
  // Validate the created metadata
  validateApplicationMetadata(metadata);
  
  return metadata;
}

/**
 * Updates an existing ApplicationMetadata object with new values.
 * 
 * This function creates a new metadata object with updated values while
 * preserving immutability and ensuring validation.
 * 
 * @param currentMetadata - The current application metadata
 * @param updates - The updates to apply
 * @returns A new ApplicationMetadata object with the updates applied
 * @throws MetadataValidationError if the updates would create invalid metadata
 */
export function updateApplicationMetadata(
  currentMetadata: ApplicationMetadata,
  updates: UpdateApplicationMetadataParams
): ApplicationMetadata {
  // Validate current metadata
  validateApplicationMetadata(currentMetadata);
  
  const now: string = new Date().toISOString();
  
  // Create updated metadata object
  const updatedMetadata: ApplicationMetadata = {
    ...currentMetadata,
    updatedAt: now,
    ...(updates.status && { status: updates.status }),
    ...(updates.progress && {
      progress: {
        ...currentMetadata.progress,
        ...updates.progress,
      },
    }),
    ...(updates.error && { error: updates.error }),
    ...(updates.files && {
      files: {
        ...currentMetadata.files,
        ...updates.files,
      },
    }),
    ...(updates.jobConfig && {
      jobConfig: {
        ...currentMetadata.jobConfig,
        ...updates.jobConfig,
      },
    }),
  };
  
  // Validate the updated metadata
  validateApplicationMetadata(updatedMetadata);
  
  return updatedMetadata;
}

/**
 * Creates an ApplicationError object with proper validation.
 * 
 * @param message - Human-readable error message
 * @param code - Error code for programmatic handling
 * @param recoverable - Whether the error is recoverable
 * @param context - Additional context information
 * @returns A new ApplicationError object
 */
export function createApplicationError(
  message: string,
  code: string,
  recoverable: boolean = false,
  context?: Record<string, unknown>
): ApplicationError {
  if (!message || message.trim().length === 0) {
    throw new MetadataValidationError('Error message is required and cannot be empty', 'message', message);
  }
  
  if (!code || code.trim().length === 0) {
    throw new MetadataValidationError('Error code is required and cannot be empty', 'code', code);
  }
  
  return {
    message: message.trim(),
    code: code.trim(),
    recoverable,
    occurredAt: new Date().toISOString(),
    context,
  };
}

/**
 * Updates the progress of an application with milestone tracking.
 * 
 * @param currentMetadata - The current application metadata
 * @param percentage - New completion percentage (0-100)
 * @param currentTask - Description of the current task
 * @param phase - Current development phase
 * @param completedMilestone - Optional milestone that was just completed
 * @returns Updated ApplicationMetadata with new progress
 */
export function updateApplicationProgress(
  currentMetadata: ApplicationMetadata,
  percentage: number,
  currentTask: string,
  phase?: DevelopmentPhase,
  completedMilestone?: string
): ApplicationMetadata {
  if (percentage < 0 || percentage > 100) {
    throw new MetadataValidationError('Progress percentage must be between 0 and 100', 'percentage', percentage);
  }
  
  if (!currentTask || currentTask.trim().length === 0) {
    throw new MetadataValidationError('Current task description is required', 'currentTask', currentTask);
  }
  
  const currentProgress = currentMetadata.progress;
  let completedMilestones = [...currentProgress.completedMilestones];
  let remainingMilestones = [...currentProgress.remainingMilestones];
  
  // Handle milestone completion
  if (completedMilestone) {
    if (!completedMilestones.includes(completedMilestone)) {
      completedMilestones.push(completedMilestone);
    }
    
    // Remove from remaining milestones
    remainingMilestones = remainingMilestones.filter(m => m !== completedMilestone);
  }
  
  const updatedProgress: DevelopmentProgress = {
    percentage,
    currentPhase: phase || currentProgress.currentPhase,
    currentTask: currentTask.trim(),
    estimatedCompletion: currentProgress.estimatedCompletion,
    completedMilestones,
    remainingMilestones,
  };
  
  return updateApplicationMetadata(currentMetadata, { progress: updatedProgress });
}

/**
 * Serializes ApplicationMetadata to JSON string.
 * 
 * @param metadata - The metadata to serialize
 * @returns JSON string representation of the metadata
 */
export function serializeApplicationMetadata(metadata: ApplicationMetadata): string {
  validateApplicationMetadata(metadata);
  return JSON.stringify(metadata, null, 2);
}

/**
 * Deserializes ApplicationMetadata from JSON string.
 * 
 * @param jsonString - JSON string to deserialize
 * @returns ApplicationMetadata object
 * @throws MetadataValidationError if the JSON is invalid or doesn't represent valid metadata
 */
export function deserializeApplicationMetadata(jsonString: string): ApplicationMetadata {
  try {
    const parsed: unknown = JSON.parse(jsonString);
    validateApplicationMetadata(parsed);
    return parsed as ApplicationMetadata;
  } catch (error: unknown) {
    if (error instanceof MetadataValidationError) {
      throw error;
    }
    
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown parsing error';
    throw new MetadataValidationError(
      `Failed to parse application metadata JSON: ${errorMessage}`,
      'json',
      jsonString
    );
  }
}