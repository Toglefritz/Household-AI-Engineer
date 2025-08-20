---
sidebar_position: 4
---

# Error Types

This page documents the error handling types and classes used in the Kiro Communication Bridge API. These types provide structured error information, recovery guidance, and debugging context for robust error handling in client applications.

## Base Error Classes

### BridgeError

Abstract base class for all bridge-related errors, providing common error properties and methods.

```typescript
abstract class BridgeError extends Error {
  /** Unique error code for programmatic handling */
  public abstract readonly code: string;
  
  /** Whether this error can be recovered from */
  public abstract readonly recoverable: boolean;
  
  /** Timestamp when the error occurred */
  public readonly timestamp: string;
  
  /** Additional context information */
  public readonly context: Record<string, unknown>;

  constructor(
    message: string,
    context: Record<string, unknown> = {}
  );

  /** Returns a sanitized error message safe for client display */
  public getSanitizedMessage(): string;

  /** Returns error information suitable for logging */
  public toLogInfo(): Record<string, unknown>;

  /** Returns error information suitable for client response */
  public toClientInfo(): Record<string, unknown>;
}
```

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `getSanitizedMessage()` | `string` | Returns error message with sensitive information removed |
| `toLogInfo()` | `Record<string, unknown>` | Returns detailed error information for logging |
| `toClientInfo()` | `Record<string, unknown>` | Returns safe error information for client responses |

#### Example Usage

```typescript
try {
  await executeCommand('invalid.command');
} catch (error) {
  if (error instanceof BridgeError) {
    console.log('Error code:', error.code);
    console.log('Recoverable:', error.recoverable);
    console.log('Client message:', error.getSanitizedMessage());
    console.log('Log info:', error.toLogInfo());
  }
}
```

## Specific Error Types

### CommandExecutionError

Error thrown when Kiro command execution fails.

```typescript
class CommandExecutionError extends BridgeError {
  public readonly code = 'COMMAND_EXECUTION_FAILED';
  public readonly recoverable = true;

  /** Command that failed */
  public readonly command: string;
  
  /** Command arguments */
  public readonly args: string[];
  
  /** Exit code from the failed command */
  public readonly exitCode?: number;
  
  /** Standard output from the command */
  public readonly stdout?: string;
  
  /** Standard error from the command */
  public readonly stderr?: string;

  constructor(
    command: string,
    args: string[],
    originalError: string,
    options?: {
      exitCode?: number;
      stdout?: string;
      stderr?: string;
      context?: Record<string, unknown>;
    }
  );
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `command` | `string` | The command that failed to execute |
| `args` | `string[]` | Arguments that were passed to the command |
| `exitCode` | `number` | Process exit code (if available) |
| `stdout` | `string` | Standard output from the failed command |
| `stderr` | `string` | Standard error output from the failed command |

#### Example

```json
{
  "code": "COMMAND_EXECUTION_FAILED",
  "message": "Command 'kiro.generateCode' failed: Invalid syntax in requirements",
  "recoverable": true,
  "timestamp": "2025-01-19T10:30:00Z",
  "command": "kiro.generateCode",
  "args": ["Create a login form"],
  "exitCode": 1,
  "stderr": "Error: Invalid syntax in requirements specification"
}
```

### KiroUnavailableError

Error thrown when Kiro IDE is not available or not responding.

```typescript
class KiroUnavailableError extends BridgeError {
  public readonly code = 'KIRO_UNAVAILABLE';
  public readonly recoverable = true;

  /** Reason why Kiro is unavailable */
  public readonly reason: 'not_installed' | 'not_running' | 'not_responding' | 'unknown';

  constructor(
    reason: 'not_installed' | 'not_running' | 'not_responding' | 'unknown' = 'unknown',
    context: Record<string, unknown> = {}
  );
}
```

#### Reason Values

| Reason | Description | Recovery Actions |
|--------|-------------|------------------|
| `not_installed` | Kiro IDE is not installed or not found in PATH | Install Kiro IDE |
| `not_running` | Kiro IDE is not currently running | Start Kiro IDE |
| `not_responding` | Kiro IDE is not responding to commands | Restart Kiro IDE |
| `unknown` | Kiro IDE is not available for unknown reasons | Check system status |

#### Example

```json
{
  "code": "KIRO_UNAVAILABLE",
  "message": "Kiro IDE is not responding to commands",
  "recoverable": true,
  "timestamp": "2025-01-19T10:30:00Z",
  "reason": "not_responding"
}
```

### ValidationError

Error thrown when request validation fails.

```typescript
class ValidationError extends BridgeError {
  public readonly code = 'VALIDATION_FAILED';
  public readonly recoverable = false;

