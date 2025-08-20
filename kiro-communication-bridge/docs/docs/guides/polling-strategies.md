---
sidebar_position: 4
---

# Polling Strategies

Learn effective strategies for monitoring Kiro IDE status and command execution progress through polling. Since the Kiro Communication Bridge API doesn't provide WebSocket connections, polling is the primary method for real-time updates.

## Overview

Polling involves making periodic HTTP requests to check for status changes. This guide covers:

- **Status Monitoring**: Track Kiro availability and current operations
- **Command Progress**: Monitor long-running command execution
- **Efficient Polling**: Minimize resource usage and API load
- **Error Handling**: Handle network issues and service unavailability
- **Adaptive Strategies**: Adjust polling based on system state

## Basic Polling Patterns

### Simple Interval Polling

The most straightforward approach uses fixed intervals:

```typescript
class SimplePoller {
  private intervalId?: NodeJS.Timeout;
  private readonly apiClient: KiroApiClient;

  constructor(apiClient: KiroApiClient) {
    this.apiClient = apiClient;
  }

  startPolling(intervalMs: number = 5000) {
    this.stopPolling();
    
    this.intervalId = setInterval(async () => {
      try {
        const status = await this.apiClient.getStatus();
        this.handleStatusUpdate(status);
      } catch (error) {
        this.handleError(error);
      }
    }, intervalMs);
  }

  stopPolling() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = undefined;
    }
  }

  private handleStatusUpdate(status: KiroStatusResponse) {
    console.log(`Kiro status: ${status.status}`);
    if (status.currentCommand) {
      console.log(`Current command: ${status.currentCommand}`);
    }
  }

  private handleError(error: any) {
    console.error('Polling error:', error);
  }
}

// Usage
const poller = new SimplePoller(apiClient);
poller.startPolling(5000); // Poll every 5 seconds
```

### Adaptive Interval Polling

Adjust polling frequency based on system state:

```typescript
class AdaptivePoller {
  private intervalId?: NodeJS.Timeout;
  private currentInterval: number = 5000;
  private readonly apiClient: KiroApiClient;

  // Different intervals for different states
  private readonly intervals = {
    ready: 10000,      // 10 seconds when ready
    busy: 2000,        // 2 seconds when busy
    unavailable: 30000, // 30 seconds when unavailable
    error: 15000       // 15 seconds after errors
  };

  constructor(apiClient: KiroApiClient) {
    this.apiClient = apiClient;
  }

  startPolling() {
    this.poll();
  }

  private async poll() {
    try {
      const status = await this.apiClient.getStatus();
      this.handleStatusUpdate(status);
      
      // Adjust interval based on status
      this.currentInterval = this.getIntervalForStatus(status.status);
      
    } catch (error) {
      this.handleError(error);
      this.currentInterval = this.intervals.error;
    }

    // Schedule next poll
    this.intervalId = setTimeout(() => this.poll(), this.currentInterval);
  }

  private getIntervalForStatus(status: string): number {
    switch (status) {
      case 'ready': return this.intervals.ready;
      case 'busy': return this.intervals.busy;
      case 'unavailable': return this.intervals.unavailable;
      default: return this.intervals.ready;
    }
  }

  stopPolling() {
    if (this.intervalId) {
      clearTimeout(this.intervalId);
      this.intervalId = undefined;
    }
  }
}
```## A
dvanced Polling Strategies

### Exponential Backoff

Implement exponential backoff for error recovery:

```typescript
class ExponentialBackoffPoller {
  private timeoutId?: NodeJS.Timeout;
  private consecutiveErrors: number = 0;
  private readonly maxBackoffMs: number = 60000; // 1 minute max
  private readonly baseIntervalMs: number = 5000;

  async poll() {
    try {
      const status = await this.apiClient.getStatus();
      this.handleSuccess(status);
      this.consecutiveErrors = 0; // Reset error count
      
    } catch (error) {
      this.consecutiveErrors++;
      this.handleError(error);
    }

    // Calculate next poll interval
    const nextInterval = this.calculateNextInterval();
    this.timeoutId = setTimeout(() => this.poll(), nextInterval);
  }

  private calculateNextInterval(): number {
    if (this.consecutiveErrors === 0) {
      return this.baseIntervalMs;
    }

    // Exponential backoff: 2^errors * baseInterval
    const backoffMs = Math.min(
      this.baseIntervalMs * Math.pow(2, this.consecutiveErrors - 1),
      this.maxBackoffMs
    );

    return backoffMs;
  }

  private handleSuccess(status: KiroStatusResponse) {
    console.log(`Status: ${status.status} (errors reset)`);
  }

  private handleError(error: any) {
    console.error(`Polling error ${this.consecutiveErrors}:`, error);
    console.log(`Next poll in ${this.calculateNextInterval()}ms`);
  }
}
```

