/**
 * Main extension entry point for the Kiro Command Research Tool.
 * 
 * This module handles extension activation, command registration,
 * and lifecycle management for the research tool.
 */

import * as vscode from 'vscode';
import { DatabaseManager } from './database/database-manager';

/**
 * Extension context and global state management.
 * 
 * This class maintains the global state of the extension and provides
 * access to shared resources like the database manager.
 */
class ExtensionState {
  private static instance: ExtensionState | null = null;
  
  private constructor(
    public readonly context: vscode.ExtensionContext,
    public readonly databaseManager: DatabaseManager
  ) {}
  
  /**
   * Initializes the extension state singleton.
   * 
   * @param context VS Code extension context
   * @returns Promise that resolves to the extension state instance
   */
  public static async initialize(context: vscode.ExtensionContext): Promise<ExtensionState> {
    if (ExtensionState.instance) {
      throw new Error('Extension state already initialized');
    }
    
    const databaseManager: DatabaseManager = new DatabaseManager(context);
    await databaseManager.initialize();
    
    ExtensionState.instance = new ExtensionState(context, databaseManager);
    return ExtensionState.instance;
  }
  
  /**
   * Gets the current extension state instance.
   * 
   * @returns The extension state instance
   * @throws Error if extension state is not initialized
   */
  public static getInstance(): ExtensionState {
    if (!ExtensionState.instance) {
      throw new Error('Extension state not initialized');
    }
    return ExtensionState.instance;
  }
  
  /**
   * Cleans up extension resources.
   * 
   * @returns Promise that resolves when cleanup is complete
   */
  public async dispose(): Promise<void> {
    await this.databaseManager.close();
    ExtensionState.instance = null;
  }
  
  /**
   * Gets the current extension state instance if it exists.
   * 
   * @returns The extension state instance or null if not initialized
   */
  public static getCurrentInstance(): ExtensionState | null {
    return ExtensionState.instance;
  }
}

/**
 * Called when the extension is activated.
 * 
 * This function initializes the extension state, registers commands,
 * and sets up the user interface components.
 * 
 * @param context VS Code extension context
 */
export async function activate(context: vscode.ExtensionContext): Promise<void> {
  try {
    console.log('Activating Kiro Command Research Tool...');
    
    // Initialize extension state
    const extensionState: ExtensionState = await ExtensionState.initialize(context);
    
    // Set context variable to enable views
    await vscode.commands.executeCommand('setContext', 'kiroCommandResearch.active', true);
    
    // Register commands
    registerCommands(context);
    
    // Show activation message
    vscode.window.showInformationMessage('Kiro Command Research Tool activated successfully!');
    
    console.log('Kiro Command Research Tool activated successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    console.error(`Failed to activate extension: ${errorMessage}`);
    vscode.window.showErrorMessage(`Failed to activate Kiro Command Research Tool: ${errorMessage}`);
  }
}

/**
 * Called when the extension is deactivated.
 * 
 * This function performs cleanup operations to ensure proper
 * resource disposal when the extension is disabled or VS Code closes.
 */
export async function deactivate(): Promise<void> {
  try {
    console.log('Deactivating Kiro Command Research Tool...');
    
    // Clean up extension state
    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (extensionState) {
      await extensionState.dispose();
    }
    
    // Clear context variable
    await vscode.commands.executeCommand('setContext', 'kiroCommandResearch.active', false);
    
    console.log('Kiro Command Research Tool deactivated successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    console.error(`Error during extension deactivation: ${errorMessage}`);
  }
}

/**
 * Registers all extension commands with VS Code.
 * 
 * This function sets up command handlers for all user-facing
 * functionality provided by the extension.
 * 
 * @param context VS Code extension context for command registration
 */
function registerCommands(context: vscode.ExtensionContext): void {
  // Command: Discover Kiro Commands
  const discoverCommandsDisposable: vscode.Disposable = vscode.commands.registerCommand(
    'kiroCommandResearch.discoverCommands',
    async () => {
      try {
        await handleDiscoverCommands();
      } catch (error: unknown) {
        const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
        vscode.window.showErrorMessage(`Command discovery failed: ${errorMessage}`);
      }
    }
  );
  
  // Command: Test Command
  const testCommandDisposable: vscode.Disposable = vscode.commands.registerCommand(
    'kiroCommandResearch.testCommand',
    async (commandId?: string) => {
      try {
        await handleTestCommand(commandId);
      } catch (error: unknown) {
        const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
        vscode.window.showErrorMessage(`Command testing failed: ${errorMessage}`);
      }
    }
  );
  
  // Command: Generate Documentation
  const generateDocsDisposable: vscode.Disposable = vscode.commands.registerCommand(
    'kiroCommandResearch.generateDocs',
    async () => {
      try {
        await handleGenerateDocumentation();
      } catch (error: unknown) {
        const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
        vscode.window.showErrorMessage(`Documentation generation failed: ${errorMessage}`);
      }
    }
  );
  
  // Command: Open Command Explorer
  const openExplorerDisposable: vscode.Disposable = vscode.commands.registerCommand(
    'kiroCommandResearch.openExplorer',
    async () => {
      try {
        await handleOpenExplorer();
      } catch (error: unknown) {
        const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
        vscode.window.showErrorMessage(`Failed to open command explorer: ${errorMessage}`);
      }
    }
  );
  
  // Register disposables for cleanup
  context.subscriptions.push(
    discoverCommandsDisposable,
    testCommandDisposable,
    generateDocsDisposable,
    openExplorerDisposable
  );
}

/**
 * Handles the discover commands operation.
 * 
 * This function initiates the command discovery process to scan
 * and catalog all available Kiro commands in the VS Code environment.
 */
async function handleDiscoverCommands(): Promise<void> {
  // Show progress indicator
  await vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Notification,
      title: 'Discovering Kiro Commands',
      cancellable: false
    },
    async (progress) => {
      progress.report({ message: 'Scanning command registry...' });
      
      // TODO: Implement command discovery logic
      // This will be implemented in task 2.1
      await new Promise(resolve => setTimeout(resolve, 2000)); // Placeholder
      
      progress.report({ message: 'Analyzing command signatures...' });
      await new Promise(resolve => setTimeout(resolve, 1000)); // Placeholder
      
      progress.report({ message: 'Storing command metadata...' });
      await new Promise(resolve => setTimeout(resolve, 500)); // Placeholder
    }
  );
  
  vscode.window.showInformationMessage('Command discovery completed successfully!');
}

