---
sidebar_position: 5
---

# Troubleshooting Guide

Common issues and solutions for the Kiro Communication Bridge API. This guide helps you diagnose and resolve problems quickly.

## Quick Diagnostics

### Health Check Checklist

Run through this checklist to identify issues:

```bash
# 1. Check if API server is running
curl http://localhost:3001/health

# 2. Check Kiro status
curl http://localhost:3001/api/kiro/status

# 3. Test simple command
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "workbench.action.showCommands"}'
```

### Expected Responses

**Healthy Server**:
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

**Kiro Ready**:
```json
{
  "status": "ready",
  "version": "1.85.0",
  "availableCommands": ["workbench.action.showCommands", "..."],
  "timestamp": "2025-01-19T10:30:00Z"
}
```

## Common Issues

### 1. Connection Refused

**Symptoms**:
- `curl: (7) Failed to connect to localhost port 3001: Connection refused`
- Network errors in client applications
- "Server not responding" messages

**Causes & Solutions**:

#### Extension Not Started
```bash
# Check VS Code extensions
code --list-extensions | grep kiro-communication-bridge
```

**Solution**: Install and activate the extension:
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "Kiro Communication Bridge"
4. Install and enable the extension

#### Server Not Running
**Solution**: Start the server manually:
1. Open Command Palette (Ctrl+Shift+P)
2. Run: "Kiro Communication: Restart Communication Servers"

#### Port Conflict
**Check port usage**:
```bash
# macOS/Linux
lsof -i :3001

# Windows
netstat -an | findstr :3001
```

**Solution**: Change port in VS Code settings:
```json
{
  "kiroOrchestration.api.port": 3002
}
```

### 2. Kiro Unavailable

**Symptoms**:
- Status shows `"status": "unavailable"`
- Commands fail with "Kiro IDE not available"
- Empty `availableCommands` array

**Diagnostic Steps**:

```bash
# Check Kiro status
curl http://localhost:3001/api/kiro/status

# Look for this response
{
  "status": "unavailable",
  "availableCommands": [],
  "timestamp": "2025-01-19T10:30:00Z"
}
```

**Solutions**:

#### Kiro Not Installed
1. Install Kiro IDE from the official website
2. Ensure Kiro is in your system PATH
3. Restart VS Code after installation

#### Kiro Not Running
1. Start Kiro IDE
2. Ensure Kiro extension is enabled in VS Code
3. Check VS Code Output panel for Kiro logs

#### Extension Communication Issues
1. Restart VS Code completely
2. Disable and re-enable the Kiro Communication Bridge extension
3. Check VS Code settings for Kiro configuration

### 3. Authentication Errors

**Symptoms**:
- HTTP 401 Unauthorized responses
- "Valid API key required" messages
- Authentication failures in client apps

**Diagnostic**:
```bash
# Test without API key
curl http://localhost:3001/api/kiro/status

# Test with API key
curl -H "Authorization: Bearer your-api-key" \
     http://localhost:3001/api/kiro/status
```

**Solutions**:

#### API Key Not Set
Check VS Code settings:
```json
{
  "kiroOrchestration.api.apiKey": "your-api-key-here"
}
```

#### Invalid API Key Format
Ensure proper header format:
```bash
# Correct format
Authorization: Bearer your-api-key

# Incorrect formats
Authorization: your-api-key
Authorization: API-Key your-api-key
```

#### API Key Mismatch
1. Generate a new API key
2. Update VS Code settings
3. Restart VS Code
4. Update client applications with new key

### 4. Command Execution Failures

**Symptoms**:
- Commands return `"success": false`
- Timeout errors
- "Command not found" messages

**Diagnostic**:
```bash
# Check available commands
curl http://localhost:3001/api/kiro/status | jq '.availableCommands'

# Test specific command
curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "workbench.action.showCommands"}'
```

**Solutions**:

#### Invalid Command Name
1. Check spelling of command name
2. Verify command is in `availableCommands` list
3. Use exact command identifier from the list

#### Command Arguments Issues
```bash
# Correct argument format
{
  "command": "vscode.open",
  "args": ["file:///path/to/file.txt"]
}

# Incorrect - args should be array of strings
{
  "command": "vscode.open",
  "args": "file:///path/to/file.txt"
}
```

#### Workspace Context Problems
```bash
# Provide workspace path for context-sensitive commands
{
  "command": "kiro.generateCode",
  "args": ["Create a login form"],
  "workspacePath": "/path/to/project"
}
```

### 5. Timeout Issues

**Symptoms**:
- HTTP 408 Request Timeout
- "Operation timed out" messages
- Long-running commands fail

**Solutions**:

#### Increase Timeout
Update VS Code settings:
```json
{
  "kiroOrchestration.api.timeoutMs": 60000,
  "kiroOrchestration.kiro.commandTimeoutMs": 600000
}
```

#### Client-Side Timeout
```typescript
// Increase client timeout
const response = await fetch('/api/kiro/execute', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(request),
  signal: AbortSignal.timeout(60000) // 60 seconds
});
```

#### Break Down Complex Commands
Instead of one complex command, use multiple simpler commands:
```bash
# Instead of complex generation
{"command": "kiro.generateCompleteApp", "args": ["complex requirements"]}

# Use step-by-step approach
{"command": "kiro.generateStructure", "args": ["basic structure"]}
{"command": "kiro.generateComponents", "args": ["user interface"]}
{"command": "kiro.generateLogic", "args": ["business logic"]}
```## Plat
form-Specific Issues

### macOS Issues

#### Port Permission Issues
```bash
# Check if port requires sudo
sudo lsof -i :3001

# Solution: Use port > 1024
{
  "kiroOrchestration.api.port": 3001
}
```

#### Firewall Blocking
```bash
# Check firewall status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Allow VS Code through firewall
System Preferences > Security & Privacy > Firewall > Firewall Options
```

#### Gatekeeper Issues
```bash
# If Kiro is blocked by Gatekeeper
sudo spctl --master-disable  # Temporarily disable
# Or right-click Kiro app > Open
```

### Windows Issues

#### Windows Defender
1. Open Windows Security
2. Go to Virus & threat protection
3. Add exclusion for VS Code and Kiro directories

#### Port Conflicts with IIS
```cmd
# Check IIS usage
netstat -an | findstr :3001

# Stop IIS if needed
iisreset /stop
```

#### PowerShell Execution Policy
```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Linux Issues

#### Permission Denied
```bash
# Check port permissions
sudo netstat -tlnp | grep :3001

# Use unprivileged port
{
  "kiroOrchestration.api.port": 3001
}
```

#### SELinux Issues
```bash
# Check SELinux status
sestatus

# Temporarily disable if needed
sudo setenforce 0
```

## Network Troubleshooting

### Proxy Issues

#### Corporate Proxy
```bash
# Check proxy settings
echo $HTTP_PROXY
echo $HTTPS_PROXY

# Configure VS Code proxy
{
  "http.proxy": "http://proxy.company.com:8080",
  "http.proxyStrictSSL": false
}
```

#### Bypass Proxy for Localhost
```json
{
  "http.noProxy": "localhost,127.0.0.1"
}
```

### DNS Resolution
```bash
# Test DNS resolution
nslookup localhost
ping localhost

# Use IP address if DNS fails
curl http://127.0.0.1:3001/health
```

### Network Interface Issues
```bash
# Check network interfaces
ifconfig  # macOS/Linux
ipconfig  # Windows

# Bind to specific interface
{
  "kiroOrchestration.api.host": "127.0.0.1"
}
```

## Performance Issues

### High CPU Usage

**Symptoms**:
- VS Code becomes unresponsive
- System fans running high
- Slow API responses

**Solutions**:

#### Reduce Polling Frequency
```typescript
// Increase polling intervals
const poller = new AdaptivePoller({
  readyInterval: 30000,    // 30 seconds instead of 10
  busyInterval: 5000,      // 5 seconds instead of 2
  unavailableInterval: 60000 // 1 minute instead of 30 seconds
});
```

#### Limit Concurrent Commands
```json
{
  "kiroOrchestration.kiro.maxConcurrentCommands": 1
}
```

#### Disable Debug Logging
```json
{
  "kiroOrchestration.logging.enableDebugLogging": false
}
```

### Memory Leaks

**Symptoms**:
- VS Code memory usage grows over time
- System becomes slow after extended use
- Out of memory errors

**Solutions**:

#### Restart Extension Periodically
```bash
# Command Palette
"Kiro Communication: Restart Communication Servers"
```

#### Clear Command History
```typescript
// Limit history size in client applications
class CommandHistory {
  private maxSize = 50; // Limit to 50 entries
  
  addCommand(command: CommandHistoryEntry) {
    this.history.unshift(command);
    if (this.history.length > this.maxSize) {
      this.history = this.history.slice(0, this.maxSize);
    }
  }
}
```

#### Monitor Memory Usage
```bash
# Check VS Code memory usage
ps aux | grep "Visual Studio Code"

# Monitor over time
while true; do
  ps aux | grep "Visual Studio Code" | awk '{print $6}'
  sleep 60
