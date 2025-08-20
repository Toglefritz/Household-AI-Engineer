---
sidebar_position: 2
---

# Get Status

Retrieve the current status of Kiro IDE, including availability, version information, and available commands. This endpoint is essential for monitoring system health and discovering available functionality.

## Endpoint

```
GET /api/kiro/status
```

## Request

### Headers

| Header | Value | Required |
|--------|-------|----------|
| `Authorization` | `Bearer <api-key>` | If auth enabled |

### Query Parameters

None required.

### Example Request

```bash
curl http://localhost:3001/api/kiro/status \
  -H "Authorization: Bearer your-api-key"
```

## Response

### Success Response

**HTTP Status:** `200 OK`

```typescript
interface KiroStatusResponse {
  /** Current Kiro status */
  status: 'ready' | 'busy' | 'unavailable';
  
  /** Currently executing command if busy */
  currentCommand?: string;
  
  /** Kiro version information */
  version?: string;
  
  /** List of available commands */
  availableCommands: string[];
  
  /** Timestamp when status was checked */
  timestamp: string;
}
```

#### Status Values

| Status | Description |
|--------|-------------|
| `ready` | Kiro is available and ready to execute commands |
| `busy` | Kiro is currently executing a command |
| `unavailable` | Kiro is not responding or not installed |

#### Example Success Response

```json
{
  "status": "ready",
  "version": "1.85.0",
  "availableCommands": [
    "workbench.action.showCommands",
    "workbench.action.openSettings",
    "workbench.action.files.newUntitledFile",
    "vscode.open",
    "kiro.generateCode",
    "kiro.chat.start",
    "workbench.action.chat.open"
  ],
  "timestamp": "2025-01-19T10:30:00Z"
}
```

#### Busy Status Response

```json
{
  "status": "busy",
  "currentCommand": "kiro.generateCode",
  "version": "1.85.0",
  "availableCommands": [
    "workbench.action.showCommands",
    "workbench.action.openSettings"
  ],
  "timestamp": "2025-01-19T10:30:00Z"
}
```

#### Unavailable Status Response

```json
{
  "status": "unavailable",
  "availableCommands": [],
  "timestamp": "2025-01-19T10:30:00Z"
}
```

## Error Handling

### Authentication Error

**HTTP Status:** `401 Unauthorized`

```json
{
  "error": "Unauthorized",
  "message": "Valid API key required"
}
```

### Server Error

**HTTP Status:** `500 Internal Server Error`

```json
{
  "code": "CONFIGURATION_ERROR",
  "message": "Failed to retrieve Kiro status",
  "recoverable": true,
  "timestamp": "2025-01-19T10:30:00Z"
}
```

## Available Commands

The `availableCommands` array contains VS Code and Kiro-specific commands that can be executed via the [execute endpoint](/docs/api/endpoints/execute-command).

### Common Command Categories

#### Workbench Commands
- `workbench.action.showCommands` - Show command palette
- `workbench.action.openSettings` - Open settings
- `workbench.action.files.newUntitledFile` - Create new file
- `workbench.action.files.save` - Save current file

#### File Operations
- `vscode.open` - Open file or folder
- `vscode.openFolder` - Open folder in workspace
- `workbench.action.files.openFile` - Open file dialog

#### Kiro AI Commands
- `kiro.generateCode` - Generate code with AI
- `kiro.chat.start` - Start AI chat session
- `kiro.explainCode` - Explain selected code
- `kiro.refactorCode` - Refactor code with AI

#### Chat and Assistant
- `workbench.action.chat.open` - Open chat panel
- `workbench.action.chat.clear` - Clear chat history

## Client Implementation Examples

### TypeScript/JavaScript

