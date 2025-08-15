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
    },
    {
      id: 'kiroCommandResearch.viewDocumentation',
      handler: async () => {
        const { ExtensionState } = await import('../core/extension-state');
        const extensionState = ExtensionState.getInstance();
        
        // Load discovery results to pass to the viewer
        const discoveryResults = await extensionState.storageManager.loadDiscoveryResults();
        const commands = discoveryResults?.commands || [];
        
        if (commands.length === 0) {
          vscode.window.showWarningMessage('No commands available for documentation viewing. Please run command discovery first.');
          return;
        }
        
        await extensionState.documentationViewer.openViewer(commands, []);
      }
    },
    {
      id: 'kiroCommandResearch.openExportDirectory',
      handler: async () => {
        const { DocumentationExporter } = await import('../export/documentation-exporter');
        const exporter = new DocumentationExporter();
        const exportDir = exporter.getExportDirectory();
        
        try {
          const uri = vscode.Uri.file(exportDir);
          await vscode.commands.executeCommand('vscode.openFolder', uri, { forceNewWindow: false });
        } catch (error: unknown) {
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          vscode.window.showErrorMessage(`Failed to open export directory: ${errorMessage}`);
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