/**
 * Command registration for the Kiro Command Research Tool.
 * 
 * This module handles the registration of all VS Code commands
 * provided by the extension.
 */

import * as vscode from 'vscode';
import { 
  handleDiscoverCommands, 
  handleTestCommand, 
  handleGenerateDocumentation, 
  handleOpenExplorer,
  handleViewResults,
  handleResearchParameters
} from '../handlers/command-handlers';
import { 
  handleValidateParameters, 
  handleExecuteCommand 
} from '../handlers/advanced-handlers';

/**
 * Command definition interface for type safety.
 */
interface CommandDefinition {
  readonly id: string;
  readonly handler: (...args: any[]) => Promise<void>;
}

/**
 * Registers all extension commands with VS Code.
 * 
 * This function sets up command handlers for all user-facing
 * functionality provided by the extension.
 * 
 * @param context VS Code extension context for command registration
 */
export function registerCommands(context: vscode.ExtensionContext): void {
  console.log('Starting command registration...');

  const commands: CommandDefinition[] = [
    {
      id: 'kiroCommandResearch.discoverCommands',
      handler: handleDiscoverCommands
    },
    {
      id: 'kiroCommandResearch.testCommand',
      handler: handleTestCommand
    },
    {
      id: 'kiroCommandResearch.generateDocs',
      handler: handleGenerateDocumentation
    },
    {
      id: 'kiroCommandResearch.openExplorer',
      handler: handleOpenExplorer
    },
    {
      id: 'kiroCommandResearch.viewResults',
      handler: handleViewResults
    },
    {
      id: 'kiroCommandResearch.researchParameters',
      handler: handleResearchParameters
    },
    {
      id: 'kiroCommandResearch.validateParameters',
      handler: handleValidateParameters
    },
    {
      id: 'kiroCommandResearch.executeCommand',
      handler: handleExecuteCommand
    },
    {
      id: 'kiroCommandResearch.refreshExplorer',
      handler: async () => {
        const { ExtensionState } = await import('../core/extension-state');
        const extensionState = ExtensionState.getInstance();
        await extensionState.commandExplorer.refresh();
      }
    },
    {
      id: 'kiroCommandResearch.searchCommands',
      handler: async () => {
        const { ExtensionState } = await import('../core/extension-state');
        const extensionState = ExtensionState.getInstance();
        await extensionState.commandExplorer.showSearchInput();
      }
    },
    {
      id: 'kiroCommandResearch.changeGrouping',
      handler: async () => {
        const { ExtensionState } = await import('../core/extension-state');
        const extensionState = ExtensionState.getInstance();
        await extensionState.commandExplorer.showGroupingOptions();
      }
    },
    {
      id: 'kiroCommandResearch.showCommandDetails',
      handler: async (command: any) => {
        const { ExtensionState } = await import('../core/extension-state');
        const extensionState = ExtensionState.getInstance();
        await extensionState.commandExplorer.showCommandDetails(command);
      }
    },
    {
      id: 'kiroCommandResearch.testCommandFromExplorer',
      handler: async (item: any) => {
        if (item && item.commandMetadata) {
          await handleTestCommand(item.commandMetadata);
        }
      }
    },
    {
      id: 'kiroCommandResearch.openDashboard',
      handler: async () => {
        const { ExtensionState } = await import('../core/extension-state');
        const extensionState = ExtensionState.getInstance();
        await extensionState.dashboard.openDashboard();
      }
    },
    {
      id: 'kiroCommandResearch.editParameters',
      handler: async (item?: any) => {
        const { ExtensionState } = await import('../core/extension-state');
        const extensionState = ExtensionState.getInstance();
        
        let command: any = null;
        
        if (item && item.commandMetadata) {
          // Called from command explorer
          command = item.commandMetadata;
        } else {
          // Called from command palette - show command picker
          const discoveryResults = await extensionState.storageManager.loadDiscoveryResults();
          if (!discoveryResults || discoveryResults.commands.length === 0) {
            vscode.window.showWarningMessage('No commands discovered yet. Please run command discovery first.');
            return;
          }
          
          const commandItems = discoveryResults.commands.map((cmd: any) => ({
            label: cmd.displayName,
            description: cmd.id,
            detail: cmd.description || 'No description available',
            command: cmd
          }));
          
          const selectedItem = await vscode.window.showQuickPick(commandItems, {
            placeHolder: 'Select a command to edit parameters for',
            matchOnDescription: true,
            matchOnDetail: true
          });
          
          if (selectedItem) {
            command = (selectedItem as any).command;
          }
        }
        
        if (command) {
          await extensionState.manualParameterEditor.openEditor(command);
        }
      }
    }
  ];

  for (const command of commands) {
    console.log(`Registering ${command.id}...`);
    const disposable = vscode.commands.registerCommand(
      command.id,
      async (...args: any[]) => {
        try {
          await command.handler(...args);
        } catch (error: unknown) {
          const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
          console.error(`Command ${command.id} failed:`, error);
          vscode.window.showErrorMessage(`Command failed: ${errorMessage}`);
        }
      }
    );
    context.subscriptions.push(disposable);
  }

  console.log(`All commands registered successfully. Total subscriptions: ${context.subscriptions.length}`);
}