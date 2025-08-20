---
sidebar_position: 3
---

# User Input

Provide user input for interactive Kiro commands that require user interaction. This endpoint enables external applications to respond to prompts, confirmations, and other interactive elements during command execution.

## Endpoint

```
POST /api/kiro/input
```

## Request

### Headers

| Header | Value | Required |
|--------|-------|----------|
| `Content-Type` | `application/json` | Yes |
| `Authorization` | `Bearer <api-key>` | If auth enabled |

### Request Body

```typescript
interface UserInputRequest {
  /** Input value provided by user */
  value: string;
  
  /** Type of input being provided */
  type: 'text' | 'choice' | 'file' | 'confirmation';
  
  /** Execution ID this input is for */
  executionId: string;
}
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `value` | `string` | Yes | The user's input value (text, choice selection, file path, or yes/no) |
| `type` | `string` | Yes | Type of input: `text`, `choice`, `file`, or `confirmation` |
| `executionId` | `string` | Yes | Unique identifier of the command execution waiting for input |

#### Input Types

| Type | Description | Example Values |
|------|-------------|----------------|
| `text` | Free-form text input | `"My application name"`, `"Enter description here"` |
| `choice` | Selection from predefined options | `"option1"`, `"2"`, `"Yes"` |
| `file` | File or directory path | `"/path/to/file.txt"`, `"./src/components"` |
| `confirmation` | Yes/no confirmation | `"yes"`, `"no"`, `"y"`, `"n"` |

### Example Request

```bash
curl -X POST http://localhost:3001/api/kiro/input \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "value": "MyApp",
    "type": "text",
    "executionId": "exec-1642598400000-1"
  }'
```

## Response

### Success Response

**HTTP Status:** `200 OK`

```typescript
interface UserInputResponse {
  /** Whether input was accepted */
  success: boolean;
  
  /** Error message if input was rejected */
  error?: string;
  
  /** Execution ID that received input */
  executionId: string;
}
```

#### Example Success Response

```json
{
  "success": true,
  "executionId": "exec-1642598400000-1"
}
```

### Error Response

**HTTP Status:** `400 Bad Request` (input rejected)

```json
{
  "success": false,
  "error": "Invalid choice. Available options: option1, option2, option3",
  "executionId": "exec-1642598400000-1"
}
```

## Error Handling

### Validation Errors

**HTTP Status:** `400 Bad Request`

```json
{
  "code": "VALIDATION_FAILED",
  "message": "Value is required and must be a string",
  "recoverable": false,
  "timestamp": "2025-01-19T10:30:00Z"
}
```

### Invalid Execution ID

**HTTP Status:** `404 Not Found`

```json
{
  "success": false,
  "error": "No pending input request found for execution ID: exec-invalid-id",
  "executionId": "exec-invalid-id"
}
```

### Input Timeout

**HTTP Status:** `408 Request Timeout`

```json
{
  "success": false,
  "error": "Input request timed out after 300000ms",
  "executionId": "exec-1642598400000-1"
}
```

## Interactive Command Flow

### 1. Execute Interactive Command

```bash
# Start an interactive command
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "kiro.createProject",
    "args": ["--interactive"]
  }'
```

### 2. Monitor for Input Requests

The command execution will pause and wait for user input. Monitor the execution status or implement a callback mechanism to detect when input is needed.

### 3. Provide User Input

```bash
# Provide the requested input
curl -X POST http://localhost:3001/api/kiro/input \
  -H "Content-Type: application/json" \
  -d '{
    "value": "MyNewProject",
    "type": "text",
    "executionId": "exec-1642598400000-1"
  }'
```

### 4. Continue Execution

The command will continue executing with the provided input and may request additional input if needed.

## Client Implementation Examples

### TypeScript/JavaScript

```typescript
interface UserInputRequest {
  value: string;
  type: 'text' | 'choice' | 'file' | 'confirmation';
  executionId: string;
}

interface UserInputResponse {
  success: boolean;
  error?: string;
  executionId: string;
}

class KiroUserInputHandler {
  private readonly baseUrl: string;
  private readonly apiKey?: string;
  private pendingInputs = new Map<string, (input: string) => void>();

