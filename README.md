# Dwellware

A personal AI-powered software development system that creates custom applications for your home on demand. Simply describe what you need in plain English, and watch as your personal software engineer designs, codes, tests, and deploys bespoke tools tailored to your unique needs.

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