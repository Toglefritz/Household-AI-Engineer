# Kiro Communication Bridge API Documentation

This document describes the REST API endpoints provided by the Kiro Communication Bridge extension. The API enables frontend applications to communicate with the Kiro IDE through a simple HTTP interface.

## Base URL

The API server runs on `http://localhost:3001` by default. The port can be configured through Kiro settings.

## Authentication

The API supports optional API key authentication. When enabled, requests must include the API key in one of the following ways:

- **Authorization Header**: `Authorization: Bearer YOUR_API_KEY`
- **Query Parameter**: `?apiKey=YOUR_API_KEY`

## Content Type

All request and response bodies use `application/json` content type.

## Error Handling

The API uses standard HTTP status codes and returns error information in a consistent format:

```json
{
  "code": "ERROR_CODE",
  "message": "Human-readable error message",
  "recoverable": true,
  "timestamp": "2025-01-16T10:30:00.000Z"
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_FAILED` | 400 | Request validation failed |
| `KIRO_UNAVAILABLE` | 503 | Kiro IDE is not available |
| `COMMAND_EXECUTION_FAILED` | 422 | Command execution failed |
| `OPERATION_TIMEOUT` | 408 | Operation timed out |
| `WEBSOCKET_ERROR` | 500 | WebSocket communication error |

## Endpoints

### Health Check

Check if the API server is running and healthy.

**Endpoint**: `GET /health`

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-16T10:30:00.000Z",
  "server": {
    "running": true,
    "port": 3001,
    "host": "localhost",
    "uptime": 3600
  }
}
```

---

### Execute Kiro Command

Execute a command in Kiro IDE and return the result.

**Endpoint**: `POST /api/kiro/execute`

**Request Body**:
```json
{
  "command": "kiro.test-command",
  "args": ["arg1", "arg2"],
  "workspacePath": "/path/to/workspace"
}
```

**Request Parameters**:
- `command` (string, required): The Kiro command to execute
- `args` (array of strings, optional): Command arguments
- `workspacePath` (string, optional): Workspace context path

**Response**:
```json
{
  "success": true,
  "output": "Command executed successfully",
  "executionTimeMs": 1500,
  "error": null
}
```

**Response Fields**:
- `success` (boolean): Whether the command executed successfully
- `output` (string): Command output text
- `executionTimeMs` (number): Execution time in milliseconds
- `error` (string, nullable): Error message if command failed

**Example Request**:
```bash
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "workbench.action.files.newUntitledFile",
    "args": []
  }'
```

**Example Response**:
```json
{
  "success": true,
  "output": "New untitled file created",
  "executionTimeMs": 250
}
```

**Error Responses**:

*400 Bad Request* - Invalid request format:
```json
{
  "code": "VALIDATION_FAILED",
  "message": "Command is required and must be a string",
  "recoverable": false,
  "timestamp": "2025-01-16T10:30:00.000Z"
}
```

*422 Unprocessable Entity* - Command execution failed:
```json
{
  "code": "COMMAND_EXECUTION_FAILED",
  "message": "Command 'invalid.command' failed: Command not found",
  "recoverable": true,
  "timestamp": "2025-01-16T10:30:00.000Z"
}
```

*503 Service Unavailable* - Kiro IDE not available:
```json
{
  "code": "KIRO_UNAVAILABLE",
  "message": "Kiro IDE is not available or not responding",
  "recoverable": true,
  "timestamp": "2025-01-16T10:30:00.000Z"
}
```

---

### Get Kiro Status

Get the current status of Kiro IDE including available commands.

**Endpoint**: `GET /api/kiro/status`

**Response**:
```json
{
  "status": "ready",
  "currentCommand": null,
  "version": "1.74.0",
  "availableCommands": [
    "kiro.command1",
    "kiro.command2",
    "workbench.action.files.newFile",
    "ai.assistant.chat"
  ],
  "timestamp": "2025-01-16T10:30:00.000Z"
}
```

**Response Fields**:
- `status` (string): Current Kiro status - `"ready"`, `"busy"`, or `"unavailable"`
- `currentCommand` (string, nullable): Currently executing command if busy
- `version` (string, nullable): Kiro/VS Code version information
- `availableCommands` (array of strings): List of available Kiro commands
- `timestamp` (string): When the status was checked

**Status Values**:
- `ready`: Kiro is available and ready to execute commands
- `busy`: Kiro is currently executing a command
- `unavailable`: Kiro is not available or not responding

**Example Request**:
```bash
curl http://localhost:3001/api/kiro/status
```

**Example Response**:
```json
{
  "status": "ready",
  "version": "1.74.0",
  "availableCommands": [
    "kiro.createSpec",
    "kiro.executeTask",
    "workbench.action.files.newFile",
    "workbench.action.terminal.new"
  ],
  "timestamp": "2025-01-16T10:30:00.000Z"
}
```

---

### Provide User Input

Provide user input for interactive Kiro commands that are waiting for input.

**Endpoint**: `POST /api/kiro/input`

**Request Body**:
```json
{
  "value": "yes",
  "type": "confirmation",
  "executionId": "exec-123456"
}
```

**Request Parameters**:
- `value` (string, required): The user's input value
- `type` (string, required): Type of input - `"text"`, `"choice"`, `"file"`, or `"confirmation"`
- `executionId` (string, required): ID of the command execution waiting for input

**Response**:
```json
{
  "success": true,
  "executionId": "exec-123456"
}
```

**Response Fields**:
- `success` (boolean): Whether the input was accepted
- `executionId` (string): ID of the execution that received the input
- `error` (string, optional): Error message if input was rejected

**Input Types**:
- `text`: Free-form text input
- `choice`: Selection from predefined options
- `file`: File path input
- `confirmation`: Yes/no confirmation (accepts: yes, no, y, n, true, false)

**Example Request**:
```bash
curl -X POST http://localhost:3001/api/kiro/input \
  -H "Content-Type: application/json" \
  -d '{
    "value": "Continue with deployment",
    "type": "text",
    "executionId": "exec-789"
  }'
