---
sidebar_position: 1
---

# Command Execution Types

This page documents the TypeScript interfaces and types used for command execution in the Kiro Communication Bridge API. These types define the structure of requests, responses, and internal data used for executing Kiro commands.

## Core Interfaces

### ExecuteCommandRequest

Request payload for executing Kiro commands via the `/api/kiro/execute` endpoint.

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

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `command` | `string` | Yes | The Kiro command identifier (e.g., `"workbench.action.showCommands"`) |
| `args` | `string[]` | No | Array of string arguments to pass to the command |
| `workspacePath` | `string` | No | Workspace directory path for command execution context |

#### Example

```json
{
  "command": "vscode.open",
  "args": ["file:///path/to/file.txt"],
  "workspacePath": "/path/to/workspace"
}
```

### ExecuteCommandResponse

Response payload returned from the `/api/kiro/execute` endpoint.

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

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `success` | `boolean` | Yes | `true` if command executed successfully, `false` otherwise |
| `output` | `string` | Yes | Text output from the command execution |
| `error` | `string` | No | Error message if command execution failed |
| `executionTimeMs` | `number` | Yes | Time taken to execute the command in milliseconds |

#### Example Success Response

```json
{
  "success": true,
  "output": "File opened successfully",
  "executionTimeMs": 1250
}
```

#### Example Error Response

```json
{
  "success": false,
  "output": "",
  "error": "Command 'invalid.command' not found",
  "executionTimeMs": 150
}
```

### CommandResult

Internal interface representing detailed command execution results with additional metadata.

```typescript
interface CommandResult {
  /** Whether the command executed successfully */
  success: boolean;
  
  /** Command output text */
  output: string;
  
  /** Error message if command failed */
  error?: string;
  
  /** Execution time in milliseconds */
  executionTimeMs: number;
  
  /** Exit code from the command */
  exitCode?: number;
  
  /** Command that was executed */
  command: string;
  
  /** Arguments passed to the command */
  args: string[];
}
```

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `success` | `boolean` | Yes | Whether the command executed successfully |
| `output` | `string` | Yes | Text output from command execution |
| `error` | `string` | No | Error message if execution failed |
| `executionTimeMs` | `number` | Yes | Execution duration in milliseconds |
| `exitCode` | `number` | No | Process exit code (0 for success, non-zero for failure) |
| `command` | `string` | Yes | The command that was executed |
| `args` | `string[]` | Yes | Arguments that were passed to the command |

## Status Types

### KiroStatusType

Enumeration of possible Kiro IDE status values.

```typescript
type KiroStatusType = 'ready' | 'busy' | 'unavailable';
```

#### Values

| Value | Description |
|-------|-------------|
| `ready` | Kiro is available and ready to execute commands |
| `busy` | Kiro is currently executing a command |
| `unavailable` | Kiro is not responding or not installed |

### KiroStatus

Basic Kiro IDE status information.

```typescript
interface KiroStatus {
  /** Current Kiro status */
  status: KiroStatusType;
  
  /** Currently executing command if busy */
  currentCommand?: string;
  
  /** Kiro version information */
  version?: string;
}
```

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `status` | `KiroStatusType` | Yes | Current status of Kiro IDE |
| `currentCommand` | `string` | No | Command currently being executed (only present when status is `busy`) |
| `version` | `string` | No | VS Code/Kiro version information |

#### Example

```json
{
  "status": "busy",
  "currentCommand": "kiro.generateCode",
  "version": "1.85.0"
}
```

### KiroStatusResponse

Extended status response returned from the `/api/kiro/status` endpoint.

```typescript
interface KiroStatusResponse extends KiroStatus {
  /** List of available commands */
  availableCommands: string[];
  
  /** Timestamp when status was checked */
  timestamp: string;
}
```

#### Properties

Inherits all properties from `KiroStatus` plus:

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `availableCommands` | `string[]` | Yes | Array of command identifiers that can be executed |
| `timestamp` | `string` | Yes | ISO 8601 timestamp when the status was checked |

#### Example

```json
{
  "status": "ready",
  "version": "1.85.0",
  "availableCommands": [
    "workbench.action.showCommands",
    "vscode.open",
    "kiro.generateCode"
  ],
  "timestamp": "2025-01-19T10:30:00Z"
}
```

## Execution Tracking

### CommandExecution

Interface representing a command execution in progress, used internally for tracking active executions.

```typescript
interface CommandExecution {
  /** Unique execution ID */
  id: string;
  
  /** Command being executed */
  command: string;
  
  /** Command arguments */
  args: string[];
  
  /** Workspace context */
  workspacePath?: string;
  
  /** Execution start time */
  startedAt: Date;
  
  /** Execution completion time */
  completedAt?: Date;
  
  /** Current status */
  status: 'running' | 'completed' | 'failed';
  
  /** Accumulated output */
  output: string;
  
  /** Error information if failed */
  error?: string;
}
```

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | `string` | Yes | Unique identifier for this execution (format: `exec-{timestamp}-{counter}`) |
| `command` | `string` | Yes | The command being executed |
| `args` | `string[]` | Yes | Arguments passed to the command |
| `workspacePath` | `string` | No | Workspace directory path |
| `startedAt` | `Date` | Yes | When the execution started |
| `completedAt` | `Date` | No | When the execution completed (only set after completion) |
| `status` | `'running' \| 'completed' \| 'failed'` | Yes | Current execution status |
| `output` | `string` | Yes | Accumulated output from the command |
| `error` | `string` | No | Error message if execution failed |

