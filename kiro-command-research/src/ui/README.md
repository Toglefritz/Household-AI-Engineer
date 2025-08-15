# UI Components

This directory contains the user interface components for the Kiro Command Research Tool.

## Testing Interface

The Testing Interface (`testing-interface.ts`) provides a comprehensive webview-based interface for testing Kiro commands with parameter input forms, validation feedback, and result display.

### Features

- **Interactive Parameter Forms**: Dynamic form generation based on command signatures
- **Real-time Parameter Validation**: Validates parameters as you type with immediate feedback
- **Execution Options**: Configure timeout, snapshots, and confirmation requirements
- **Rich Result Display**: Comprehensive execution results with syntax highlighting
- **Recent Tests History**: Quick access to previously executed tests
- **Side Effect Monitoring**: Displays detected workspace changes during execution
- **Error Handling**: Detailed error information with stack traces
- **Workspace Snapshots**: Create and restore workspace state for safe testing

### Usage

The Testing Interface is opened when you:
1. Use the "Test Command" command from the command palette
2. Click "Test Command" from the Command Explorer context menu
3. Select a command and choose to test it

#### Interface Sections

1. **Command Header**: Shows command name, ID, and risk level
2. **Parameter Form**: Dynamic inputs based on command signature
3. **Execution Options**: Timeout, snapshot, and confirmation settings
4. **Action Buttons**: Validate, Execute, and Clear controls
5. **Recent Tests**: Quick access to previous test executions
6. **Command Info**: Detailed command metadata
7. **Results Panel**: Execution results with comprehensive details

#### Parameter Input Types

- **String**: Text input with placeholder
- **Number**: Numeric input with validation
- **Boolean**: Checkbox input
- **Object/Array**: JSON textarea with syntax validation
- **Complex Types**: JSON input with error handling

### Integration

The Testing Interface integrates with:

- **Command Executor**: Safe command execution with monitoring
- **Parameter Validator**: Real-time parameter validation
- **Side Effect Detector**: Workspace change monitoring
- **Result Capture**: Detailed test result storage
- **Workspace Snapshots**: State backup and restoration

### Configuration

The Testing Interface supports these configuration options:

- `defaultTimeout`: Default execution timeout (30000ms)
- `defaultCreateSnapshot`: Create snapshots by default (false)
- `requireConfirmation`: Require confirmation for destructive commands (true)
- `showAdvancedOptions`: Show advanced execution options (true)
- `maxRecentTests`: Maximum recent tests to remember (10)

## Command Explorer

The Command Explorer (`command-explorer.ts`) provides an interactive tree view for browsing discovered Kiro commands.

### Features

- **Hierarchical Command Display**: Commands are organized in a tree structure with grouping options
- **Multiple Grouping Modes**: 
  - Category (default)
  - Subcategory 
  - Risk Level
  - Alphabetical
- **Search Functionality**: Filter commands by name, ID, or description
- **Risk Level Indicators**: Visual indicators for safe, moderate, and destructive commands
- **Test Result Integration**: Shows which commands have been tested
- **Command Details View**: Rich webview showing detailed command information
- **Context Menu Actions**: Right-click actions for testing and viewing details

### Usage

The Command Explorer is automatically activated when the extension loads. It appears in the VS Code Explorer panel as "Kiro Commands".

#### Available Actions

1. **Refresh** (🔄): Reload commands from storage
2. **Search** (🔍): Filter commands by search query
3. **Change Grouping** (📊): Switch between different grouping modes
4. **Test Command** (▶️): Launch the testing interface for a command
5. **Show Details** (ℹ️): Open detailed command information in a webview

#### Tree View Structure

```
📁 Category Name (count)
  ├── 🟢 Safe Command Name
  ├── 🟡 Moderate Risk Command
  └── 🔴 Destructive Command
```

### Configuration

The Command Explorer supports the following configuration options:

- `showSignatures`: Display command signatures in tree (default: true)
- `showRiskLevels`: Show risk level indicators (default: true) 
- `showTestResults`: Display test result indicators (default: true)
- `defaultGrouping`: Default grouping mode (default: 'category')
- `autoRefresh`: Auto-refresh on file changes (default: true)

### Integration

The Command Explorer integrates with:

- **File Storage Manager**: Loads discovered commands from storage
- **Testing Interface**: Launches command testing from tree items
- **Command Handlers**: Executes commands via the command palette
- **Documentation System**: Shows detailed command documentation

### Commands

The following VS Code commands are registered for the Command Explorer:

- `kiroCommandResearch.refreshExplorer`
- `kiroCommandResearch.searchCommands`
- `kiroCommandResearch.changeGrouping`
- `kiroCommandResearch.showCommandDetails`
- `kiroCommandResearch.testCommandFromExplorer`