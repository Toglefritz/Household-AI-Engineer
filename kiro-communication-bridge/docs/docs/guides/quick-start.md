---
sidebar_position: 1
---

# Quick Start Guide

Get up and running with the Kiro Communication Bridge API in just a few minutes. This guide will walk you through installation, configuration, and making your first API call.

## Prerequisites

Before you begin, ensure you have:

- **VS Code** installed (version 1.74.0 or higher)
- **Kiro IDE** installed and configured
- **Node.js** (for testing with curl/JavaScript examples)
- **Basic knowledge** of REST APIs and HTTP requests

## Step 1: Install the Extension

### From VS Code Marketplace

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for "Kiro Communication Bridge"
4. Click "Install"

### From VSIX File

If you have the VSIX file:

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Click the "..." menu and select "Install from VSIX..."
4. Select the `kiro-communication-bridge-*.vsix` file

## Step 2: Configure the Extension

### Basic Configuration

The extension works with default settings, but you can customize it:

1. Open VS Code Settings (Ctrl+, / Cmd+,)
2. Search for "kiro orchestration"
3. Configure the following settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `kiroOrchestration.api.port` | `3001` | API server port |
| `kiroOrchestration.api.host` | `localhost` | API server host |
| `kiroOrchestration.api.enableCors` | `true` | Enable CORS for web clients |
| `kiroOrchestration.api.timeoutMs` | `30000` | Request timeout (30 seconds) |

### Optional: Enable Authentication

For production use, enable API key authentication:

1. Generate a secure API key:
   ```bash
   # Using Node.js
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   
   # Using OpenSSL
   openssl rand -hex 32
   ```

2. Set the API key in VS Code settings:
   ```json
   {
     "kiroOrchestration.api.apiKey": "your-generated-api-key-here"
   }
   ```

## Step 3: Start the API Server

### Automatic Startup (Default)

The API server starts automatically when VS Code loads. You should see a notification:

> "Kiro Communication Bridge Extension activated successfully!"

### Manual Startup

If auto-start is disabled, start the server manually:

1. Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
2. Run: "Kiro Communication: Restart Communication Servers"

### Verify Server Status

Check if the server is running:

```bash
curl http://localhost:3001/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-19T10:30:00Z",
  "server": {
    "running": true,
    "port": 3001,
    "host": "localhost",
    "uptime": 120
  }
}
```

## Step 4: Make Your First API Call

### Check Kiro Status

First, verify that Kiro is available:

```bash
curl http://localhost:3001/api/kiro/status
```

Expected response:
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

### Execute a Simple Command

Execute your first Kiro command:

```bash
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "workbench.action.showCommands"
  }'
```

Expected response:
```json
{
  "success": true,
  "output": "Command palette opened",
  "executionTimeMs": 150
}
```

### Execute a Command with Arguments

Try a more complex command:

```bash
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{
    "command": "vscode.open",
    "args": ["file:///path/to/your/file.txt"]
  }'
```

## Step 5: Test with Authentication (Optional)

If you enabled API key authentication, include it in your requests:

```bash
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key-here" \
  -d '{
    "command": "workbench.action.showCommands"
  }'
```

## Step 6: Build a Simple Client

### JavaScript/Node.js Client

Create a simple Node.js client:

```javascript
// kiro-client.js
const fetch = require('node-fetch'); // npm install node-fetch

class KiroClient {
  constructor(baseUrl = 'http://localhost:3001', apiKey = null) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }

  async getStatus() {
    const headers = {};
    if (this.apiKey) {
      headers['Authorization'] = `Bearer ${this.apiKey}`;
    }

    const response = await fetch(`${this.baseUrl}/api/kiro/status`, {
      headers
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json();
  }

  async executeCommand(command, args = []) {
    const headers = {
      'Content-Type': 'application/json'
    };
    
    if (this.apiKey) {
      headers['Authorization'] = `Bearer ${this.apiKey}`;
    }

    const response = await fetch(`${this.baseUrl}/api/kiro/execute`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ command, args })
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json();
  }
}

// Usage example
async function main() {
  const client = new KiroClient();

  try {
    // Check status
    const status = await client.getStatus();
    console.log('Kiro status:', status.status);
    console.log('Available commands:', status.availableCommands.length);

    // Execute command
    const result = await client.executeCommand('workbench.action.showCommands');
    console.log('Command result:', result.success ? 'Success' : 'Failed');
    console.log('Output:', result.output);
    console.log('Execution time:', result.executionTimeMs, 'ms');

  } catch (error) {
    console.error('Error:', error.message);
  }
}

main();
```

