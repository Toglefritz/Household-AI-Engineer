/**
 * Unit tests for WebSocket event interfaces and validation.
 */

import {
  WebSocketEvent,
  CommandStartedEvent,
  CommandOutputEvent,
  CommandCompletedEvent,
  UserInputRequiredEvent,
  UserInputRequest,
  WebSocketValidation
} from '../types/websocket-events';

describe('WebSocket Event Interfaces', () => {
  describe('WebSocketValidation.isValidWebSocketEvent', () => {
    it('should validate a valid CommandStartedEvent', () => {
      const event: CommandStartedEvent = {
        type: 'command-started',
        timestamp: new Date().toISOString(),
        command: 'test-command',
        args: ['arg1', 'arg2'],
        executionId: 'exec-123'
      };

      expect(WebSocketValidation.isValidWebSocketEvent(event)).toBe(true);
    });

    it('should validate a valid CommandOutputEvent', () => {
      const event: CommandOutputEvent = {
        type: 'command-output',
        timestamp: new Date().toISOString(),
        output: 'Command output text',
        executionId: 'exec-123',
        stream: 'stdout'
      };

      expect(WebSocketValidation.isValidWebSocketEvent(event)).toBe(true);
    });

    it('should validate a valid CommandCompletedEvent', () => {
      const event: CommandCompletedEvent = {
        type: 'command-completed',
        timestamp: new Date().toISOString(),
        success: true,
        output: 'Final output',
        executionId: 'exec-123',
        exitCode: 0,
        executionTimeMs: 1500
      };

      expect(WebSocketValidation.isValidWebSocketEvent(event)).toBe(true);
    });

    it('should validate a valid UserInputRequiredEvent', () => {
      const event: UserInputRequiredEvent = {
        type: 'user-input-required',
        timestamp: new Date().toISOString(),
        prompt: 'Please enter your choice:',
        inputType: 'choice',
        choices: ['yes', 'no'],
        executionId: 'exec-123',
        timeoutMs: 30000
      };

      expect(WebSocketValidation.isValidWebSocketEvent(event)).toBe(true);
    });

    it('should reject event without required type field', () => {
      const invalidEvent = {
        timestamp: new Date().toISOString(),
        command: 'test'
      };

      expect(WebSocketValidation.isValidWebSocketEvent(invalidEvent)).toBe(false);
    });

    it('should reject event without required timestamp field', () => {
      const invalidEvent = {
        type: 'command-started',
        command: 'test'
      };

      expect(WebSocketValidation.isValidWebSocketEvent(invalidEvent)).toBe(false);
    });

    it('should reject event with unknown type', () => {
      const invalidEvent = {
        type: 'unknown-event-type',
        timestamp: new Date().toISOString()
      };

      expect(WebSocketValidation.isValidWebSocketEvent(invalidEvent)).toBe(false);
    });

    it('should reject CommandStartedEvent with missing required fields', () => {
      const invalidEvent = {
        type: 'command-started',
        timestamp: new Date().toISOString(),
        command: 'test'
        // Missing executionId and args
      };

      expect(WebSocketValidation.isValidWebSocketEvent(invalidEvent)).toBe(false);
    });

    it('should reject CommandOutputEvent with invalid stream', () => {
      const invalidEvent = {
        type: 'command-output',
        timestamp: new Date().toISOString(),
        output: 'test output',
        executionId: 'exec-123',
        stream: 'invalid-stream'
      };

      expect(WebSocketValidation.isValidWebSocketEvent(invalidEvent)).toBe(false);
    });

    it('should reject UserInputRequiredEvent with invalid inputType', () => {
      const invalidEvent = {
        type: 'user-input-required',
        timestamp: new Date().toISOString(),
        prompt: 'Enter something:',
        inputType: 'invalid-type',
        executionId: 'exec-123'
      };

      expect(WebSocketValidation.isValidWebSocketEvent(invalidEvent)).toBe(false);
    });
  });

  describe('WebSocketValidation.isValidUserInputRequest', () => {
    it('should validate a valid UserInputRequest', () => {
      const request: UserInputRequest = {
        value: 'user response',
        type: 'text',
        executionId: 'exec-123'
      };

      expect(WebSocketValidation.isValidUserInputRequest(request)).toBe(true);
    });

    it('should validate UserInputRequest with choice type', () => {
      const request: UserInputRequest = {
        value: 'yes',
        type: 'choice',
        executionId: 'exec-123'
      };

      expect(WebSocketValidation.isValidUserInputRequest(request)).toBe(true);
    });

    it('should reject UserInputRequest with invalid type', () => {
      const invalidRequest = {
        value: 'test',
        type: 'invalid-type',
        executionId: 'exec-123'
      };

      expect(WebSocketValidation.isValidUserInputRequest(invalidRequest)).toBe(false);
    });

    it('should reject UserInputRequest with missing fields', () => {
      const invalidRequest = {
        value: 'test'
        // Missing type and executionId
      };

      expect(WebSocketValidation.isValidUserInputRequest(invalidRequest)).toBe(false);
    });

    it('should reject UserInputRequest with non-string value', () => {
      const invalidRequest = {
        value: 123,
        type: 'text',
        executionId: 'exec-123'
      };

      expect(WebSocketValidation.isValidUserInputRequest(invalidRequest)).toBe(false);
    });
  });
});