  /** Field that failed validation */
  public readonly field?: string;
  
  /** Value that failed validation */
  public readonly value?: unknown;
  
  /** Validation rule that was violated */
  public readonly rule?: string;

  constructor(
    message: string,
    options?: {
      field?: string;
      value?: unknown;
      rule?: string;
      context?: Record<string, unknown>;
    }
  );
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `field` | `string` | Name of the field that failed validation |
| `value` | `unknown` | The invalid value that was provided |
| `rule` | `string` | The validation rule that was violated |

#### Common Validation Rules

| Rule | Description | Example |
|------|-------------|---------|
| `required` | Field is required but missing | `"Command is required"` |
| `type` | Field has incorrect type | `"Args must be an array"` |
| `format` | Field has invalid format | `"Invalid email format"` |
| `range` | Field value is out of range | `"Port must be between 1024 and 65535"` |

#### Example

```json
{
  "code": "VALIDATION_FAILED",
  "message": "Command is required and must be a string",
  "recoverable": false,
  "timestamp": "2025-01-19T10:30:00Z",
  "field": "command",
  "value": null,
  "rule": "required"
}
```

### TimeoutError

Error thrown when operations exceed their timeout limits.

```typescript
class TimeoutError extends BridgeError {
  public readonly code = 'OPERATION_TIMEOUT';
  public readonly recoverable = true;

  /** Operation that timed out */
  public readonly operation: string;
  
  /** Timeout duration in milliseconds */
  public readonly timeoutMs: number;
  
  /** Elapsed time before timeout in milliseconds */
  public readonly elapsedMs: number;

  constructor(
    operation: string,
    timeoutMs: number,
    elapsedMs: number,
    context: Record<string, unknown> = {}
  );
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `operation` | `string` | Name of the operation that timed out |
| `timeoutMs` | `number` | Configured timeout duration in milliseconds |
| `elapsedMs` | `number` | Actual elapsed time before timeout |

#### Example

```json
{
  "code": "OPERATION_TIMEOUT",
  "message": "Operation 'command-execution' timed out after 305000ms (limit: 300000ms)",
  "recoverable": true,
  "timestamp": "2025-01-19T10:30:00Z",
  "operation": "command-execution",
  "timeoutMs": 300000,
  "elapsedMs": 305000
}
```

## Error Code Reference

### Complete Error Code List

| Code | Class | Recoverable | Description |
|------|-------|-------------|-------------|
| `COMMAND_EXECUTION_FAILED` | `CommandExecutionError` | Yes | Kiro command execution failed |
| `KIRO_UNAVAILABLE` | `KiroUnavailableError` | Yes | Kiro IDE is not available |
| `VALIDATION_FAILED` | `ValidationError` | No | Request validation failed |
| `OPERATION_TIMEOUT` | `TimeoutError` | Yes | Operation exceeded timeout |
| `CONFIGURATION_ERROR` | `BridgeError` | No | Server configuration error |
| `NETWORK_ERROR` | `BridgeError` | Yes | Network communication error |
| `AUTHENTICATION_FAILED` | `BridgeError` | No | API authentication failed |
| `RATE_LIMIT_EXCEEDED` | `BridgeError` | Yes | Request rate limit exceeded |
| `RESOURCE_EXHAUSTED` | `BridgeError` | Yes | System resources exhausted |
| `INTERNAL_ERROR` | `BridgeError` | No | Unexpected internal error |

### HTTP Status Code Mapping

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `VALIDATION_FAILED` | 400 | Bad Request |
| `AUTHENTICATION_FAILED` | 401 | Unauthorized |
| `RATE_LIMIT_EXCEEDED` | 429 | Too Many Requests |
| `OPERATION_TIMEOUT` | 408 | Request Timeout |
| `COMMAND_EXECUTION_FAILED` | 422 | Unprocessable Entity |
| `CONFIGURATION_ERROR` | 500 | Internal Server Error |
| `KIRO_UNAVAILABLE` | 503 | Service Unavailable |
| `INTERNAL_ERROR` | 500 | Internal Server Error |

## Error Handling Patterns

### Type Guards

Use type guards to identify specific error types:

```typescript
function isBridgeError(error: unknown): error is BridgeError {
  return error instanceof BridgeError;
}

function isCommandExecutionError(error: unknown): error is CommandExecutionError {
  return error instanceof CommandExecutionError;
}

function isKiroUnavailableError(error: unknown): error is KiroUnavailableError {
  return error instanceof KiroUnavailableError;
}

function isValidationError(error: unknown): error is ValidationError {
  return error instanceof ValidationError;
}

function isTimeoutError(error: unknown): error is TimeoutError {
  return error instanceof TimeoutError;
}

// Usage example
try {
  await executeCommand('some.command');
} catch (error) {
  if (isCommandExecutionError(error)) {
    console.log(`Command '${error.command}' failed with exit code ${error.exitCode}`);
  } else if (isKiroUnavailableError(error)) {
    console.log(`Kiro is unavailable: ${error.reason}`);
  } else if (isValidationError(error)) {
    console.log(`Validation failed for field '${error.field}': ${error.message}`);
  } else if (isTimeoutError(error)) {
    console.log(`Operation '${error.operation}' timed out after ${error.elapsedMs}ms`);
  } else {
    console.log('Unknown error:', error);
  }
}
```

### Error Recovery Strategies

```typescript
class ErrorRecoveryHandler {
  async handleError(error: BridgeError): Promise<boolean> {
    if (!error.recoverable) {
      console.error('Non-recoverable error:', error.toLogInfo());
      return false;
    }

    switch (error.code) {
      case 'KIRO_UNAVAILABLE':
        return this.handleKiroUnavailable(error as KiroUnavailableError);
      
      case 'COMMAND_EXECUTION_FAILED':
        return this.handleCommandExecutionFailed(error as CommandExecutionError);
      
      case 'OPERATION_TIMEOUT':
        return this.handleTimeout(error as TimeoutError);
      
      case 'RATE_LIMIT_EXCEEDED':
        return this.handleRateLimit(error);
      
      default:
        console.warn('Unknown recoverable error:', error.code);
        return false;
    }
  }