```

**Example Response**:
```json
{
  "success": true,
  "executionId": "exec-789"
}
```

**Error Responses**:

*400 Bad Request* - Invalid input format:
```json
{
  "code": "VALIDATION_FAILED",
  "message": "Type must be one of: text, choice, file, confirmation",
  "recoverable": false,
  "timestamp": "2025-01-16T10:30:00.000Z"
}
```

*200 OK* - Input rejected by handler:
```json
{
  "success": false,
  "error": "No pending input request found with ID: exec-invalid",
  "executionId": ""
}
```

## WebSocket Integration

While this API provides HTTP endpoints, the system also supports WebSocket connections for real-time updates. When commands are executed via the REST API, real-time progress updates are broadcast to connected WebSocket clients.

### WebSocket Events

The following events are emitted during command execution:

- `command-started`: Command execution begins
- `command-output`: Real-time output from the command
- `command-completed`: Command execution completes
- `command-error`: Command execution fails
- `user-input-required`: Command needs user input
- `status-changed`: Kiro status changes

## Rate Limiting

The API does not currently implement rate limiting, but it does enforce:

- Maximum concurrent command executions (default: 3)
- Request timeout (default: 30 seconds)
- Maximum request body size (default: 10MB)

## Configuration

The API server can be configured through VS Code settings:

```json
{
  "kiroOrchestration.api.port": 3001,
  "kiroOrchestration.api.host": "localhost",
  "kiroOrchestration.api.apiKey": "your-api-key",
  "kiroOrchestration.api.timeoutMs": 30000
}
```

## Examples

### Complete Workflow Example

1. **Check Kiro Status**:
```bash
curl http://localhost:3001/api/kiro/status
```

2. **Execute a Command**:
```bash
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "kiro.createNewProject",
    "args": ["MyProject", "web-app"]
  }'
```

3. **Provide User Input** (if command requires it):
```bash
curl -X POST http://localhost:3001/api/kiro/input \
  -H "Content-Type: application/json" \
  -d '{
    "value": "React",
    "type": "choice",
    "executionId": "exec-456"
  }'
```

### Error Handling Example

```javascript
async function executeKiroCommand(command, args = []) {
  try {
    const response = await fetch('http://localhost:3001/api/kiro/execute', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ command, args })
    });

    const result = await response.json();

    if (!response.ok) {
      console.error(`API Error (${response.status}):`, result.message);
      
      if (result.recoverable) {
        console.log('Error is recoverable, you may retry');
      }
      
      return null;
    }

    return result;
  } catch (error) {
    console.error('Network error:', error);
    return null;
  }
}

// Usage
const result = await executeKiroCommand('workbench.action.files.newFile');
if (result && result.success) {
  console.log('Command executed successfully:', result.output);
} else {
  console.log('Command failed');
}
```

## Troubleshooting

### Common Issues

1. **503 Service Unavailable**: Kiro IDE is not running or not responding
   - Ensure VS Code is running
   - Check that the Kiro extension is installed and activated
   - Verify VS Code is responsive

2. **422 Command Execution Failed**: Command failed to execute
   - Check that the command name is correct
   - Verify command arguments are valid
   - Ensure the command is available in the current context

3. **400 Validation Failed**: Request format is invalid
   - Check JSON syntax
   - Verify all required fields are present
   - Ensure field types match the specification

4. **408 Request Timeout**: Request took too long
   - Command may be hanging or taking longer than expected
   - Check Kiro IDE responsiveness
   - Consider increasing timeout configuration

### Debug Information

Enable debug logging in VS Code settings to get detailed information about API requests and command execution:

```json
{
  "kiroOrchestration.logging.level": "debug"
}
```

This will log detailed information about:
- Incoming API requests
- Command execution details
- Error conditions and stack traces
- Performance metrics