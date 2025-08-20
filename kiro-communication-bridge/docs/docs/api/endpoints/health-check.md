---
sidebar_position: 4
---

# Health Check

Check the health and availability of the Kiro Communication Bridge API server. This endpoint provides basic server status information and is useful for monitoring, load balancing, and service discovery.

## Endpoint

```
GET /health
```

## Request

### Headers

No special headers required. Authentication is **not** required for this endpoint.

### Query Parameters

None.

### Example Request

```bash
curl http://localhost:3001/health
```

## Response

### Success Response

**HTTP Status:** `200 OK`

```typescript
interface HealthResponse {
  /** Server health status */
  status: 'healthy' | 'unhealthy';
  
  /** Timestamp when health was checked */
  timestamp: string;
  
  /** Server status information */
  server: {
    /** Whether the server is running */
    running: boolean;
    
    /** Server port */
    port?: number;
    
    /** Server host */
    host?: string;
    
    /** Server uptime in seconds */
    uptime?: number;
  };
}
```

#### Example Success Response

```json
{
  "status": "healthy",
  "timestamp": "2025-01-19T10:30:00Z",
  "server": {
    "running": true,
    "port": 3001,
    "host": "localhost",
    "uptime": 3600
  }
}
```

### Server Error Response

**HTTP Status:** `500 Internal Server Error`

```json
{
  "status": "unhealthy",
  "timestamp": "2025-01-19T10:30:00Z",
  "server": {
    "running": false
  },
  "error": "Internal server error"
}
```

## Use Cases

### Service Discovery

Use the health check endpoint to verify that the API server is running and accessible:

```bash
# Simple availability check
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
  echo "API server is available"
else
  echo "API server is not available"
fi
```

### Load Balancer Health Checks

Configure load balancers to use this endpoint for health monitoring:

```yaml
# Example Kubernetes liveness probe
livenessProbe:
  httpGet:
    path: /health
    port: 3001
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

### Monitoring and Alerting

Integrate with monitoring systems to track API server availability:

```bash
# Prometheus health check
curl -s http://localhost:3001/health | jq -r '.status'
```

## Client Implementation Examples

### TypeScript/JavaScript

```typescript
interface HealthResponse {
  status: 'healthy' | 'unhealthy';
  timestamp: string;
  server: {
    running: boolean;
    port?: number;
    host?: string;
    uptime?: number;
  };
  error?: string;
}

class KiroHealthChecker {
  private readonly baseUrl: string;

  constructor(baseUrl: string = 'http://localhost:3001') {
    this.baseUrl = baseUrl;
  }

