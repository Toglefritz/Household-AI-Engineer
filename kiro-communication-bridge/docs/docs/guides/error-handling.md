---
sidebar_position: 3
---

# Error Handling Guide

Learn how to implement robust error handling for the Kiro Communication Bridge API. This guide covers error types, recovery strategies, and best practices for building resilient applications.

## Understanding API Errors

The Kiro Communication Bridge API uses structured error responses with specific error codes for programmatic handling.

### Error Response Format

All API errors follow this consistent format:

```json
{
  "code": "ERROR_CODE",
  "message": "Human-readable error description",
  "recoverable": true,
  "timestamp": "2025-01-19T10:30:00Z",
  "context": {
    "field": "command",
    "operation": "command-execution"
  }
}
```

### Error Categories

| Category | Recoverable | Action Required |
|----------|-------------|-----------------|
| **Validation Errors** | No | Fix client request |
| **Authentication Errors** | No | Update API key |
| **Availability Errors** | Yes | Retry with backoff |
| **Timeout Errors** | Yes | Retry with longer timeout |
| **Rate Limit Errors** | Yes | Wait and retry |

## Common Error Types

### 1. Validation Errors (400 Bad Request)

**Cause**: Invalid request data or missing required fields

```json
{
  "code": "VALIDATION_FAILED",
  "message": "Command is required and must be a string",
  "recoverable": false,
  "field": "command",
  "rule": "required"
}
```

**Handling Strategy**:
```typescript
function handleValidationError(error: ValidationError) {
  // Don't retry - fix the request
  console.error(`Validation failed for field '${error.field}': ${error.message}`);
  
  // Show user-friendly message
  showUserError(`Please provide a valid ${error.field}`);
  
  // Highlight problematic field in UI
  highlightField(error.field);
}
```

### 2. Authentication Errors (401 Unauthorized)

**Cause**: Missing or invalid API key

```json
{
  "error": "Unauthorized",
  "message": "Valid API key required"
}
```

**Handling Strategy**:
```typescript
function handleAuthError(error: AuthError) {
  // Don't retry - fix authentication
  console.error('Authentication failed:', error.message);
  
  // Redirect to settings or show auth dialog
  showAuthenticationDialog();
  
  // Clear invalid credentials
  clearStoredApiKey();
}
```

### 3. Service Unavailable (503)

**Cause**: Kiro IDE is not available or not responding

```json
{
  "code": "KIRO_UNAVAILABLE",
  "message": "Kiro IDE is not responding to commands",
  "recoverable": true,
  "reason": "not_responding"
}
```

**Handling Strategy**:
```typescript
async function handleKiroUnavailable(error: KiroUnavailableError) {
  console.log(`Kiro unavailable: ${error.reason}`);
  
  switch (error.reason) {
    case 'not_running':
      showUserMessage('Please start Kiro IDE');
      break;
    case 'not_responding':
      showUserMessage('Kiro IDE is not responding. Retrying...');
      await waitAndRetry();
      break;
    case 'not_installed':
      showUserMessage('Please install Kiro IDE');
      break;
  }
}
```

### 4. Timeout Errors (408)

**Cause**: Operation exceeded time limit

```json
{
  "code": "OPERATION_TIMEOUT",
  "message": "Operation 'command-execution' timed out after 300000ms",
  "recoverable": true,
  "operation": "command-execution",
  "timeoutMs": 300000
}
```

**Handling Strategy**:
```typescript
async function handleTimeout(error: TimeoutError) {
  console.log(`Operation '${error.operation}' timed out`);
  
  // Retry with longer timeout
  const newTimeout = Math.min(error.timeoutMs * 1.5, 600000); // Max 10 minutes
  return retryWithTimeout(newTimeout);
}
```## Error 
Handling Patterns

### 1. Retry with Exponential Backoff

Implement exponential backoff for recoverable errors:

