/**
 * Command registration for the Kiro Orchestration Extension.
 * 
 * This module registers all VS Code commands provided by the extension
 * and connects them to their respective handler implementations.
 */

import * as vscode from 'vscode';
import { Logger } from './logger';
import { ExtensionState } from './extension-state';

/**
 * Registers all extension commands with VS Code.
 * 
 * This function sets up command handlers for server management,
 * job monitoring, and workspace operations.
 * 
 * @param context - VS Code extension context for command registration
 */
export function registerCommands(context: vscode.ExtensionContext): void {
  const logger: Logger = new Logger('CommandRegistration');
  
  try {
    // Server management commands
    const startServerCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.startServer',
      handleStartServer
    );
    
    const stopServerCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.stopServer',
      handleStopServer
    );
    
    const viewStatusCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.viewStatus',
      handleViewStatus
    );
    
    // Job management commands
    const viewJobsCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.viewJobs',
      handleViewJobs
    );
    
    // Workspace management commands
    const openAppsDirectoryCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.openAppsDirectory',
      handleOpenAppsDirectory
    );
    
    // Add all commands to the extension context for proper disposal
    context.subscriptions.push(
      startServerCommand,
      stopServerCommand,
      viewStatusCommand,
      viewJobsCommand,
      openAppsDirectoryCommand
    );
    
    logger.info('All commands registered successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to register commands: ${errorMessage}`);
    throw error;
  }
}

/**
 * Handles the start server command.
 * 
 * Starts the API and WebSocket servers if they are not already running.
 */
async function handleStartServer(): Promise<void> {
  const logger: Logger = new Logger('StartServerCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    logger.info('Starting orchestration servers...');
    await extensionState.startServers();
    
    const message: string = 'Orchestration servers started successfully';
    vscode.window.showInformationMessage(message);
    logger.info(message);
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to start servers: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to start servers: ${errorMessage}`);
  }
}

/**
 * Handles the stop server command.
 * 
 * Stops the API and WebSocket servers if they are currently running.
 */
async function handleStopServer(): Promise<void> {
  const logger: Logger = new Logger('StopServerCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    logger.info('Stopping orchestration servers...');
    await extensionState.stopServers();
    
    const message: string = 'Orchestration servers stopped successfully';
    vscode.window.showInformationMessage(message);
    logger.info(message);
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to stop servers: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to stop servers: ${errorMessage}`);
  }
}

/**
 * Handles the view status command.
 * 
 * Displays the current status of all orchestration services.
 */
async function handleViewStatus(): Promise<void> {
  const logger: Logger = new Logger('ViewStatusCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    const status = extensionState.getServerStatus();
    
    const statusMessage: string = [
      'Kiro Orchestration Extension Status:',
      `• Initialized: ${status.initialized ? '✓' : '✗'}`,
      `• Servers Started: ${status.serversStarted ? '✓' : '✗'}`,
      `• API Server: ${status.apiServerRunning ? 'Running' : 'Stopped'}`,
      `• WebSocket Server: ${status.webSocketServerRunning ? 'Running' : 'Stopped'}`,
      `• Active Jobs: ${status.activeJobs}`,
    ].join('\n');
    
    vscode.window.showInformationMessage(statusMessage, { modal: true });
    logger.info('Status displayed to user');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to get status: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to get status: ${errorMessage}`);
  }
}

/**
 * Handles the view jobs command.
 * 
 * Displays information about currently active development jobs.
 */
async function handleViewJobs(): Promise<void> {
  const logger: Logger = new Logger('ViewJobsCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    const jobManager = extensionState.getJobManager();
    const activeJobCount: number = jobManager.getActiveJobCount();
    
    if (activeJobCount === 0) {
      vscode.window.showInformationMessage('No active development jobs');
    } else {
      const message: string = `Currently managing ${activeJobCount} active development job${activeJobCount === 1 ? '' : 's'}`;
      vscode.window.showInformationMessage(message);
    }
    
    logger.info(`Displayed job information: ${activeJobCount} active jobs`);
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to get job information: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to get job information: ${errorMessage}`);
  }
}

/**
 * Handles the open apps directory command.
 * 
 * Opens the configured apps directory in the VS Code explorer.
 */
async function handleOpenAppsDirectory(): Promise<void> {
  const logger: Logger = new Logger('OpenAppsDirectoryCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    const workspaceManager = extensionState.getWorkspaceManager();
    const appsDirectoryPath: string = workspaceManager.getAppsDirectoryPath();
    
    // Open the apps directory in VS Code
    const uri: vscode.Uri = vscode.Uri.file(appsDirectoryPath);
    await vscode.commands.executeCommand('vscode.openFolder', uri, { forceNewWindow: false });
    
    logger.info(`Opened apps directory: ${appsDirectoryPath}`);
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to open apps directory: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to open apps directory: ${errorMessage}`);
  }
}