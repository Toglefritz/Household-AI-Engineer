/**
 * Unit tests for ApplicationMetadata types, validation, and factory functions.
 * 
 * This test suite ensures that all application metadata functionality works
 * correctly, including validation, serialization, and factory methods.
 */

import {
  ApplicationMetadata,
  ApplicationStatus,
  DevelopmentPhase,
  JobPriority,
} from '../types/application-metadata';
import {
  validateApplicationMetadata,
  isValidApplicationStatus,
  isValidDevelopmentPhase,
  isValidJobPriority,
  isValidTimestamp,
  MetadataValidationError,
} from '../types/application-metadata-validator';
import {
  createApplicationMetadata,
  updateApplicationMetadata,
  createApplicationError,
  updateApplicationProgress,
  serializeApplicationMetadata,
  deserializeApplicationMetadata,
  CreateApplicationMetadataParams,
} from '../types/application-metadata-factory';

describe('ApplicationMetadata Validation', () => {
  describe('isValidApplicationStatus', () => {
    it('should validate correct application statuses', () => {
      const validStatuses: ApplicationStatus[] = [
        'queued',
        'developing',
        'waiting-input',
        'paused',
        'completed',
        'failed',
        'cancelled',
      ];
      
      validStatuses.forEach(status => {
        expect(isValidApplicationStatus(status)).toBe(true);
      });
    });
    
    it('should reject invalid application statuses', () => {
      const invalidStatuses = ['invalid', 123, null, undefined, {}];
      
      invalidStatuses.forEach(status => {
        expect(isValidApplicationStatus(status)).toBe(false);
      });
    });
  });
  
  describe('isValidDevelopmentPhase', () => {
    it('should validate correct development phases', () => {
      const validPhases: DevelopmentPhase[] = [
        'requirements',
        'design',
        'implementation',
        'testing',
        'finalization',
      ];
      
      validPhases.forEach(phase => {
        expect(isValidDevelopmentPhase(phase)).toBe(true);
      });
    });
    
    it('should reject invalid development phases', () => {
      const invalidPhases = ['invalid', 123, null, undefined, {}];
      
      invalidPhases.forEach(phase => {
        expect(isValidDevelopmentPhase(phase)).toBe(false);
      });
    });
  });
  
  describe('isValidJobPriority', () => {
    it('should validate correct job priorities', () => {
      const validPriorities: JobPriority[] = ['low', 'normal', 'high'];
      
      validPriorities.forEach(priority => {
        expect(isValidJobPriority(priority)).toBe(true);
      });
    });
    
    it('should reject invalid job priorities', () => {
      const invalidPriorities = ['invalid', 123, null, undefined, {}];
      
      invalidPriorities.forEach(priority => {
        expect(isValidJobPriority(priority)).toBe(false);
      });
    });
  });
  
  describe('isValidTimestamp', () => {
    it('should validate correct ISO 8601 timestamps', () => {
      const validTimestamps = [
        '2023-12-01T10:30:00.000Z',
        '2023-01-15T14:45:30.123Z',
        new Date().toISOString(),
      ];
      
      validTimestamps.forEach(timestamp => {
        expect(isValidTimestamp(timestamp)).toBe(true);
      });
    });
    
    it('should reject invalid timestamps', () => {
      const invalidTimestamps = [
        'invalid-date',
        '2023-12-01',
        '2023-12-01T10:30:00',
        123,
        null,
        undefined,
      ];
      
      invalidTimestamps.forEach(timestamp => {
        expect(isValidTimestamp(timestamp)).toBe(false);
      });
    });
  });
  
  describe('validateApplicationMetadata', () => {
    let validMetadata: ApplicationMetadata;
    
    beforeEach(() => {
      validMetadata = createApplicationMetadata({
        title: 'Test Application',
        description: 'A test application for unit testing',
        userRequestDescription: 'I need a test application',
      });
    });
    
    it('should validate correct application metadata', () => {
      expect(() => validateApplicationMetadata(validMetadata)).not.toThrow();
      expect(validateApplicationMetadata(validMetadata)).toBe(true);
    });
    
    it('should reject metadata with invalid ID', () => {
      const invalidMetadata = { ...validMetadata, id: '' };
      
      expect(() => validateApplicationMetadata(invalidMetadata)).toThrow(MetadataValidationError);
      expect(() => validateApplicationMetadata(invalidMetadata)).toThrow('Application ID must be a non-empty string');
    });
    
    it('should reject metadata with invalid title', () => {
      const invalidMetadata = { ...validMetadata, title: '' };
      
      expect(() => validateApplicationMetadata(invalidMetadata)).toThrow(MetadataValidationError);
      expect(() => validateApplicationMetadata(invalidMetadata)).toThrow('Application title must be a non-empty string');
    });
    
    it('should reject metadata with invalid status', () => {
      const invalidMetadata = { ...validMetadata, status: 'invalid-status' as ApplicationStatus };
      
      expect(() => validateApplicationMetadata(invalidMetadata)).toThrow(MetadataValidationError);
      expect(() => validateApplicationMetadata(invalidMetadata)).toThrow('Application status must be a valid ApplicationStatus');
    });
    
    it('should reject metadata with invalid timestamps', () => {
      const invalidMetadata = { ...validMetadata, createdAt: 'invalid-date' };
      
      expect(() => validateApplicationMetadata(invalidMetadata)).toThrow(MetadataValidationError);
      expect(() => validateApplicationMetadata(invalidMetadata)).toThrow('createdAt must be a valid ISO 8601 timestamp');
    });
  });
});