```typescript
class RetryHandler {
  async executeWithRetry<T>(
    operation: () => Promise<T>,
    options: {
      maxRetries?: number;
      baseDelayMs?: number;
      maxDelayMs?: number;
      backoffMultiplier?: number;
    } = {}
  ): Promise<T> {
    const {
      maxRetries = 3,
      baseDelayMs = 1000,
      maxDelayMs = 30000,
      backoffMultiplier = 2
    } = options;

    let lastError: Error;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error as Error;

        // Don't retry non-recoverable errors
        if (!this.isRecoverableError(error)) {
          throw error;
        }

        if (attempt === maxRetries) {
          break; // Last attempt failed
        }

        // Calculate delay with exponential backoff
        const delay = Math.min(
          baseDelayMs * Math.pow(backoffMultiplier, attempt - 1),
          maxDelayMs
        );

        console.log(`Attempt ${attempt} failed, retrying in ${delay}ms...`);
        await this.delay(delay);
      }
    }

    throw lastError!;
  }

  private isRecoverableError(error: any): boolean {
    if (error.code) {
      const recoverableCodes = [
        'KIRO_UNAVAILABLE',
        'OPERATION_TIMEOUT',
        'NETWORK_ERROR',
        'RATE_LIMIT_EXCEEDED'
      ];
      return recoverableCodes.includes(error.code);
    }

    // Network errors are usually recoverable
    return error.name === 'NetworkError' || 
           error.code === 'ECONNREFUSED' ||
           error.code === 'ETIMEDOUT';
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Usage
const retryHandler = new RetryHandler();

try {
  const result = await retryHandler.executeWithRetry(
    () => apiClient.executeCommand('workbench.action.showCommands'),
    { maxRetries: 5, baseDelayMs: 2000 }
  );
  console.log('Command executed:', result);
} catch (error) {
  console.error('All retry attempts failed:', error);
}
```

### 2. Circuit Breaker Pattern

Prevent cascading failures with circuit breaker:

```typescript
enum CircuitState {
  CLOSED = 'closed',     // Normal operation
  OPEN = 'open',         // Failing, reject requests
  HALF_OPEN = 'half_open' // Testing recovery
}

class CircuitBreaker {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount: number = 0;
  private lastFailureTime: number = 0;
  private successCount: number = 0;

  constructor(
    private readonly failureThreshold: number = 5,
    private readonly recoveryTimeoutMs: number = 60000,
    private readonly successThreshold: number = 3
  ) {}

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (this.shouldAttemptReset()) {
        this.state = CircuitState.HALF_OPEN;
        this.successCount = 0;
      } else {
        throw new Error('Circuit breaker is OPEN - operation rejected');
      }
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private shouldAttemptReset(): boolean {
    return Date.now() - this.lastFailureTime >= this.recoveryTimeoutMs;
  }

  private onSuccess(): void {
    this.failureCount = 0;

    if (this.state === CircuitState.HALF_OPEN) {
      this.successCount++;
      if (this.successCount >= this.successThreshold) {
        this.state = CircuitState.CLOSED;
      }
    }
  }

  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    if (this.state === CircuitState.HALF_OPEN) {
      this.state = CircuitState.OPEN;
    } else if (this.failureCount >= this.failureThreshold) {
      this.state = CircuitState.OPEN;
    }
  }

  getState(): CircuitState {
    return this.state;
  }
}

// Usage
const circuitBreaker = new CircuitBreaker(5, 60000, 3);

try {
  const result = await circuitBreaker.execute(
    () => apiClient.getStatus()
  );
  console.log('Status retrieved:', result);
} catch (error) {
  if (error.message.includes('Circuit breaker is OPEN')) {
    console.log('Service is temporarily unavailable');
  } else {
    console.error('Operation failed:', error);
  }
}
```

### 3. Graceful Degradation

Provide fallback functionality when services are unavailable:

