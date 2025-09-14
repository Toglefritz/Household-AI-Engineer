# Dwellware Dashboard

A revolutionary macOS desktop application that makes creating custom household applications as easy as having a conversation. Built with Flutter, Dwellware Dashboard provides an intuitive interface for managing your household's digital tools through natural language interaction.

## Overview

Dwellware transforms is a personal development environment where you can create custom applications without any technical knowledge. Through a conversational interface, you describe the tools you need, and the system handles everything from requirements gathering to deployment.

**Key Features:**
- 🗣️ **Natural Language Interface** - Describe your needs in plain English
- 📱 **Native macOS App** - Beautiful Flutter desktop interface
- 🔒 **Sandboxed Applications** - Each app runs independently and securely
- 🔄 **Iterative Development** - Refine and modify apps through conversation
- ⚡ **Real-time Progress** - Watch your applications being built live

## System Architecture

The system consists of four main components working together:

### 1. Flutter Desktop Dashboard
Your main interface for managing applications:

- Grid view of all your custom applications
- Conversational interface for requesting new apps
- Real-time development progress monitoring
- One-click application launching

### 2. Orchestrator Backend
The intelligent coordination layer that:

- Processes natural language requests into technical specifications
- Manages Amazon Kiro development sessions
- Handles application deployment and containerization
- Provides real-time progress updates via WebSocket
- Maintains application metadata and version control

### 3. AI Development Engine (Amazon Kiro)
Automated development capabilities:

- Generates code, tests, and documentation from specifications
- Iteratively refines implementations until quality standards are met
- Follows predefined templates and coding policies
- Outputs complete application artifacts

### 4. Application Isolation System
Ensures security and stability:

- Each application runs independently
- Isolated file system and network access per application
- Changes to the codebase for one application do not affect any of the other applications

## Example Use Cases

Transform your home management with custom applications:

- **Chore Rotation Tracker** - Automatically rotate home tasks with custom rules for your family
- **Trip Cost Forecaster** - Combine travel booking data with expense estimates for accurate trip budgeting  
- **Seasonal Maintenance Reminders** - Get timely notifications for home maintenance tasks based on your location and preferences
- **Local Events Dashboard** - Aggregate community events and activities relevant to your interests
- **Family Calendar Coordinator** - Sync and manage multiple family schedules with conflict detection
- **Home Inventory Manager** - Track supplies, expiration dates, and shopping lists with barcode scanning

## Getting Started

1. **Launch the Dashboard** - Open the Dwellware application
2. **Describe Your Need** - Click "Create New App" and describe what you want in plain English
3. **Watch It Build** - Monitor real-time progress as your application is developed
4. **Start Using** - Launch your new application directly from the dashboard
5. **Iterate and Improve** - Request modifications through conversation as your needs evolve

## Technical Highlights

- **Version Control** - Automatic Git repositories for each application with rollback capabilities
- **Quality Assurance** - Comprehensive testing and validation before deployment
- **Resource Management** - Intelligent queuing and resource allocation for multiple development jobs
- **Error Recovery** - Robust error handling with automatic recovery procedures
- **Extensible Architecture** - Clean separation of concerns for future enhancements

## Project Components

The Dwellware system consists of three main components working together to provide a seamless application development experience:

### 1. Dwellware Frontend Dashboard

The **Flutter Desktop Dashboard** serves as your primary interface for managing and creating custom household applications. Built with Flutter for macOS, it provides an intuitive, conversational approach to application development.

**Key Features:**
- 🖥️ **Native macOS Interface** - Beautiful Flutter desktop application optimized for macOS
- 🗂️ **Application Grid View** - Visual management of all your custom applications with responsive design
- 💬 **Conversational Interface** - Natural language input for describing application requirements
- ⚡ **Real-Time Progress Monitoring** - Live updates during application development with WebSocket integration
- 🚀 **One-Click Application Launch** - Direct launching of completed applications from the dashboard
- 🎯 **Context Menu Actions** - Right-click functionality for application management (favorites, deletion, etc.)
- 📱 **Responsive Design** - Adaptive layout that works across different screen sizes

