/**
 * Command registration for the Kiro Communication Bridge Extension.
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
 * This function sets up command handlers for Kiro communication,
 * status monitoring, and server management.
 * 
 * @param context - VS Code extension context for command registration
 */
export function registerCommands(context: vscode.ExtensionContext): void {
  const logger: Logger = new Logger('CommandRegistration');
  
  try {
    // Kiro communication commands
    const getStatusCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.getStatus',
      handleGetStatus
    );
    
    const executeCommandCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.executeCommand',
      handleExecuteCommand
    );
    
    const showAvailableCommandsCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.showAvailableCommands',
      handleShowAvailableCommands
    );
    
    const restartServersCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.restartServers',
      handleRestartServers
    );
    
    // Add all commands to the extension context for proper disposal
    context.subscriptions.push(
      getStatusCommand,
      executeCommandCommand,
      showAvailableCommandsCommand,
      restartServersCommand
    );
    
    logger.info('All commands registered successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to register commands: ${errorMessage}`);
    throw error;
  }
}

/**
 * Handles the get Kiro status command.
 * 
 * Displays the current status of Kiro IDE and the communication bridge.
 */
async function handleGetStatus(): Promise<void> {
  const logger: Logger = new Logger('GetStatusCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    const statusMonitor = extensionState.getStatusMonitor();
    const status = await statusMonitor.forceStatusCheck();
    const serverStatus = extensionState.getServerStatus();
    
    const statusMessage: string = [
      'Kiro Communication Bridge Status:',
      `• Bridge Initialized: ${serverStatus.initialized ? '✓' : '✗'}`,
      `• Servers Running: ${serverStatus.serversStarted ? '✓' : '✗'}`,
      `• Kiro Status: ${status.status}`,
      `• Kiro Available: ${serverStatus.kiroAvailable ? '✓' : '✗'}`,
      `• Connected Clients: ${serverStatus.connectedClients}`,
      status.version ? `• Kiro Version: ${status.version}` : '',
    ].filter(line => line).join('\n');
    
    vscode.window.showInformationMessage(statusMessage, { modal: true });
    logger.info('Status displayed to user');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to get status: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to get status: ${errorMessage}`);
  }
}

/**
 * Handles the execute Kiro command.
 * 
 * Prompts the user for a command and executes it through Kiro.
 */
async function handleExecuteCommand(): Promise<void> {
  const logger: Logger = new Logger('ExecuteCommandCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    // Prompt user for command
    const command = await vscode.window.showInputBox({
      prompt: 'Enter Kiro command to execute',
      placeHolder: 'e.g., workbench.action.files.newFile'
    });
    
    if (!command) {
      return; // User cancelled
    }
    
    const kiroProxy = extensionState.getKiroProxy();
    const result = await kiroProxy.executeCommand(command);
    
    if (result.success) {
      const message = `Command executed successfully: ${result.output || 'No output'}`;
      vscode.window.showInformationMessage(message);
      logger.info(`Command executed: ${command}`);
    } else {
      const message = `Command failed: ${result.error || 'Unknown error'}`;
      vscode.window.showErrorMessage(message);
      logger.error(`Command failed: ${command} - ${result.error}`);
    }
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to execute command: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to execute command: ${errorMessage}`);
  }
}

/**
 * Handles the show available commands command.
 * 
 * Displays a list of available Kiro commands for the user to select from.
 */
async function handleShowAvailableCommands(): Promise<void> {
  const logger: Logger = new Logger('ShowAvailableCommandsCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    const statusMonitor = extensionState.getStatusMonitor();
    const commands = await statusMonitor.forceCommandDiscovery();
    
    if (commands.length === 0) {
      vscode.window.showInformationMessage('No Kiro commands available');
      return;
    }
    
    const selected = await vscode.window.showQuickPick(commands, {
      placeHolder: 'Select a command to execute',
      canPickMany: false
    });
    
    if (selected) {
      // Execute the selected command
      const kiroProxy = extensionState.getKiroProxy();
      const result = await kiroProxy.executeCommand(selected);
      
      if (result.success) {
        const message = `Command executed successfully: ${result.output || 'No output'}`;
        vscode.window.showInformationMessage(message);
        logger.info(`Command executed: ${selected}`);
      } else {
        const message = `Command failed: ${result.error || 'Unknown error'}`;
        vscode.window.showErrorMessage(message);
        logger.error(`Command failed: ${selected} - ${result.error}`);
      }
    }
    
    logger.info(`Displayed ${commands.length} available commands`);
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to show available commands: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to show available commands: ${errorMessage}`);
  }
}

/**
 * Handles the restart servers command.
 * 
 * Restarts the API and WebSocket servers.
 */
async function handleRestartServers(): Promise<void> {
  const logger: Logger = new Logger('RestartServersCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    logger.info('Restarting communication servers...');
    
    // Stop servers
    await extensionState.stopServers();
    
    // Start servers
    await extensionState.startServers();
    
    const message: string = 'Communication servers restarted successfully';
    vscode.window.showInformationMessage(message);
    logger.info(message);
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to restart servers: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to restart servers: ${errorMessage}`);
  }
}