```typescript
class GracefulApiClient {
  private fallbackData: Map<string, any> = new Map();
  private lastSuccessfulResponse: Map<string, number> = new Map();

  async getStatusWithFallback(): Promise<KiroStatusResponse> {
    try {
      const status = await this.apiClient.getStatus();
      
      // Cache successful response
      this.fallbackData.set('status', status);
      this.lastSuccessfulResponse.set('status', Date.now());
      
      return status;
    } catch (error) {
      console.warn('Status request failed, using fallback:', error);
      
      const cachedStatus = this.fallbackData.get('status');
      if (cachedStatus && this.isCacheValid('status', 300000)) { // 5 minutes
        return {
          ...cachedStatus,
          status: 'unavailable' as const,
          timestamp: new Date().toISOString(),
        };
      }

      // Return minimal fallback
      return {
        status: 'unavailable' as const,
        availableCommands: [],
        timestamp: new Date().toISOString(),
      };
    }
  }

  async executeCommandWithFallback(
    command: string,
    args: string[] = []
  ): Promise<ExecuteCommandResponse> {
    try {
      return await this.apiClient.executeCommand({ command, args });
    } catch (error) {
      console.warn('Command execution failed, providing fallback response:', error);
      
      // Return failure response instead of throwing
      return {
        success: false,
        output: '',
        error: `Command failed: ${error.message}`,
        executionTimeMs: 0,
      };
    }
  }

  private isCacheValid(key: string, maxAgeMs: number): boolean {
    const lastSuccess = this.lastSuccessfulResponse.get(key);
    return lastSuccess ? (Date.now() - lastSuccess) < maxAgeMs : false;
  }
}
```##
 Flutter Error Handling

### Dart Error Handler

```dart
class KiroErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Network connection failed. Please check your connection.';
    } else if (error is HttpException) {
      if (error.message.contains('401')) {
        return 'Authentication failed. Please check your API key.';
      } else if (error.message.contains('503')) {
        return 'Kiro IDE is not available. Please ensure Kiro is running.';
      } else if (error.message.contains('408')) {
        return 'Request timed out. Please try again.';
      }
      return 'Server error: ${error.message}';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }

  static bool isRetryableError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) {
      return error.message.contains('503') || 
             error.message.contains('408') ||
             error.message.contains('500');
    }
    return false;
  }

  static ErrorSeverity getErrorSeverity(dynamic error) {
    if (error is HttpException && error.message.contains('401')) {
      return ErrorSeverity.critical;
    }
    if (error is SocketException) {
      return ErrorSeverity.warning;
    }
    return ErrorSeverity.error;
  }
}

enum ErrorSeverity { info, warning, error, critical }
```

### Flutter Provider with Error Handling

```dart
class KiroProvider extends ChangeNotifier {
  String? _error;
  ErrorSeverity? _errorSeverity;
  bool _isRetrying = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  String? get error => _error;
  ErrorSeverity? get errorSeverity => _errorSeverity;
  bool get isRetrying => _isRetrying;

  Future<ExecuteCommandResponse?> executeCommandWithErrorHandling(
    String command, {
    List<String>? args,
  }) async {
    _clearError();
    
    try {
      return await _executeWithRetry(command, args: args);
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  Future<ExecuteCommandResponse> _executeWithRetry(
    String command, {
    List<String>? args,
    int attempt = 1,
  }) async {
    try {
      final request = ExecuteCommandRequest(command: command, args: args);
      return await _apiService.executeCommand(request);
    } catch (e) {
      if (attempt < _maxRetries && KiroErrorHandler.isRetryableError(e)) {
        _isRetrying = true;
        _retryCount = attempt;
        notifyListeners();

        // Exponential backoff
        final delay = Duration(milliseconds: 1000 * (1 << (attempt - 1)));
        await Future.delayed(delay);

        return _executeWithRetry(command, args: args, attempt: attempt + 1);
      }
      rethrow;
    } finally {
      _isRetrying = false;
      _retryCount = 0;
      notifyListeners();
    }
  }

  void _handleError(dynamic error) {
    _error = KiroErrorHandler.getErrorMessage(error);
    _errorSeverity = KiroErrorHandler.getErrorSeverity(error);
    notifyListeners();

    // Log error for debugging
    print('Kiro API Error: $_error');
    
    // Show user notification based on severity
    _showErrorNotification();
  }

  void _showErrorNotification() {
    // Implementation depends on your notification system
    switch (_errorSeverity) {
      case ErrorSeverity.critical:
        // Show persistent error dialog
        break;
      case ErrorSeverity.error:
        // Show error snackbar
        break;
      case ErrorSeverity.warning:
        // Show warning message
        break;
      case ErrorSeverity.info:
        // Show info message
        break;
      default:
        break;
    }
  }

  void _clearError() {
    _error = null;
    _errorSeverity = null;
    notifyListeners();
  }

  void dismissError() {
    _clearError();
  }
}
```

