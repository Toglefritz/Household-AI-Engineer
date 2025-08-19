/**
 * Main extension entry point for the Kiro Orchestration Extension.
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
 * This function initializes the orchestration system, starts the API and WebSocket
 * servers, and registers all commands for managing the development workflow.
 */
export async function activate(context: vscode.ExtensionContext): Promise<void> {
  try {
    const logger: Logger = new Logger('Extension');
    logger.info('Activating Kiro Orchestration Extension v0.1.0...');

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
      await extensionState.startServers();
    } else {
      logger.info('Auto-start disabled, servers can be started manually using commands');
    }

    // Show success message
    const message: string = 'Kiro Orchestration Extension v0.1.0 activated successfully!';
    vscode.window.showInformationMessage(message);
    logger.info('Kiro Orchestration Extension v0.1.0 activated successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    const stack: string = error instanceof Error && error.stack ? error.stack : 'No stack trace';
    
    const logger: Logger = new Logger('Extension');
    logger.error(`Failed to activate extension: ${errorMessage}`);
    logger.error('Stack trace:', stack);
    
    vscode.window.showErrorMessage(`Failed to activate Kiro Orchestration Extension: ${errorMessage}`);
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
    logger.info('Deactivating Kiro Orchestration Extension...');

    // Get current extension state and perform cleanup
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (extensionState) {
      logger.info('Stopping orchestration servers...');
      await extensionState.stopServers();
      
      logger.info('Disposing extension state...');
      await extensionState.dispose();
    }

    // Clear context variables
    await vscode.commands.executeCommand('setContext', 'kiroOrchestration.active', false);
    
    logger.info('Kiro Orchestration Extension deactivated successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    const logger: Logger = new Logger('Extension');
    logger.error(`Error during extension deactivation: ${errorMessage}`);
  }
}