Run the client:
```bash
npm install node-fetch
node kiro-client.js
```

### Python Client

Create a Python client:

```python
# kiro_client.py
import requests
import json

class KiroClient:
    def __init__(self, base_url='http://localhost:3001', api_key=None):
        self.base_url = base_url
        self.api_key = api_key

    def _get_headers(self):
        headers = {'Content-Type': 'application/json'}
        if self.api_key:
            headers['Authorization'] = f'Bearer {self.api_key}'
        return headers

    def get_status(self):
        response = requests.get(
            f'{self.base_url}/api/kiro/status',
            headers=self._get_headers()
        )
        response.raise_for_status()
        return response.json()

    def execute_command(self, command, args=None):
        if args is None:
            args = []
        
        payload = {
            'command': command,
            'args': args
        }
        
        response = requests.post(
            f'{self.base_url}/api/kiro/execute',
            headers=self._get_headers(),
            json=payload
        )
        response.raise_for_status()
        return response.json()

# Usage example
def main():
    client = KiroClient()

    try:
        # Check status
        status = client.get_status()
        print(f"Kiro status: {status['status']}")
        print(f"Available commands: {len(status['availableCommands'])}")

        # Execute command
        result = client.execute_command('workbench.action.showCommands')
        print(f"Command result: {'Success' if result['success'] else 'Failed'}")
        print(f"Output: {result['output']}")
        print(f"Execution time: {result['executionTimeMs']} ms")

    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    main()
```

Run the client:
```bash
pip install requests
python kiro_client.py
```

## Common Issues and Solutions

### Server Not Starting

**Problem**: API server doesn't start automatically

**Solutions**:
1. Check VS Code output panel for errors
2. Manually restart: Command Palette → "Kiro Communication: Restart Communication Servers"
3. Check port availability: `netstat -an | grep 3001`

### Port Already in Use

**Problem**: Error "EADDRINUSE: address already in use"

**Solutions**:
1. Use "Force Restart Communication Servers" command
2. Change port in settings: `kiroOrchestration.api.port`
3. Kill process using port: `lsof -ti:3001 | xargs kill -9` (macOS/Linux)

### Kiro Unavailable

**Problem**: Status shows "unavailable"

**Solutions**:
1. Ensure Kiro IDE is installed and running
2. Check Kiro extension is enabled in VS Code
3. Restart VS Code completely

### Authentication Errors

**Problem**: Getting 401 Unauthorized errors

**Solutions**:
1. Verify API key is set correctly in VS Code settings
2. Check API key format in Authorization header
3. Restart VS Code after changing API key

### Command Execution Fails

**Problem**: Commands return success: false

**Solutions**:
1. Check command name spelling
2. Verify command is in availableCommands list
3. Check command arguments format
4. Review error message in response

## Next Steps

Now that you have the basics working, explore more advanced features:

- **[Flutter Integration](/docs/guides/flutter-setup)** - Build Flutter apps with the API
- **[Error Handling](/docs/guides/error-handling)** - Implement robust error handling
- **[Polling Strategies](/docs/guides/polling-strategies)** - Monitor long-running operations
- **[API Reference](/docs/api/overview)** - Explore all available endpoints

## Getting Help

If you encounter issues:

1. **Check the logs**: VS Code Output panel → "Kiro Communication Bridge"
2. **Review documentation**: [API Reference](/docs/api/overview)
3. **Search issues**: [GitHub Issues](https://github.com/Toglefritz/Household-AI-Engineer/issues)
4. **Ask for help**: [GitHub Discussions](https://github.com/Toglefritz/Household-AI-Engineer/discussions)

## Example Projects

Check out these example projects to see the API in action:

- **[Simple Node.js Client](https://github.com/Toglefritz/Household-AI-Engineer/tree/main/examples/nodejs-client)**
- **[Python Integration](https://github.com/Toglefritz/Household-AI-Engineer/tree/main/examples/python-client)**
- **[Flutter Dashboard](https://github.com/Toglefritz/Household-AI-Engineer/tree/main/examples/flutter-dashboard)**

Happy coding! 🚀