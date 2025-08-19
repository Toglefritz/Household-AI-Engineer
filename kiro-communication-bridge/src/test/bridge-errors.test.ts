/**
 * Unit tests for bridge error types and error handling.
 */

import {
  BridgeError,
  CommandExecutionError,
  KiroUnavailableError,
  WebSocketError,
  ValidationError,
  TimeoutError,
  ConfigurationError,
  isBridgeError,
  isRecoverableError,
  ErrorUtils
} from '../types/bridge-errors';

describe('Bridge Error Types', () => {
  describe('CommandExecutionError', () => {
    it('should create CommandExecutionError with all properties', () => {
      const error = new CommandExecutionError(
        'test-command',
        ['arg1', 'arg2'],
        'Command failed',
        {
          exitCode: 1,
          stdout: 'output',
          stderr: 'error output'
        }
      );

      expect(error).toBeInstanceOf(BridgeError);
      expect(error).toBeInstanceOf(CommandExecutionError);
      expect(error.code).toBe('COMMAND_EXECUTION_FAILED');
      expect(error.recoverable).toBe(true);
      expect(error.command).toBe('test-command');
      expect(error.args).toEqual(['arg1', 'arg2']);
      expect(error.exitCode).toBe(1);
      expect(error.stdout).toBe('output');
      expect(error.stderr).toBe('error output');
      expect(error.message).toContain('test-command');
      expect(error.message).toContain('Command failed');
    });

    it('should create CommandExecutionError from command result', () => {
      const result = {
        exitCode: 2,
        stdout: 'some output',
        stderr: 'some error',
        error: 'Process failed'
      };

      const error = CommandExecutionError.fromCommandResult('my-command', ['--flag'], result);

      expect(error.command).toBe('my-command');
      expect(error.args).toEqual(['--flag']);
      expect(error.exitCode).toBe(2);
      expect(error.stdout).toBe('some output');
      expect(error.stderr).toBe('some error');
      expect(error.message).toContain('Process failed');
    });
  });

  describe('KiroUnavailableError', () => {
    it('should create KiroUnavailableError with specific reason', () => {
      const error = new KiroUnavailableError('not_installed');

      expect(error).toBeInstanceOf(BridgeError);
      expect(error.code).toBe('KIRO_UNAVAILABLE');
      expect(error.recoverable).toBe(true);
      expect(error.reason).toBe('not_installed');
      expect(error.message).toContain('not installed');
    });

    it('should provide recovery actions based on reason', () => {
      const notInstalledError = new KiroUnavailableError('not_installed');
      const notRunningError = new KiroUnavailableError('not_running');
      const notRespondingError = new KiroUnavailableError('not_responding');

      expect(notInstalledError.getRecoveryActions()).toContain('Install Kiro IDE');
      expect(notRunningError.getRecoveryActions()).toContain('Start Kiro IDE');
      expect(notRespondingError.getRecoveryActions()).toContain('Restart Kiro IDE');
    });
  });

  describe('WebSocketError', () => {
    it('should create WebSocketError with error type', () => {
      const error = new WebSocketError(
        'connection_failed',
        'Connection refused',
        { wsCode: 1006, wsReason: 'Abnormal closure' }
      );

      expect(error).toBeInstanceOf(BridgeError);
      expect(error.code).toBe('WEBSOCKET_ERROR');
      expect(error.recoverable).toBe(true);
      expect(error.errorType).toBe('connection_failed');
      expect(error.wsCode).toBe(1006);
      expect(error.wsReason).toBe('Abnormal closure');
    });

    it('should create WebSocketError from close event', () => {
      const error = WebSocketError.fromCloseEvent(1000, 'Normal closure');

      expect(error.errorType).toBe('client_disconnected');
      expect(error.wsCode).toBe(1000);
      expect(error.wsReason).toBe('Normal closure');
      expect(error.message).toContain('1000');
      expect(error.message).toContain('Normal closure');
    });

    it('should create WebSocketError from connection failure', () => {
      const originalError = new Error('ECONNREFUSED');
      const error = WebSocketError.fromConnectionFailure(originalError);

      expect(error.errorType).toBe('connection_failed');
      expect(error.message).toContain('ECONNREFUSED');
    });
  });

  describe('ValidationError', () => {
    it('should create ValidationError with field information', () => {
      const error = new ValidationError(
        'Invalid field value',
        {
          field: 'command',
          value: '',
          rule: 'required'
        }
      );

      expect(error).toBeInstanceOf(BridgeError);
      expect(error.code).toBe('VALIDATION_FAILED');
      expect(error.recoverable).toBe(false);
      expect(error.field).toBe('command');
      expect(error.value).toBe('');
      expect(error.rule).toBe('required');
    });

    it('should create ValidationError for missing field', () => {
      const error = ValidationError.missingField('executionId');

      expect(error.field).toBe('executionId');
      expect(error.rule).toBe('required');
      expect(error.message).toContain('executionId');
      expect(error.message).toContain('missing');
    });

    it('should create ValidationError for invalid format', () => {
      const error = ValidationError.invalidFormat('timestamp', 'ISO 8601', 'invalid-date');

      expect(error.field).toBe('timestamp');
      expect(error.value).toBe('invalid-date');
      expect(error.rule).toBe('format');
      expect(error.message).toContain('timestamp');
      expect(error.message).toContain('ISO 8601');
    });
  });

  describe('TimeoutError', () => {
    it('should create TimeoutError with timing information', () => {
      const error = new TimeoutError('command-execution', 5000, 6000);

      expect(error).toBeInstanceOf(BridgeError);
      expect(error.code).toBe('OPERATION_TIMEOUT');
      expect(error.recoverable).toBe(true);
      expect(error.operation).toBe('command-execution');
      expect(error.timeoutMs).toBe(5000);
      expect(error.elapsedMs).toBe(6000);
      expect(error.message).toContain('command-execution');
      expect(error.message).toContain('6000ms');
      expect(error.message).toContain('5000ms');
    });
  });

  describe('ConfigurationError', () => {
    it('should create ConfigurationError with config details', () => {
      const error = new ConfigurationError(
        'Invalid port configuration',
        {
          configKey: 'api.port',
          expectedFormat: 'number between 1024-65535',
          actualValue: 'invalid'
        }
      );

      expect(error).toBeInstanceOf(BridgeError);
      expect(error.code).toBe('CONFIGURATION_ERROR');
      expect(error.recoverable).toBe(false);
      expect(error.configKey).toBe('api.port');
      expect(error.expectedFormat).toBe('number between 1024-65535');
      expect(error.actualValue).toBe('invalid');
    });
  });

  describe('Error utility functions', () => {
    it('should identify BridgeError instances', () => {
      const bridgeError = new ValidationError('test');
      const regularError = new Error('test');

      expect(isBridgeError(bridgeError)).toBe(true);
      expect(isBridgeError(regularError)).toBe(false);
      expect(isBridgeError(null)).toBe(false);
      expect(isBridgeError(undefined)).toBe(false);
    });

    it('should identify recoverable errors', () => {
      const recoverableError = new CommandExecutionError('cmd', [], 'failed');
      const nonRecoverableError = new ValidationError('invalid');

      expect(isRecoverableError(recoverableError)).toBe(true);
      expect(isRecoverableError(nonRecoverableError)).toBe(false);
      expect(isRecoverableError(new Error('regular error'))).toBe(false);
    });
  });

  describe('ErrorUtils', () => {
    it('should convert regular Error to BridgeError', () => {
      const regularError = new Error('Something went wrong');
      const bridgeError = ErrorUtils.toBridgeError(regularError);

      expect(isBridgeError(bridgeError)).toBe(true);
      expect(bridgeError.code).toBe('UNKNOWN_ERROR');
      expect(bridgeError.recoverable).toBe(false);
      expect(bridgeError.message).toBe('Something went wrong');
    });

    it('should return BridgeError unchanged', () => {
      const originalError = new ValidationError('test error');
      const result = ErrorUtils.toBridgeError(originalError);

      expect(result).toBe(originalError);
    });

    it('should convert non-Error values to BridgeError', () => {
      const stringError = 'String error message';
      const bridgeError = ErrorUtils.toBridgeError(stringError);

      expect(isBridgeError(bridgeError)).toBe(true);
      expect(bridgeError.message).toBe('String error message');
    });

    it('should format error for logging', () => {
      const error = new CommandExecutionError('test-cmd', ['arg'], 'failed');
      const logInfo = ErrorUtils.formatForLogging(error);

      expect(logInfo).toHaveProperty('name', 'CommandExecutionError');
      expect(logInfo).toHaveProperty('code', 'COMMAND_EXECUTION_FAILED');
      expect(logInfo).toHaveProperty('message');
      expect(logInfo).toHaveProperty('recoverable', true);
      expect(logInfo).toHaveProperty('timestamp');
      expect(logInfo).toHaveProperty('context');
    });

    it('should format error for client', () => {
      const error = new ValidationError('Invalid input');
      const clientInfo = ErrorUtils.formatForClient(error);

      expect(clientInfo).toHaveProperty('code', 'VALIDATION_FAILED');
      expect(clientInfo).toHaveProperty('message');
      expect(clientInfo).toHaveProperty('recoverable', false);
      expect(clientInfo).toHaveProperty('timestamp');
      expect(clientInfo).not.toHaveProperty('stack');
      expect(clientInfo).not.toHaveProperty('context');
    });

    it('should provide recovery suggestions for different error types', () => {
      const kiroError = new KiroUnavailableError('not_running');
      const commandError = new CommandExecutionError('cmd', [], 'failed');
      const wsError = new WebSocketError('connection_failed', 'failed');
      const validationError = new ValidationError('invalid');

      expect(ErrorUtils.getRecoverySuggestions(kiroError)).toContain('Start Kiro IDE');
      expect(ErrorUtils.getRecoverySuggestions(commandError)).toContain('Check command syntax');
      expect(ErrorUtils.getRecoverySuggestions(wsError)).toContain('Check network connection');
      expect(ErrorUtils.getRecoverySuggestions(validationError)).toContain('Check request format');
    });
  });

  describe('BridgeError base class methods', () => {
    it('should sanitize error messages', () => {
      const error = new ValidationError(
        'Failed to access /home/user/secret/file.txt with email user@example.com and IP 192.168.1.1'
      );

      const sanitized = error.getSanitizedMessage();
      expect(sanitized).not.toContain('/home/user/secret/file.txt');
      expect(sanitized).not.toContain('user@example.com');
      expect(sanitized).not.toContain('192.168.1.1');
      expect(sanitized).toContain('[path]');
      expect(sanitized).toContain('[email]');
      expect(sanitized).toContain('[ip]');
    });

    it('should provide log info with all details', () => {
      const error = new TimeoutError('test-op', 1000, 1500);
      const logInfo = error.toLogInfo();

      expect(logInfo).toHaveProperty('name', 'TimeoutError');
      expect(logInfo).toHaveProperty('code', 'OPERATION_TIMEOUT');
      expect(logInfo).toHaveProperty('message');
      expect(logInfo).toHaveProperty('recoverable', true);
      expect(logInfo).toHaveProperty('timestamp');
      expect(logInfo).toHaveProperty('context');
      expect(logInfo).toHaveProperty('stack');
    });

    it('should provide client info without sensitive details', () => {
      const error = new ConfigurationError('Config error', { configKey: 'secret.key' });
      const clientInfo = error.toClientInfo();

      expect(clientInfo).toHaveProperty('code', 'CONFIGURATION_ERROR');
      expect(clientInfo).toHaveProperty('message');
      expect(clientInfo).toHaveProperty('recoverable', false);
      expect(clientInfo).toHaveProperty('timestamp');
      expect(clientInfo).not.toHaveProperty('stack');
      expect(clientInfo).not.toHaveProperty('context');
    });
  });
});