  private async handleKiroUnavailable(error: KiroUnavailableError): Promise<boolean> {
    console.log(`Kiro unavailable: ${error.reason}`);
    
    switch (error.reason) {
      case 'not_running':
        console.log('Attempting to start Kiro...');
        // Implementation would attempt to start Kiro
        return true;
      
      case 'not_responding':
        console.log('Waiting for Kiro to respond...');
        await this.waitForKiroAvailable();
        return true;
      
      default:
        return false;
    }
  }

  private async handleCommandExecutionFailed(error: CommandExecutionError): Promise<boolean> {
    console.log(`Command '${error.command}' failed, attempting retry...`);
    
    // Implement retry logic with exponential backoff
    await this.delay(1000);
    return true;
  }

  private async handleTimeout(error: TimeoutError): Promise<boolean> {
    console.log(`Operation '${error.operation}' timed out, retrying with longer timeout...`);
    
    // Implement retry with increased timeout
    return true;
  }

  private async handleRateLimit(error: BridgeError): Promise<boolean> {
    console.log('Rate limit exceeded, waiting before retry...');
    
    // Extract retry-after from context if available
    const retryAfter = error.context.retryAfter as number || 5000;
    await this.delay(retryAfter);
    return true;
  }

  private async waitForKiroAvailable(timeoutMs: number = 30000): Promise<void> {
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeoutMs) {
      try {
        // Check if Kiro is available
        const response = await fetch('http://localhost:3001/api/kiro/status');
        if (response.ok) {
          return;
        }
      } catch {
        // Continue waiting
      }
      
      await this.delay(2000);
    }
    
    throw new Error('Kiro did not become available within timeout');
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Usage example
const recoveryHandler = new ErrorRecoveryHandler();

async function executeWithRecovery(command: string, maxRetries: number = 3): Promise<any> {
  let lastError: BridgeError;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await executeCommand(command);
    } catch (error) {
      if (!isBridgeError(error)) {
        throw error; // Re-throw non-bridge errors
      }
      
      lastError = error;
      console.log(`Attempt ${attempt} failed:`, error.message);
      
      if (attempt < maxRetries) {
        const canRecover = await recoveryHandler.handleError(error);
        if (!canRecover) {
          break; // Stop retrying if recovery is not possible
        }
      }
    }
  }
  
  throw lastError!;
}
```

### Client-Side Error Handling

```typescript
class KiroBridgeClient {
  private readonly baseUrl: string;
  private readonly recoveryHandler: ErrorRecoveryHandler;

  constructor(baseUrl: string = 'http://localhost:3001') {
    this.baseUrl = baseUrl;
    this.recoveryHandler = new ErrorRecoveryHandler();
  }