### Error Display Widget

```dart
class ErrorDisplayWidget extends StatelessWidget {
  final String? error;
  final ErrorSeverity? severity;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({
    Key? key,
    this.error,
    this.severity,
    this.onDismiss,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (error == null) return SizedBox.shrink();

    return Card(
      color: _getBackgroundColor(),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _getIcon(),
              color: _getIconColor(),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTitle(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    error!,
                    style: TextStyle(color: _getTextColor()),
                  ),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text('Retry'),
              ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (severity) {
      case ErrorSeverity.critical:
        return Colors.red.shade100;
      case ErrorSeverity.error:
        return Colors.orange.shade100;
      case ErrorSeverity.warning:
        return Colors.yellow.shade100;
      case ErrorSeverity.info:
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getIcon() {
    switch (severity) {
      case ErrorSeverity.critical:
        return Icons.error;
      case ErrorSeverity.error:
        return Icons.warning;
      case ErrorSeverity.warning:
        return Icons.info;
      case ErrorSeverity.info:
        return Icons.info_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getIconColor() {
    switch (severity) {
      case ErrorSeverity.critical:
        return Colors.red;
      case ErrorSeverity.error:
        return Colors.orange;
      case ErrorSeverity.warning:
        return Colors.amber;
      case ErrorSeverity.info:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getTextColor() {
    switch (severity) {
      case ErrorSeverity.critical:
        return Colors.red.shade800;
      case ErrorSeverity.error:
        return Colors.orange.shade800;
      case ErrorSeverity.warning:
        return Colors.amber.shade800;
      case ErrorSeverity.info:
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  String _getTitle() {
    switch (severity) {
      case ErrorSeverity.critical:
        return 'Critical Error';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.info:
        return 'Information';
      default:
        return 'Notice';
    }
  }
}
```##
 User Experience Best Practices

### 1. Progressive Error Disclosure

Show appropriate level of detail based on user type:

```typescript
class ErrorPresenter {
  presentError(error: BridgeError, userType: 'developer' | 'end-user') {
    const baseMessage = error.getSanitizedMessage();
    
    if (userType === 'developer') {
      return {
        title: `Error ${error.code}`,
        message: baseMessage,
        details: error.toLogInfo(),
        actions: this.getDeveloperActions(error),
      };
    } else {
      return {
        title: 'Something went wrong',
        message: this.getUserFriendlyMessage(error),
        actions: this.getEndUserActions(error),
      };
    }
  }

  private getUserFriendlyMessage(error: BridgeError): string {
    switch (error.code) {
      case 'KIRO_UNAVAILABLE':
        return 'The development environment is not available. Please try again later.';
      case 'COMMAND_EXECUTION_FAILED':
        return 'The requested operation could not be completed. Please try again.';
      case 'OPERATION_TIMEOUT':
        return 'The operation is taking longer than expected. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  private getDeveloperActions(error: BridgeError): Action[] {
    const actions: Action[] = [
      { label: 'Retry', action: 'retry' },
      { label: 'View Logs', action: 'view-logs' },
    ];

    if (error.recoverable) {
      actions.unshift({ label: 'Auto Retry', action: 'auto-retry' });
    }

    return actions;
  }

  private getEndUserActions(error: BridgeError): Action[] {
    if (error.recoverable) {
      return [{ label: 'Try Again', action: 'retry' }];
    }
    return [{ label: 'OK', action: 'dismiss' }];
  }
}
```

