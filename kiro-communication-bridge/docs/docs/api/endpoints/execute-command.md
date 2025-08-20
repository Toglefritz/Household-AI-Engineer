---
sidebar_position: 1
---

# Execute Command

Execute Kiro IDE commands remotely through the REST API. This endpoint allows external applications to trigger Kiro functionality and receive execution results.

## Endpoint

```
POST /api/kiro/execute
```

## Request

### Headers

| Header | Value | Required |
|--------|-------|----------|
| `Content-Type` | `application/json` | Yes |
| `Authorization` | `Bearer <api-key>` | If auth enabled |

### Request Body

```typescript
interface ExecuteCommandRequest {
  /** Kiro command to execute */
  command: string;
  
  /** Optional command arguments */
  args?: string[];
  
  /** Optional workspace context path */
  workspacePath?: string;
}
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `command` | `string` | Yes | The Kiro command to execute (e.g., `"workbench.action.showCommands"`) |
| `args` | `string[]` | No | Array of string arguments to pass to the command |
| `workspacePath` | `string` | No | Workspace directory path for command context |

### Example Request

```bash
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "command": "workbench.action.showCommands",
    "args": [],
    "workspacePath": "/path/to/workspace"
  }'
```

## Response

### Success Response

**HTTP Status:** `200 OK`

```typescript
interface ExecuteCommandResponse {
  /** Whether command executed successfully */
  success: boolean;
  
  /** Command output */
  output: string;
  
  /** Error message if failed */
  error?: string;
  
  /** Execution time in milliseconds */
  executionTimeMs: number;
}
```

#### Example Success Response

```json
{
  "success": true,
  "output": "Command executed successfully",
  "executionTimeMs": 1250
}
```

### Error Response

**HTTP Status:** `422 Unprocessable Entity` (command execution failed)

```json
{
  "success": false,
  "output": "",
  "error": "Command 'invalid.command' failed: Command not found",
  "executionTimeMs": 150
}
```

## Error Handling

### Validation Errors

**HTTP Status:** `400 Bad Request`

```json
{
  "code": "VALIDATION_FAILED",
  "message": "Command is required and must be a string",
  "recoverable": false,
  "timestamp": "2025-01-19T10:30:00Z"
}
```

### Kiro Unavailable

**HTTP Status:** `503 Service Unavailable`

```json
{
  "code": "KIRO_UNAVAILABLE",
  "message": "Kiro IDE is not responding to commands",
  "recoverable": true,
  "timestamp": "2025-01-19T10:30:00Z"
}
```

### Timeout Error

**HTTP Status:** `408 Request Timeout`

```json
{
  "code": "OPERATION_TIMEOUT",
  "message": "Operation 'command-execution' timed out after 300000ms (limit: 300000ms)",
  "recoverable": true,
  "timestamp": "2025-01-19T10:30:00Z"
}
```

### Concurrent Limit Exceeded

**HTTP Status:** `422 Unprocessable Entity`

```json
{
  "success": false,
  "output": "",
  "error": "Maximum concurrent commands limit reached (3)",
  "executionTimeMs": 0
}
```

## Common Commands

### Kiro-Specific Commands

```bash
# Show command palette
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "workbench.action.showCommands"}'

# Open file
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "vscode.open",
    "args": ["file:///path/to/file.txt"]
  }'

# Create new file
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "workbench.action.files.newUntitledFile"}'
```

### AI Assistant Commands

```bash
# Start AI chat
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "workbench.action.chat.open"}'

# Generate code
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "kiro.generateCode",
    "args": ["Create a React component for user login"]
  }'
```

## Client Implementation Examples

### TypeScript/JavaScript

```typescript
interface ExecuteCommandOptions {
  command: string;
  args?: string[];
  workspacePath?: string;
  timeoutMs?: number;
}

class KiroCommandExecutor {
  private readonly baseUrl: string;
  private readonly apiKey?: string;

