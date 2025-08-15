"use strict";
/**
 * Command registration for the Kiro Command Research Tool.
 *
 * This module handles the registration of all VS Code commands
 * provided by the extension.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.registerCommands = void 0;
const vscode = __importStar(require("vscode"));
const command_handlers_1 = require("../handlers/command-handlers");
const advanced_handlers_1 = require("../handlers/advanced-handlers");
/**
 * Registers all extension commands with VS Code.
 *
 * This function sets up command handlers for all user-facing
 * functionality provided by the extension.
 *
 * @param context VS Code extension context for command registration
 */
function registerCommands(context) {
    console.log('Starting command registration...');
    const commands = [
        {
            id: 'kiroCommandResearch.discoverCommands',
            handler: command_handlers_1.handleDiscoverCommands
        },
        {
            id: 'kiroCommandResearch.testCommand',
            handler: command_handlers_1.handleTestCommand
        },
        {
            id: 'kiroCommandResearch.generateDocs',
            handler: command_handlers_1.handleGenerateDocumentation
        },
        {
            id: 'kiroCommandResearch.openExplorer',
            handler: command_handlers_1.handleOpenExplorer
        },
        {
            id: 'kiroCommandResearch.viewResults',
            handler: command_handlers_1.handleViewResults
        },
        {
            id: 'kiroCommandResearch.researchParameters',
            handler: command_handlers_1.handleResearchParameters
        },
        {
            id: 'kiroCommandResearch.validateParameters',
            handler: advanced_handlers_1.handleValidateParameters
        },
        {
            id: 'kiroCommandResearch.executeCommand',
            handler: advanced_handlers_1.handleExecuteCommand
        },
        {
            id: 'kiroCommandResearch.refreshExplorer',
            handler: async () => {
                const { ExtensionState } = await Promise.resolve().then(() => __importStar(require('../core/extension-state')));
                const extensionState = ExtensionState.getInstance();
                await extensionState.commandExplorer.refresh();
            }
        },
        {
            id: 'kiroCommandResearch.searchCommands',
            handler: async () => {
                const { ExtensionState } = await Promise.resolve().then(() => __importStar(require('../core/extension-state')));
                const extensionState = ExtensionState.getInstance();
                await extensionState.commandExplorer.showSearchInput();
            }
        },
        {
            id: 'kiroCommandResearch.changeGrouping',
            handler: async () => {
                const { ExtensionState } = await Promise.resolve().then(() => __importStar(require('../core/extension-state')));
                const extensionState = ExtensionState.getInstance();
                await extensionState.commandExplorer.showGroupingOptions();
            }
        },
        {
            id: 'kiroCommandResearch.showCommandDetails',
            handler: async (command) => {
                const { ExtensionState } = await Promise.resolve().then(() => __importStar(require('../core/extension-state')));
                const extensionState = ExtensionState.getInstance();
                await extensionState.commandExplorer.showCommandDetails(command);
            }
        },
        {
            id: 'kiroCommandResearch.testCommandFromExplorer',
            handler: async (item) => {
                if (item && item.commandMetadata) {
                    await (0, command_handlers_1.handleTestCommand)(item.commandMetadata);
                }
            }
        },
        {
            id: 'kiroCommandResearch.openDashboard',
            handler: async () => {
                const { ExtensionState } = await Promise.resolve().then(() => __importStar(require('../core/extension-state')));
                const extensionState = ExtensionState.getInstance();
                await extensionState.dashboard.openDashboard();
            }
        },
        {
            id: 'kiroCommandResearch.editParameters',
            handler: async (item) => {
                const { ExtensionState } = await Promise.resolve().then(() => __importStar(require('../core/extension-state')));
                const extensionState = ExtensionState.getInstance();
                let command = null;
                if (item && item.commandMetadata) {
                    // Called from command explorer
                    command = item.commandMetadata;
                }
                else {
                    // Called from command palette - show command picker
                    const discoveryResults = await extensionState.storageManager.loadDiscoveryResults();
                    if (!discoveryResults || discoveryResults.commands.length === 0) {
                        vscode.window.showWarningMessage('No commands discovered yet. Please run command discovery first.');
                        return;
                    }
                    const commandItems = discoveryResults.commands.map((cmd) => ({
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
                        command = selectedItem.command;
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
                const { ExtensionState } = await Promise.resolve().then(() => __importStar(require('../core/extension-state')));
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
                const { DocumentationExporter } = await Promise.resolve().then(() => __importStar(require('../export/documentation-exporter')));
                const exporter = new DocumentationExporter();
                const exportDir = exporter.getExportDirectory();
                try {
                    const uri = vscode.Uri.file(exportDir);
                    await vscode.commands.executeCommand('vscode.openFolder', uri, { forceNewWindow: false });
                }
                catch (error) {
                    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
                    vscode.window.showErrorMessage(`Failed to open export directory: ${errorMessage}`);
                }
            }
        }
    ];
    for (const command of commands) {
        console.log(`Registering ${command.id}...`);
        const disposable = vscode.commands.registerCommand(command.id, async (...args) => {
            try {
                await command.handler(...args);
            }
            catch (error) {
                const errorMessage = error instanceof Error ? error.message : 'Unknown error';
                console.error(`Command ${command.id} failed:`, error);
                vscode.window.showErrorMessage(`Command failed: ${errorMessage}`);
            }
        });
        context.subscriptions.push(disposable);
    }
    console.log(`All commands registered successfully. Total subscriptions: ${context.subscriptions.length}`);
}
exports.registerCommands = registerCommands;
//# sourceMappingURL=command-registration.js.map