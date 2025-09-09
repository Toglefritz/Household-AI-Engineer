# Dwellware Installation Guide

## Overview

Dwellware is a household AI engineer that creates custom applications for your home using natural language requests. This guide will walk you through the complete installation process to get Dwellware running on your system.

## System Requirements

### System Requirements
- **Operating System**: macOS 10.15+
- **Internet Connection**: Required for initial setup and application development

## Installation Steps

### Step 1: Install the Kiro IDE

The Kiro IDE is the development environment that powers Dwellware's application creation capabilities.

#### Download and Install Kiro

1. **Visit the Kiro website**: Navigate to [https://kiro.dev/](https://kiro.dev/)
2. **Download the installer**: Download the Kiro installer
3. **Run the installer**: Open the downloaded `.app` file and drag Kiro to Applications

#### Sign In to Kiro

1. **Launch Kiro IDE**: Open the application from your Applications folder
2. **Create or sign in to your account**: Authenticate with the Kiro IDE
3. **Verify installation**: Ensure Kiro loads successfully and you can access the main interface

> **Note**: A Kiro account is required for Dwellware to function properly, as it handles the AI-powered application development process.

### Step 2: Install the Communication Bridge Extension

The communication bridge extension enables Dwellware to interact with the Kiro IDE for automated application development.

#### Download the Extension

1. **Download the VSIX file**: Visit the [Dwellware releases page](https://github.com/Toglefritz/Dwellware/blob/main/kiro-communication-bridge/kiro-communication-bridge-0.8.0.vsix)
2. **Save the file**: Download `kiro-communication-bridge-0.8.0.vsix` to your computer
3. **Note the download location**: Remember where you saved the file for the next step

#### Install the Extension in Kiro

1. **Open Kiro IDE**: Launch the Kiro application
2. **Access the Extensions panel**:
   - Use the keyboard shortcut `Cmd+Shift+X`
   - Or click the Extensions icon in the left sidebar
3. **Install from VSIX**:
   - Click the three dots menu (`...`) in the Extensions panel header
   - Select "Install from VSIX..."
   - Navigate to and select the downloaded `kiro-communication-bridge-0.8.0.vsix` file
   - Click "Install"
4. **Verify installation**:
   - The extension should appear in your installed extensions list
   - Look for "Kiro Communication Bridge" in the extensions panel
   - Restart Kiro IDE if prompted

### Step 3: Install the Dwellware Frontend

The Dwellware frontend provides the user interface for creating and managing your household applications.

#### Download the Application

1. **Visit the releases page**: Go to [https://github.com/Toglefritz/Dwellware/releases/tag/v1.0.0](https://github.com/Toglefritz/Dwellware/releases/tag/v1.0.0)
2. **Download the Dwellware frontend app**: Download the `.app` file

#### Install the Application

##### macOS Installation
1. **Open the app file**: Double-click the downloaded `.app` file
2. **Install the application**: Drag Dwellware to your Applications folder
3. **Handle security warnings**: 
   - If macOS blocks the app, go to System Preferences > Security & Privacy
   - Click "Open Anyway" for Dwellware
4. **Launch Dwellware**: Open from Applications folder

## Next Steps

Once installation is complete:

1. **Explore the dashboard**: Familiarize yourself with the Dwellware interface
2. **Create your first application**: Start with a simple request to test the system

---

**Congratulations!** You have successfully installed Dwellware. You're now ready to create custom applications for your household using natural language requests.