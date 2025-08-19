/**
 * Unit tests for DevelopmentJob types, state machine, and factory functions.
 * 
 * This test suite ensures that all development job functionality works
 * correctly, including state transitions, validation, and factory methods.
 */

import {
  DevelopmentJob,
  JobStatus,
  UserInputType,
} from '../types/development-job';
import {
  isValidJobTransition,
  validateJobTransition,
  isTerminalJobStatus,
  isActiveJobStatus,
  isErrorJobStatus,
  isRunningJobStatus,
  getValidNextStatuses,
  getJobStatusDescription,
  suggestNextJobStatus,
  InvalidJobTransitionError,
  VALID_JOB_TRANSITIONS,
} from '../types/job-state-machine';
import {
  createDevelopmentJob,
  updateDevelopmentJob,
  createJobLogEntry,
  createKiroSessionInfo,
  createUserInteractionState,
  updateJobProgress,
  addJobLogEntry,
  failDevelopmentJob,
  DevelopmentJobValidationError,
  CreateDevelopmentJobParams,
} from '../types/development-job-factory';

describe('Job State Machine', () => {
  describe('isValidJobTransition', () => {
    it('should validate correct job transitions', () => {
      // Test some valid transitions
      expect(isValidJobTransition('queued', 'initializing')).toBe(true);
      expect(isValidJobTransition('initializing', 'developing')).toBe(true);
      expect(isValidJobTransition('developing', 'testing')).toBe(true);
      expect(isValidJobTransition('testing', 'finalizing')).toBe(true);
      expect(isValidJobTransition('finalizing', 'completed')).toBe(true);
      
      // Test error transitions
      expect(isValidJobTransition('developing', 'failed')).toBe(true);
      expect(isValidJobTransition('queued', 'cancelled')).toBe(true);
      
      // Test pause/resume transitions
      expect(isValidJobTransition('developing', 'paused')).toBe(true);
      expect(isValidJobTransition('paused', 'developing')).toBe(true);
      
      // Test user input transitions
      expect(isValidJobTransition('developing', 'waiting-input')).toBe(true);
      expect(isValidJobTransition('waiting-input', 'developing')).toBe(true);
    });
    
    it('should reject invalid job transitions', () => {
      // Test invalid transitions
      expect(isValidJobTransition('completed', 'developing')).toBe(false);
      expect(isValidJobTransition('failed', 'developing')).toBe(false);
      expect(isValidJobTransition('cancelled', 'developing')).toBe(false);
      expect(isValidJobTransition('queued', 'completed')).toBe(false);
      expect(isValidJobTransition('initializing', 'completed')).toBe(false);
    });
  });
  
  describe('validateJobTransition', () => {
    it('should not throw for valid transitions', () => {
      expect(() => validateJobTransition('queued', 'initializing', 'job-123')).not.toThrow();
      expect(() => validateJobTransition('developing', 'testing', 'job-123')).not.toThrow();
    });
    
    it('should throw InvalidJobTransitionError for invalid transitions', () => {
      expect(() => validateJobTransition('completed', 'developing', 'job-123'))
        .toThrow(InvalidJobTransitionError);
      
      try {
        validateJobTransition('failed', 'developing', 'job-123');
      } catch (error) {
        expect(error).toBeInstanceOf(InvalidJobTransitionError);
        const transitionError = error as InvalidJobTransitionError;
        expect(transitionError.fromStatus).toBe('failed');
        expect(transitionError.toStatus).toBe('developing');
        expect(transitionError.jobId).toBe('job-123');
      }
    });
  });
  
  describe('Status Classification', () => {
    it('should correctly identify terminal statuses', () => {
      expect(isTerminalJobStatus('completed')).toBe(true);
      expect(isTerminalJobStatus('failed')).toBe(true);
      expect(isTerminalJobStatus('cancelled')).toBe(true);
      expect(isTerminalJobStatus('developing')).toBe(false);
      expect(isTerminalJobStatus('queued')).toBe(false);
    });
    
    it('should correctly identify active statuses', () => {
      expect(isActiveJobStatus('queued')).toBe(true);
      expect(isActiveJobStatus('developing')).toBe(true);
      expect(isActiveJobStatus('paused')).toBe(true);
      expect(isActiveJobStatus('completed')).toBe(false);
      expect(isActiveJobStatus('failed')).toBe(false);
    });
    
    it('should correctly identify error statuses', () => {
      expect(isErrorJobStatus('failed')).toBe(true);
      expect(isErrorJobStatus('cancelled')).toBe(true);
      expect(isErrorJobStatus('developing')).toBe(false);
      expect(isErrorJobStatus('completed')).toBe(false);
    });
    
    it('should correctly identify running statuses', () => {
      expect(isRunningJobStatus('developing')).toBe(true);
      expect(isRunningJobStatus('testing')).toBe(true);
      expect(isRunningJobStatus('initializing')).toBe(true);
      expect(isRunningJobStatus('paused')).toBe(false);
      expect(isRunningJobStatus('waiting-input')).toBe(false);
    });
  });
  
  describe('getValidNextStatuses', () => {
    it('should return correct next statuses', () => {
      const queuedNext = getValidNextStatuses('queued');
      expect(queuedNext).toContain('initializing');
      expect(queuedNext).toContain('cancelled');
      
      const developingNext = getValidNextStatuses('developing');
      expect(developingNext).toContain('waiting-input');
      expect(developingNext).toContain('testing');
      expect(developingNext).toContain('paused');
      expect(developingNext).toContain('failed');
      expect(developingNext).toContain('cancelled');
      
      const completedNext = getValidNextStatuses('completed');
      expect(completedNext).toHaveLength(0);
    });
  });
  
  describe('getJobStatusDescription', () => {
    it('should return meaningful descriptions for all statuses', () => {
      const statuses: JobStatus[] = [
        'queued', 'initializing', 'developing', 'waiting-input',
        'paused', 'testing', 'finalizing', 'completed', 'failed', 'cancelled'
      ];
      
      statuses.forEach(status => {
        const description = getJobStatusDescription(status);
        expect(description).toBeTruthy();
        expect(typeof description).toBe('string');
        expect(description.length).toBeGreaterThan(0);
      });
    });
  });
  
  describe('suggestNextJobStatus', () => {
    it('should suggest appropriate next status based on conditions', () => {
      expect(suggestNextJobStatus('queued')).toBe('initializing');
      expect(suggestNextJobStatus('initializing')).toBe('developing');
      expect(suggestNextJobStatus('developing')).toBe('finalizing');
      
      expect(suggestNextJobStatus('developing', { hasError: true })).toBe('failed');
      expect(suggestNextJobStatus('developing', { userInputRequired: true })).toBe('waiting-input');
      expect(suggestNextJobStatus('developing', { isPaused: true })).toBe('paused');
      expect(suggestNextJobStatus('finalizing', { isComplete: true })).toBe('completed');
    });
  });
});