done
```

## Debugging Tools

### VS Code Output Panel

1. Open Output panel (View > Output)
2. Select "Kiro Communication Bridge" from dropdown
3. Look for error messages and warnings

**Common Log Messages**:
```
[INFO] API server started on localhost:3001
[ERROR] Failed to execute command: Command not found
[WARN] Kiro status check failed, retrying...
[DEBUG] Command executed successfully in 1250ms
```

### Browser Developer Tools

For web-based clients:

1. Open Developer Tools (F12)
2. Go to Network tab
3. Monitor API requests and responses
4. Check Console for JavaScript errors

### Command Line Testing

#### Test API Endpoints
```bash
# Health check
curl -v http://localhost:3001/health

# Status with verbose output
curl -v http://localhost:3001/api/kiro/status

# Command execution with timing
time curl -X POST http://localhost:3001/api/kiro/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "workbench.action.showCommands"}'
```

#### JSON Validation
```bash
# Validate JSON request
echo '{"command": "test"}' | jq .

# Pretty print response
curl http://localhost:3001/api/kiro/status | jq .
```

### Log Analysis

#### Enable Debug Logging
```json
{
  "kiroOrchestration.logging.enableDebugLogging": true
}
```

#### Log File Locations
- **VS Code Logs**: Help > Toggle Developer Tools > Console
- **Extension Logs**: Output panel > Kiro Communication Bridge
- **System Logs**: 
  - macOS: Console.app
  - Windows: Event Viewer
  - Linux: journalctl or /var/log/

## Recovery Procedures

### Complete Reset

If all else fails, perform a complete reset:

1. **Stop all processes**:
   ```bash
   # Kill any processes using port 3001
   lsof -ti:3001 | xargs kill -9  # macOS/Linux
   ```

2. **Reset VS Code settings**:
   ```json
   {
     "kiroOrchestration.api.port": 3001,
     "kiroOrchestration.api.host": "localhost",
     "kiroOrchestration.api.enableCors": true,
     "kiroOrchestration.api.timeoutMs": 30000
   }
   ```

3. **Restart VS Code completely**

4. **Reinstall extension** (if needed):
   - Uninstall Kiro Communication Bridge
   - Restart VS Code
   - Reinstall extension

### Emergency Fallback

If the API is completely unavailable, use direct VS Code commands:

```typescript
// Fallback to direct VS Code API
if (!await isKiroApiAvailable()) {
  // Use VS Code extension API directly
  await vscode.commands.executeCommand('workbench.action.showCommands');
}
```

## Getting Help

### Information to Collect

When reporting issues, include:

1. **System Information**:
   ```bash
   # Operating system and version
   uname -a  # macOS/Linux
   systeminfo  # Windows
   
   # VS Code version
   code --version
   
   # Extension version
   code --list-extensions --show-versions | grep kiro
   ```

2. **Error Messages**:
   - Complete error messages from API responses
   - VS Code Output panel logs
   - Browser console errors (for web clients)

3. **Configuration**:
   ```json
   // VS Code settings (remove sensitive data like API keys)
   {
     "kiroOrchestration.api.port": 3001,
     "kiroOrchestration.api.host": "localhost"
   }
   ```

4. **Reproduction Steps**:
   - Exact steps to reproduce the issue
   - Expected vs actual behavior
   - Frequency of occurrence

### Support Channels

1. **GitHub Issues**: [Report bugs and feature requests](https://github.com/Toglefritz/Household-AI-Engineer/issues)
2. **GitHub Discussions**: [Ask questions and get help](https://github.com/Toglefritz/Household-AI-Engineer/discussions)
3. **Documentation**: [Check latest documentation](https://toglefritz.github.io/Household-AI-Engineer/docs/intro)

### Before Reporting

1. **Search existing issues** for similar problems
2. **Try the latest version** of the extension
3. **Test with minimal configuration** to isolate the issue
4. **Reproduce the issue** consistently

## Prevention Tips

### Regular Maintenance

1. **Keep extensions updated**
2. **Restart VS Code periodically**
3. **Monitor system resources**
4. **Clear logs and cache regularly**

### Best Practices

1. **Use appropriate timeouts** for your use case
2. **Implement proper error handling** in client applications
3. **Monitor API health** proactively
4. **Test changes in development** before production

### Monitoring Setup

```typescript
// Simple health monitoring
setInterval(async () => {
  try {
    const response = await fetch('http://localhost:3001/health');
    if (!response.ok) {
      console.warn('API health check failed:', response.status);
    }
  } catch (error) {
    console.error('API health check error:', error);
  }
}, 60000); // Check every minute
```

## Next Steps

- **[Error Handling Guide](/docs/guides/error-handling)** - Implement robust error handling
- **[API Reference](/docs/api/overview)** - Complete API documentation
- **[Quick Start Guide](/docs/guides/quick-start)** - Basic setup and usage
- **[Flutter Integration](/docs/guides/flutter-setup)** - Flutter-specific guidance