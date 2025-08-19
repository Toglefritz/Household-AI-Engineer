/**
 * Validation utilities for ApplicationMetadata and related types.
 * 
 * This module provides comprehensive validation functions for all application
 * metadata structures, ensuring data integrity and type safety throughout
 * the orchestration system.
 */

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

/**
 * Validation error thrown when metadata validation fails.
 */
export class MetadataValidationError extends Error {
  /**
   * Creates a new metadata validation error.
   * 
   * @param message - Description of the validation failure
   * @param field - The field that failed validation
   * @param value - The invalid value
   */
  constructor(
    message: string,
    public readonly field: string,
    public readonly value: unknown
  ) {
    super(message);
    this.name = 'MetadataValidationError';
  }
}

/**
 * Validates that a value is a valid ApplicationStatus.
 * 
 * @param value - Value to validate
 * @returns True if the value is a valid ApplicationStatus
 */
export function isValidApplicationStatus(value: unknown): value is ApplicationStatus {
  const validStatuses: ApplicationStatus[] = [
    'queued',
    'developing',
    'waiting-input',
    'paused',
    'completed',
    'failed',
    'cancelled',
  ];
  
  return typeof value === 'string' && validStatuses.includes(value as ApplicationStatus);
}

/**
 * Validates that a value is a valid DevelopmentPhase.
 * 
 * @param value - Value to validate
 * @returns True if the value is a valid DevelopmentPhase
 */
export function isValidDevelopmentPhase(value: unknown): value is DevelopmentPhase {
  const validPhases: DevelopmentPhase[] = [
    'requirements',
    'design',
    'implementation',
    'testing',
    'finalization',
  ];
  
  return typeof value === 'string' && validPhases.includes(value as DevelopmentPhase);
}

/**
 * Validates that a value is a valid JobPriority.
 * 
 * @param value - Value to validate
 * @returns True if the value is a valid JobPriority
 */
export function isValidJobPriority(value: unknown): value is JobPriority {
  const validPriorities: JobPriority[] = ['low', 'normal', 'high'];
  return typeof value === 'string' && validPriorities.includes(value as JobPriority);
}

/**
 * Validates that a value is a valid ISO 8601 timestamp string.
 * 
 * @param value - Value to validate
 * @returns True if the value is a valid ISO 8601 timestamp
 */
export function isValidTimestamp(value: unknown): value is string {
  if (typeof value !== 'string') {
    return false;
  }
  
  try {
    const date: Date = new Date(value);
    return !isNaN(date.getTime()) && value === date.toISOString();
  } catch {
    return false;
  }
}

/**
 * Validates a DevelopmentProgress object.
 * 
 * @param value - Value to validate
 * @returns True if the value is a valid DevelopmentProgress
 */
export function isValidDevelopmentProgress(value: unknown): value is DevelopmentProgress {
  if (typeof value !== 'object' || value === null) {
    return false;
  }
  
  const progress = value as Record<string, unknown>;
  
  // Validate required fields
  if (typeof progress.percentage !== 'number' || 
      progress.percentage < 0 || 
      progress.percentage > 100) {
    return false;
  }
  
  if (!isValidDevelopmentPhase(progress.currentPhase)) {
    return false;
  }
  
  if (typeof progress.currentTask !== 'string') {
    return false;
  }
  
  // Validate optional estimatedCompletion
  if (progress.estimatedCompletion !== undefined && 
      !isValidTimestamp(progress.estimatedCompletion)) {
    return false;
  }
  
  // Validate milestone arrays
  if (!Array.isArray(progress.completedMilestones) ||
      !progress.completedMilestones.every((m: unknown) => typeof m === 'string')) {
    return false;
  }
  
  if (!Array.isArray(progress.remainingMilestones) ||
      !progress.remainingMilestones.every((m: unknown) => typeof m === 'string')) {
    return false;
  }
  
  return true;
}

/**
 * Validates a JobConfiguration object.
 * 
 * @param value - Value to validate
 * @returns True if the value is a valid JobConfiguration
 */
export function isValidJobConfiguration(value: unknown): value is JobConfiguration {
  if (typeof value !== 'object' || value === null) {
    return false;
  }
  
  const config = value as Record<string, unknown>;
  
  return isValidJobPriority(config.priority) &&
         typeof config.timeoutMs === 'number' &&
         config.timeoutMs > 0 &&
         typeof config.debugLogging === 'boolean';
}

/**
 * Validates an ApplicationError object.
 * 
 * @param value - Value to validate
 * @returns True if the value is a valid ApplicationError
 */
