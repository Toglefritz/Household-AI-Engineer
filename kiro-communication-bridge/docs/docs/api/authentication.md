---
sidebar_position: 2
---

# Authentication

The Kiro Communication Bridge API supports optional API key authentication to secure access to the bridge functionality. Authentication is disabled by default but can be enabled through VS Code configuration.

## Configuration

### Enable Authentication

To enable API key authentication, configure the API key in VS Code settings:

1. Open VS Code Settings (Cmd/Ctrl + ,)
2. Search for "kiro orchestration"
3. Set `Kiro Orchestration › Api: Api Key` to your desired key

Or edit your VS Code `settings.json`:

```json
{
  "kiroOrchestration.api.apiKey": "your-secret-api-key-here"
}
```

### Generate Secure API Keys

For production use, generate a cryptographically secure API key:

```bash
# Using Node.js crypto
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Using OpenSSL
openssl rand -hex 32

# Using Python
python -c "import secrets; print(secrets.token_hex(32))"
```

## Authentication Methods

When authentication is enabled, you can authenticate using either method:

### Header-Based Authentication (Recommended)

Include the API key in the `Authorization` header:

```bash
curl -H "Authorization: Bearer your-secret-api-key" \
     http://localhost:3001/api/kiro/status
```

### Query Parameter Authentication

Include the API key as a query parameter:

```bash
curl "http://localhost:3001/api/kiro/status?apiKey=your-secret-api-key"
```

:::warning Security Note
Query parameter authentication exposes the API key in URLs, which may be logged by proxies, web servers, or browser history. Use header-based authentication for better security.
:::

## Client Implementation Examples

### TypeScript/JavaScript

```typescript
class KiroBridgeClient {
  private readonly baseUrl: string;
  private readonly apiKey?: string;

  constructor(baseUrl: string = 'http://localhost:3001', apiKey?: string) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }

  private getHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (this.apiKey) {
      headers['Authorization'] = `Bearer ${this.apiKey}`;
    }

    return headers;
  }

  async getStatus(): Promise<KiroStatusResponse> {
    const response = await fetch(`${this.baseUrl}/api/kiro/status`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  }

  async executeCommand(command: string, args?: string[]): Promise<ExecuteCommandResponse> {
    const response = await fetch(`${this.baseUrl}/api/kiro/execute`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify({ command, args }),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  }
}

// Usage
const client = new KiroBridgeClient('http://localhost:3001', 'your-api-key');
const status = await client.getStatus();
```

### Dart/Flutter

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class KiroBridgeClient {
  final String baseUrl;
  final String? apiKey;

  KiroBridgeClient({
    this.baseUrl = 'http://localhost:3001',
    this.apiKey,
  });

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (apiKey != null) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    return headers;
  }

  Future<Map<String, dynamic>> getStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/kiro/status'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> executeCommand(
    String command, {
    List<String>? args,
  }) async {
    final body = <String, dynamic>{
      'command': command,
      if (args != null) 'args': args,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/kiro/execute'),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
}

// Usage
final client = KiroBridgeClient(apiKey: 'your-api-key');
final status = await client.getStatus();
```

### cURL Examples

```bash
# Get status with authentication
curl -H "Authorization: Bearer your-api-key" \
     http://localhost:3001/api/kiro/status

# Execute command with authentication
curl -X POST \
     -H "Authorization: Bearer your-api-key" \
     -H "Content-Type: application/json" \
     -d '{"command": "workbench.action.showCommands"}' \
     http://localhost:3001/api/kiro/execute

# Health check (no authentication required)
curl http://localhost:3001/health
```

## Error Responses

### Missing API Key

When authentication is enabled but no API key is provided:

```json
{
  "error": "Unauthorized",
  "message": "Valid API key required"
}
```

**HTTP Status:** `401 Unauthorized`

### Invalid API Key

When an incorrect API key is provided:

```json
{
  "error": "Unauthorized", 
  "message": "Valid API key required"
}
```

**HTTP Status:** `401 Unauthorized`

## Security Best Practices

### API Key Management

1. **Use Environment Variables**: Store API keys in environment variables, not in source code
2. **Rotate Keys Regularly**: Change API keys periodically for better security
3. **Limit Scope**: Use different API keys for different environments (dev, staging, prod)
4. **Monitor Usage**: Log API key usage to detect unauthorized access

### Network Security

1. **Use HTTPS**: In production, ensure the API server uses HTTPS
2. **Network Isolation**: Run the API server on a private network when possible
3. **Firewall Rules**: Restrict access to the API port to authorized clients only

### Client-Side Security

1. **Secure Storage**: Store API keys securely on client devices
2. **Key Rotation**: Implement automatic key rotation in client applications
3. **Error Handling**: Don't expose API keys in error messages or logs

## Troubleshooting

### Common Issues

**Problem**: Getting 401 Unauthorized despite setting API key
- **Solution**: Verify the API key is correctly configured in VS Code settings
- **Check**: Restart VS Code after changing the API key setting

**Problem**: API key not working after VS Code restart
- **Solution**: Check VS Code settings are saved correctly
- **Check**: Verify the extension is properly loaded and active

**Problem**: Authentication works in development but not production
- **Solution**: Ensure API key is properly configured in production environment
- **Check**: Verify network connectivity and firewall rules

## Next Steps

- **[Execute Commands](/docs/api/endpoints/execute-command)** - Learn to execute Kiro commands
- **[Error Handling](/docs/guides/error-handling)** - Handle authentication errors gracefully
- **[Flutter Setup](/docs/guides/flutter-setup)** - Integrate authentication in Flutter apps