### Smart Polling with Change Detection

Only process updates when status actually changes:

```typescript
class ChangeDetectionPoller {
  private lastStatus?: KiroStatusResponse;
  private lastStatusHash?: string;

  async poll() {
    try {
      const status = await this.apiClient.getStatus();
      const statusHash = this.hashStatus(status);

      if (statusHash !== this.lastStatusHash) {
        this.handleStatusChange(this.lastStatus, status);
        this.lastStatus = status;
        this.lastStatusHash = statusHash;
      }

    } catch (error) {
      this.handleError(error);
    }
  }

  private hashStatus(status: KiroStatusResponse): string {
    // Create a hash of relevant status fields
    return JSON.stringify({
      status: status.status,
      currentCommand: status.currentCommand,
      commandCount: status.availableCommands.length
    });
  }

  private handleStatusChange(
    oldStatus: KiroStatusResponse | undefined,
    newStatus: KiroStatusResponse
  ) {
    console.log(`Status changed: ${oldStatus?.status} → ${newStatus.status}`);
    
    if (oldStatus?.currentCommand !== newStatus.currentCommand) {
      if (newStatus.currentCommand) {
        console.log(`Command started: ${newStatus.currentCommand}`);
      } else if (oldStatus?.currentCommand) {
        console.log(`Command completed: ${oldStatus.currentCommand}`);
      }
    }
  }
}
```

## Command Execution Monitoring

### Long-Running Command Tracking

Monitor commands that take time to complete:

```typescript
class CommandExecutionMonitor {
  private readonly activeCommands = new Map<string, CommandExecution>();
  private monitoringInterval?: NodeJS.Timeout;

  async executeAndMonitor(
    command: string,
    args: string[] = [],
    options: { timeout?: number; pollInterval?: number } = {}
  ): Promise<ExecuteCommandResponse> {
    const { timeout = 300000, pollInterval = 2000 } = options;
    
    // Start command execution
    const response = await this.apiClient.executeCommand({ command, args });
    
    if (!response.success) {
      return response;
    }

    // If command is still running, monitor it
    if (this.isLongRunningCommand(command)) {
      return this.monitorCommandExecution(command, timeout, pollInterval);
    }

    return response;
  }

  private async monitorCommandExecution(
    command: string,
    timeoutMs: number,
    pollIntervalMs: number
  ): Promise<ExecuteCommandResponse> {
    const startTime = Date.now();
    
    return new Promise((resolve, reject) => {
      const monitor = setInterval(async () => {
        try {
          const status = await this.apiClient.getStatus();
          
          // Check if command is still running
          if (status.currentCommand !== command) {
            clearInterval(monitor);
            resolve({
              success: true,
              output: 'Command completed',
              executionTimeMs: Date.now() - startTime
            });
            return;
          }

          // Check timeout
          if (Date.now() - startTime > timeoutMs) {
            clearInterval(monitor);
            reject(new Error(`Command '${command}' timed out after ${timeoutMs}ms`));
            return;
          }

          // Log progress
          console.log(`Command '${command}' still running...`);

        } catch (error) {
          clearInterval(monitor);
          reject(error);
        }
      }, pollIntervalMs);
    });
  }

  private isLongRunningCommand(command: string): boolean {
    const longRunningCommands = [
      'kiro.generateCode',
      'kiro.createProject',
      'workbench.action.files.save',
      // Add other long-running commands
    ];
    
    return longRunningCommands.includes(command);
  }
}
```## 
Flutter Implementation

### Dart Polling Service

