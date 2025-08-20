---
sidebar_position: 3
---

# Integration Patterns

This guide covers common patterns and best practices for integrating with the Kiro Communication Bridge API. These patterns help you build robust, efficient, and maintainable integrations.

## Basic Integration Patterns

### 1. Simple Request-Response Pattern

The most basic integration pattern for one-off command execution.

```typescript
class SimpleKiroClient {
  private readonly baseUrl: string;
  private readonly apiKey?: string;

  constructor(baseUrl: string = 'http://localhost:3001', apiKey?: string) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }

  async executeCommand(command: string, args?: string[]): Promise<any> {
    const response = await fetch(`${this.baseUrl}/api/kiro/execute`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` })
      },
      body: JSON.stringify({ command, args })
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  }
}

// Usage
const client = new SimpleKiroClient();
const result = await client.executeCommand('workbench.action.showCommands');
```

**When to Use**:
- Simple, infrequent operations
- Prototype development
- One-off scripts or tools

**Pros**:
- Simple to implement
- Low overhead
- Easy to understand

**Cons**:
- No error recovery
- No connection reuse
- No status monitoring

### 2. Connection Pool Pattern

Reuse HTTP connections for better performance with multiple requests.

```typescript
import { Agent } from 'http';

class PooledKiroClient {
  private readonly agent: Agent;
  private readonly baseUrl: string;
  private readonly apiKey?: string;