  constructor(baseUrl: string = 'http://localhost:3001', apiKey?: string) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }

  async executeCommand(options: ExecuteCommandOptions): Promise<ExecuteCommandResponse> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (this.apiKey) {
      headers['Authorization'] = `Bearer ${this.apiKey}`;
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), options.timeoutMs || 30000);

    try {
      const response = await fetch(`${this.baseUrl}/api/kiro/execute`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          command: options.command,
          args: options.args,
          workspacePath: options.workspacePath,
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(`HTTP ${response.status}: ${errorData.message || response.statusText}`);
      }

      return await response.json();
    } finally {
      clearTimeout(timeoutId);
    }
  }

  async executeWithRetry(
    options: ExecuteCommandOptions,
    maxRetries: number = 3,
    retryDelayMs: number = 1000
  ): Promise<ExecuteCommandResponse> {
    let lastError: Error;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await this.executeCommand(options);
      } catch (error) {
        lastError = error as Error;
        
        // Don't retry validation errors
        if (error instanceof Error && error.message.includes('400')) {
          throw error;
        }

        if (attempt < maxRetries) {
          await new Promise(resolve => setTimeout(resolve, retryDelayMs * attempt));
        }
      }
    }

    throw lastError!;
  }
}

// Usage examples
const executor = new KiroCommandExecutor('http://localhost:3001', 'your-api-key');

// Simple command execution
const result = await executor.executeCommand({
  command: 'workbench.action.showCommands'
});

// Command with arguments and workspace
const fileResult = await executor.executeCommand({
  command: 'vscode.open',
  args: ['file:///path/to/file.txt'],
  workspacePath: '/path/to/workspace'
});

// Command with retry logic
const retryResult = await executor.executeWithRetry({
  command: 'kiro.generateCode',
  args: ['Create a login form']
}, 3, 2000);
```

### Dart/Flutter

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ExecuteCommandRequest {
  final String command;
  final List<String>? args;
  final String? workspacePath;

  ExecuteCommandRequest({
    required this.command,
    this.args,
    this.workspacePath,
  });

  Map<String, dynamic> toJson() => {
    'command': command,
    if (args != null) 'args': args,
    if (workspacePath != null) 'workspacePath': workspacePath,
  };
}

class ExecuteCommandResponse {
  final bool success;
  final String output;
  final String? error;
  final int executionTimeMs;

  ExecuteCommandResponse({
    required this.success,
    required this.output,
    this.error,
    required this.executionTimeMs,
  });

  factory ExecuteCommandResponse.fromJson(Map<String, dynamic> json) {
    return ExecuteCommandResponse(
      success: json['success'] as bool,
      output: json['output'] as String,
      error: json['error'] as String?,
      executionTimeMs: json['executionTimeMs'] as int,
    );
  }
}

class KiroCommandExecutor {
  final String baseUrl;
  final String? apiKey;
  final http.Client _client;

  KiroCommandExecutor({
    this.baseUrl = 'http://localhost:3001',
    this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (apiKey != null) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    return headers;
  }

  Future<ExecuteCommandResponse> executeCommand(
    ExecuteCommandRequest request, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/kiro/execute'),
            headers: _headers,
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ExecuteCommandResponse.fromJson(responseData);
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${responseData['message'] ?? response.reasonPhrase}',
          uri: Uri.parse('$baseUrl/api/kiro/execute'),
        );
      }
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<ExecuteCommandResponse> executeWithRetry(
    ExecuteCommandRequest request, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    Duration timeout = const Duration(seconds: 30),
  }) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await executeCommand(request, timeout: timeout);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Don't retry validation errors (400 status)
        if (e.toString().contains('HTTP 400')) {
          throw lastException;
        }

        if (attempt < maxRetries) {
          await Future.delayed(retryDelay * attempt);
        }
      }
    }

    throw lastException!;
  }

  void dispose() {
    _client.close();
  }
}

// Usage examples
void main() async {
  final executor = KiroCommandExecutor(apiKey: 'your-api-key');

  try {
    // Simple command execution
    final result = await executor.executeCommand(
      ExecuteCommandRequest(command: 'workbench.action.showCommands'),
    );
    print('Command executed: ${result.success}');
    print('Output: ${result.output}');
    print('Execution time: ${result.executionTimeMs}ms');

    // Command with arguments
    final fileResult = await executor.executeCommand(
      ExecuteCommandRequest(
        command: 'vscode.open',
        args: ['file:///path/to/file.txt'],
        workspacePath: '/path/to/workspace',
      ),
    );

    // Command with retry logic
    final retryResult = await executor.executeWithRetry(
      ExecuteCommandRequest(
        command: 'kiro.generateCode',
        args: ['Create a login form'],
      ),
      maxRetries: 3,
      retryDelay: const Duration(seconds: 2),
    );

  } catch (e) {
    print('Error executing command: $e');
  } finally {
    executor.dispose();
  }
}
```