describe('ApplicationMetadata Factory', () => {
  describe('createApplicationMetadata', () => {
    it('should create valid application metadata with required parameters', () => {
      const params: CreateApplicationMetadataParams = {
        title: 'Test Application',
        description: 'A test application for unit testing',
        userRequestDescription: 'I need a test application',
      };
      
      const metadata = createApplicationMetadata(params);
      
      expect(metadata.title).toBe(params.title);
      expect(metadata.description).toBe(params.description);
      expect(metadata.userRequest.description).toBe(params.userRequestDescription);
      expect(metadata.status).toBe('queued');
      expect(metadata.progress.percentage).toBe(0);
      expect(metadata.progress.currentPhase).toBe('requirements');
      expect(metadata.jobConfig.priority).toBe('normal');
      expect(metadata.jobConfig.timeoutMs).toBe(1800000);
      expect(metadata.jobConfig.debugLogging).toBe(false);
      
      // Validate the created metadata
      expect(() => validateApplicationMetadata(metadata)).not.toThrow();
    });
    
    it('should create metadata with custom job configuration', () => {
      const params: CreateApplicationMetadataParams = {
        title: 'High Priority App',
        description: 'An urgent application',
        userRequestDescription: 'I need this urgently',
        priority: 'high',
        timeoutMs: 3600000, // 1 hour
        debugLogging: true,
      };
      
      const metadata = createApplicationMetadata(params);
      
      expect(metadata.jobConfig.priority).toBe('high');
      expect(metadata.jobConfig.timeoutMs).toBe(3600000);
      expect(metadata.jobConfig.debugLogging).toBe(true);
    });
    
    it('should throw error for invalid parameters', () => {
      const invalidParams: CreateApplicationMetadataParams = {
        title: '',
        description: 'Valid description',
        userRequestDescription: 'Valid request',
      };
      
      expect(() => createApplicationMetadata(invalidParams)).toThrow(MetadataValidationError);
      expect(() => createApplicationMetadata(invalidParams)).toThrow('Title is required and cannot be empty');
    });
  });
  
  describe('updateApplicationMetadata', () => {
    let baseMetadata: ApplicationMetadata;
    
    beforeEach(() => {
      baseMetadata = createApplicationMetadata({
        title: 'Test Application',
        description: 'A test application',
        userRequestDescription: 'Test request',
      });
    });
    
    it('should update application status', async () => {
      // Add small delay to ensure different timestamps
      await new Promise(resolve => setTimeout(resolve, 1));
      
      const updatedMetadata = updateApplicationMetadata(baseMetadata, {
        status: 'developing',
      });
      
      expect(updatedMetadata.status).toBe('developing');
      expect(updatedMetadata.updatedAt).not.toBe(baseMetadata.updatedAt);
      expect(updatedMetadata.id).toBe(baseMetadata.id); // Should preserve ID
    });
    
    it('should update progress information', () => {
      const updatedMetadata = updateApplicationMetadata(baseMetadata, {
        progress: {
          percentage: 50,
          currentTask: 'Implementing features',
          currentPhase: 'implementation',
        },
      });
      
      expect(updatedMetadata.progress.percentage).toBe(50);
      expect(updatedMetadata.progress.currentTask).toBe('Implementing features');
      expect(updatedMetadata.progress.currentPhase).toBe('implementation');
    });
    
    it('should add error information', () => {
      const error = createApplicationError('Test error', 'TEST_ERROR', true);
      const updatedMetadata = updateApplicationMetadata(baseMetadata, { error });
      
      expect(updatedMetadata.error).toEqual(error);
    });
  });
  
  describe('updateApplicationProgress', () => {
    let baseMetadata: ApplicationMetadata;
    
    beforeEach(() => {
      baseMetadata = createApplicationMetadata({
        title: 'Test Application',
        description: 'A test application',
        userRequestDescription: 'Test request',
      });
    });
    
    it('should update progress with milestone completion', () => {
      const updatedMetadata = updateApplicationProgress(
        baseMetadata,
        25,
        'Completing requirements analysis',
        'requirements',
        'Requirements Analysis'
      );
      
      expect(updatedMetadata.progress.percentage).toBe(25);
      expect(updatedMetadata.progress.currentTask).toBe('Completing requirements analysis');
      expect(updatedMetadata.progress.currentPhase).toBe('requirements');
      expect(updatedMetadata.progress.completedMilestones).toContain('Requirements Analysis');
      expect(updatedMetadata.progress.remainingMilestones).not.toContain('Requirements Analysis');
    });
    
    it('should throw error for invalid progress percentage', () => {
      expect(() => updateApplicationProgress(baseMetadata, -10, 'Invalid progress')).toThrow(MetadataValidationError);
      expect(() => updateApplicationProgress(baseMetadata, 150, 'Invalid progress')).toThrow(MetadataValidationError);
    });
  });
  
  describe('Serialization', () => {
    let metadata: ApplicationMetadata;
    
    beforeEach(() => {
      metadata = createApplicationMetadata({
        title: 'Serialization Test',
        description: 'Testing serialization',
        userRequestDescription: 'Test serialization',
      });
    });
    
    it('should serialize and deserialize metadata correctly', () => {
      const serialized = serializeApplicationMetadata(metadata);
      const deserialized = deserializeApplicationMetadata(serialized);
      
      expect(deserialized).toEqual(metadata);
      expect(() => validateApplicationMetadata(deserialized)).not.toThrow();
    });
    
    it('should throw error for invalid JSON', () => {
      const invalidJson = '{ invalid json }';
      
      expect(() => deserializeApplicationMetadata(invalidJson)).toThrow(MetadataValidationError);
    });
    
    it('should throw error for JSON that doesn\'t represent valid metadata', () => {
      const invalidMetadataJson = JSON.stringify({ invalid: 'metadata' });
      
      expect(() => deserializeApplicationMetadata(invalidMetadataJson)).toThrow(MetadataValidationError);
    });
  });
  
  describe('createApplicationError', () => {
    it('should create valid application error', () => {
      const error = createApplicationError('Test error message', 'TEST_ERROR', true, { context: 'test' });
      
      expect(error.message).toBe('Test error message');
      expect(error.code).toBe('TEST_ERROR');
      expect(error.recoverable).toBe(true);
      expect(error.context).toEqual({ context: 'test' });
      expect(isValidTimestamp(error.occurredAt)).toBe(true);
    });
    
    it('should throw error for invalid parameters', () => {
      expect(() => createApplicationError('', 'TEST_ERROR')).toThrow(MetadataValidationError);
      expect(() => createApplicationError('Valid message', '')).toThrow(MetadataValidationError);
    });
  });
});