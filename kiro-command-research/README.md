# Kiro Command Research Extension

A comprehensive Kiro IDE extension designed to discover, document, and safely test Kiro IDE commands for automation and integration purposes. This tool serves as the foundation for understanding Kiro's command ecosystem and building reliable command orchestration systems.

## Overview

The Kiro Command Research Extension provides developers and system integrators with powerful tools to explore, understand, and document the complete Kiro IDE command surface. Through automated discovery, safe testing environments, and comprehensive documentation generation, this extension makes Kiro's capabilities accessible for automation and remote orchestration.

**Key Features:**
- � **Automated Command Discovery** - Discover all available Kiro commands through multiple detection methods
- 🧪 **Safe Command Testing** - Test commands in controlled environments with rollback capabilities
- � **Documentation Generation** - Generate comprehensive API documentation with examples
- 🎛️ **Interactive Command Explorer** - Browse and manage commands through an intuitive tree interface
- 📊 **Research Dashboard** - Monitor discovery progress and analyze command statistics
- 🔬 **Parameter Research** - Deep analysis of command parameters, types, and validation rules
- 📤 **Multi-Format Export** - Export results in JSON, Markdown, TypeScript, and OpenAPI formats
- 🔒 **Built-in Safety** - Comprehensive safeguards prevent destructive operations during research

## Architecture Overview

The extension follows a modular architecture with clear separation of concerns:

### Core Components

#### 1. Command Discovery System
**Location**: `src/discovery/`

The discovery system automatically identifies available Kiro commands through multiple strategies:

- **Command Registry Scanner** (`command-registry-scanner.ts`) - Scans VS Code's command registry for Kiro-related commands
- **Parameter Researcher** (`parameter-researcher.ts`) - Analyzes command signatures and parameter requirements
- **Risk Assessment** - Categorizes commands by potential impact and safety level

#### 2. Testing Framework
**Location**: `src/testing/`

Provides safe command execution with comprehensive monitoring:

- **Command Executor** (`command-executor.ts`) - Executes commands with timeout protection and rollback capabilities
- **Parameter Validator** (`parameter-validator.ts`) - Validates command parameters before execution
- **Result Capture** (`result-capture.ts`) - Captures detailed execution results and performance metrics
- **Side Effect Detector** (`side-effect-detector.ts`) - Monitors workspace changes during command execution

#### 3. Documentation System
**Location**: `src/documentation/` and `src/export/`

Generates comprehensive documentation from research results:

- **Documentation Viewer** (`documentation-viewer.ts`) - Interactive webview for browsing command documentation
- **Schema Generator** (`schema-generator.ts`) - Creates TypeScript definitions and OpenAPI specifications
- **Documentation Exporter** (`documentation-exporter.ts`) - Exports documentation in multiple formats

#### 4. Storage and Management
**Location**: `src/storage/`

Persistent storage for research results and configuration:

- **File Storage Manager** (`file-storage-manager.ts`) - Manages research data persistence and export functionality
- **Extension State** (`src/core/extension-state.ts`) - Centralized state management and dependency injection

## Use Cases

The Kiro Command Research Extension serves multiple scenarios:

### For System Integrators
- **API Discovery** - Understand the complete Kiro command surface for integration planning
- **Automation Development** - Build reliable command orchestration systems with validated parameters
- **Documentation Generation** - Create comprehensive API documentation for team reference
- **Risk Assessment** - Identify safe vs. potentially destructive commands for automated workflows

### For Extension Developers
- **Command Analysis** - Research existing commands before developing new functionality
- **Parameter Validation** - Understand parameter requirements and validation rules
- **Testing Framework** - Validate command behavior across different scenarios
- **Documentation Standards** - Generate consistent documentation following established patterns

### For DevOps Teams
- **Workflow Automation** - Build CI/CD pipelines using validated Kiro commands
- **Environment Setup** - Automate development environment configuration
- **Quality Assurance** - Test command reliability and performance characteristics
- **Change Management** - Track command evolution and breaking changes

## Getting Started

### Installation

1. **Install the Extension**
   ```bash
   # Clone the repository
   git clone <repository-url>
   cd kiro-command-research
   
   # Install dependencies
   npm install
   
   # Build the extension
   npm run compile
   ```

2. **Load in Kiro IDE**
   - Open Kiro IDE
   - Go to Extensions view (Ctrl+Shift+X)
   - Click "..." menu → "Install from VSIX"
   - Select the built extension package

### Quick Start

1. **Open Command Palette** - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)

2. **Discover Commands** - Run `Kiro Research: Discover Commands`
   - Automatically scans for all available Kiro commands
   - Categorizes commands by functionality and risk level
   - Stores results for future reference