/**
 * Handles the test command operation.
 * 
 * This function opens the command testing interface for the specified
 * command or prompts the user to select a command to test.
 * 
 * @param commandId Optional command ID to test directly
 */
async function handleTestCommand(commandId?: string): Promise<void> {
  if (!commandId) {
    // TODO: Show command picker when no command specified
    // This will be implemented in task 7.2
    vscode.window.showInformationMessage('Command testing interface will be implemented in task 7.2');
    return;
  }
  
  // TODO: Open testing interface for specific command
  // This will be implemented in task 7.2
  vscode.window.showInformationMessage(`Testing interface for command '${commandId}' will be implemented in task 7.2`);
}

/**
 * Handles the generate documentation operation.
 * 
 * This function initiates the documentation generation process to create
 * comprehensive API documentation from discovered command metadata.
 */
async function handleGenerateDocumentation(): Promise<void> {
  // Show progress indicator
  await vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Notification,
      title: 'Generating Documentation',
      cancellable: false
    },
    async (progress) => {
      progress.report({ message: 'Loading command metadata...' });
      
      // TODO: Implement documentation generation logic
      // This will be implemented in task 5.1 and 5.2
      await new Promise(resolve => setTimeout(resolve, 1500)); // Placeholder
      
      progress.report({ message: 'Generating schemas and types...' });
      await new Promise(resolve => setTimeout(resolve, 1000)); // Placeholder
      
      progress.report({ message: 'Exporting documentation...' });
      await new Promise(resolve => setTimeout(resolve, 500)); // Placeholder
    }
  );
  
  vscode.window.showInformationMessage('Documentation generation completed successfully!');
}

/**
 * Handles the open command explorer operation.
 * 
 * This function focuses the command explorer view or creates it if
 * it doesn't exist, allowing users to browse discovered commands.
 */
async function handleOpenExplorer(): Promise<void> {
  // Focus the command explorer view
  await vscode.commands.executeCommand('kiroCommandExplorer.focus');
  
  // TODO: Populate explorer with discovered commands
  // This will be implemented in task 7.1
  vscode.window.showInformationMessage('Command explorer interface will be implemented in task 7.1');
}