```dart
import 'dart:async';
import 'dart:math';

class KiroPollingService {
  final KiroApiService _apiService;
  Timer? _timer;
  KiroStatusResponse? _lastStatus;
  int _consecutiveErrors = 0;
  
  // Polling intervals in milliseconds
  static const int _readyInterval = 10000;    // 10 seconds
  static const int _busyInterval = 2000;      // 2 seconds
  static const int _unavailableInterval = 30000; // 30 seconds
  static const int _baseInterval = 5000;      // 5 seconds
  static const int _maxBackoff = 60000;       // 1 minute

  final StreamController<KiroStatusResponse> _statusController = 
      StreamController<KiroStatusResponse>.broadcast();

  KiroPollingService(this._apiService);

  Stream<KiroStatusResponse> get statusStream => _statusController.stream;
  KiroStatusResponse? get lastStatus => _lastStatus;

  void startPolling() {
    stopPolling();
    _poll();
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      final status = await _apiService.getStatus();
      _handleStatusUpdate(status);
      _consecutiveErrors = 0;
      
    } catch (e) {
      _consecutiveErrors++;
      _handleError(e);
    }

    // Schedule next poll with adaptive interval
    final nextInterval = _calculateNextInterval();
    _timer = Timer(Duration(milliseconds: nextInterval), _poll);
  }

  void _handleStatusUpdate(KiroStatusResponse status) {
    final hasChanged = _hasStatusChanged(_lastStatus, status);
    _lastStatus = status;

    if (hasChanged) {
      _statusController.add(status);
    }
  }

  void _handleError(dynamic error) {
    print('Polling error (attempt $_consecutiveErrors): $error');
  }

  int _calculateNextInterval() {
    // If we have errors, use exponential backoff
    if (_consecutiveErrors > 0) {
      final backoff = min(
        _baseInterval * pow(2, _consecutiveErrors - 1).toInt(),
        _maxBackoff
      );
      return backoff;
    }

    // Adaptive interval based on status
    if (_lastStatus == null) return _baseInterval;

    switch (_lastStatus!.status) {
      case KiroStatus.ready:
        return _readyInterval;
      case KiroStatus.busy:
        return _busyInterval;
      case KiroStatus.unavailable:
        return _unavailableInterval;
    }
  }

  bool _hasStatusChanged(
    KiroStatusResponse? oldStatus,
    KiroStatusResponse newStatus
  ) {
    if (oldStatus == null) return true;

    return oldStatus.status != newStatus.status ||
           oldStatus.currentCommand != newStatus.currentCommand ||
           oldStatus.availableCommands.length != newStatus.availableCommands.length;
  }

  void dispose() {
    stopPolling();
    _statusController.close();
  }
}
```

### Flutter Provider with Polling

```dart
class KiroProvider extends ChangeNotifier {
  final KiroPollingService _pollingService;
  StreamSubscription<KiroStatusResponse>? _statusSubscription;
  
  KiroStatusResponse? _status;
  bool _isPolling = false;

  KiroProvider(KiroApiService apiService) 
      : _pollingService = KiroPollingService(apiService);

  KiroStatusResponse? get status => _status;
  bool get isPolling => _isPolling;
  bool get isHealthy => _status?.status != KiroStatus.unavailable;

  void startPolling() {
    if (_isPolling) return;

    _isPolling = true;
    _statusSubscription = _pollingService.statusStream.listen(
      _onStatusUpdate,
      onError: _onPollingError,
    );
    
    _pollingService.startPolling();
    notifyListeners();
  }

  void stopPolling() {
    if (!_isPolling) return;

    _isPolling = false;
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _pollingService.stopPolling();
    notifyListeners();
  }

  void _onStatusUpdate(KiroStatusResponse status) {
    _status = status;
    notifyListeners();
  }

  void _onPollingError(dynamic error) {
    print('Polling error in provider: $error');
    // Could set error state here
  }

  @override
  void dispose() {
    stopPolling();
    _pollingService.dispose();
    super.dispose();
  }
}
```

### Flutter UI with Polling Controls

```dart
class PollingControlWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<KiroProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time Monitoring',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: provider.isPolling 
                          ? null 
                          : () => provider.startPolling(),
                      child: Text('Start Monitoring'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: provider.isPolling 
                          ? () => provider.stopPolling()
                          : null,
                      child: Text('Stop Monitoring'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildStatusIndicator(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(KiroProvider provider) {
    if (!provider.isPolling) {
      return Text('Monitoring stopped');
    }

    if (provider.status == null) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Connecting...'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status: ${provider.status!.status.name}'),
        if (provider.status!.currentCommand != null)
          Text('Current: ${provider.status!.currentCommand}'),
        Text('Last update: ${_formatTime(provider.status!.timestamp)}'),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}
```## 
Performance Optimization

### Connection Pooling

Reuse HTTP connections for better performance:

```typescript
class OptimizedApiClient {
  private readonly httpAgent: http.Agent;

  constructor() {
    // Configure connection pooling
    this.httpAgent = new http.Agent({
      keepAlive: true,
      maxSockets: 5,
      maxFreeSockets: 2,
      timeout: 30000,
    });
  }

  async makeRequest(url: string, options: RequestOptions = {}) {
    return fetch(url, {
      ...options,
      agent: this.httpAgent,
    });
  }
}
```