3. **Explore Results** - Run `Kiro Research: Open Explorer`
   - Browse discovered commands in an interactive tree view
   - View command details, parameters, and documentation
   - Filter by category, risk level, or search terms

4. **Test Commands** - Run `Kiro Research: Test Command`
   - Select a command to test in a safe environment
   - Validate parameters before execution
   - Monitor side effects and capture results

5. **Generate Documentation** - Run `Kiro Research: Generate Documentation`
   - Creates comprehensive API documentation
   - Exports in multiple formats (Markdown, JSON, TypeScript, OpenAPI)
   - Includes examples and usage patterns

### Available Commands

Access these commands through the Command Palette (`Ctrl+Shift+P`):

| Command | Description |
|---------|-------------|
| `Kiro Research: Discover Commands` | Scan and discover all available Kiro commands |
| `Kiro Research: Research Parameters` | Analyze command parameters and signatures |
| `Kiro Research: Open Explorer` | Open the interactive command explorer |
| `Kiro Research: Test Command` | Safely test a specific command |
| `Kiro Research: Generate Documentation` | Generate comprehensive documentation |
| `Kiro Research: View Results` | View captured test results and analysis |
| `Kiro Research: Open Dashboard` | Open the research dashboard webview |

## Key Features

### Command Discovery
- **Multi-Strategy Detection** - Uses multiple methods to discover commands including registry scanning, documentation parsing, and runtime analysis
- **Intelligent Categorization** - Automatically categorizes commands by functionality (agent, execution, spec, etc.)
- **Risk Assessment** - Evaluates potential impact of commands (low, medium, high risk)
- **Context Analysis** - Determines workspace and environment requirements for each command

### Safe Testing Environment
- **Parameter Validation** - Comprehensive validation of command parameters before execution
- **Workspace Snapshots** - Creates rollback points before potentially destructive operations
- **Side Effect Monitoring** - Tracks file system, editor, and workspace changes during execution
- **Timeout Protection** - Prevents runaway command execution with configurable timeouts
- **Confirmation Dialogs** - Requires user confirmation for high-risk operations

### Comprehensive Documentation
- **Multi-Format Export** - Generates documentation in Markdown, JSON, TypeScript definitions, and OpenAPI specifications
- **Interactive Viewer** - Built-in webview for browsing and searching command documentation
- **Usage Examples** - Includes real execution examples with parameters and results
- **Change Tracking** - Tracks command evolution and breaking changes over time

### Advanced Analysis
- **Performance Metrics** - Captures execution time, memory usage, and resource impact
- **Return Value Analysis** - Analyzes command return values for structure and usefulness
- **Parameter Research** - Deep analysis of parameter types, validation rules, and default values
- **Integration Patterns** - Identifies common command usage patterns and workflows

## User Interface

### Command Explorer
The interactive tree view provides hierarchical browsing of discovered commands:

- **Categorized Organization** - Commands grouped by functionality (agent, execution, spec, etc.)
- **Search and Filtering** - Find commands by name, category, or risk level
- **Command Details** - View parameters, documentation, and usage examples
- **Context Actions** - Right-click to test, document, or export individual commands

### Research Dashboard
A comprehensive webview interface for monitoring research progress:

- **Discovery Statistics** - Overview of discovered commands, categories, and completion status
- **Recent Activity** - Timeline of recent discoveries and test results
- **Command Analytics** - Charts and graphs showing command distribution and characteristics
- **Export Options** - Quick access to documentation generation and export functions

### Testing Interface
Safe command execution environment with comprehensive validation:

- **Parameter Input** - Interactive forms for entering command parameters
- **Validation Feedback** - Real-time validation with error messages and suggestions
- **Execution Monitoring** - Progress indicators and side effect tracking during execution
- **Result Analysis** - Detailed analysis of command results, performance, and impact

### Documentation Viewer
Built-in documentation browser with rich formatting:

- **Multi-Format Support** - View documentation in Markdown, HTML, or interactive formats
- **Search Functionality** - Full-text search across all generated documentation
- **Cross-References** - Navigate between related commands and concepts
- **Export Integration** - Direct export to external documentation systems

## Configuration

### Extension Settings

Configure the extension through VS Code settings (`settings.json`):

```json
{
  "kiroResearch.discovery.autoScan": true,
  "kiroResearch.discovery.includeInternal": false,
  "kiroResearch.testing.requireConfirmation": true,
  "kiroResearch.testing.timeoutMs": 30000,
  "kiroResearch.testing.createSnapshots": true,
  "kiroResearch.export.outputDirectory": "./kiro-research-output",
  "kiroResearch.export.formats": ["markdown", "json", "typescript"],
  "kiroResearch.safety.riskThreshold": "medium"
}
```