## Best Practices

### Command Validation

1. **Verify Commands**: Use the [status endpoint](/docs/api/endpoints/get-status) to get available commands
2. **Validate Arguments**: Ensure command arguments are properly formatted
3. **Handle Failures**: Always check the `success` field in responses

### Performance Optimization

1. **Timeout Management**: Set appropriate timeouts for different command types
2. **Concurrent Limits**: Respect the maximum concurrent command limit (default: 3)
3. **Retry Logic**: Implement exponential backoff for transient failures

### Error Recovery

1. **Retry Transient Errors**: Retry on timeout or availability errors
2. **Don't Retry Validation Errors**: Validation errors indicate client-side issues
3. **Monitor Kiro Status**: Check Kiro availability before executing commands

import { SeeAlso, PageNavigation } from '@site/src/components/NavigationHelpers';
import { TagSystem, RelatedContent } from '@site/src/components/CrossReference';

<TagSystem
  tags={[
    { id: 'api', label: 'API', color: 'primary' },
    { id: 'command', label: 'Command Execution', color: 'info' },
    { id: 'rest', label: 'REST', color: 'secondary' },
    { id: 'typescript', label: 'TypeScript', color: 'success' },
    { id: 'dart', label: 'Dart', color: 'warning' }
  ]}
/>

<RelatedContent
  items={[
    {
      id: 'get-status',
      title: 'Get Status',
      url: '/docs/api/endpoints/get-status',
      description: 'Monitor Kiro availability and get available commands',
      type: 'api',
      relevance: 0.9,
      tags: ['api', 'monitoring']
    },
    {
      id: 'user-input',
      title: 'User Input',
      url: '/docs/api/endpoints/user-input',
      description: 'Handle interactive commands that require user input',
      type: 'api',
      relevance: 0.8,
      tags: ['api', 'interactive']
    },
    {
      id: 'error-handling',
      title: 'Error Handling Guide',
      url: '/docs/guides/error-handling',
      description: 'Best practices for robust error handling',
      type: 'guide',
      relevance: 0.9,
      tags: ['error-handling', 'best-practices']
    },
    {
      id: 'polling-strategies',
      title: 'Polling Strategies',
      url: '/docs/guides/polling-strategies',
      description: 'Monitor long-running operations effectively',
      type: 'guide',
      relevance: 0.7,
      tags: ['polling', 'monitoring']
    },
    {
      id: 'flutter-setup',
      title: 'Flutter Integration',
      url: '/docs/guides/flutter-setup',
      description: 'Complete Flutter integration guide with examples',
      type: 'tutorial',
      relevance: 0.8,
      tags: ['flutter', 'integration']
    },
    {
      id: 'authentication',
      title: 'Authentication',
      url: '/docs/api/authentication',
      description: 'Learn about API key setup and security',
      type: 'reference',
      relevance: 0.6,
      tags: ['security', 'authentication']
    }
  ]}
  currentUrl="/docs/api/endpoints/execute-command"
  showTypes={true}
  showTags={true}
/>

<PageNavigation
  previous={{
    to: '/docs/api/overview',
    label: 'API Overview',
    description: 'Learn about the API architecture and design principles'
  }}
  next={{
    to: '/docs/api/endpoints/get-status',
    label: 'Get Status',
    description: 'Monitor Kiro availability and get available commands'
  }}
/>