  async executeCommand(
    command: string,
    args: string[] = [],
    options: { maxRetries?: number; timeout?: number } = {}
  ): Promise<any> {
    const { maxRetries = 3, timeout = 30000 } = options;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), timeout);

        const response = await fetch(`${this.baseUrl}/api/kiro/execute`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ command, args }),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          const errorData = await response.json();
          throw this.createErrorFromResponse(response.status, errorData);
        }

        return await response.json();

      } catch (error) {
        if (attempt === maxRetries) {
          throw error;
        }

        if (isBridgeError(error)) {
          const canRecover = await this.recoveryHandler.handleError(error);
          if (!canRecover) {
            throw error;
          }
        } else {
          throw error; // Re-throw non-bridge errors immediately
        }

        // Exponential backoff
        const delay = Math.min(1000 * Math.pow(2, attempt - 1), 10000);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  private createErrorFromResponse(status: number, errorData: any): BridgeError {
    const { code, message, context } = errorData;

    switch (code) {
      case 'COMMAND_EXECUTION_FAILED':
        return new CommandExecutionError(
          context.command,
          context.args,
          message,
          context
        );
      
      case 'KIRO_UNAVAILABLE':
        return new KiroUnavailableError(context.reason, context);
      
      case 'VALIDATION_FAILED':
        return new ValidationError(message, context);
      
      case 'OPERATION_TIMEOUT':
        return new TimeoutError(
          context.operation,
          context.timeoutMs,
          context.elapsedMs,
          context
        );
      
      default:
        // Create a generic BridgeError for unknown error codes
        return new (class extends BridgeError {
          public readonly code = errorData.code || 'UNKNOWN_ERROR';
          public readonly recoverable = errorData.recoverable ?? false;
        })(message, context);
    }
  }
}
```

### Dart/Flutter Error Handling

```dart
abstract class BridgeError implements Exception {
  String get code;
  String get message;
  bool get recoverable;
  DateTime get timestamp;
  Map<String, dynamic> get context;
}

class CommandExecutionError extends BridgeError {
  @override
  final String code = 'COMMAND_EXECUTION_FAILED';
  
  @override
  final bool recoverable = true;
  
  @override
  final String message;
  
  @override
  final DateTime timestamp;
  
  @override
  final Map<String, dynamic> context;
  
  final String command;
  final List<String> args;
  final int? exitCode;
  final String? stdout;
  final String? stderr;

  CommandExecutionError({
    required this.message,
    required this.timestamp,
    required this.context,
    required this.command,
    required this.args,
    this.exitCode,
    this.stdout,
    this.stderr,
  });

  factory CommandExecutionError.fromJson(Map<String, dynamic> json) {
    return CommandExecutionError(
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: json['context'] as Map<String, dynamic>? ?? {},
      command: json['command'] as String,
      args: List<String>.from(json['args'] as List),
      exitCode: json['exitCode'] as int?,
      stdout: json['stdout'] as String?,
      stderr: json['stderr'] as String?,
    );
  }
}

class ErrorHandler {
  Future<bool> handleError(BridgeError error) async {
    if (!error.recoverable) {
      print('Non-recoverable error: ${error.code} - ${error.message}');
      return false;
    }

    switch (error.code) {
      case 'KIRO_UNAVAILABLE':
        return _handleKiroUnavailable(error);
      case 'COMMAND_EXECUTION_FAILED':
        return _handleCommandExecutionFailed(error);
      case 'OPERATION_TIMEOUT':
        return _handleTimeout(error);
      default:
        print('Unknown recoverable error: ${error.code}');
        return false;
    }
  }

  Future<bool> _handleKiroUnavailable(BridgeError error) async {
    print('Kiro unavailable, waiting for recovery...');
    await Future.delayed(const Duration(seconds: 5));
    return true;
  }

  Future<bool> _handleCommandExecutionFailed(BridgeError error) async {
    print('Command execution failed, retrying...');
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<bool> _handleTimeout(BridgeError error) async {
    print('Operation timed out, retrying with longer timeout...');
    await Future.delayed(const Duration(seconds: 3));
    return true;
  }
}
```

## Best Practices

### Error Logging

1. **Structured Logging**: Use the `toLogInfo()` method for detailed error logging
2. **Context Preservation**: Include relevant context information in error logs
3. **Error Correlation**: Use correlation IDs to track errors across requests

### User Experience

1. **User-Friendly Messages**: Use `getSanitizedMessage()` for user-facing error messages
2. **Recovery Guidance**: Provide clear guidance on how users can resolve errors
3. **Progress Indication**: Show progress during error recovery attempts

### Monitoring and Alerting

1. **Error Metrics**: Track error rates and types for monitoring
2. **Alert Thresholds**: Set up alerts for high error rates or critical errors
3. **Error Trends**: Monitor error trends to identify systemic issues

## Next Steps

- **[Command Execution Types](/docs/api/types/command-execution)** - Command execution interfaces
- **[Error Handling Guide](/docs/guides/error-handling)** - Best practices for error handling
- **[Troubleshooting](/docs/guides/troubleshooting)** - Common issues and solutions
- **[API Overview](/docs/api/overview)** - Complete API reference