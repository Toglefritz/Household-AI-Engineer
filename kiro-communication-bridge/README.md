# Kiro Communication Bridge Extension

The Kiro Communication Bridge Extension is a VS Code extension that enables the Kiro IDE to function as a headless development environment for the Household Software Engineer system. It provides REST API and WebSocket endpoints that allow the Flutter frontend to orchestrate automated application development through Kiro's command system.

## Features

- **REST API Server**: Provides endpoints for application creation, job management, and status monitoring
- **WebSocket Server**: Enables real-time progress updates and job status notifications
- **Workspace Management**: Creates isolated workspaces for each application development job
- **Job Management**: Handles the lifecycle of development jobs including queuing, execution, and cleanup
- **Configuration Management**: Provides typed access to VS Code settings with validation and defaults

## Installation

1. Open VS Code
2. Install the extension from the VSIX file or marketplace
3. The extension will activate when:
   - VS Code startup is finished (if auto-start is enabled)
   - Any orchestration command is executed
   - A workspace contains application metadata files (`apps/**/metadata.json`)

## Activation

The extension uses efficient activation events instead of the performance-impacting `"*"` activation:

- `onStartupFinished` - Activates after VS Code has fully loaded
- `onCommand:*` - Activates when any orchestration command is executed
- `workspaceContains:**/apps/**/metadata.json` - Activates when opening a workspace with existing applications

By default, the orchestration servers start automatically when the extension activates. This can be controlled with the `kiroOrchestration.autoStart` setting.

## Configuration

The extension can be configured through VS Code settings under the `kiroOrchestration` namespace:

- `kiroOrchestration.api.port`: Port for the HTTP API server (default: 3001)
- `kiroOrchestration.api.host`: Host address to bind the API server to (default: localhost)
- `kiroOrchestration.websocket.port`: Port for the WebSocket server (default: 3002)
- `kiroOrchestration.workspace.appsDirectory`: Directory where application workspaces are created (default: ./apps)
- `kiroOrchestration.jobs.maxConcurrentJobs`: Maximum number of concurrent development jobs (default: 3)
- `kiroOrchestration.jobs.defaultTimeoutMs`: Default job timeout in milliseconds (default: 1800000)
- `kiroOrchestration.logging.level`: Logging level (default: info)
- `kiroOrchestration.autoStart`: Automatically start orchestration servers when the extension activates (default: true)

## Commands

The extension provides the following commands:

### Server Management
- `Kiro Communication: Restart Communication Servers` - Gracefully restarts both servers with automatic port conflict detection
- `Kiro Communication: Force Restart Communication Servers` - Forcefully restarts servers by killing any processes using the required ports
- `Kiro Communication: Health Check Communication Servers` - Verifies server health and responsiveness

### Kiro Integration
- `Kiro Communication: Get Kiro Status` - Shows the current status of Kiro IDE and the communication bridge
- `Kiro Communication: Execute Kiro Command` - Executes a command through Kiro IDE
- `Kiro Communication: Show Available Commands` - Displays available Kiro commands for selection

## Port Conflict Handling

The extension uses ports 3001 (API) and 3002 (WebSocket) by default. When port conflicts occur (e.g., multiple Kiro IDE windows or previous sessions not properly closed), the extension provides:

- **Automatic Detection**: Identifies processes using the required ports
- **Smart Resolution**: Attempts to gracefully terminate conflicting processes
- **User Prompts**: Offers clear options for resolving conflicts
- **Force Restart**: Option to forcefully kill conflicting processes when needed

For detailed information about port conflict handling, see [PORT-CONFLICT-HANDLING.md](./PORT-CONFLICT-HANDLING.md).
- `Kiro Orchestration: View Server Status` - Shows the current status of all services
- `Kiro Orchestration: View Active Jobs` - Displays information about active development jobs
- `Kiro Orchestration: Open Apps Directory` - Opens the configured apps directory

## Development

To build and test the extension:

1. Clone the repository
2. Navigate to the `kiro-orchestration-extension` directory
3. Run `npm install` to install dependencies
4. Run `npm run compile` to build the extension
5. Press F5 in VS Code to launch a new Extension Development Host window

## Architecture

The extension follows a modular architecture with the following components:

- **Extension State**: Central state management and lifecycle coordination
- **Configuration Manager**: Handles loading and validation of extension settings
- **API Server**: Provides REST endpoints for frontend communication
- **WebSocket Server**: Manages real-time communication with clients
- **Job Manager**: Orchestrates application development jobs
- **Workspace Manager**: Handles creation and management of application workspaces

## Version

Current version: 0.1.0

This is an initial implementation with basic infrastructure. Full functionality will be implemented in subsequent tasks.