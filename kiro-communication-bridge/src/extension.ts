/**
 * Main extension entry point for the Kiro Communication Bridge Extension.
 * 
 * This module handles extension activation, server startup, command registration,
 * and lifecycle management for the orchestration system that bridges the Flutter
 * frontend with Kiro IDE for automated application development.
 */

import * as vscode from 'vscode';
import { ExtensionState } from './core/extension-state';
import { registerCommands } from './core/command-registration';
import { Logger } from './core/logger';

/**
 * Called when the extension is activated.
 * 
 * This function initializes the orchestration system, starts the API server,
 * and registers all commands for managing the development workflow.
 */
export async function activate(context: vscode.ExtensionContext): Promise<void> {
  try {
    const logger: Logger = new Logger('Extension');
    logger.info('Activating Kiro Communication Bridge Extension...');

    // Initialize extension state and configuration
    logger.info('Initializing extension state...');
    await ExtensionState.initialize(context);
    logger.info('Extension state initialized successfully');

    // Set context variables for command enablement
    logger.info('Setting context variables...');
    await vscode.commands.executeCommand('setContext', 'kiroOrchestration.active', true);

    // Register all extension commands
    logger.info('Registering commands...');
    registerCommands(context);

    // Check if auto-start is enabled and start servers if so
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (!extensionState) {
      throw new Error('Extension state is not initialized');
    }
    
    const config = vscode.workspace.getConfiguration('kiroOrchestration');
    const autoStart: boolean = config.get('autoStart', true);
    
    if (autoStart) {
      logger.info('Auto-start enabled, starting orchestration servers...');
      await extensionState.startServersWithPortConflictHandling();
    } else {
      logger.info('Auto-start disabled, servers can be started manually using commands');
    }

    // Show success message
    const message: string = 'Kiro Communication Bridge Extension activated successfully!';
    vscode.window.showInformationMessage(message);
    logger.info('Kiro Communication Bridge Extension activated successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    const stack: string = error instanceof Error && error.stack ? error.stack : 'No stack trace';
    
    const logger: Logger = new Logger('Extension');
    logger.error(`Failed to activate extension: ${errorMessage}`);
    logger.error('Stack trace:', stack);
    
    // Handle port conflict errors specifically
    if (error instanceof Error && error.message.includes('EADDRINUSE')) {
      const portMatch: RegExpMatchArray | null = error.message.match(/127\.0\.0\.1:(\d+)/);
      const port: string = portMatch ? portMatch[1] : 'unknown';
      
      const userChoice = await vscode.window.showErrorMessage(
        `Failed to start Kiro Communication Bridge: Port ${port} is already in use. This may be from another Kiro IDE window or a previous session that didn't close properly.`,
        'Force Close Previous Connection',
        'Cancel'
      );
      
      if (userChoice === 'Force Close Previous Connection') {
        try {
          logger.info('User chose to force close previous connection, attempting to restart servers...');
          const currentExtensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
          if (currentExtensionState) {
            await currentExtensionState.forceRestartServers();
            vscode.window.showInformationMessage('Kiro Communication Bridge restarted successfully!');
          } else {
            throw new Error('Extension state is not initialized');
          }
        } catch (restartError: unknown) {
          const restartErrorMessage: string = restartError instanceof Error ? restartError.message : 'Unknown error';
          logger.error(`Failed to restart servers: ${restartErrorMessage}`);
          vscode.window.showErrorMessage(`Failed to restart servers: ${restartErrorMessage}`);
        }
      }
    } else {
      vscode.window.showErrorMessage(`Failed to activate Kiro Communincation Bridge Extension: ${errorMessage}`);
    }
  }
}

/**
 * Called when the extension is deactivated.
 * 
 * This function performs cleanup operations including stopping servers,
 * saving state, and disposing of resources.
 */
export async function deactivate(): Promise<void> {
  try {
    const logger: Logger = new Logger('Extension');
    logger.info('Deactivating Kiro Communication Bridge Extension...');

    // Get current extension state and perform cleanup
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (extensionState) {
      logger.info('Stopping orchestration servers...');
      
      // Use a timeout to ensure deactivation doesn't hang
      const stopPromise = extensionState.stopServers();
      const timeoutPromise = new Promise<void>((resolve) => {
        setTimeout(() => {
          logger.warn('Server stop timeout reached, forcing cleanup');
          resolve();
        }, 10000); // 10 second timeout
      });
      
      await Promise.race([stopPromise, timeoutPromise]);
      
      logger.info('Disposing extension state...');
      await extensionState.dispose();
    }

    // Clear context variables
    await vscode.commands.executeCommand('setContext', 'kiroOrchestration.active', false);
    
    logger.info('Kiro Communication Bridge Extension deactivated successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    const logger: Logger = new Logger('Extension');
    logger.error(`Error during extension deactivation: ${errorMessage}`);
    
    // Even if cleanup fails, we should try to clear context
    try {
      await vscode.commands.executeCommand('setContext', 'kiroOrchestration.active', false);
    } catch (contextError) {
      logger.error('Failed to clear context variables during cleanup');
    }
  }
}