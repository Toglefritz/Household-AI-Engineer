---
sidebar_position: 2
---

# Flutter Integration

This guide provides comprehensive instructions for integrating the Kiro Communication Bridge API with Flutter applications. You'll learn how to set up HTTP clients, handle responses, and implement best practices for robust Flutter integration.

## Prerequisites

Before starting, ensure you have:

- **Flutter SDK** installed and configured
- **Kiro Communication Bridge** extension running in VS Code
- **API server** accessible at `http://localhost:3001`
- **Basic knowledge** of Dart and Flutter development

## Installation

### Add HTTP Dependencies

Add the required HTTP client dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

Run the following command to install dependencies:

```bash
flutter pub get
```

## Basic Setup

### Create API Client

Create a dedicated API client class for communicating with the Kiro Communication Bridge:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class KiroApiClient {
  final String baseUrl;
  final String? apiKey;
  final http.Client _client;

  KiroApiClient({
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

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      late http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: _headers).timeout(timeout);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(timeout);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw KiroApiException(
          message: responseData['message'] ?? 'Request failed',
          statusCode: response.statusCode,
          errorCode: responseData['code'],
        );
      }
    } on SocketException catch (e) {
      throw KiroApiException(
        message: 'Network error: ${e.message}',
        statusCode: 0,
      );
    } on TimeoutException catch (e) {
      throw KiroApiException(
        message: 'Request timeout: ${e.message}',
        statusCode: 408,
      );
    } catch (e) {
      if (e is KiroApiException) rethrow;
      throw KiroApiException(
        message: 'Unexpected error: $e',
        statusCode: 500,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
```

### Define Data Models

Create data models for API requests and responses:

```dart
// lib/models/execute_command_request.dart
class ExecuteCommandRequest {
  final String command;
  final List<String>? args;
  final String? workspacePath;

  const ExecuteCommandRequest({
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

// lib/models/execute_command_response.dart
class ExecuteCommandResponse {
  final bool success;
  final String output;
  final String? error;
  final int executionTimeMs;

  const ExecuteCommandResponse({
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

// lib/models/kiro_status_response.dart
class KiroStatusResponse {
  final bool available;
  final List<String> availableCommands;
  final String? version;

  const KiroStatusResponse({
    required this.available,
    required this.availableCommands,
    this.version,
  });

  factory KiroStatusResponse.fromJson(Map<String, dynamic> json) {
    return KiroStatusResponse(
      available: json['available'] as bool,
      availableCommands: (json['availableCommands'] as List<dynamic>)
          .cast<String>(),
      version: json['version'] as String?,
    );
  }
}
```

### Create Exception Classes

Define custom exception classes for better error handling:

```dart
// lib/exceptions/kiro_api_exception.dart
class KiroApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;

  const KiroApiException({
    required this.message,
    required this.statusCode,
    this.errorCode,
  });

  bool get isNetworkError => statusCode == 0;
  bool get isTimeout => statusCode == 408;
  bool get isServerError => statusCode >= 500;
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  @override
  String toString() {
    return 'KiroApiException: $message (Status: $statusCode${errorCode != null ? ', Code: $errorCode' : ''})';
  }
}
```

## API Methods

### Execute Commands

Add command execution methods to your API client:

```dart
extension KiroCommandMethods on KiroApiClient {
  Future<ExecuteCommandResponse> executeCommand(
    ExecuteCommandRequest request, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await _makeRequest(
      'POST',
      '/api/kiro/execute',
      body: request.toJson(),
      timeout: timeout,
    );

    return ExecuteCommandResponse.fromJson(response);
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
        
        // Don't retry client errors (4xx)
        if (e is KiroApiException && e.isClientError) {
          throw lastException;
        }

        if (attempt < maxRetries) {
          await Future.delayed(retryDelay * attempt);
        }
      }
    }

    throw lastException!;
  }
}
```

### Status Monitoring

Add status monitoring methods:

```dart
extension KiroStatusMethods on KiroApiClient {
  Future<KiroStatusResponse> getStatus({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final response = await _makeRequest(
      'GET',
      '/api/kiro/status',
      timeout: timeout,
    );

    return KiroStatusResponse.fromJson(response);
  }

  Future<bool> checkHealth({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      await _makeRequest('GET', '/health', timeout: timeout);
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

## Flutter Integration

### Create a Service Class

Create a service class that integrates with Flutter's state management:

```dart
// lib/services/kiro_service.dart
import 'package:flutter/foundation.dart';

class KiroService extends ChangeNotifier {
  final KiroApiClient _apiClient;
  
  bool _isConnected = false;
  bool _isExecuting = false;
  String? _lastError;
  List<String> _availableCommands = [];

  KiroService({KiroApiClient? apiClient})
      : _apiClient = apiClient ?? KiroApiClient();

  bool get isConnected => _isConnected;
  bool get isExecuting => _isExecuting;
  String? get lastError => _lastError;
  List<String> get availableCommands => List.unmodifiable(_availableCommands);

  Future<void> initialize() async {
    try {
      _lastError = null;
      notifyListeners();

      final status = await _apiClient.getStatus();
      _isConnected = status.available;
      _availableCommands = status.availableCommands;
      
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<ExecuteCommandResponse> executeCommand(
    String command, {
    List<String>? args,
    String? workspacePath,
  }) async {
    if (!_isConnected) {
      throw Exception('Kiro is not connected');
    }

    try {
      _isExecuting = true;
      _lastError = null;
      notifyListeners();

      final request = ExecuteCommandRequest(
        command: command,
        args: args,
        workspacePath: workspacePath,
      );

      final response = await _apiClient.executeWithRetry(request);
      
      if (!response.success && response.error != null) {
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

  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}
```

### Use in Flutter Widgets

Here's how to use the service in your Flutter widgets:

```dart
// lib/screens/kiro_control_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KiroControlScreen extends StatefulWidget {
  const KiroControlScreen({super.key});

  @override
  State<KiroControlScreen> createState() => _KiroControlScreenState();
}

class _KiroControlScreenState extends State<KiroControlScreen> {
  final _commandController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KiroService>().initialize();
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiro Control'),
      ),
      body: Consumer<KiroService>(
        builder: (context, kiroService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          kiroService.isConnected 
                              ? Icons.check_circle 
                              : Icons.error,
                          color: kiroService.isConnected 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          kiroService.isConnected 
                              ? 'Connected to Kiro' 
                              : 'Disconnected',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (!kiroService.isConnected)
                          ElevatedButton(
                            onPressed: kiroService.initialize,
                            child: const Text('Retry'),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Command Input
                TextField(
                  controller: _commandController,
                  decoration: const InputDecoration(
                    labelText: 'Command',
                    hintText: 'Enter Kiro command',
                    border: OutlineInputBorder(),
                  ),
                  enabled: kiroService.isConnected && !kiroService.isExecuting,
                ),
                
                const SizedBox(height: 16),
                
                // Execute Button
                ElevatedButton(
                  onPressed: kiroService.isConnected && 
                           !kiroService.isExecuting &&
                           _commandController.text.isNotEmpty
                      ? () => _executeCommand(context, kiroService)
                      : null,
                  child: kiroService.isExecuting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Execute Command'),
                ),
                
                const SizedBox(height: 16),
                
                // Error Display
                if (kiroService.lastError != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${kiroService.lastError}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Available Commands
                if (kiroService.availableCommands.isNotEmpty) ...[
                  Text(
                    'Available Commands:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: kiroService.availableCommands.length,
                      itemBuilder: (context, index) {
                        final command = kiroService.availableCommands[index];
                        return ListTile(
                          title: Text(command),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              _commandController.text = command;
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _executeCommand(
    BuildContext context, 
    KiroService kiroService,
  ) async {
    try {
      final response = await kiroService.executeCommand(
        _commandController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success 
                  ? 'Command executed successfully' 
                  : 'Command failed: ${response.error}',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

## Best Practices

### Error Handling

1. **Use Custom Exceptions**: Create specific exception types for different error scenarios
2. **Implement Retry Logic**: Retry transient errors with exponential backoff
3. **Validate Responses**: Always check response success status
4. **Handle Network Issues**: Gracefully handle network connectivity problems

### Performance Optimization

1. **Connection Pooling**: Reuse HTTP client instances
2. **Timeout Management**: Set appropriate timeouts for different operations
3. **Background Processing**: Use isolates for heavy processing
4. **Caching**: Cache frequently accessed data like available commands

### State Management

1. **Use ChangeNotifier**: For simple state management scenarios
2. **Provider Pattern**: Inject services using the Provider package
3. **Reactive Updates**: Update UI automatically when service state changes
4. **Proper Disposal**: Always dispose of resources in dispose() methods

## Testing

### Unit Tests

Create unit tests for your API client and service classes:

```dart
// test/services/kiro_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([KiroApiClient])
import 'kiro_service_test.mocks.dart';

void main() {
  group('KiroService', () {
    late MockKiroApiClient mockApiClient;
    late KiroService kiroService;

    setUp(() {
      mockApiClient = MockKiroApiClient();
      kiroService = KiroService(apiClient: mockApiClient);
    });

    tearDown(() {
      kiroService.dispose();
    });

    test('should initialize successfully with available status', () async {
      // Arrange
      final mockStatus = KiroStatusResponse(
        available: true,
        availableCommands: ['test.command'],
      );
      when(mockApiClient.getStatus()).thenAnswer((_) async => mockStatus);

      // Act
      await kiroService.initialize();

      // Assert
      expect(kiroService.isConnected, true);
      expect(kiroService.availableCommands, ['test.command']);
      expect(kiroService.lastError, null);
    });

    test('should handle initialization errors', () async {
      // Arrange
      when(mockApiClient.getStatus())
          .thenThrow(const KiroApiException(
            message: 'Connection failed',
            statusCode: 503,
          ));

      // Act
      await kiroService.initialize();

      // Assert
      expect(kiroService.isConnected, false);
      expect(kiroService.lastError, isNotNull);
    });
  });
}
```

### Integration Tests

Create integration tests to verify end-to-end functionality:

```dart
// integration_test/kiro_integration_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Kiro Integration Tests', () {
    testWidgets('should connect to Kiro and execute commands', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for connection
      await tester.pump(const Duration(seconds: 2));

      // Find and tap the command input
      final commandInput = find.byType(TextField);
      expect(commandInput, findsOneWidget);

      await tester.enterText(commandInput, 'workbench.action.showCommands');
      await tester.pump();

      // Find and tap execute button
      final executeButton = find.text('Execute Command');
      expect(executeButton, findsOneWidget);

      await tester.tap(executeButton);
      await tester.pump();

      // Wait for command execution
      await tester.pump(const Duration(seconds: 5));

      // Verify success message
      expect(find.text('Command executed successfully'), findsOneWidget);
    });
  });
}
```

## Troubleshooting

### Common Issues

1. **Connection Refused**: Ensure the Kiro Communication Bridge extension is running
2. **Timeout Errors**: Increase timeout values for slow operations
3. **Authentication Failures**: Verify API key configuration
4. **Command Not Found**: Check available commands using the status endpoint

### Debug Tips

1. **Enable Logging**: Add detailed logging to track API calls
2. **Use Network Inspector**: Monitor HTTP traffic during development
3. **Test Connectivity**: Implement health check functionality
4. **Validate Responses**: Always validate API response structure

## Next Steps

- **[Error Handling Guide](/docs/guides/error-handling)** - Advanced error handling patterns
- **[Polling Strategies](/docs/guides/polling-strategies)** - Monitor long-running operations
- **[API Reference](/docs/api/overview)** - Complete API documentation
- **[Troubleshooting](/docs/guides/troubleshooting)** - Common issues and solutions

import { SeeAlso, PageNavigation } from '@site/src/components/NavigationHelpers';

<SeeAlso
  title="Related Resources"
  links={[
    {
      to: '/docs/guides/error-handling',
      label: 'Error Handling',
      description: 'Advanced error handling patterns and best practices',
      icon: '🛠️'
    },
    {
      to: '/docs/api/endpoints/execute-command',
      label: 'Execute Command API',
      description: 'Detailed API reference for command execution',
      icon: '⚡'
    },
    {
      to: '/docs/guides/polling-strategies',
      label: 'Polling Strategies',
      description: 'Monitor long-running operations effectively',
      icon: '🔄'
    },
    {
      to: '/docs/guides/troubleshooting',
      label: 'Troubleshooting',
      description: 'Common issues and solutions',
      icon: '🐛'
    }
  ]}
/>

<PageNavigation
  previous={{
    to: '/docs/guides/quick-start',
    label: 'Quick Start Guide',
    description: 'Basic setup and first API calls'
  }}
  next={{
    to: '/docs/guides/error-handling',
    label: 'Error Handling',
    description: 'Learn robust error handling patterns'
  }}
/>