  async checkHealth(): Promise<HealthResponse> {
    const response = await fetch(`${this.baseUrl}/health`, {
      method: 'GET',
      // No authentication required
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json();
  }

  async isHealthy(): Promise<boolean> {
    try {
      const health = await this.checkHealth();
      return health.status === 'healthy' && health.server.running;
    } catch (error) {
      return false;
    }
  }

  async waitForHealthy(
    timeoutMs: number = 30000,
    pollIntervalMs: number = 1000
  ): Promise<void> {
    const startTime = Date.now();

    while (Date.now() - startTime < timeoutMs) {
      if (await this.isHealthy()) {
        return;
      }
      await new Promise(resolve => setTimeout(resolve, pollIntervalMs));
    }

    throw new Error(`Server did not become healthy within ${timeoutMs}ms`);
  }

  async getServerInfo(): Promise<HealthResponse['server'] | null> {
    try {
      const health = await this.checkHealth();
      return health.server;
    } catch (error) {
      return null;
    }
  }

  async getUptime(): Promise<number | null> {
    try {
      const health = await this.checkHealth();
      return health.server.uptime || null;
    } catch (error) {
      return null;
    }
  }
}

// Usage examples
const healthChecker = new KiroHealthChecker('http://localhost:3001');

// Simple health check
const isHealthy = await healthChecker.isHealthy();
console.log(`Server is ${isHealthy ? 'healthy' : 'unhealthy'}`);

// Get detailed health information
try {
  const health = await healthChecker.checkHealth();
  console.log(`Status: ${health.status}`);
  console.log(`Uptime: ${health.server.uptime} seconds`);
  console.log(`Running on: ${health.server.host}:${health.server.port}`);
} catch (error) {
  console.error('Health check failed:', error);
}

// Wait for server to become healthy
try {
  await healthChecker.waitForHealthy(30000);
  console.log('Server is now healthy');
} catch (error) {
  console.error('Server did not become healthy:', error);
}

// Get server uptime
const uptime = await healthChecker.getUptime();
if (uptime !== null) {
  console.log(`Server uptime: ${Math.floor(uptime / 60)} minutes`);
}
```

### Dart/Flutter

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

enum HealthStatus { healthy, unhealthy }

class ServerInfo {
  final bool running;
  final int? port;
  final String? host;
  final int? uptime;

  ServerInfo({
    required this.running,
    this.port,
    this.host,
    this.uptime,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      running: json['running'] as bool,
      port: json['port'] as int?,
      host: json['host'] as String?,
      uptime: json['uptime'] as int?,
    );
  }
}

class HealthResponse {
  final HealthStatus status;
  final DateTime timestamp;
  final ServerInfo server;
  final String? error;

  HealthResponse({
    required this.status,
    required this.timestamp,
    required this.server,
    this.error,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] == 'healthy' 
          ? HealthStatus.healthy 
          : HealthStatus.unhealthy,
      timestamp: DateTime.parse(json['timestamp'] as String),
      server: ServerInfo.fromJson(json['server'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );
  }
}

class KiroHealthChecker {
  final String baseUrl;
  final http.Client _client;

  KiroHealthChecker({
    this.baseUrl = 'http://localhost:3001',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
        // No authentication required
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return HealthResponse.fromJson(data);
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          uri: Uri.parse('$baseUrl/health'),
        );
      }
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }

  Future<bool> isHealthy() async {
    try {
      final health = await checkHealth();
      return health.status == HealthStatus.healthy && health.server.running;
    } catch (e) {
      return false;
    }
  }

  Future<void> waitForHealthy({
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(seconds: 1),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (await isHealthy()) {
        return;
      }
      await Future.delayed(pollInterval);
    }

    throw TimeoutException(
      'Server did not become healthy within ${timeout.inMilliseconds}ms',
      timeout,
    );
  }

  Future<ServerInfo?> getServerInfo() async {
    try {
      final health = await checkHealth();
      return health.server;
    } catch (e) {
      return null;
    }
  }

  Future<Duration?> getUptime() async {
    try {
      final health = await checkHealth();
      final uptimeSeconds = health.server.uptime;
      return uptimeSeconds != null 
          ? Duration(seconds: uptimeSeconds) 
          : null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

// Usage examples
void main() async {
  final healthChecker = KiroHealthChecker();

  try {
    // Simple health check
    final isHealthy = await healthChecker.isHealthy();
    print('Server is ${isHealthy ? 'healthy' : 'unhealthy'}');

    // Get detailed health information
    final health = await healthChecker.checkHealth();
    print('Status: ${health.status}');
    print('Timestamp: ${health.timestamp}');
    print('Server running: ${health.server.running}');
    
    if (health.server.uptime != null) {
      final uptimeMinutes = health.server.uptime! ~/ 60;
      print('Uptime: $uptimeMinutes minutes');
    }

    if (health.server.host != null && health.server.port != null) {
      print('Running on: ${health.server.host}:${health.server.port}');
    }

    // Wait for server to become healthy
    await healthChecker.waitForHealthy(
      timeout: const Duration(seconds: 30),
      pollInterval: const Duration(seconds: 2),
    );
    print('Server is now healthy');

    // Get server uptime as Duration
    final uptime = await healthChecker.getUptime();
    if (uptime != null) {
      print('Server uptime: ${uptime.inMinutes} minutes');
    }

  } catch (e) {
    print('Health check error: $e');
  } finally {
    healthChecker.dispose();
  }
}
```

### Shell Script Health Check

```bash
#!/bin/bash

# Health check script for Kiro Communication Bridge
# Usage: ./health_check.sh [base_url] [timeout]

BASE_URL=${1:-"http://localhost:3001"}
TIMEOUT=${2:-10}

check_health() {
    local url="$1"
    local timeout="$2"
    
    # Perform health check with timeout
    if response=$(curl -s --max-time "$timeout" "$url/health"); then
        # Parse JSON response
        status=$(echo "$response" | jq -r '.status // "unknown"')
        running=$(echo "$response" | jq -r '.server.running // false')
        uptime=$(echo "$response" | jq -r '.server.uptime // 0')
        
        if [[ "$status" == "healthy" && "$running" == "true" ]]; then
            echo "✅ Server is healthy"
            echo "   Uptime: $(($uptime / 60)) minutes"
            return 0
        else
            echo "❌ Server is unhealthy"
            echo "   Status: $status"
            echo "   Running: $running"
            return 1
        fi
    else
        echo "❌ Health check failed - server not responding"
        return 1
    fi
}

wait_for_healthy() {
    local url="$1"
    local max_attempts=${2:-30}
    local interval=${3:-1}
    
    echo "Waiting for server to become healthy..."
    
    for ((i=1; i<=max_attempts; i++)); do
        if check_health "$url" 5 > /dev/null 2>&1; then
            echo "✅ Server became healthy after $i attempts"
            return 0
        fi
        
        echo "Attempt $i/$max_attempts failed, retrying in ${interval}s..."
        sleep "$interval"
    done
    
    echo "❌ Server did not become healthy after $max_attempts attempts"
    return 1
}

# Main execution
case "${3:-check}" in
    "check")
        check_health "$BASE_URL" "$TIMEOUT"
        ;;
    "wait")
        wait_for_healthy "$BASE_URL" 30 2
        ;;
    *)
        echo "Usage: $0 [base_url] [timeout] [check|wait]"
        echo "  check: Perform single health check (default)"
        echo "  wait:  Wait for server to become healthy"
        exit 1
        ;;
esac
```

## Monitoring Integration

### Prometheus Metrics

```bash
# Create a simple Prometheus exporter for health status
#!/bin/bash

while true; do
    if curl -s http://localhost:3001/health | jq -e '.status == "healthy"' > /dev/null; then
        echo "kiro_bridge_health_status 1"
    else
        echo "kiro_bridge_health_status 0"
    fi
    
    # Get uptime if available
    uptime=$(curl -s http://localhost:3001/health | jq -r '.server.uptime // 0')
    echo "kiro_bridge_uptime_seconds $uptime"
    
    sleep 10
done
```

### Docker Health Check

```dockerfile
# Add health check to Dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1
```

### Kubernetes Probes

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kiro-bridge
    image: kiro-bridge:latest
    ports:
    - containerPort: 3001
    livenessProbe:
      httpGet:
        path: /health
        port: 3001
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /health
        port: 3001
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 3
```

## Best Practices

### Health Check Implementation

1. **Lightweight Checks**: Keep health checks fast and lightweight
2. **No Authentication**: Health checks should not require authentication
3. **Consistent Format**: Use consistent response format across environments

### Monitoring Strategy

1. **Regular Polling**: Poll health endpoint at regular intervals
2. **Alerting**: Set up alerts for health check failures
3. **Logging**: Log health check results for debugging

### Error Handling

1. **Timeout Handling**: Set appropriate timeouts for health checks
2. **Retry Logic**: Implement retry logic for transient failures
3. **Graceful Degradation**: Handle health check failures gracefully

## Next Steps

- **[API Overview](/docs/api/overview)** - Learn about the complete API
- **[Execute Commands](/docs/api/endpoints/execute-command)** - Execute commands after health check
- **[Get Status](/docs/api/endpoints/get-status)** - Get detailed Kiro status
- **[Troubleshooting](/docs/guides/troubleshooting)** - Debug health check issues