**Video Demonstration:**
The [Dwellware Overview Demo](https://www.youtube.com/watch?v=akMIcMcPc9w&t=8s) showcases the complete user experience, from opening the dashboard to creating a new application through natural language conversation. You'll see the intuitive grid interface, the conversational request process, and real-time progress updates as applications are developed. The demo also highlights the responsive design and context menu functionality that makes managing multiple applications effortless.

**Technical Architecture:**
- Built with Flutter 3.x for cross-platform desktop support
- Implements MVC architecture pattern with strict separation of concerns
- Uses WebSocket connections for real-time progress updates
- REST API integration for application metadata management
- Localized interface supporting multiple languages
- Comprehensive error handling and user feedback systems

### 2. Kiro Communication Bridge Extension

The **Kiro Communication Bridge** is a Kiro IDE extension that transforms the IDE into a headless development environment for the Dwellware system. It provides the critical link between the Flutter frontend and Kiro's development capabilities.

**Key Features:**
- 🔗 **REST API Server** - HTTP endpoints for application creation, job management, and status monitoring
- 🏗️ **Workspace Management** - Automated creation of isolated development environments for each application
- ⚙️ **Job Orchestration** - Complete lifecycle management of development jobs including queuing, execution, and cleanup
- 🔧 **Configuration Management** - Typed access to the Kiro IDE settings with validation and intelligent defaults
- 🚨 **Port Conflict Resolution** - Automatic detection and resolution of port conflicts across multiple Kiro instances
- 📊 **Health Monitoring** - Continuous monitoring of server health and automatic recovery procedures

**Video Demonstration:**
The communication bridge extension process is explained in the [Dwellware Communication Bridge Explainer](https://youtu.be/Rhtd7WHvbME), which shows how the communication bridge orchestrates the entire development workflow. You'll see how user requests are processed, how Kiro sessions are managed, and how progress updates flow back to the frontend in real-time.

**Technical Architecture:**
- TypeScript-based Kiro IDE extension with comprehensive type safety
- Express.js REST API server with CORS support and authentication
- WebSocket server for bidirectional real-time communication
- Modular architecture with separate managers for jobs, workspaces, and configuration
- Automatic activation based on workspace content and startup events
- Robust error handling with graceful degradation and recovery mechanisms
- Comprehensive logging and debugging capabilities

**Configuration Options:**
- API server port and host configuration
- WebSocket server settings
- Job concurrency limits and timeout settings
- Workspace directory management
- Logging levels and debug options
- Auto-start behavior control

### 3. Kiro Command Research Extension

The **Kiro Command Research Tool** is a specialized Kiro IDE extension designed to discover, document, and test Kiro IDE commands for remote orchestration. It serves as the foundation for understanding Kiro's capabilities and building reliable automation.

**Key Features:**
- 🔍 **Command Discovery** - Automated discovery of available Kiro commands through multiple detection methods
- 🧪 **Safe Command Testing** - Controlled testing environment with parameter validation and rollback capabilities
- 📚 **Documentation Generation** - Automatic generation of comprehensive command documentation with examples
- 🎛️ **Interactive Command Explorer** - Tree view interface for browsing and managing discovered commands
- 📊 **Research Dashboard** - Centralized interface for monitoring discovery progress and results
- 🔬 **Parameter Research** - Deep analysis of command parameters, types, and validation rules
- 📤 **Export Capabilities** - Multiple export formats for integration with other systems
- 🔒 **Safety Mechanisms** - Built-in safeguards to prevent destructive operations during research

**Video Demonstration:**
The research capabilities are demonstrated through the [Command Research  Explainer](https://youtu.be/hcOhmLfT0Es) This video explains the extension's comprehensive command explorer, the interactive testing interface, and the detailed documentation generation capabilities that make Kiro command research both thorough and safe.

**Technical Architecture:**
- TypeScript-based extension with modular component architecture
- Multiple command discovery strategies (API introspection, documentation parsing, runtime analysis)
- Comprehensive storage system for research results and command metadata
- Interactive UI components including tree views, dashboards, and detail panels
- Export system supporting JSON, Markdown, and API documentation formats
- Safety mechanisms including command validation, parameter checking, and operation rollback
- Extensive logging and error tracking for research operations

**Research Capabilities:**
- **Command Discovery**: Automated identification of available commands across Kiro's API surface
- **Parameter Analysis**: Deep inspection of command parameters, types, and validation requirements
- **Usage Pattern Detection**: Analysis of common command usage patterns and workflows
- **Documentation Extraction**: Automated extraction and formatting of command documentation
- **Test Case Generation**: Creation of comprehensive test cases for command validation
- **Integration Mapping**: Understanding of how commands integrate with the broader Kiro ecosystem

**User Interface Components:**
- **Command Explorer**: Hierarchical view of discovered commands with search and filtering
- **Research Dashboard**: Overview of discovery progress, statistics, and recent findings
- **Testing Interface**: Safe environment for command execution with parameter validation
- **Documentation Viewer**: Formatted display of generated command documentation
- **Export Manager**: Tools for exporting research results in various formats

## Disclaimer

In the creation of this project, artificial intelligence (AI) tools have been utilized. These tools have assisted in various stages of the project's development, from initial code generation to the optimization of algorithms.

It is emphasized that the AI's contributions have been thoroughly overseen. Each segment of AI-assisted code has undergone meticulous scrutiny to ensure adherence to high standards of quality, reliability, and performance. This scrutiny was conducted by the sole developer responsible for the projects's creation.

Rigorous testing has been applied to all AI-suggested outputs, encompassing a wide array of conditions and use cases. Modifications have been implemented where necessary, ensuring that the AI's contributions are well-suited to the specific requirements and limitations inherent in the subject matter covered by this project.

Commitment to the projects's accuracy and functionality is paramount, and feedback or issue reports from users are invited to facilitate continuous improvement.

It is to be understood that this project, like all software, is subject to evolution over time. The developer is dedicated to its progressive refinement and is actively working to surpass the expectations of the community.