#### Status Values

| Status | Description |
|--------|-------------|
| `running` | Command is currently executing |
| `completed` | Command completed successfully |
| `failed` | Command execution failed |

## Type Usage Examples

### TypeScript Client Implementation

```typescript
import { 
  ExecuteCommandRequest, 
  ExecuteCommandResponse, 
  KiroStatusResponse 
} from './kiro-bridge-types';

class KiroBridgeClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = 'http://localhost:3001') {
    this.baseUrl = baseUrl;
  }

  async executeCommand(request: ExecuteCommandRequest): Promise<ExecuteCommandResponse> {
    const response = await fetch(`${this.baseUrl}/api/kiro/execute`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json() as ExecuteCommandResponse;
  }

  async getStatus(): Promise<KiroStatusResponse> {
    const response = await fetch(`${this.baseUrl}/api/kiro/status`);
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json() as KiroStatusResponse;
  }

  async isReady(): Promise<boolean> {
    try {
      const status = await this.getStatus();
      return status.status === 'ready';
    } catch (error) {
      return false;
    }
  }
}

// Usage example
const client = new KiroBridgeClient();

// Execute a command
const executeRequest: ExecuteCommandRequest = {
  command: 'workbench.action.showCommands',
  args: [],
};

const result: ExecuteCommandResponse = await client.executeCommand(executeRequest);
console.log(`Command ${result.success ? 'succeeded' : 'failed'}`);
console.log(`Output: ${result.output}`);
console.log(`Execution time: ${result.executionTimeMs}ms`);

// Check status
const status: KiroStatusResponse = await client.getStatus();
console.log(`Kiro status: ${status.status}`);
console.log(`Available commands: ${status.availableCommands.length}`);
```

### Dart/Flutter Type Definitions

```dart
// Equivalent Dart classes for Flutter integration

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

enum KiroStatusType { ready, busy, unavailable }

class KiroStatusResponse {
  final KiroStatusType status;
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

  static KiroStatusType _parseStatus(String status) {
    switch (status) {
      case 'ready': return KiroStatusType.ready;
      case 'busy': return KiroStatusType.busy;
      case 'unavailable': return KiroStatusType.unavailable;
      default: return KiroStatusType.unavailable;
    }
  }
}
```

## Validation and Error Handling

### Request Validation

The API server validates all incoming requests against these type definitions:

```typescript
function validateExecuteCommandRequest(data: any): ExecuteCommandRequest {
  if (!data.command || typeof data.command !== 'string') {
    throw new ValidationError('Command is required and must be a string');
  }

  if (data.args && !Array.isArray(data.args)) {
    throw new ValidationError('Args must be an array');
  }

  if (data.args && !data.args.every((arg: any) => typeof arg === 'string')) {
    throw new ValidationError('All args must be strings');
  }

  if (data.workspacePath && typeof data.workspacePath !== 'string') {
    throw new ValidationError('WorkspacePath must be a string');
  }

  return {
    command: data.command,
    args: data.args || [],
    workspacePath: data.workspacePath,
  };
}
```

### Type Guards

Use type guards to safely handle API responses:

```typescript
function isExecuteCommandResponse(data: any): data is ExecuteCommandResponse {
  return (
    typeof data === 'object' &&
    data !== null &&
    typeof data.success === 'boolean' &&
    typeof data.output === 'string' &&
    typeof data.executionTimeMs === 'number' &&
    (data.error === undefined || typeof data.error === 'string')
  );
}

function isKiroStatusResponse(data: any): data is KiroStatusResponse {
  return (
    typeof data === 'object' &&
    data !== null &&
    ['ready', 'busy', 'unavailable'].includes(data.status) &&
    Array.isArray(data.availableCommands) &&
    typeof data.timestamp === 'string'
  );
}

// Usage
const response = await fetch('/api/kiro/status');
const data = await response.json();

if (isKiroStatusResponse(data)) {
  // TypeScript now knows data is KiroStatusResponse
  console.log(`Status: ${data.status}`);
  console.log(`Commands: ${data.availableCommands.length}`);
} else {
  throw new Error('Invalid response format');
}
```

## Next Steps

- **[Application Metadata Types](/docs/api/types/application-metadata)** - Application and job metadata structures
- **[Development Job Types](/docs/api/types/development-job)** - Development job lifecycle types
- **[Error Types](/docs/api/types/error-types)** - Error handling and recovery types
- **[Execute Commands](/docs/api/endpoints/execute-command)** - Use these types with the execute endpoint