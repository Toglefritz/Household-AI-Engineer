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
    
    const forceRestartServersCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.forceRestartServers',
      handleForceRestartServers
    );
    
    const healthCheckCommand: vscode.Disposable = vscode.commands.registerCommand(
      'kiroOrchestration.healthCheck',
      handleHealthCheck
    );
    
    // Add all commands to the extension context for proper disposal
    context.subscriptions.push(
      getStatusCommand,
      executeCommandCommand,
      showAvailableCommandsCommand,
      restartServersCommand,
      forceRestartServersCommand,
      healthCheckCommand
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
 * Restarts the API server gracefully.
 */
async function handleRestartServers(): Promise<void> {
  const logger: Logger = new Logger('RestartServersCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    logger.info('Restarting communication servers...');
    
    // Use the port conflict handling method for restart
    await extensionState.stopServers();
    await extensionState.startServersWithPortConflictHandling();
    
    const message: string = 'Communication servers restarted successfully';
    vscode.window.showInformationMessage(message);
    logger.info(message);
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to restart servers: ${errorMessage}`);
    
    // Handle port conflicts specifically
    if (error instanceof Error && error.message.includes('EADDRINUSE')) {
      const userChoice = await vscode.window.showErrorMessage(
        'Failed to restart servers due to port conflicts. Would you like to force restart and kill any processes using the required ports?',
        'Force Restart',
        'Cancel'
      );
      
      if (userChoice === 'Force Restart') {
        try {
          const currentExtensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
          if (currentExtensionState) {
            await currentExtensionState.forceRestartServers();
            vscode.window.showInformationMessage('Servers force restarted successfully!');
          } else {
            throw new Error('Extension state is not initialized');
          }
        } catch (forceError: unknown) {
          const forceErrorMessage: string = forceError instanceof Error ? forceError.message : 'Unknown error';
          vscode.window.showErrorMessage(`Force restart failed: ${forceErrorMessage}`);
        }
      }
    } else {
      vscode.window.showErrorMessage(`Failed to restart servers: ${errorMessage}`);
    }
  }
}

/**
 * Handles the force restart servers command.
 * 
 * Forcefully restarts servers by killing any processes using the required ports.
 */
async function handleForceRestartServers(): Promise<void> {
  const logger: Logger = new Logger('ForceRestartServersCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    // Confirm with user before force restart
    const confirmation = await vscode.window.showWarningMessage(
      'Force restart will kill any processes using ports 3001 and 3002. This may affect other Kiro IDE windows. Continue?',
      { modal: true },
      'Yes, Force Restart',
      'Cancel'
    );
    
    if (confirmation !== 'Yes, Force Restart') {
      return;
    }
    
    logger.info('Force restarting communication servers...');
    
    await vscode.window.withProgress({
      location: vscode.ProgressLocation.Notification,
      title: 'Force restarting Kiro Communication Bridge...',
      cancellable: false
    }, async (progress) => {
      progress.report({ increment: 0, message: 'Stopping current servers...' });
      
      progress.report({ increment: 25, message: 'Killing processes on required ports...' });
      await extensionState.forceRestartServers();
      
      progress.report({ increment: 100, message: 'Servers restarted successfully!' });
    });
    
    const message: string = 'Communication servers force restarted successfully';
    vscode.window.showInformationMessage(message);
    logger.info(message);
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to force restart servers: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to force restart servers: ${errorMessage}`);
  }
}

/**
 * Handles the health check command.
 * 
 * Performs a comprehensive health check of all servers and displays the results.
 */
async function handleHealthCheck(): Promise<void> {
  const logger: Logger = new Logger('HealthCheckCommand');
  
  try {
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    logger.info('Performing health check...');
    
    const healthResults = await vscode.window.withProgress({
      location: vscode.ProgressLocation.Notification,
      title: 'Performing health check...',
      cancellable: false
    }, async (progress) => {
      progress.report({ increment: 0, message: 'Checking API server...' });
      
      const results = await extensionState.performHealthCheck();
      
      progress.report({ increment: 50, message: 'Checking API server...' });
      
      progress.report({ increment: 100, message: 'Health check complete!' });
      
      return results;
    });
    
    // Format health check results
    const statusLines: string[] = [
      'Kiro Communication Bridge Health Check:',
      '',
      `Overall Status: ${healthResults.overall ? '✅ Healthy' : '❌ Unhealthy'}`,
      '',
      'API Server:',
      `  • Running: ${healthResults.apiServer.running ? '✅' : '❌'}`,
      `  • Responding: ${healthResults.apiServer.responding ? '✅' : '❌'}`,
    ];
    
    if (healthResults.apiServer.error) {
      statusLines.push(`  • Error: ${healthResults.apiServer.error}`);
    }
    

    
    const statusMessage = statusLines.join('\n');
    
    if (healthResults.overall) {
      vscode.window.showInformationMessage('Health Check Passed', { modal: true, detail: statusMessage });
    } else {
      const action = await vscode.window.showWarningMessage(
        'Health Check Failed',
        { modal: true, detail: statusMessage },
        'Restart Servers',
        'Force Restart',
        'OK'
      );
      
      if (action === 'Restart Servers') {
        await handleRestartServers();
      } else if (action === 'Force Restart') {
        await handleForceRestartServers();
      }
    }
    
    logger.info('Health check completed');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`Failed to perform health check: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to perform health check: ${errorMessage}`);
  }
}