```typescript
interface KiroStatusResponse {
  status: 'ready' | 'busy' | 'unavailable';
  currentCommand?: string;
  version?: string;
  availableCommands: string[];
  timestamp: string;
}

class KiroStatusMonitor {
  private readonly baseUrl: string;
  private readonly apiKey?: string;
  private statusCheckInterval?: NodeJS.Timeout;

  constructor(baseUrl: string = 'http://localhost:3001', apiKey?: string) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }

  async getStatus(): Promise<KiroStatusResponse> {
    const headers: Record<string, string> = {};

    if (this.apiKey) {
      headers['Authorization'] = `Bearer ${this.apiKey}`;
    }

    const response = await fetch(`${this.baseUrl}/api/kiro/status`, {
      method: 'GET',
      headers,
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json();
  }

  async waitForReady(timeoutMs: number = 30000, pollIntervalMs: number = 1000): Promise<void> {
    const startTime = Date.now();

    while (Date.now() - startTime < timeoutMs) {
      try {
        const status = await this.getStatus();
        if (status.status === 'ready') {
          return;
        }
      } catch (error) {
        // Continue polling on errors
      }

      await new Promise(resolve => setTimeout(resolve, pollIntervalMs));
    }

    throw new Error(`Kiro did not become ready within ${timeoutMs}ms`);
  }

  startMonitoring(
    callback: (status: KiroStatusResponse) => void,
    intervalMs: number = 5000
  ): void {
    this.stopMonitoring();

    this.statusCheckInterval = setInterval(async () => {
      try {
        const status = await this.getStatus();
        callback(status);
      } catch (error) {
        console.error('Status check failed:', error);
      }
    }, intervalMs);
  }

  stopMonitoring(): void {
    if (this.statusCheckInterval) {
      clearInterval(this.statusCheckInterval);
      this.statusCheckInterval = undefined;
    }
  }

  async isCommandAvailable(command: string): Promise<boolean> {
    try {
      const status = await this.getStatus();
      return status.availableCommands.includes(command);
    } catch (error) {
      return false;
    }
  }
}

// Usage examples
const monitor = new KiroStatusMonitor('http://localhost:3001', 'your-api-key');

// Get current status
const status = await monitor.getStatus();
console.log(`Kiro status: ${status.status}`);
console.log(`Available commands: ${status.availableCommands.length}`);

// Wait for Kiro to be ready
await monitor.waitForReady(30000);
console.log('Kiro is ready!');

// Start monitoring with callback
monitor.startMonitoring((status) => {
  console.log(`Status changed: ${status.status}`);
  if (status.currentCommand) {
    console.log(`Currently executing: ${status.currentCommand}`);
  }
}, 5000);

// Check if specific command is available
const canGenerateCode = await monitor.isCommandAvailable('kiro.generateCode');
if (canGenerateCode) {
  console.log('Code generation is available');
}

// Stop monitoring when done
monitor.stopMonitoring();
```

### Dart/Flutter

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

enum KiroStatus { ready, busy, unavailable }

class KiroStatusResponse {
  final KiroStatus status;
  final String? currentCommand;
  final String? version;
  final List<String> availableCommands;
  final DateTime timestamp;

  KiroStatusResponse({
    required this.status,
    this.currentCommand,
    this.version,
    required this.availableCommands,
    required this.timestamp,
  });