### 2. Contextual Error Messages

Provide context-specific error messages:

```typescript
class ContextualErrorHandler {
  handleCommandExecutionError(
    error: CommandExecutionError,
    context: { command: string; userIntent: string }
  ) {
    const contextualMessages = {
      'workbench.action.showCommands': 'Unable to open the command palette',
      'vscode.open': 'Unable to open the specified file',
      'kiro.generateCode': 'Code generation failed',
    };

    const baseMessage = contextualMessages[context.command] || 
                       'Command execution failed';

    return {
      message: `${baseMessage}. ${error.getSanitizedMessage()}`,
      suggestion: this.getSuggestion(context.command, error),
      canRetry: error.recoverable,
    };
  }

  private getSuggestion(command: string, error: CommandExecutionError): string {
    if (command === 'vscode.open' && error.stderr?.includes('ENOENT')) {
      return 'Please check that the file path is correct and the file exists.';
    }
    
    if (command === 'kiro.generateCode' && error.message.includes('timeout')) {
      return 'Code generation is taking longer than usual. Try with a simpler request.';
    }

    return 'Please try again or contact support if the problem persists.';
  }
}
```

### 3. Error Recovery Guidance

Provide actionable recovery steps:

```typescript
class ErrorRecoveryGuide {
  getRecoverySteps(error: BridgeError): RecoveryStep[] {
    switch (error.code) {
      case 'KIRO_UNAVAILABLE':
        return [
          {
            title: 'Check Kiro IDE',
            description: 'Ensure Kiro IDE is running and responsive',
            action: 'check-kiro-status',
            automated: true,
          },
          {
            title: 'Restart Extension',
            description: 'Restart the Kiro Communication Bridge extension',
            action: 'restart-extension',
            automated: true,
          },
          {
            title: 'Restart VS Code',
            description: 'Close and reopen VS Code',
            action: 'manual-restart',
            automated: false,
          },
        ];

      case 'VALIDATION_FAILED':
        return [
          {
            title: 'Check Input',
            description: 'Verify all required fields are filled correctly',
            action: 'validate-input',
            automated: false,
          },
        ];

      case 'OPERATION_TIMEOUT':
        return [
          {
            title: 'Retry with Longer Timeout',
            description: 'Increase the timeout and try again',
            action: 'retry-with-timeout',
            automated: true,
          },
          {
            title: 'Simplify Request',
            description: 'Try breaking the operation into smaller parts',
            action: 'simplify-request',
            automated: false,
          },
        ];

      default:
        return [
          {
            title: 'Retry Operation',
            description: 'Try the operation again',
            action: 'retry',
            automated: true,
          },
        ];
    }
  }
}

interface RecoveryStep {
  title: string;
  description: string;
  action: string;
  automated: boolean;
}
```

## Testing Error Handling

### Unit Tests

```typescript
describe('Error Handling', () => {
  let errorHandler: RetryHandler;
  let mockApiClient: jest.Mocked<KiroApiClient>;

  beforeEach(() => {
    mockApiClient = {
      executeCommand: jest.fn(),
    } as any;
    errorHandler = new RetryHandler();
  });

  it('should retry recoverable errors', async () => {
    const recoverableError = new Error('Network error');
    recoverableError.code = 'ECONNREFUSED';

    mockApiClient.executeCommand
      .mockRejectedValueOnce(recoverableError)
      .mockRejectedValueOnce(recoverableError)
      .mockResolvedValueOnce({ success: true, output: 'Success' });

    const result = await errorHandler.executeWithRetry(
      () => mockApiClient.executeCommand({ command: 'test' }),
      { maxRetries: 3, baseDelayMs: 10 }
    );

    expect(result.success).toBe(true);
    expect(mockApiClient.executeCommand).toHaveBeenCalledTimes(3);
  });

  it('should not retry non-recoverable errors', async () => {
    const nonRecoverableError = new ValidationError('Invalid command');

    mockApiClient.executeCommand.mockRejectedValue(nonRecoverableError);

    await expect(
      errorHandler.executeWithRetry(
        () => mockApiClient.executeCommand({ command: 'test' }),
        { maxRetries: 3 }
      )
    ).rejects.toThrow('Invalid command');

    expect(mockApiClient.executeCommand).toHaveBeenCalledTimes(1);
  });
});
```