  constructor(baseUrl: string = 'http://localhost:3001', apiKey?: string) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }

  async provideInput(request: UserInputRequest): Promise<UserInputResponse> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (this.apiKey) {
      headers['Authorization'] = `Bearer ${this.apiKey}`;
    }

    const response = await fetch(`${this.baseUrl}/api/kiro/input`, {
      method: 'POST',
      headers,
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`HTTP ${response.status}: ${errorData.message || response.statusText}`);
    }

    return await response.json();
  }

  async handleInteractiveCommand(
    command: string,
    args: string[] = [],
    inputHandler: (prompt: string, type: string) => Promise<string>
  ): Promise<any> {
    // This would integrate with the execute command endpoint
    // and handle the interactive flow
    
    const executeResponse = await this.executeCommand(command, args);
    
    // If command requires input, handle the interactive flow
    if (executeResponse.requiresInput) {
      const input = await inputHandler(
        executeResponse.inputPrompt,
        executeResponse.inputType
      );
      
      return await this.provideInput({
        value: input,
        type: executeResponse.inputType as any,
        executionId: executeResponse.executionId,
      });
    }
    
    return executeResponse;
  }

  // Helper method for text input
  async provideTextInput(executionId: string, text: string): Promise<UserInputResponse> {
    return this.provideInput({
      value: text,
      type: 'text',
      executionId,
    });
  }

  // Helper method for choice input
  async provideChoice(executionId: string, choice: string): Promise<UserInputResponse> {
    return this.provideInput({
      value: choice,
      type: 'choice',
      executionId,
    });
  }

  // Helper method for file input
  async provideFilePath(executionId: string, filePath: string): Promise<UserInputResponse> {
    return this.provideInput({
      value: filePath,
      type: 'file',
      executionId,
    });
  }

  // Helper method for confirmation input
  async provideConfirmation(executionId: string, confirmed: boolean): Promise<UserInputResponse> {
    return this.provideInput({
      value: confirmed ? 'yes' : 'no',
      type: 'confirmation',
      executionId,
    });
  }

  private async executeCommand(command: string, args: string[]): Promise<any> {
    // Implementation would call the execute endpoint
    // This is a simplified version for the example
    const response = await fetch(`${this.baseUrl}/api/kiro/execute`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(this.apiKey && { 'Authorization': `Bearer ${this.apiKey}` }),
      },
      body: JSON.stringify({ command, args }),
    });
    
    return response.json();
  }
}

// Usage examples
const inputHandler = new KiroUserInputHandler('http://localhost:3001', 'your-api-key');

// Handle interactive project creation
async function createProjectInteractively() {
  try {
    // Provide text input
    await inputHandler.provideTextInput('exec-123', 'MyNewProject');
    
    // Provide choice input
    await inputHandler.provideChoice('exec-123', 'React');
    
    // Provide file path
    await inputHandler.provideFilePath('exec-123', './src/projects');
    
    // Provide confirmation
    await inputHandler.provideConfirmation('exec-123', true);
    
  } catch (error) {
    console.error('Interactive command failed:', error);
  }
}