export function isValidApplicationError(value: unknown): value is ApplicationError {
  if (typeof value !== 'object' || value === null) {
    return false;
  }
  
  const error = value as Record<string, unknown>;
  
  return typeof error.message === 'string' &&
         typeof error.code === 'string' &&
         typeof error.recoverable === 'boolean' &&
         isValidTimestamp(error.occurredAt) &&
         (error.context === undefined || 
          (typeof error.context === 'object' && error.context !== null));
}

/**
 * Validates an ApplicationFiles object.
 * 
 * @param value - Value to validate
 * @returns True if the value is a valid ApplicationFiles
 */
export function isValidApplicationFiles(value: unknown): value is ApplicationFiles {
  if (typeof value !== 'object' || value === null) {
    return false;
  }
  
  const files = value as Record<string, unknown>;
  
  // Validate optional string fields
  if (files.mainFile !== undefined && typeof files.mainFile !== 'string') {
    return false;
  }
  
  if (files.readme !== undefined && typeof files.readme !== 'string') {
    return false;
  }
  
  if (files.packageFile !== undefined && typeof files.packageFile !== 'string') {
    return false;
  }
  
  // Validate required sourceFiles array
  if (!Array.isArray(files.sourceFiles) ||
      !files.sourceFiles.every((f: unknown) => typeof f === 'string')) {
    return false;
  }
  
  return true;
}

/**
 * Validates a complete ApplicationMetadata object.
 * 
 * @param value - Value to validate
 * @returns True if the value is a valid ApplicationMetadata
 * @throws MetadataValidationError if validation fails with detailed error information
 */
export function validateApplicationMetadata(value: unknown): value is ApplicationMetadata {
  if (typeof value !== 'object' || value === null) {
    throw new MetadataValidationError(
      'Application metadata must be an object',
      'root',
      value
    );
  }
  
  const metadata = value as Record<string, unknown>;
  
  // Validate required string fields
  if (typeof metadata.id !== 'string' || metadata.id.trim().length === 0) {
    throw new MetadataValidationError(
      'Application ID must be a non-empty string',
      'id',
      metadata.id
    );
  }
  
  if (typeof metadata.title !== 'string' || metadata.title.trim().length === 0) {
    throw new MetadataValidationError(
      'Application title must be a non-empty string',
      'title',
      metadata.title
    );
  }
  
  if (typeof metadata.description !== 'string' || metadata.description.trim().length === 0) {
    throw new MetadataValidationError(
      'Application description must be a non-empty string',
      'description',
      metadata.description
    );
  }
  
  // Validate status
  if (!isValidApplicationStatus(metadata.status)) {
    throw new MetadataValidationError(
      'Application status must be a valid ApplicationStatus',
      'status',
      metadata.status
    );
  }
  
  // Validate timestamps
  if (!isValidTimestamp(metadata.createdAt)) {
    throw new MetadataValidationError(
      'createdAt must be a valid ISO 8601 timestamp',
      'createdAt',
      metadata.createdAt
    );
  }
  
  if (!isValidTimestamp(metadata.updatedAt)) {
    throw new MetadataValidationError(
      'updatedAt must be a valid ISO 8601 timestamp',
      'updatedAt',
      metadata.updatedAt
    );
  }
  
  // Validate progress
  if (!isValidDevelopmentProgress(metadata.progress)) {
    throw new MetadataValidationError(
      'progress must be a valid DevelopmentProgress object',
      'progress',
      metadata.progress
    );
  }
  
  // Validate job configuration
  if (!isValidJobConfiguration(metadata.jobConfig)) {
    throw new MetadataValidationError(
      'jobConfig must be a valid JobConfiguration object',
      'jobConfig',
      metadata.jobConfig
    );
  }
  
  // Validate optional error
  if (metadata.error !== undefined && !isValidApplicationError(metadata.error)) {
    throw new MetadataValidationError(
      'error must be a valid ApplicationError object',
      'error',
      metadata.error
    );
  }
  
  // Validate files
  if (!isValidApplicationFiles(metadata.files)) {
    throw new MetadataValidationError(
      'files must be a valid ApplicationFiles object',
      'files',
      metadata.files
    );
  }
  
  // Validate user request
  if (typeof metadata.userRequest !== 'object' || metadata.userRequest === null) {
    throw new MetadataValidationError(
      'userRequest must be an object',
      'userRequest',
      metadata.userRequest
    );
  }
  
  const userRequest = metadata.userRequest as Record<string, unknown>;
  if (typeof userRequest.description !== 'string' || userRequest.description.trim().length === 0) {
    throw new MetadataValidationError(
      'userRequest.description must be a non-empty string',
      'userRequest.description',
      userRequest.description
    );
  }
  
  if (userRequest.conversationId !== undefined && typeof userRequest.conversationId !== 'string') {
    throw new MetadataValidationError(
      'userRequest.conversationId must be a string if provided',
      'userRequest.conversationId',
      userRequest.conversationId
    );
  }
  
  return true;
}