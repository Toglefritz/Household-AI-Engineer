part of 'conversation_service.dart';

/// A client for interacting with the local Kiro Bridge REST API.
///
/// The [KiroBridgeClient] is responsible for communicating with a local instance of the Kiro Bridge,
/// which serves as a backend for executing commands and workflows in the Kiro system. It provides
/// convenient methods to query the bridge status, execute commands via the `/api/kiro/execute` endpoint,
/// and provide user input to ongoing executions. This client abstracts away the HTTP communication,
/// headers, and endpoint details, allowing other parts of the application to easily interact with
/// Kiro Bridge using Dart objects and methods.
///
/// Typical usage involves creating an instance of [KiroBridgeClient], optionally providing a base URL,
/// API key, and a default workspace path. The client can then be used to check the bridge status,
/// execute commands (such as running tools or workflows), and respond to prompts for user input
/// when required by the execution flow.
///
/// This class is intended for use within the frontend of the application to facilitate
/// seamless integration with the local Kiro Bridge API.
class KiroBridgeClient {
  /// Creates an instance of [KiroBridgeClient].
  KiroBridgeClient({
    this.baseUrl = 'http://localhost:3001',
    this.apiKey,
    this.defaultWorkspacePath,
    Client? httpClient,
  }) : _http = httpClient ?? Client();

  /// The base URL of the Kiro Bridge REST API.
  ///
  /// Defaults to `'http://localhost:3001'`. You can override this to point to a different
  /// bridge instance if needed.
  final String baseUrl;

  /// The API key used for authenticating requests to the Kiro Bridge.
  ///
  /// If provided, the API key will be included as a Bearer token in the `Authorization` header
  /// for all requests. If `null`, no authentication header is sent.
  final String? apiKey;

  /// The default workspace path to be used for command executions.
  ///
  /// If a workspace path is not explicitly provided when executing a command,
  /// this value will be used as the workspace context for the operation.
  final String? defaultWorkspacePath;

  /// The underlying HTTP client used for sending requests to the Kiro Bridge API.
  ///
  /// This is an instance of [Client] from the `package:http` package. If no client is provided
  /// during construction, a new [Client] instance is created.
  final Client _http;

  Map<String, String> _headers() => <String, String>{
    'Content-Type': 'application/json',
    if (apiKey != null && apiKey!.trim().isNotEmpty) 'Authorization': 'Bearer $apiKey',
  };

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// GET /api/kiro/status
  Future<Map<String, Object?>> getStatus() async {
    final Response res = await _http.get(_uri('/api/kiro/status'), headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Status request failed: ${res.statusCode} ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, Object?>;
  }

  /// POST /api/kiro/execute with the given command
  Future<Map<String, Object?>> execute(KiroCommand command, {String? workspacePath}) async {
    final Map<String, Object?> payload = command.toJson(
      workspacePath: workspacePath ?? defaultWorkspacePath,
    );
    final Response res = await _http.post(
      _uri('/api/kiro/execute'),
      headers: _headers(),
      body: jsonEncode(payload),
    );

    final bool isJson = res.headers['content-type']?.contains('application/json') ?? false;
    if (!isJson) {
      throw Exception('Execute returned non-JSON content-type: ${res.headers['content-type']}');
    }
    final Map<String, Object?> body = jsonDecode(res.body) as Map<String, Object?>;
    if (res.statusCode != 200 || body['success'] == false) {
      final String code = (body['code'] ?? 'EXECUTE_ERROR').toString();
      final String msg = (body['message'] ?? 'Unknown error').toString();
      throw Exception('$code: $msg');
    }

    return body;
  }

  /// POST /api/kiro/input — convenience wrapper if the bridge exposes it.
  Future<Map<String, Object?>> provideUserInput({
    required String executionId,
    required String value,
    String type = 'text',
  }) async {
    final Response res = await _http.post(
      _uri('/api/kiro/input'),
      headers: _headers(),
      body: jsonEncode(<String, Object?>{
        'executionId': executionId,
        'value': value,
        'type': type,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Input failed: ${res.statusCode} ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, Object?>;
  }
}
