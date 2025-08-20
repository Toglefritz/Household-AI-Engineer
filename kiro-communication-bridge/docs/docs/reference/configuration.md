---
sidebar_position: 1
---

# Configuration Reference

Complete reference for configuring the Kiro Communication Bridge extension. All settings are configured through VS Code's settings system.

## API Server Configuration

### kiroOrchestration.api.port

**Type**: `number`  
**Default**: `3001`  
**Description**: Port number for the HTTP API server.

```json
{
  "kiroOrchestration.api.port": 3001
}
```

**Valid Range**: 1024-65535  
**Restart Required**: Yes

### kiroOrchestration.api.host

**Type**: `string`  
**Default**: `"localhost"`  
**Description**: Host address to bind the API server to.

```json
{
  "kiroOrchestration.api.host": "localhost"
}
```

**Valid Values**: 
- `"localhost"` - Local access only
- `"127.0.0.1"` - IPv4 localhost
- `"0.0.0.0"` - All interfaces (use with caution)

**Security Note**: Binding to `0.0.0.0` exposes the API to network access. Only use in secure environments.

### kiroOrchestration.api.apiKey

**Type**: `string`  
**Default**: `""` (empty, authentication disabled)  
**Description**: API key for authentication. Leave empty to disable authentication.

```json
{
  "kiroOrchestration.api.apiKey": "your-secret-api-key-here"
}
```

**Security Best Practices**:
- Use cryptographically secure random keys (32+ characters)
- Rotate keys regularly
- Don't commit keys to version control
- Use different keys for different environments

**Generate Secure Key**:
```bash
# Using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Using OpenSSL
openssl rand -hex 32
```

### kiroOrchestration.api.timeoutMs

**Type**: `number`  
**Default**: `30000` (30 seconds)  
**Description**: Request timeout in milliseconds.

```json
{
  "kiroOrchestration.api.timeoutMs": 30000
}
```

**Valid Range**: 1000-300000 (1 second to 5 minutes)  
**Use Cases**:
- Short timeout (5-10s): Quick commands, status checks
- Medium timeout (30-60s): Standard operations
- Long timeout (2-5min): Complex code generation

### kiroOrchestration.api.enableCors

**Type**: `boolean`  
**Default**: `true`  
**Description**: Enable Cross-Origin Resource Sharing (CORS) for web clients.

```json
{
  "kiroOrchestration.api.enableCors": true
}
```

**When to Disable**: Only disable if you're not using web-based clients and want stricter security.

## Kiro Integration Configuration

### kiroOrchestration.kiro.commandTimeoutMs

**Type**: `number`  
**Default**: `300000` (5 minutes)  
**Description**: Default timeout for Kiro command execution.

```json
{
  "kiroOrchestration.kiro.commandTimeoutMs": 300000
}
```

**Valid Range**: 5000-1800000 (5 seconds to 30 minutes)  
**Recommendations**:
- Simple commands: 30-60 seconds
- Code generation: 5-10 minutes
- Complex operations: 15-30 minutes

### kiroOrchestration.kiro.maxConcurrentCommands

**Type**: `number`  
**Default**: `3`  
**Description**: Maximum number of concurrent command executions.

```json
{
  "kiroOrchestration.kiro.maxConcurrentCommands": 3
}
```

**Valid Range**: 1-10  
**Performance Impact**:
- Higher values: More parallelism, higher resource usage
- Lower values: Less parallelism, more stable performance

### kiroOrchestration.kiro.statusCheckIntervalMs

**Type**: `number`  
**Default**: `5000` (5 seconds)  
**Description**: Interval for Kiro status checks in milliseconds.

```json
{
  "kiroOrchestration.kiro.statusCheckIntervalMs": 5000
}
```

**Valid Range**: 1000-60000 (1 second to 1 minute)  
**Trade-offs**:
- Shorter intervals: More responsive status updates, higher CPU usage
- Longer intervals: Less responsive, lower resource usage

### kiroOrchestration.kiro.statusCheckTimeoutMs

**Type**: `number`  
**Default**: `3000` (3 seconds)  
**Description**: Timeout for status check operations.