  constructor(baseUrl: string = 'http://localhost:3001', apiKey?: string) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.agent = new Agent({
      keepAlive: true,
      maxSockets: 5,
      maxFreeSockets: 2,
      timeout: 30000
    });
  }

  async executeCommand(command: string, args?: string[]): Promise<any> {
    const response = await fetch(`${this.baseUrl}/api/kiro/execute`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` })
      },
      body: JSON.stringify({ command, args }),
      // @ts-ignore - Node.js specific
      agent: this.agent
    });

    return this.handleResponse(response);
  }

  private async handleResponse(response: Response): Promise<any> {
    const data = await response.json();
    
    if (!response.ok) {
      throw new KiroApiError(data.message, response.status, data.code);
    }
    
    return data;
  }

  dispose(): void {
    this.agent.destroy();
  }
}
```

**When to Use**:
- Multiple requests in sequence
- Long-running applications
- Performance-critical scenarios

**Benefits**:
- Reduced connection overhead
- Better resource utilization
- Improved throughput

## Resilient Integration Patterns

### 3. Retry with Exponential Backoff

Handle transient failures gracefully with intelligent retry logic.

```typescript
interface RetryOptions {
  maxRetries: number;
  baseDelayMs: number;
  maxDelayMs: number;
  backoffMultiplier: number;
  retryableErrors: string[];
}

class ResilientKiroClient {
  private readonly defaultRetryOptions: RetryOptions = {
    maxRetries: 3,
    baseDelayMs: 1000,
    maxDelayMs: 30000,
    backoffMultiplier: 2,
    retryableErrors: ['KIRO_UNAVAILABLE', 'OPERATION_TIMEOUT', 'NETWORK_ERROR']
  };

  async executeCommandWithRetry(
    command: string, 
    args?: string[], 
    options: Partial<RetryOptions> = {}
  ): Promise<any> {
    const retryOptions = { ...this.defaultRetryOptions, ...options };
    let lastError: Error;

    for (let attempt = 1; attempt <= retryOptions.maxRetries + 1; attempt++) {
      try {
        return await this.executeCommand(command, args);
      } catch (error) {
        lastError = error as Error;
        
        // Don't retry on final attempt
        if (attempt > retryOptions.maxRetries) {
          break;
        }

        // Check if error is retryable
        if (!this.isRetryableError(error, retryOptions.retryableErrors)) {
          throw error;
        }

        // Calculate delay with exponential backoff
        const delay = Math.min(
          retryOptions.baseDelayMs * Math.pow(retryOptions.backoffMultiplier, attempt - 1),
          retryOptions.maxDelayMs
        );

        console.log(`Attempt ${attempt} failed, retrying in ${delay}ms...`);
        await this.sleep(delay);
      }
    }

    throw lastError!;
  }

  private isRetryableError(error: any, retryableErrors: string[]): boolean {
    if (error.code && retryableErrors.includes(error.code)) {
      return true;
    }
    
    // Check for network errors
    if (error.message?.includes('ECONNREFUSED') || 
        error.message?.includes('ETIMEDOUT')) {
      return true;
    }
    
    return false;
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

**When to Use**:
- Production applications
- Unreliable network conditions
- Critical operations that must succeed

**Configuration Guidelines**:
- Start with 3-5 retries maximum
- Use exponential backoff (2x multiplier)
- Cap maximum delay at 30-60 seconds
- Only retry transient errors

### 4. Circuit Breaker Pattern

Prevent cascading failures by temporarily stopping requests to failing services.

```typescript
enum CircuitState {
  CLOSED = 'CLOSED',     // Normal operation
  OPEN = 'OPEN',         // Failing, reject requests
  HALF_OPEN = 'HALF_OPEN' // Testing if service recovered
}

interface CircuitBreakerOptions {
  failureThreshold: number;
  recoveryTimeoutMs: number;
  monitoringPeriodMs: number;
}

class CircuitBreakerKiroClient {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount: number = 0;
  private lastFailureTime: number = 0;
  private nextAttemptTime: number = 0;

  constructor(
    private readonly client: SimpleKiroClient,
    private readonly options: CircuitBreakerOptions = {
      failureThreshold: 5,
      recoveryTimeoutMs: 60000,
      monitoringPeriodMs: 30000
    }
  ) {}

  async executeCommand(command: string, args?: string[]): Promise<any> {
    if (this.state === CircuitState.OPEN) {
      if (Date.now() < this.nextAttemptTime) {
        throw new Error('Circuit breaker is OPEN - service unavailable');
      }
      
      // Transition to half-open to test service
      this.state = CircuitState.HALF_OPEN;
    }

    try {
      const result = await this.client.executeCommand(command, args);
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess(): void {
    this.failureCount = 0;
    this.state = CircuitState.CLOSED;
  }

  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    if (this.failureCount >= this.options.failureThreshold) {
      this.state = CircuitState.OPEN;
      this.nextAttemptTime = Date.now() + this.options.recoveryTimeoutMs;
    }
  }

  getState(): CircuitState {
    return this.state;
  }

  getMetrics() {
    return {
      state: this.state,
      failureCount: this.failureCount,
      lastFailureTime: this.lastFailureTime,
      nextAttemptTime: this.nextAttemptTime
    };
  }
}
```

**When to Use**:
- High-availability applications
- Microservice architectures
- Systems with multiple dependencies

**Benefits**:
- Prevents cascade failures
- Faster failure detection
- Automatic recovery testing
- System stability improvement

## Monitoring and Observability Patterns

### 5. Health Check Pattern

Continuously monitor service health and availability.

```typescript
interface HealthStatus {
  healthy: boolean;
  lastCheck: Date;
  responseTime: number;
  error?: string;
}

class HealthMonitoringClient {
  private healthStatus: HealthStatus = {
    healthy: false,
    lastCheck: new Date(),
    responseTime: 0
  };

  private healthCheckInterval?: NodeJS.Timeout;

  constructor(
    private readonly client: SimpleKiroClient,
    private readonly checkIntervalMs: number = 30000
  ) {}

  startHealthMonitoring(): void {
    this.healthCheckInterval = setInterval(
      () => this.performHealthCheck(),
      this.checkIntervalMs
    );
    
    // Perform initial check
    this.performHealthCheck();
  }

  stopHealthMonitoring(): void {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
      this.healthCheckInterval = undefined;
    }
  }

  private async performHealthCheck(): Promise<void> {
    const startTime = Date.now();
    
    try {
      await fetch('http://localhost:3001/health', {
        method: 'GET',
        timeout: 5000
      });
      
      this.healthStatus = {
        healthy: true,
        lastCheck: new Date(),
        responseTime: Date.now() - startTime
      };
    } catch (error) {
      this.healthStatus = {
        healthy: false,
        lastCheck: new Date(),
        responseTime: Date.now() - startTime,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  getHealthStatus(): HealthStatus {
    return { ...this.healthStatus };
  }

  isHealthy(): boolean {
    return this.healthStatus.healthy;
  }

  async waitForHealthy(timeoutMs: number = 30000): Promise<void> {
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeoutMs) {
      if (this.isHealthy()) {
        return;
      }
      
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    throw new Error('Service did not become healthy within timeout');
  }
}
```

### 6. Metrics Collection Pattern

Collect and expose operational metrics for monitoring.

```typescript
interface Metrics {
  requestCount: number;
  errorCount: number;
  averageResponseTime: number;
  lastRequestTime: Date | null;
  errorRate: number;
}

class MetricsCollectingClient {
  private metrics: Metrics = {
    requestCount: 0,
    errorCount: 0,
    averageResponseTime: 0,
    lastRequestTime: null,
    errorRate: 0
  };

  private responseTimes: number[] = [];
  private readonly maxResponseTimeHistory = 100;

  constructor(private readonly client: SimpleKiroClient) {}

  async executeCommand(command: string, args?: string[]): Promise<any> {
    const startTime = Date.now();
    this.metrics.requestCount++;
    this.metrics.lastRequestTime = new Date();

    try {
      const result = await this.client.executeCommand(command, args);
      this.recordSuccess(Date.now() - startTime);
      return result;
    } catch (error) {
      this.recordError(Date.now() - startTime);
      throw error;
    }
  }

  private recordSuccess(responseTime: number): void {
    this.updateResponseTime(responseTime);
    this.updateErrorRate();
  }

  private recordError(responseTime: number): void {
    this.metrics.errorCount++;
    this.updateResponseTime(responseTime);
    this.updateErrorRate();
  }

  private updateResponseTime(responseTime: number): void {
    this.responseTimes.push(responseTime);
    
    if (this.responseTimes.length > this.maxResponseTimeHistory) {
      this.responseTimes.shift();
    }
    
    this.metrics.averageResponseTime = 
      this.responseTimes.reduce((sum, time) => sum + time, 0) / 
      this.responseTimes.length;
  }

  private updateErrorRate(): void {
    this.metrics.errorRate = this.metrics.requestCount > 0 
      ? this.metrics.errorCount / this.metrics.requestCount 
      : 0;
  }

  getMetrics(): Metrics {
    return { ...this.metrics };
  }

  resetMetrics(): void {
    this.metrics = {
      requestCount: 0,
      errorCount: 0,
      averageResponseTime: 0,
      lastRequestTime: null,
      errorRate: 0
    };
    this.responseTimes = [];
  }
}
```

## Advanced Integration Patterns

### 7. Command Queue Pattern

Queue commands for batch processing or rate limiting.

```typescript
interface QueuedCommand {
  id: string;
  command: string;
  args?: string[];
  priority: number;
  timestamp: Date;
  resolve: (value: any) => void;
  reject: (error: Error) => void;
}

class QueuedKiroClient {
  private queue: QueuedCommand[] = [];
  private processing = false;
  private readonly maxConcurrent: number;
  private activeCommands = 0;

  constructor(
    private readonly client: SimpleKiroClient,
    maxConcurrent: number = 3
  ) {
    this.maxConcurrent = maxConcurrent;
  }

  async executeCommand(
    command: string, 
    args?: string[], 
    priority: number = 0
  ): Promise<any> {
    return new Promise((resolve, reject) => {
      const queuedCommand: QueuedCommand = {
        id: this.generateId(),
        command,
        args,
        priority,
        timestamp: new Date(),
        resolve,
        reject
      };

      this.queue.push(queuedCommand);
      this.queue.sort((a, b) => b.priority - a.priority); // Higher priority first
      
      this.processQueue();
    });
  }

  private async processQueue(): Promise<void> {
    if (this.processing || this.activeCommands >= this.maxConcurrent) {
      return;
    }

    const command = this.queue.shift();
    if (!command) {
      return;
    }

    this.processing = true;
    this.activeCommands++;

    try {
      const result = await this.client.executeCommand(command.command, command.args);
      command.resolve(result);
    } catch (error) {
      command.reject(error as Error);
    } finally {
      this.activeCommands--;
      this.processing = false;
      
      // Process next command if available
      if (this.queue.length > 0 && this.activeCommands < this.maxConcurrent) {
        setImmediate(() => this.processQueue());
      }
    }
  }

  private generateId(): string {
    return Math.random().toString(36).substr(2, 9);
  }

  getQueueStatus() {
    return {
      queueLength: this.queue.length,
      activeCommands: this.activeCommands,
      processing: this.processing
    };
  }
}
```

### 8. Event-Driven Pattern

Use events for loose coupling and reactive programming.

```typescript
import { EventEmitter } from 'events';

interface KiroEvents {
  'command:start': (command: string, args?: string[]) => void;
  'command:success': (command: string, result: any, duration: number) => void;
  'command:error': (command: string, error: Error, duration: number) => void;
  'status:changed': (status: 'available' | 'unavailable') => void;
  'health:check': (healthy: boolean, responseTime: number) => void;
}

class EventDrivenKiroClient extends EventEmitter {
  private lastStatus: 'available' | 'unavailable' = 'unavailable';

  constructor(private readonly client: SimpleKiroClient) {
    super();
    this.startStatusMonitoring();
  }

  async executeCommand(command: string, args?: string[]): Promise<any> {
    const startTime = Date.now();
    
    this.emit('command:start', command, args);

    try {
      const result = await this.client.executeCommand(command, args);
      const duration = Date.now() - startTime;
      
      this.emit('command:success', command, result, duration);
      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      
      this.emit('command:error', command, error as Error, duration);
      throw error;
    }
  }

  private startStatusMonitoring(): void {
    setInterval(async () => {
      try {
        await fetch('http://localhost:3001/health');
        const newStatus = 'available';
        
        if (newStatus !== this.lastStatus) {
          this.lastStatus = newStatus;
          this.emit('status:changed', newStatus);
        }
      } catch (error) {
        const newStatus = 'unavailable';
        
        if (newStatus !== this.lastStatus) {
          this.lastStatus = newStatus;
          this.emit('status:changed', newStatus);
        }
      }
    }, 5000);
  }
}

// Usage with event handlers
const client = new EventDrivenKiroClient(new SimpleKiroClient());

client.on('command:start', (command) => {
  console.log(`Starting command: ${command}`);
});

client.on('command:success', (command, result, duration) => {
  console.log(`Command ${command} completed in ${duration}ms`);
});

client.on('command:error', (command, error, duration) => {
  console.error(`Command ${command} failed after ${duration}ms:`, error.message);
});

client.on('status:changed', (status) => {
  console.log(`Kiro status changed to: ${status}`);
});
```

## Flutter-Specific Patterns

### 9. Provider Pattern for State Management

```dart
class KiroProvider extends ChangeNotifier {
  final KiroApiClient _client;
  
  bool _isConnected = false;
  bool _isExecuting = false;
  String? _lastError;
  List<String> _availableCommands = [];

  KiroProvider(this._client);

  // Getters
  bool get isConnected => _isConnected;
  bool get isExecuting => _isExecuting;
  String? get lastError => _lastError;
  List<String> get availableCommands => List.unmodifiable(_availableCommands);

  Future<void> initialize() async {
    try {
      final status = await _client.getStatus();
      _isConnected = status.available;
      _availableCommands = status.availableCommands;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<ExecuteCommandResponse> executeCommand(String command, {List<String>? args}) async {
    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _client.executeCommand(
        ExecuteCommandRequest(command: command, args: args),
      );
      
      if (!response.success) {
        _lastError = response.error;
      }
      
      return response;
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }
}

// Usage in Flutter widget
class KiroControlWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<KiroProvider>(
      builder: (context, kiroProvider, child) {
        return Column(
          children: [
            if (kiroProvider.isConnected)
              Text('Connected to Kiro')
            else
              Text('Disconnected'),
            
            if (kiroProvider.isExecuting)
              CircularProgressIndicator(),
            
            if (kiroProvider.lastError != null)
              Text('Error: ${kiroProvider.lastError}'),
            
            ElevatedButton(
              onPressed: kiroProvider.isConnected && !kiroProvider.isExecuting
                  ? () => kiroProvider.executeCommand('workbench.action.showCommands')
                  : null,
              child: Text('Execute Command'),
            ),
          ],
        );
      },
    );
  }
}
```

### 10. Stream-Based Pattern for Real-Time Updates

```dart
class StreamingKiroClient {
  final KiroApiClient _client;
  final StreamController<KiroStatus> _statusController = StreamController.broadcast();
  final StreamController<CommandResult> _commandController = StreamController.broadcast();
  
  Timer? _statusTimer;

  StreamingKiroClient(this._client);

  Stream<KiroStatus> get statusStream => _statusController.stream;
  Stream<CommandResult> get commandStream => _commandController.stream;

  void startStatusMonitoring({Duration interval = const Duration(seconds: 5)}) {
    _statusTimer = Timer.periodic(interval, (_) async {
      try {
        final status = await _client.getStatus();
        _statusController.add(KiroStatus.fromResponse(status));
      } catch (e) {
        _statusController.add(KiroStatus.unavailable(e.toString()));
      }
    });
  }

  Future<void> executeCommand(String command, {List<String>? args}) async {
    try {
      _commandController.add(CommandResult.started(command));
      
      final response = await _client.executeCommand(
        ExecuteCommandRequest(command: command, args: args),
      );
      
      _commandController.add(CommandResult.completed(command, response));
    } catch (e) {
      _commandController.add(CommandResult.failed(command, e.toString()));
    }
  }

  void dispose() {
    _statusTimer?.cancel();
    _statusController.close();
    _commandController.close();
  }
}

// Usage with StreamBuilder
class StreamingKiroWidget extends StatefulWidget {
  @override
  _StreamingKiroWidgetState createState() => _StreamingKiroWidgetState();
}

class _StreamingKiroWidgetState extends State<StreamingKiroWidget> {
  late StreamingKiroClient _client;

  @override
  void initState() {
    super.initState();
    _client = StreamingKiroClient(KiroApiClient());
    _client.startStatusMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<KiroStatus>(
          stream: _client.statusStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();
            
            final status = snapshot.data!;
            return Text(status.isAvailable ? 'Connected' : 'Disconnected');
          },
        ),
        
        StreamBuilder<CommandResult>(
          stream: _client.commandStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox.shrink();
            
            final result = snapshot.data!;
            return Text('Last command: ${result.command} - ${result.status}');
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
}
```

## Best Practices Summary

### Error Handling
- Always implement retry logic for transient failures
- Use circuit breakers for high-availability scenarios
- Distinguish between retryable and non-retryable errors
- Provide meaningful error messages to users

### Performance
- Use connection pooling for multiple requests
- Implement appropriate timeouts
- Cache frequently accessed data
- Monitor and optimize response times

### Reliability
- Implement health checks and status monitoring
- Use exponential backoff for retries
- Handle network failures gracefully
- Provide fallback mechanisms

### Monitoring
- Collect metrics on request/response patterns
- Monitor error rates and response times
- Log important events and errors
- Set up alerting for critical failures

### Security
- Always use HTTPS in production
- Implement proper authentication
- Validate all inputs
- Don't log sensitive information

## Next Steps

- **[Error Handling Guide](/docs/guides/error-handling)** - Detailed error handling strategies
- **[Performance Optimization](/docs/guides/polling-strategies)** - Optimize your integration performance
- **[Flutter Integration](/docs/guides/flutter-setup)** - Complete Flutter integration guide
- **[API Reference](/docs/api/overview)** - Complete API documentation

import { SeeAlso, PageNavigation } from '@site/src/components/NavigationHelpers';

<SeeAlso
  title="Implementation Guides"
  links={[
    {
      to: '/docs/guides/flutter-setup',
      label: 'Flutter Integration',
      description: 'Complete Flutter integration with examples',
      icon: '📱'
    },
    {
      to: '/docs/guides/error-handling',
      label: 'Error Handling',
      description: 'Robust error handling patterns',
      icon: '🛠️'
    },
    {
      to: '/docs/guides/polling-strategies',
      label: 'Polling Strategies',
      description: 'Optimize polling and monitoring',
      icon: '🔄'
    },
    {
      to: '/docs/api/overview',
      label: 'API Reference',
      description: 'Complete API documentation',
      icon: '📚'
    }
  ]}
/>

<PageNavigation
  previous={{
    to: '/docs/overview/data-flow',
    label: 'Data Flow',
    description: 'Understand how data flows through the system'
  }}
  next={{
    to: '/docs/guides/quick-start',
    label: 'Quick Start Guide',
    description: 'Get started with your first integration'
  }}
/>