### Request Deduplication

Prevent duplicate requests when polling frequently:

```typescript
class DeduplicatedPoller {
  private pendingRequest?: Promise<KiroStatusResponse>;

  async getStatus(): Promise<KiroStatusResponse> {
    // If request is already in flight, return the same promise
    if (this.pendingRequest) {
      return this.pendingRequest;
    }

    // Create new request
    this.pendingRequest = this.apiClient.getStatus();

    try {
      const result = await this.pendingRequest;
      return result;
    } finally {
      // Clear pending request
      this.pendingRequest = undefined;
    }
  }
}
```

### Conditional Requests

Use ETags or timestamps to avoid unnecessary data transfer:

```typescript
class ConditionalPoller {
  private lastETag?: string;
  private lastModified?: string;

  async getStatus(): Promise<KiroStatusResponse | null> {
    const headers: Record<string, string> = {};

    if (this.lastETag) {
      headers['If-None-Match'] = this.lastETag;
    }

    if (this.lastModified) {
      headers['If-Modified-Since'] = this.lastModified;
    }

    const response = await fetch('/api/kiro/status', { headers });

    if (response.status === 304) {
      // Not modified, return null to indicate no change
      return null;
    }

    // Update cache headers
    this.lastETag = response.headers.get('ETag') || undefined;
    this.lastModified = response.headers.get('Last-Modified') || undefined;

    return await response.json();
  }
}
```

## Error Handling Strategies

### Circuit Breaker Pattern

Prevent cascading failures with circuit breaker:

```typescript
enum CircuitState {
  CLOSED,   // Normal operation
  OPEN,     // Failing, stop requests
  HALF_OPEN // Testing if service recovered
}

class CircuitBreakerPoller {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount: number = 0;
  private lastFailureTime: number = 0;
  private readonly failureThreshold: number = 5;
  private readonly recoveryTimeoutMs: number = 60000; // 1 minute

  async poll(): Promise<KiroStatusResponse | null> {
    if (this.state === CircuitState.OPEN) {
      if (Date.now() - this.lastFailureTime > this.recoveryTimeoutMs) {
        this.state = CircuitState.HALF_OPEN;
        console.log('Circuit breaker: Attempting recovery');
      } else {
        console.log('Circuit breaker: Open, skipping request');
        return null;
      }
    }

    try {
      const status = await this.apiClient.getStatus();
      this.onSuccess();
      return status;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    this.failureCount = 0;
    this.state = CircuitState.CLOSED;
  }

  private onFailure() {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    if (this.failureCount >= this.failureThreshold) {
      this.state = CircuitState.OPEN;
      console.log('Circuit breaker: Opened due to failures');
    }
  }
}
```

### Graceful Degradation

Handle service unavailability gracefully:

```typescript
class GracefulPoller {
  private fallbackData?: KiroStatusResponse;

  async poll(): Promise<KiroStatusResponse> {
    try {
      const status = await this.apiClient.getStatus();
      this.fallbackData = status; // Cache successful response
      return status;
    } catch (error) {
      console.warn('Polling failed, using fallback data:', error);
      
      if (this.fallbackData) {
        // Return cached data with updated timestamp
        return {
          ...this.fallbackData,
          status: 'unavailable' as const,
          timestamp: new Date().toISOString(),
        };
      }

      // Return minimal fallback status
      return {
        status: 'unavailable' as const,
        availableCommands: [],
        timestamp: new Date().toISOString(),
      };
    }
  }
}
```

## Best Practices

### 1. Choose Appropriate Intervals

| Scenario | Recommended Interval | Reason |
|----------|---------------------|---------|
| Kiro Ready | 10-30 seconds | Infrequent changes expected |
| Kiro Busy | 1-3 seconds | Monitor command progress |
| Kiro Unavailable | 30-60 seconds | Avoid overwhelming unavailable service |
| After Errors | Exponential backoff | Prevent cascading failures |

### 2. Implement Proper Error Handling

```typescript
class RobustPoller {
  async poll() {
    try {
      return await this.apiClient.getStatus();
    } catch (error) {
      if (this.isNetworkError(error)) {
        // Network issues - retry with backoff
        throw new RetryableError(error);
      } else if (this.isAuthError(error)) {
        // Auth issues - stop polling
        throw new FatalError(error);
      } else {
        // Unknown error - log and retry
        console.error('Unknown polling error:', error);
        throw new RetryableError(error);
      }
    }
  }

  private isNetworkError(error: any): boolean {
    return error.code === 'ECONNREFUSED' || 
           error.code === 'ETIMEDOUT' ||
           error.message.includes('fetch failed');
  }

  private isAuthError(error: any): boolean {
    return error.status === 401 || error.status === 403;
  }
}
```

