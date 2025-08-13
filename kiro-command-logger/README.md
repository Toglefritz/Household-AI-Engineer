# Kiro Command Logger

A VS Code extension that discovers and analyzes Kiro IDE's programmatic interface by cataloging available `kiroAgent` and `kiro` commands for headless automation research.

## Project Context

This extension is a critical component of the **Household AI Engineer** project, which aims to create a seamless user experience where:

1. **Frontend**: A Flutter mobile/desktop app provides the primary user interface
2. **Orchestration Layer**: A backend service coordinates between the frontend and Kiro IDE
3. **Kiro IDE**: Runs headlessly in the background, driven programmatically to perform AI-assisted development tasks

The ultimate goal is to enable users to interact with AI development capabilities through a polished frontend interface, while Kiro IDE operates invisibly in the background, executing development tasks through programmatic commands.

## Research Purpose

This extension exists to **reverse-engineer Kiro IDE's programmatic interface** by:

- Discovering all available `kiroAgent.*` and `kiro.*` commands that can be invoked programmatically
- Categorizing these commands by functionality (chat, file operations, workspace management, etc.)
- Understanding the command structure and parameters for headless automation
- Providing documentation for building the orchestration layer that will drive Kiro programmatically

The research conducted with this extension will inform the design of the orchestration service that bridges the Flutter frontend and Kiro IDE backend.

## Features

- **kiroAgent Command Discovery**: Automatically discovers all commands prefixed with `kiroAgent.`
- **Functional Categorization**: Groups commands by purpose (chat, file operations, workspace, UI, etc.)
- **Detailed Analysis**: Provides structured analysis of Kiro's programmatic interface
- **Research Documentation**: Generates comprehensive logs for building headless automation
- **Zero Configuration**: Works immediately after installation with no setup required

## Installation

### Local Development Installation

1. Clone or copy the extension files to a local directory
2. Open the extension directory in VS Code
3. Press `F5` to launch a new Extension Development Host window
4. The extension will be automatically loaded and activated

### Manual Installation

1. Copy the extension directory to your VS Code extensions folder:
   - **Windows**: `%USERPROFILE%\.vscode\extensions\`
   - **macOS**: `~/.vscode/extensions/`
   - **Linux**: `~/.vscode/extensions/`
2. Restart VS Code
3. The extension will activate automatically

## Usage

1. **Automatic Activation**: The extension activates automatically when Kiro IDE starts
2. **View Analysis**: Open the Output panel (`View > Output`) and select "Kiro Command Logger" from the dropdown
3. **Command Discovery**: The extension will immediately scan for and log all `kiroAgent` commands
4. **Periodic Updates**: Every 30 seconds, the extension rescans for new commands

### Example Output

```
2025-01-10T14:30:15.123Z [STATUS] Starting command discovery...
2025-01-10T14:30:15.124Z [STATUS] Found 1247 total registered commands
2025-01-10T14:30:15.125Z [STATUS] Found 23 kiroAgent commands:
2025-01-10T14:30:15.126Z [STATUS]   1. kiroAgent.chat.sendMessage
2025-01-10T14:30:15.127Z [STATUS]   2. kiroAgent.conversation.start
2025-01-10T14:30:15.128Z [STATUS]   3. kiroAgent.file.create
2025-01-10T14:30:15.129Z [STATUS]   4. kiroAgent.workspace.analyze

=== KIRO AGENT COMMAND ANALYSIS ===
Total kiroAgent commands: 23

Commands by functionality:
  CHAT: 5 commands
    - sendMessage (kiroAgent.chat.sendMessage)
    - clearHistory (kiroAgent.chat.clearHistory)
    - exportConversation (kiroAgent.chat.exportConversation)
  
  FILE: 8 commands
    - create (kiroAgent.file.create)
    - modify (kiroAgent.file.modify)
    - delete (kiroAgent.file.delete)
    
=== END KIRO AGENT ANALYSIS ===
```

## Command Categories

The extension categorizes `kiroAgent` commands into functional groups:

- **CHAT**: Chat interface and messaging commands
  - Message sending, conversation management, history operations
- **CONVERSATION**: Dialog and conversation flow control
  - Starting/stopping conversations, context management
- **FILE**: File and document operations
  - Creating, modifying, deleting files programmatically
- **EDITOR**: Text editing and manipulation commands
  - Inserting text, cursor positioning, selection management
- **WORKSPACE**: Project and workspace management
  - Opening projects, analyzing codebases, workspace configuration
- **UI**: User interface and panel management
  - Showing/hiding panels, managing views, UI state control
- **SETTINGS**: Configuration and preferences
  - Kiro settings, user preferences, extension configuration
- **OTHER**: Uncategorized or specialized commands

## Architecture Integration

This extension fits into the larger Household AI Engineer architecture:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Orchestration   │    │   Kiro IDE      │
│   (Frontend)    │◄──►│     Layer        │◄──►│  (Headless)     │
│                 │    │                  │    │                 │
│ User Interface  │    │ Command Mapping  │    │ AI Development  │
│ Mobile/Desktop  │    │ State Management │    │ Code Generation │
│ User Experience │    │ API Translation  │    │ File Operations │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │ Command Logger   │
                       │   (Research)     │
                       │                  │
                       │ Interface        │
                       │ Discovery        │
                       │ Documentation    │
                       └──────────────────┘
```

## Development

### Prerequisites

- Node.js 16.x or later
- Kiro IDE (VS Code-based)
- `vsce` package manager for extension packaging

### Installation for Development

1. **Package the extension**:
   ```bash
   cd kiro-command-logger
   vsce package --allow-missing-repository
   ```

2. **Install in Kiro IDE**:
   ```bash
   kiro --install-extension kiro-command-logger-0.0.1.vsix
   ```

3. **Launch Kiro and monitor output**:
   ```bash
   kiro .
   # Open Output panel and select "Kiro Command Logger"
   ```

### Project Structure

```
kiro-command-logger/
├── extension.js          # Main command discovery logic
├── package.json          # Extension manifest and dependencies
├── README.md            # This documentation
└── .vscode/
    └── launch.json       # Debug configuration
```

## Research Workflow

### 1. Command Discovery Phase
- Install and activate the extension in Kiro IDE
- Monitor the output for discovered `kiroAgent` commands
- Document command names, categories, and apparent functionality

### 2. Command Testing Phase
- Use Kiro IDE normally to trigger various AI operations
- Observe which commands are executed during different workflows
- Test individual commands programmatically to understand parameters

### 3. Interface Documentation Phase
- Create comprehensive documentation of the `kiroAgent` API
- Map user actions to underlying command sequences
- Design the orchestration layer API based on discovered commands

### 4. Integration Phase
- Implement the orchestration service using discovered commands
- Build the Flutter frontend to communicate with the orchestration layer
- Test end-to-end headless automation scenarios

## Contributing

This extension is part of the Household AI Engineer project. To contribute:

1. Review the project specifications in `.kiro/specs/kiro-command-logger/`
2. Follow the implementation tasks outlined in `tasks.md`
3. Focus on expanding command discovery and analysis capabilities
4. Test with various Kiro IDE workflows to ensure comprehensive coverage

## License

This extension is developed as part of the Household AI Engineer project for research and development purposes. It is intended to enable headless automation of AI-assisted development workflows.