  factory KiroStatusResponse.fromJson(Map<String, dynamic> json) {
    return KiroStatusResponse(
      status: _parseStatus(json['status'] as String),
      currentCommand: json['currentCommand'] as String?,
      version: json['version'] as String?,
      availableCommands: List<String>.from(json['availableCommands'] as List),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  static KiroStatus _parseStatus(String status) {
    switch (status) {
      case 'ready':
        return KiroStatus.ready;
      case 'busy':
        return KiroStatus.busy;
      case 'unavailable':
        return KiroStatus.unavailable;
      default:
        return KiroStatus.unavailable;
    }
  }
}

class KiroStatusMonitor {
  final String baseUrl;
  final String? apiKey;
  final http.Client _client;
  Timer? _statusTimer;

  KiroStatusMonitor({
    this.baseUrl = 'http://localhost:3001',
    this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final headers = <String, String>{};
    if (apiKey != null) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    return headers;
  }

  Future<KiroStatusResponse> getStatus() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/kiro/status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return KiroStatusResponse.fromJson(data);
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          uri: Uri.parse('$baseUrl/api/kiro/status'),
        );
      }
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get status: $e');
    }
  }

  Future<void> waitForReady({
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(seconds: 1),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      try {
        final status = await getStatus();
        if (status.status == KiroStatus.ready) {
          return;
        }
      } catch (e) {
        // Continue polling on errors
      }

      await Future.delayed(pollInterval);
    }

    throw TimeoutException(
      'Kiro did not become ready within ${timeout.inMilliseconds}ms',
      timeout,
    );
  }

  StreamSubscription<KiroStatusResponse> startMonitoring({
    Duration interval = const Duration(seconds: 5),
  }) {
    final controller = StreamController<KiroStatusResponse>();

    _statusTimer = Timer.periodic(interval, (timer) async {
      try {
        final status = await getStatus();
        if (!controller.isClosed) {
          controller.add(status);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    });

    controller.onCancel = () {
      _statusTimer?.cancel();
      _statusTimer = null;
    };

    return controller.stream.listen(null);
  }

  void stopMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  Future<bool> isCommandAvailable(String command) async {
    try {
      final status = await getStatus();
      return status.availableCommands.contains(command);
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    stopMonitoring();
    _client.close();
  }
}

// Usage examples
void main() async {
  final monitor = KiroStatusMonitor(apiKey: 'your-api-key');

  try {
    // Get current status
    final status = await monitor.getStatus();
    print('Kiro status: ${status.status}');
    print('Available commands: ${status.availableCommands.length}');

    // Wait for Kiro to be ready
    await monitor.waitForReady(timeout: const Duration(seconds: 30));
    print('Kiro is ready!');

    // Start monitoring
    final subscription = monitor.startMonitoring(
      interval: const Duration(seconds: 5),
    );

    subscription.onData((status) {
      print('Status changed: ${status.status}');
      if (status.currentCommand != null) {
        print('Currently executing: ${status.currentCommand}');
      }
    });

    subscription.onError((error) {
      print('Status monitoring error: $error');
    });

    // Check if specific command is available
    final canGenerateCode = await monitor.isCommandAvailable('kiro.generateCode');
    if (canGenerateCode) {
      print('Code generation is available');
    }

    // Stop monitoring after some time
    await Future.delayed(const Duration(minutes: 1));
    await subscription.cancel();

  } catch (e) {
    print('Error: $e');
  } finally {
    monitor.dispose();
  }
}
```

## Monitoring Patterns

### Health Check Pattern

```typescript
class KiroHealthChecker {
  private readonly monitor: KiroStatusMonitor;
  private isHealthy: boolean = false;

  constructor(monitor: KiroStatusMonitor) {
    this.monitor = monitor;
  }

  async performHealthCheck(): Promise<boolean> {
    try {
      const status = await this.monitor.getStatus();
      this.isHealthy = status.status !== 'unavailable';
      return this.isHealthy;
    } catch (error) {
      this.isHealthy = false;
      return false;
    }
  }

  async waitForHealthy(timeoutMs: number = 60000): Promise<void> {
    const startTime = Date.now();

    while (Date.now() - startTime < timeoutMs) {
      if (await this.performHealthCheck()) {
        return;
      }
      await new Promise(resolve => setTimeout(resolve, 2000));
    }

    throw new Error('Kiro health check failed within timeout');
  }

  getHealthStatus(): boolean {
    return this.isHealthy;
  }
}
```

### Command Availability Cache

```typescript
class CommandCache {
  private cache: Set<string> = new Set();
  private lastUpdate: number = 0;
  private readonly cacheTimeoutMs: number = 30000; // 30 seconds

  constructor(private readonly monitor: KiroStatusMonitor) {}

  async getAvailableCommands(): Promise<string[]> {
    const now = Date.now();
    
    if (now - this.lastUpdate > this.cacheTimeoutMs) {
      await this.refreshCache();
    }

    return Array.from(this.cache);
  }

  async isCommandAvailable(command: string): Promise<boolean> {
    const commands = await this.getAvailableCommands();
    return commands.includes(command);
  }

  private async refreshCache(): Promise<void> {
    try {
      const status = await this.monitor.getStatus();
      this.cache = new Set(status.availableCommands);
      this.lastUpdate = Date.now();
    } catch (error) {
      // Keep existing cache on error
      console.warn('Failed to refresh command cache:', error);
    }
  }

  clearCache(): void {
    this.cache.clear();
    this.lastUpdate = 0;
  }
}
```

## Best Practices

### Polling Strategy

1. **Reasonable Intervals**: Use 5-10 second intervals for status monitoring
2. **Exponential Backoff**: Increase intervals during extended unavailability
3. **Error Handling**: Continue polling despite temporary errors

### Performance Optimization

1. **Cache Commands**: Cache available commands to reduce API calls
2. **Conditional Requests**: Only poll when necessary
3. **Connection Reuse**: Use persistent HTTP connections

### Reliability

1. **Timeout Handling**: Set appropriate timeouts for status requests
2. **Retry Logic**: Implement retry logic for transient failures
3. **Graceful Degradation**: Handle unavailable status gracefully

## Next Steps

- **[Execute Commands](/docs/api/endpoints/execute-command)** - Execute commands when Kiro is ready
- **[User Input](/docs/api/endpoints/user-input)** - Handle interactive command sessions
- **[Polling Strategies](/docs/guides/polling-strategies)** - Implement effective monitoring patterns
- **[Error Handling](/docs/guides/error-handling)** - Handle status monitoring errors