```json
{
  "kiroOrchestration.kiro.statusCheckTimeoutMs": 3000
}
```

**Valid Range**: 1000-30000 (1-30 seconds)  
**Should be less than**: `statusCheckIntervalMs`

### kiroOrchestration.kiro.failureThreshold

**Type**: `number`  
**Default**: `3`  
**Description**: Number of consecutive failures before marking Kiro as unavailable.

```json
{
  "kiroOrchestration.kiro.failureThreshold": 3
}
```

**Valid Range**: 1-10  
**Behavior**:
- Lower values: Faster failure detection, more sensitive to transient issues
- Higher values: More tolerant of temporary problems, slower failure detection

### kiroOrchestration.kiro.commandDiscoveryIntervalMs

**Type**: `number`  
**Default**: `30000` (30 seconds)  
**Description**: Interval for discovering available commands.

```json
{
  "kiroOrchestration.kiro.commandDiscoveryIntervalMs": 30000
}
```

**Valid Range**: 10000-300000 (10 seconds to 5 minutes)  
**Note**: Commands don't change frequently, so longer intervals are usually fine.

## User Input Configuration

### kiroOrchestration.userInput.defaultTimeoutMs

**Type**: `number`  
**Default**: `300000` (5 minutes)  
**Description**: Default timeout for user input requests.

```json
{
  "kiroOrchestration.userInput.defaultTimeoutMs": 300000
}
```

**Valid Range**: 30000-1800000 (30 seconds to 30 minutes)  
**Considerations**:
- Interactive applications: 1-5 minutes
- Automated systems: 30-60 seconds
- Manual processes: 10-30 minutes

### kiroOrchestration.userInput.maxPendingRequests

**Type**: `number`  
**Default**: `10`  
**Description**: Maximum number of pending input requests.

```json
{
  "kiroOrchestration.userInput.maxPendingRequests": 10
}
```

**Valid Range**: 1-100  
**Memory Impact**: Each pending request consumes memory until resolved or timed out.

## Logging Configuration

### kiroOrchestration.logging.enableDebugLogging

**Type**: `boolean`  
**Default**: `false`  
**Description**: Enable debug logging for all components.

```json
{
  "kiroOrchestration.logging.enableDebugLogging": false
}
```

**When to Enable**:
- Troubleshooting issues
- Development and testing
- Performance analysis

**Performance Impact**: Debug logging can impact performance and generate large log files.

## Configuration Profiles

### Development Profile

Optimized for development with detailed logging and shorter timeouts:

```json
{
  "kiroOrchestration.api.port": 3001,
  "kiroOrchestration.api.timeoutMs": 60000,
  "kiroOrchestration.kiro.commandTimeoutMs": 600000,
  "kiroOrchestration.kiro.statusCheckIntervalMs": 2000,
  "kiroOrchestration.logging.enableDebugLogging": true
}
```

### Production Profile

Optimized for stability and performance:

```json
{
  "kiroOrchestration.api.port": 3001,
  "kiroOrchestration.api.apiKey": "your-production-api-key",
  "kiroOrchestration.api.timeoutMs": 30000,
  "kiroOrchestration.kiro.commandTimeoutMs": 300000,
  "kiroOrchestration.kiro.maxConcurrentCommands": 2,
  "kiroOrchestration.kiro.statusCheckIntervalMs": 10000,
  "kiroOrchestration.logging.enableDebugLogging": false
}
```

### High-Performance Profile

Optimized for high-throughput scenarios:

```json
{
  "kiroOrchestration.api.timeoutMs": 15000,
  "kiroOrchestration.kiro.commandTimeoutMs": 120000,
  "kiroOrchestration.kiro.maxConcurrentCommands": 5,
  "kiroOrchestration.kiro.statusCheckIntervalMs": 1000,
  "kiroOrchestration.userInput.defaultTimeoutMs": 60000
}
```

### Low-Resource Profile

Optimized for systems with limited resources:

```json
{
  "kiroOrchestration.kiro.maxConcurrentCommands": 1,
  "kiroOrchestration.kiro.statusCheckIntervalMs": 15000,
  "kiroOrchestration.kiro.commandDiscoveryIntervalMs": 120000,
  "kiroOrchestration.userInput.maxPendingRequests": 3,
  "kiroOrchestration.logging.enableDebugLogging": false
}
```

## Environment-Specific Configuration

### Using VS Code Settings

#### User Settings (Global)
File: `~/.vscode/settings.json` or `%APPDATA%\Code\User\settings.json`

```json
{
  "kiroOrchestration.api.port": 3001,
  "kiroOrchestration.logging.enableDebugLogging": false
}
```

#### Workspace Settings (Project-Specific)
File: `.vscode/settings.json` in your project root

```json
{
  "kiroOrchestration.api.apiKey": "project-specific-key",
  "kiroOrchestration.kiro.commandTimeoutMs": 600000
}
```

### Configuration Precedence

1. **Workspace Settings** (highest priority)
2. **User Settings**
3. **Default Values** (lowest priority)

### Environment Variables

Some settings can be overridden with environment variables:

```bash
# Set API port via environment
export KIRO_API_PORT=3002

# Set API key via environment (more secure)
export KIRO_API_KEY="your-secret-key"

# Enable debug logging
export KIRO_DEBUG=true
```

## Validation and Constraints

### Port Validation

```typescript
function validatePort(port: number): boolean {
  return port >= 1024 && port <= 65535;
}
```

**Common Port Conflicts**:
- 3000: React development server
- 3001: Default Kiro Bridge port
- 8080: Common development server
- 8000: Python development server

### Timeout Validation

```typescript
function validateTimeout(timeoutMs: number): boolean {
  return timeoutMs >= 1000 && timeoutMs <= 1800000; // 1s to 30min
}
```

### API Key Validation

```typescript
function validateApiKey(key: string): boolean {
  return key.length >= 16 && /^[a-zA-Z0-9]+$/.test(key);
}
```

## Configuration Management

### Backup Configuration

```bash
# Backup VS Code settings
cp ~/.vscode/settings.json ~/.vscode/settings.json.backup

# Backup workspace settings
cp .vscode/settings.json .vscode/settings.json.backup
```

### Reset to Defaults

```json
{
  "kiroOrchestration.api.port": null,
  "kiroOrchestration.api.host": null,
  "kiroOrchestration.api.timeoutMs": null
}
```

Setting values to `null` resets them to defaults.

### Configuration Migration

When upgrading the extension, configuration is automatically migrated:

```typescript
// Example migration from v1.0 to v2.0
function migrateConfig(oldConfig: any): any {
  return {
    'kiroOrchestration.api.port': oldConfig['kiro.port'] || 3001,
    'kiroOrchestration.api.host': oldConfig['kiro.host'] || 'localhost',
    // ... other migrations
  };
}
```

## Troubleshooting Configuration

### Common Issues

**Port Already in Use**:
```bash
# Check what's using the port
lsof -i :3001  # macOS/Linux
netstat -an | findstr :3001  # Windows

# Solution: Change port or kill process
{
  "kiroOrchestration.api.port": 3002
}
```

**Invalid API Key Format**:
```json
// Incorrect
{
  "kiroOrchestration.api.apiKey": "key with spaces!"
}

// Correct
{
  "kiroOrchestration.api.apiKey": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
}
```

**Timeout Too Short**:
```json
// May cause timeouts for complex operations
{
  "kiroOrchestration.kiro.commandTimeoutMs": 5000
}

// Better for complex operations
{
  "kiroOrchestration.kiro.commandTimeoutMs": 300000
}
```

### Validation Commands

Use VS Code commands to validate configuration:

1. Open Command Palette (Ctrl+Shift+P)
2. Run: "Kiro Communication: Health Check Communication Servers"
3. Check Output panel for validation results

## Next Steps

- **[Deployment Guide](/docs/reference/deployment)** - Deploy in different environments
- **[Troubleshooting](/docs/guides/troubleshooting)** - Common configuration issues
- **[API Reference](/docs/api/overview)** - API behavior with different configurations
- **[Quick Start](/docs/guides/quick-start)** - Basic configuration setup