describe('DevelopmentJob Factory', () => {
  describe('createDevelopmentJob', () => {
    it('should create valid development job with required parameters', () => {
      const params: CreateDevelopmentJobParams = {
        applicationId: 'app-123',
        userRequestDescription: 'I need a test application',
      };
      
      const job = createDevelopmentJob(params);
      
      expect(job.applicationId).toBe(params.applicationId);
      expect(job.userRequest.description).toBe(params.userRequestDescription);
      expect(job.status).toBe('queued');
      expect(job.progress.percentage).toBe(0);
      expect(job.progress.phase).toBe('requirements');
      expect(job.retryCount).toBe(0);
      expect(job.maxRetries).toBe(3);
      expect(job.timeoutMs).toBe(1800000);
      expect(job.debugLogging).toBe(false);
      expect(job.logs).toHaveLength(1);
      expect(job.logs[0].message).toContain('created and queued');
    });
    
    it('should create job with custom parameters', () => {
      const params: CreateDevelopmentJobParams = {
        applicationId: 'app-456',
        userRequestDescription: 'Urgent application needed',
        priority: 'high',
        timeoutMs: 3600000,
        debugLogging: true,
        maxRetries: 5,
        conversationId: 'conv-123',
        userId: 'user-456',
      };
      
      const job = createDevelopmentJob(params);
      
      expect(job.userRequest.priority).toBe('high');
      expect(job.timeoutMs).toBe(3600000);
      expect(job.debugLogging).toBe(true);
      expect(job.maxRetries).toBe(5);
      expect(job.userRequest.conversationId).toBe('conv-123');
      expect(job.userRequest.userId).toBe('user-456');
    });
    
    it('should throw error for invalid parameters', () => {
      const invalidParams: CreateDevelopmentJobParams = {
        applicationId: '',
        userRequestDescription: 'Valid description',
      };
      
      expect(() => createDevelopmentJob(invalidParams)).toThrow(DevelopmentJobValidationError);
      expect(() => createDevelopmentJob(invalidParams)).toThrow('Application ID is required');
    });
  });
  
  describe('updateDevelopmentJob', () => {
    let baseJob: DevelopmentJob;
    
    beforeEach(() => {
      baseJob = createDevelopmentJob({
        applicationId: 'app-123',
        userRequestDescription: 'Test application',
      });
    });
    
    it('should update job status with validation', async () => {
      // Add small delay to ensure different timestamps
      await new Promise(resolve => setTimeout(resolve, 1));
      
      const updatedJob = updateDevelopmentJob(baseJob, {
        status: 'initializing',
      });
      
      expect(updatedJob.status).toBe('initializing');
      expect(updatedJob.startedAt).toBeTruthy();
      expect(updatedJob.updatedAt).not.toBe(baseJob.updatedAt);
    });
    
    it('should throw error for invalid status transition', () => {
      expect(() => updateDevelopmentJob(baseJob, { status: 'completed' }))
        .toThrow(InvalidJobTransitionError);
    });
    
    it('should update progress information', () => {
      const updatedJob = updateDevelopmentJob(baseJob, {
        progress: {
          percentage: 50,
          currentTask: 'Implementing features',
          phase: 'implementation',
        },
      });
      
      expect(updatedJob.progress.percentage).toBe(50);
      expect(updatedJob.progress.currentTask).toBe('Implementing features');
      expect(updatedJob.progress.phase).toBe('implementation');
    });
    
    it('should add log entries', () => {
      const logEntry = createJobLogEntry('info', 'Test log message', 'TestComponent');
      const updatedJob = updateDevelopmentJob(baseJob, {
        logEntries: [logEntry],
      });
      
      expect(updatedJob.logs).toHaveLength(2); // Original + new
      expect(updatedJob.logs[1]).toEqual(logEntry);
    });
    
    it('should increment retry count', () => {
      const updatedJob = updateDevelopmentJob(baseJob, {
        incrementRetryCount: true,
      });
      
      expect(updatedJob.retryCount).toBe(1);
    });
  });
  
  describe('createJobLogEntry', () => {
    it('should create valid log entry', () => {
      const logEntry = createJobLogEntry('info', 'Test message', 'TestComponent', { key: 'value' });
      
      expect(logEntry.level).toBe('info');
      expect(logEntry.message).toBe('Test message');
      expect(logEntry.component).toBe('TestComponent');
      expect(logEntry.context).toEqual({ key: 'value' });
      expect(logEntry.timestamp).toBeTruthy();
    });
    
    it('should throw error for invalid parameters', () => {
      expect(() => createJobLogEntry('info', '', 'TestComponent')).toThrow(DevelopmentJobValidationError);
      expect(() => createJobLogEntry('info', 'Valid message', '')).toThrow(DevelopmentJobValidationError);
    });
  });
  
  describe('createKiroSessionInfo', () => {
    it('should create valid session info', () => {
      const sessionInfo = createKiroSessionInfo('session-123', '/path/to/workspace', 12345, 'test-command');
      
      expect(sessionInfo.sessionId).toBe('session-123');
      expect(sessionInfo.workspacePath).toBe('/path/to/workspace');
      expect(sessionInfo.processId).toBe(12345);
      expect(sessionInfo.currentCommand).toBe('test-command');
      expect(sessionInfo.startedAt).toBeTruthy();
      expect(sessionInfo.lastActivityAt).toBeTruthy();
    });
    
    it('should throw error for invalid parameters', () => {
      expect(() => createKiroSessionInfo('', '/path')).toThrow(DevelopmentJobValidationError);
      expect(() => createKiroSessionInfo('session-123', '')).toThrow(DevelopmentJobValidationError);
    });
  });
  
  describe('createUserInteractionState', () => {
    it('should create valid user interaction state', () => {
      const interactionState = createUserInteractionState(
        'What framework would you like to use?',
        'choice',
        ['React', 'Vue', 'Angular'],
        30000
      );
      
      expect(interactionState.waitingForInput).toBe(true);
      expect(interactionState.question).toBe('What framework would you like to use?');
      expect(interactionState.inputType).toBe('choice');
      expect(interactionState.choices).toEqual(['React', 'Vue', 'Angular']);
      expect(interactionState.timeoutMs).toBe(30000);
      expect(interactionState.requestedAt).toBeTruthy();
    });
    
    it('should throw error for choice input without choices', () => {
      expect(() => createUserInteractionState('Choose option', 'choice'))
        .toThrow(DevelopmentJobValidationError);
    });
  });
  
  describe('updateJobProgress', () => {
    let baseJob: DevelopmentJob;
    
    beforeEach(() => {
      baseJob = createDevelopmentJob({
        applicationId: 'app-123',
        userRequestDescription: 'Test application',
      });
    });
    
    it('should update progress with phase change', () => {
      const updatedJob = updateJobProgress(
        baseJob,
        25,
        'design',
        'Creating technical design',
        'Requirements Analysis'
      );
      
      expect(updatedJob.progress.percentage).toBe(25);
      expect(updatedJob.progress.phase).toBe('design');
      expect(updatedJob.progress.currentTask).toBe('Creating technical design');
      expect(updatedJob.progress.completedTasks).toContain('Requirements Analysis');
      
      // Should have logged phase change and task completion
      expect(updatedJob.logs.length).toBeGreaterThan(baseJob.logs.length);
    });
    
    it('should throw error for invalid percentage', () => {
      expect(() => updateJobProgress(baseJob, -10, 'requirements')).toThrow(DevelopmentJobValidationError);
      expect(() => updateJobProgress(baseJob, 150, 'requirements')).toThrow(DevelopmentJobValidationError);
    });
  });
  
  describe('addJobLogEntry', () => {
    let baseJob: DevelopmentJob;
    
    beforeEach(() => {
      baseJob = createDevelopmentJob({
        applicationId: 'app-123',
        userRequestDescription: 'Test application',
      });
    });
    
    it('should add log entry to job', () => {
      const updatedJob = addJobLogEntry(baseJob, 'warn', 'Warning message', 'TestComponent');
      
      expect(updatedJob.logs).toHaveLength(2);
      expect(updatedJob.logs[1].level).toBe('warn');
      expect(updatedJob.logs[1].message).toBe('Warning message');
      expect(updatedJob.logs[1].component).toBe('TestComponent');
    });
  });
  
  describe('failDevelopmentJob', () => {
    let baseJob: DevelopmentJob;
    
    beforeEach(() => {
      baseJob = createDevelopmentJob({
        applicationId: 'app-123',
        userRequestDescription: 'Test application',
      });
      // Update to a status that can transition to failed
      baseJob = updateDevelopmentJob(baseJob, { status: 'initializing' });
      baseJob = updateDevelopmentJob(baseJob, { status: 'developing' });
    });
    
    it('should mark job as failed with error information', () => {
      const failedJob = failDevelopmentJob(
        baseJob,
        'Test error occurred',
        'TEST_ERROR',
        true,
        'Additional error details'
      );
      
      expect(failedJob.status).toBe('failed');
      expect(failedJob.error).toBeTruthy();
      expect(failedJob.error!.message).toBe('Test error occurred');
      expect(failedJob.error!.code).toBe('TEST_ERROR');
      expect(failedJob.error!.recoverable).toBe(true);
      expect(failedJob.error!.details).toBe('Additional error details');
      expect(failedJob.completedAt).toBeTruthy();
      
      // Should have added error log entry
      const errorLog = failedJob.logs.find(log => log.level === 'error');
      expect(errorLog).toBeTruthy();
      expect(errorLog!.message).toContain('Job failed');
    });
  });
});