### 3. Resource Management

```typescript
class ResourceAwarePoller {
  private isDocumentVisible: boolean = true;
  private isOnline: boolean = navigator.onLine;

  constructor() {
    // Pause polling when document is hidden
    document.addEventListener('visibilitychange', () => {
      this.isDocumentVisible = !document.hidden;
      this.adjustPolling();
    });

    // Pause polling when offline
    window.addEventListener('online', () => {
      this.isOnline = true;
      this.adjustPolling();
    });

    window.addEventListener('offline', () => {
      this.isOnline = false;
      this.adjustPolling();
    });
  }

  private adjustPolling() {
    if (!this.isDocumentVisible || !this.isOnline) {
      this.pausePolling();
    } else {
      this.resumePolling();
    }
  }
}
```

### 4. Memory Management

```typescript
class MemoryEfficientPoller {
  private readonly maxHistorySize = 100;
  private statusHistory: KiroStatusResponse[] = [];

  addToHistory(status: KiroStatusResponse) {
    this.statusHistory.unshift(status);
    
    // Limit history size to prevent memory leaks
    if (this.statusHistory.length > this.maxHistorySize) {
      this.statusHistory = this.statusHistory.slice(0, this.maxHistorySize);
    }
  }

  cleanup() {
    this.statusHistory = [];
  }
}
```

## Testing Polling Logic

### Unit Tests

```typescript
describe('AdaptivePoller', () => {
  let poller: AdaptivePoller;
  let mockApiClient: jest.Mocked<KiroApiClient>;

  beforeEach(() => {
    mockApiClient = {
      getStatus: jest.fn(),
    } as any;
    poller = new AdaptivePoller(mockApiClient);
  });

  it('should use shorter interval when Kiro is busy', async () => {
    mockApiClient.getStatus.mockResolvedValue({
      status: 'busy',
      currentCommand: 'test.command',
      availableCommands: [],
      timestamp: new Date().toISOString(),
    });

    const interval = poller.getIntervalForStatus('busy');
    expect(interval).toBe(2000); // 2 seconds for busy state
  });

  it('should implement exponential backoff on errors', async () => {
    mockApiClient.getStatus.mockRejectedValue(new Error('Network error'));

    const intervals = [];
    for (let i = 0; i < 5; i++) {
      try {
        await poller.poll();
      } catch (error) {
        intervals.push(poller.calculateNextInterval());
      }
    }

    // Verify exponential backoff
    expect(intervals[0]).toBe(5000);   // Base interval
    expect(intervals[1]).toBe(10000);  // 2x base
    expect(intervals[2]).toBe(20000);  // 4x base
    expect(intervals[3]).toBe(40000);  // 8x base
  });
});
```

### Integration Tests

```typescript
describe('Polling Integration', () => {
  it('should handle server restart gracefully', async () => {
    const poller = new AdaptivePoller(realApiClient);
    const statusUpdates: KiroStatusResponse[] = [];

    poller.onStatusUpdate = (status) => statusUpdates.push(status);
    poller.startPolling();

    // Simulate server restart
    await simulateServerRestart();

    // Wait for recovery
    await waitFor(() => {
      const lastStatus = statusUpdates[statusUpdates.length - 1];
      return lastStatus?.status !== 'unavailable';
    });

    expect(statusUpdates).toContainEqual(
      expect.objectContaining({ status: 'unavailable' })
    );
    expect(statusUpdates).toContainEqual(
      expect.objectContaining({ status: 'ready' })
    );
  });
});
```

## Troubleshooting

### Common Issues

**High CPU Usage**
- Reduce polling frequency
- Implement request deduplication
- Use conditional requests

**Memory Leaks**
- Limit history size
- Clear timers on cleanup
- Remove event listeners

**Network Congestion**
- Implement exponential backoff
- Use connection pooling
- Add jitter to prevent thundering herd

**Inconsistent Updates**
- Implement change detection
- Add sequence numbers
- Use proper error handling

## Next Steps

- **[Error Handling Guide](/docs/guides/error-handling)** - Robust error handling patterns
- **[Flutter Integration](/docs/guides/flutter-setup)** - Implement polling in Flutter
- **[API Reference](/docs/api/overview)** - Complete API documentation
- **[Troubleshooting](/docs/guides/troubleshooting)** - Common issues and solutions