### Integration Tests

```typescript
describe('Error Handling Integration', () => {
  it('should handle server unavailability gracefully', async () => {
    // Start with server down
    const client = new GracefulApiClient('http://localhost:9999');
    
    const status = await client.getStatusWithFallback();
    
    expect(status.status).toBe('unavailable');
    expect(status.availableCommands).toEqual([]);
  });

  it('should recover when server comes back online', async () => {
    const client = new GracefulApiClient();
    
    // Simulate server going down and coming back up
    await simulateServerDowntime(5000);
    
    const status = await client.getStatusWithFallback();
    expect(status.status).not.toBe('unavailable');
  });
});
```

## Monitoring and Alerting

### Error Metrics

Track error rates and patterns:

```typescript
class ErrorMetrics {
  private errorCounts = new Map<string, number>();
  private errorRates = new Map<string, number[]>();

  recordError(error: BridgeError) {
    const code = error.code;
    
    // Increment error count
    this.errorCounts.set(code, (this.errorCounts.get(code) || 0) + 1);
    
    // Track error rate (errors per minute)
    const now = Date.now();
    const rates = this.errorRates.get(code) || [];
    rates.push(now);
    
    // Keep only last minute of data
    const oneMinuteAgo = now - 60000;
    this.errorRates.set(code, rates.filter(time => time > oneMinuteAgo));
  }

  getErrorRate(errorCode: string): number {
    const rates = this.errorRates.get(errorCode) || [];
    return rates.length; // Errors per minute
  }

  getTopErrors(limit: number = 5): Array<{ code: string; count: number }> {
    return Array.from(this.errorCounts.entries())
      .map(([code, count]) => ({ code, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, limit);
  }

  shouldAlert(errorCode: string): boolean {
    const rate = this.getErrorRate(errorCode);
    const thresholds = {
      'KIRO_UNAVAILABLE': 5,
      'OPERATION_TIMEOUT': 10,
      'COMMAND_EXECUTION_FAILED': 15,
    };
    
    return rate > (thresholds[errorCode] || 20);
  }
}
```

## Best Practices Summary

### 1. Error Classification
- **Categorize errors** by type and recoverability
- **Use specific error codes** for programmatic handling
- **Provide context** in error messages

### 2. Recovery Strategies
- **Implement exponential backoff** for transient failures
- **Use circuit breakers** to prevent cascading failures
- **Provide graceful degradation** when services are unavailable

### 3. User Experience
- **Show appropriate error details** based on user type
- **Provide actionable recovery steps** when possible
- **Use progressive disclosure** for complex errors

### 4. Monitoring
- **Track error rates and patterns** for system health
- **Set up alerts** for critical error conditions
- **Log errors with sufficient context** for debugging

### 5. Testing
- **Test error scenarios** in unit and integration tests
- **Simulate network failures** and service unavailability
- **Verify error recovery mechanisms** work correctly

## Next Steps

- **[Polling Strategies](/docs/guides/polling-strategies)** - Handle real-time monitoring errors
- **[Troubleshooting](/docs/guides/troubleshooting)** - Common issues and solutions
- **[API Reference](/docs/api/overview)** - Complete error code reference
- **[Flutter Integration](/docs/guides/flutter-setup)** - Implement error handling in Flutter