// Advanced interactive handler with retry logic
async function handleInputWithRetry(
  executionId: string,
  value: string,
  type: 'text' | 'choice' | 'file' | 'confirmation',
  maxRetries: number = 3
): Promise<UserInputResponse> {
  let lastError: Error;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await inputHandler.provideInput({ value, type, executionId });
    } catch (error) {
      lastError = error as Error;
      
      // Don't retry validation errors
      if (error instanceof Error && error.message.includes('400')) {
        throw error;
      }

      if (attempt < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
      }
    }
  }

  throw lastError!;
}
```

### Dart/Flutter

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

enum UserInputType { text, choice, file, confirmation }

class UserInputRequest {
  final String value;
  final UserInputType type;
  final String executionId;

  UserInputRequest({
    required this.value,
    required this.type,
    required this.executionId,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'type': type.name,
    'executionId': executionId,
  };
}

class UserInputResponse {
  final bool success;
  final String? error;
  final String executionId;

  UserInputResponse({
    required this.success,
    this.error,
    required this.executionId,
  });

  factory UserInputResponse.fromJson(Map<String, dynamic> json) {
    return UserInputResponse(
      success: json['success'] as bool,
      error: json['error'] as String?,
      executionId: json['executionId'] as String,
    );
  }
}

class KiroUserInputHandler {
  final String baseUrl;
  final String? apiKey;
  final http.Client _client;

  KiroUserInputHandler({
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

  Future<UserInputResponse> provideInput(UserInputRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/kiro/input'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return UserInputResponse.fromJson(responseData);
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${responseData['message'] ?? response.reasonPhrase}',
          uri: Uri.parse('$baseUrl/api/kiro/input'),
        );
      }
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to provide input: $e');
    }
  }

  // Helper methods for different input types
  Future<UserInputResponse> provideTextInput(
    String executionId,
    String text,
  ) async {
    return provideInput(UserInputRequest(
      value: text,
      type: UserInputType.text,
      executionId: executionId,
    ));
  }

  Future<UserInputResponse> provideChoice(
    String executionId,
    String choice,
  ) async {
    return provideInput(UserInputRequest(
      value: choice,
      type: UserInputType.choice,
      executionId: executionId,
    ));
  }

  Future<UserInputResponse> provideFilePath(
    String executionId,
    String filePath,
  ) async {
    return provideInput(UserInputRequest(
      value: filePath,
      type: UserInputType.file,
      executionId: executionId,
    ));
  }

  Future<UserInputResponse> provideConfirmation(
    String executionId,
    bool confirmed,
  ) async {
    return provideInput(UserInputRequest(
      value: confirmed ? 'yes' : 'no',
      type: UserInputType.confirmation,
      executionId: executionId,
    ));
  }

  Future<UserInputResponse> provideInputWithRetry(
    UserInputRequest request, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await provideInput(request);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Don't retry validation errors
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

// Interactive command handler
class InteractiveCommandHandler {
  final KiroUserInputHandler inputHandler;
  final Map<String, Function(String)> _inputCallbacks = {};

  InteractiveCommandHandler(this.inputHandler);

  Future<void> handleInteractiveSession(
    String executionId,
    Map<String, dynamic> inputPrompts,
  ) async {
    for (final entry in inputPrompts.entries) {
      final inputType = entry.key;
      final prompt = entry.value as String;

      // Get user input based on type
      String userInput;
      switch (inputType) {
        case 'text':
          userInput = await _getTextInput(prompt);
          await inputHandler.provideTextInput(executionId, userInput);
          break;
        case 'choice':
          userInput = await _getChoiceInput(prompt);
          await inputHandler.provideChoice(executionId, userInput);
          break;
        case 'file':
          userInput = await _getFileInput(prompt);
          await inputHandler.provideFilePath(executionId, userInput);
          break;
        case 'confirmation':
          final confirmed = await _getConfirmation(prompt);
          await inputHandler.provideConfirmation(executionId, confirmed);
          break;
      }
    }
  }

  Future<String> _getTextInput(String prompt) async {
    // Implementation would show UI prompt to user
    // This is a simplified example
    print('Text input required: $prompt');
    return 'User provided text';
  }

  Future<String> _getChoiceInput(String prompt) async {
    // Implementation would show choice dialog to user
    print('Choice input required: $prompt');
    return 'option1';
  }

  Future<String> _getFileInput(String prompt) async {
    // Implementation would show file picker to user
    print('File input required: $prompt');
    return '/path/to/selected/file';
  }

  Future<bool> _getConfirmation(String prompt) async {
    // Implementation would show confirmation dialog to user
    print('Confirmation required: $prompt');
    return true;
  }
}

// Usage example
void main() async {
  final inputHandler = KiroUserInputHandler(apiKey: 'your-api-key');
  final interactiveHandler = InteractiveCommandHandler(inputHandler);

  try {
    // Provide different types of input
    await inputHandler.provideTextInput('exec-123', 'MyProject');
    await inputHandler.provideChoice('exec-123', 'React');
    await inputHandler.provideFilePath('exec-123', './src/projects');
    await inputHandler.provideConfirmation('exec-123', true);

    // Handle interactive session
    await interactiveHandler.handleInteractiveSession(
      'exec-456',
      {
        'text': 'Enter project name:',
        'choice': 'Select framework:',
        'confirmation': 'Create project?',
      },
    );

  } catch (e) {
    print('Error handling user input: $e');
  } finally {
    inputHandler.dispose();
  }
}
```

## Input Validation

### Text Input Validation

```typescript
function validateTextInput(value: string, constraints?: {
  minLength?: number;
  maxLength?: number;
  pattern?: RegExp;
}): boolean {
  if (constraints?.minLength && value.length < constraints.minLength) {
    return false;
  }
  
  if (constraints?.maxLength && value.length > constraints.maxLength) {
    return false;
  }
  
  if (constraints?.pattern && !constraints.pattern.test(value)) {
    return false;
  }
  
  return true;
}
```

### Choice Input Validation

```typescript
function validateChoiceInput(value: string, availableChoices: string[]): boolean {
  return availableChoices.includes(value);
}
```

### File Path Validation

```typescript
function validateFilePath(value: string): boolean {
  // Basic path validation
  return value.length > 0 && !value.includes('\0');
}
```

## Best Practices

### Input Handling

1. **Validate Input**: Always validate user input before sending
2. **Handle Timeouts**: Implement timeout handling for user input requests
3. **Provide Feedback**: Give users clear feedback about input requirements

### Error Recovery

1. **Retry Logic**: Implement retry logic for transient failures
2. **Input Correction**: Allow users to correct invalid input
3. **Graceful Fallbacks**: Provide fallback options when input fails

### User Experience

1. **Clear Prompts**: Provide clear, actionable prompts to users
2. **Input Validation**: Validate input client-side before sending
3. **Progress Indication**: Show progress during interactive sessions

## Next Steps

- **[Execute Commands](/docs/api/endpoints/execute-command)** - Learn about interactive command execution
- **[Get Status](/docs/api/endpoints/get-status)** - Monitor command execution status
- **[Error Handling](/docs/guides/error-handling)** - Handle input errors gracefully
- **[Flutter Integration](/docs/guides/flutter-setup)** - Implement user input in Flutter apps