### Storage Configuration

Research results are stored in the extension's global storage directory:

```
~/.vscode/extensions/kiro-command-research/storage/
├── discovery-results.json      # Discovered commands and metadata
├── test-results.json          # Captured test execution results
├── exports/                   # Generated documentation files
│   ├── commands.md
│   ├── api-spec.json
│   └── types.d.ts
└── logs/                      # Activity and error logs
    └── research-YYYY-MM-DD.log
```

## API Reference

### Core Interfaces

The extension exposes several key TypeScript interfaces for integration:

```typescript
interface CommandMetadata {
  readonly id: string;
  readonly displayName: string;
  readonly category: string;
  readonly subcategory: string;
  readonly riskLevel: 'low' | 'medium' | 'high';
  readonly contextRequirements: string[];
  readonly signature?: CommandSignature;
}

interface CommandSignature {
  readonly commandId: string;
  readonly parameters: ParameterInfo[];
  readonly returnType?: string;
  readonly async: boolean;
  readonly confidence: 'high' | 'medium' | 'low';
}

interface TestResult {
  readonly id: string;
  readonly commandId: string;
  readonly parameters: Record<string, any>;
  readonly executionResult: ExecutionResult;
  readonly analysis: ResultAnalysis;
  readonly timestamp: Date;
}
```

### Extension API

For programmatic access from other extensions:

```typescript
// Get the extension API
const kiroResearch = vscode.extensions.getExtension('kiro-command-research');
const api = kiroResearch?.exports;

// Discover commands programmatically
const commands = await api.discoverCommands();

// Test a command safely
const result = await api.testCommand('kiroAgent.createApplication', {
  description: 'Test application'
});

// Generate documentation
await api.generateDocumentation(['markdown', 'json']);
```

## Development

### Building from Source

```bash
# Clone the repository
git clone <repository-url>
cd kiro-command-research

# Install dependencies
npm install

# Build the extension
npm run compile

# Run tests
npm test

# Package for distribution
npm run package
```

### Project Structure

```
src/
├── core/                      # Core extension infrastructure
│   ├── extension-state.ts     # Centralized state management
│   └── command-registration.ts # Command registration system
├── discovery/                 # Command discovery system
│   ├── command-registry-scanner.ts
│   └── parameter-researcher.ts
├── testing/                   # Safe command testing framework
│   ├── command-executor.ts
│   ├── parameter-validator.ts
│   ├── result-capture.ts
│   └── side-effect-detector.ts
├── documentation/             # Documentation generation
│   ├── documentation-viewer.ts
│   └── schema-generator.ts
├── export/                    # Multi-format export system
│   └── documentation-exporter.ts
├── storage/                   # Data persistence
│   └── file-storage-manager.ts
└── handlers/                  # Command handlers
    ├── command-handlers.ts
    ├── advanced-handlers.ts
    └── utility-functions.ts
```

### Contributing

1. **Fork the Repository** - Create your own fork for development
2. **Create Feature Branch** - Use descriptive branch names (`feature/command-discovery-improvements`)
3. **Follow Code Standards** - Adhere to TypeScript and documentation standards
4. **Write Tests** - Include comprehensive tests for new functionality
5. **Update Documentation** - Keep README and inline documentation current
6. **Submit Pull Request** - Provide detailed description of changes

### Testing

The extension includes comprehensive test suites:

```bash
# Run all tests
npm test

# Run specific test suites
npm run test:discovery
npm run test:execution
npm run test:documentation

# Run tests with coverage
npm run test:coverage
```

## Safety and Security

### Built-in Safeguards

- **Risk Assessment** - All commands are categorized by potential impact
- **Parameter Validation** - Comprehensive validation prevents invalid inputs
- **Workspace Snapshots** - Automatic rollback points for destructive operations
- **Confirmation Dialogs** - User confirmation required for high-risk commands
- **Timeout Protection** - Prevents runaway command execution
- **Side Effect Monitoring** - Tracks and reports all workspace changes

### Best Practices

- **Start with Discovery** - Always run command discovery before testing
- **Review Risk Levels** - Pay attention to command risk assessments
- **Use Snapshots** - Enable workspace snapshots for testing unknown commands
- **Monitor Side Effects** - Review detected side effects after command execution
- **Backup Important Work** - Create backups before extensive testing sessions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for the Kiro IDE ecosystem
- Utilizes Kiro Extension API
- Inspired by API documentation tools and testing frameworks
- Part of the broader Dwellware development platform
