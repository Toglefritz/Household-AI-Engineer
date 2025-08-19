/**
 * Unit tests for command execution interfaces and validation.
 */

import {
  ExecuteCommandRequest,
  CommandResult,
  KiroStatus,
  CommandValidation
} from '../types/command-execution';

describe('Command Execution Interfaces', () => {
  describe('CommandValidation.isValidExecuteCommandRequest', () => {
    it('should validate a valid ExecuteCommandRequest', () => {
      const validRequest: ExecuteCommandRequest = {
        command: 'test-command',
        args: ['arg1', 'arg2'],
        workspacePath: '/path/to/workspace'
      };

      expect(CommandValidation.isValidExecuteCommandRequest(validRequest)).toBe(true);
    });

    it('should validate a minimal ExecuteCommandRequest', () => {
      const minimalRequest: ExecuteCommandRequest = {
        command: 'test-command'
      };

      expect(CommandValidation.isValidExecuteCommandRequest(minimalRequest)).toBe(true);
    });

    it('should reject request with empty command', () => {
      const invalidRequest = {
        command: '',
        args: ['arg1']
      };

      expect(CommandValidation.isValidExecuteCommandRequest(invalidRequest)).toBe(false);
    });

    it('should reject request with non-string command', () => {
      const invalidRequest = {
        command: 123,
        args: ['arg1']
      };

      expect(CommandValidation.isValidExecuteCommandRequest(invalidRequest)).toBe(false);
    });

    it('should reject request with invalid args array', () => {
      const invalidRequest = {
        command: 'test-command',
        args: ['valid', 123, 'invalid']
      };

      expect(CommandValidation.isValidExecuteCommandRequest(invalidRequest)).toBe(false);
    });

    it('should reject request with non-string workspacePath', () => {
      const invalidRequest = {
        command: 'test-command',
        workspacePath: 123
      };

      expect(CommandValidation.isValidExecuteCommandRequest(invalidRequest)).toBe(false);
    });

    it('should reject null or undefined input', () => {
      expect(CommandValidation.isValidExecuteCommandRequest(null)).toBe(false);
      expect(CommandValidation.isValidExecuteCommandRequest(undefined)).toBe(false);
    });
  });

  describe('CommandValidation.isValidCommandResult', () => {
    it('should validate a valid CommandResult', () => {
      const validResult: CommandResult = {
        success: true,
        output: 'Command executed successfully',
        executionTimeMs: 1500,
        command: 'test-command',
        args: ['arg1', 'arg2'],
        exitCode: 0
      };

      expect(CommandValidation.isValidCommandResult(validResult)).toBe(true);
    });

    it('should validate CommandResult without optional fields', () => {
      const minimalResult: CommandResult = {
        success: false,
        output: 'Command failed',
        executionTimeMs: 500,
        command: 'test-command',
        args: [],
        error: 'Command not found'
      };

      expect(CommandValidation.isValidCommandResult(minimalResult)).toBe(true);
    });

    it('should reject CommandResult with invalid success field', () => {
      const invalidResult = {
        success: 'true',
        output: 'test',
        executionTimeMs: 100,
        command: 'test',
        args: []
      };

      expect(CommandValidation.isValidCommandResult(invalidResult)).toBe(false);
    });

    it('should reject CommandResult with invalid args', () => {
      const invalidResult = {
        success: true,
        output: 'test',
        executionTimeMs: 100,
        command: 'test',
        args: 'not-an-array'
      };

      expect(CommandValidation.isValidCommandResult(invalidResult)).toBe(false);
    });
  });

  describe('CommandValidation.isValidKiroStatus', () => {
    it('should validate a valid KiroStatus', () => {
      const validStatus: KiroStatus = {
        status: 'ready',
        currentCommand: 'some-command',
        version: '1.0.0'
      };

      expect(CommandValidation.isValidKiroStatus(validStatus)).toBe(true);
    });

    it('should validate minimal KiroStatus', () => {
      const minimalStatus: KiroStatus = {
        status: 'unavailable'
      };

      expect(CommandValidation.isValidKiroStatus(minimalStatus)).toBe(true);
    });

    it('should reject KiroStatus with invalid status', () => {
      const invalidStatus = {
        status: 'invalid-status'
      };

      expect(CommandValidation.isValidKiroStatus(invalidStatus)).toBe(false);
    });

    it('should reject KiroStatus with non-string currentCommand', () => {
      const invalidStatus = {
        status: 'busy',
        currentCommand: 123
      };

      expect(CommandValidation.isValidKiroStatus(invalidStatus)).toBe(false);
    });
  });
});