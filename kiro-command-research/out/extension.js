"use strict";
/**
 * Main extension entry point for the Kiro Command Research Tool.
 *
 * This module handles extension activation, command registration,
 * and lifecycle management for the research tool.
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
exports.deactivate = exports.activate = void 0;
const vscode = __importStar(require("vscode"));
const file_storage_manager_1 = require("./storage/file-storage-manager");
const command_registry_scanner_1 = require("./discovery/command-registry-scanner");
/**
 * Extension context and global state management.
 *
 * This class maintains the global state of the extension and provides
 * access to shared resources like the database manager.
 */
class ExtensionState {
    constructor(context, storageManager, commandScanner) {
        this.context = context;
        this.storageManager = storageManager;
        this.commandScanner = commandScanner;
    }
    /**
     * Initializes the extension state singleton.
     *
     * @param context VS Code extension context
     * @returns Promise that resolves to the extension state instance
     */
    static async initialize(context) {
        if (ExtensionState.instance) {
            throw new Error('Extension state already initialized');
        }
        const storageManager = new file_storage_manager_1.FileStorageManager(context);
        await storageManager.initialize();
        const commandScanner = new command_registry_scanner_1.CommandRegistryScanner();
        ExtensionState.instance = new ExtensionState(context, storageManager, commandScanner);
        return ExtensionState.instance;
    }
    /**
     * Gets the current extension state instance.
     *
     * @returns The extension state instance
     * @throws Error if extension state is not initialized
     */
    static getInstance() {
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
    async dispose() {
        // No cleanup needed for file storage
        ExtensionState.instance = null;
    }
    /**
     * Gets the current extension state instance if it exists.
     *
     * @returns The extension state instance or null if not initialized
     */
    static getCurrentInstance() {
        return ExtensionState.instance;
    }
}
ExtensionState.instance = null;
/**
 * Called when the extension is activated.
 *
 * This function initializes the extension state, registers commands,
 * and sets up the user interface components.
 *
 * @param context VS Code extension context
 */
async function activate(context) {
    try {
        console.log('Activating Kiro Command Research Tool v0.5.0 (Simplified)...');
        console.log('Initializing file storage...');
        // Initialize extension state
        const extensionState = await ExtensionState.initialize(context);
        console.log('Extension state initialized successfully');
        console.log('Setting context variables...');
        // Set context variable to enable views
        await vscode.commands.executeCommand('setContext', 'kiroCommandResearch.active', true);
        console.log('Registering commands...');
        // Register commands
        registerCommands(context);
        // Show activation message
        vscode.window.showInformationMessage('Kiro Command Research Tool v0.5.0 (Simplified) activated successfully!');
        console.log('Kiro Command Research Tool v0.5.0 (Simplified) activated successfully');
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        const stack = error instanceof Error && error.stack ? error.stack : 'No stack trace';
        console.error(`Failed to activate extension: ${errorMessage}`);
        console.error('Stack trace:', stack);
        vscode.window.showErrorMessage(`Failed to activate Kiro Command Research Tool: ${errorMessage}`);
    }
}
exports.activate = activate;
/**
 * Called when the extension is deactivated.
 *
 * This function performs cleanup operations to ensure proper
 * resource disposal when the extension is disabled or VS Code closes.
 */
async function deactivate() {
    try {
        console.log('Deactivating Kiro Command Research Tool...');
        // Clean up extension state
        const extensionState = ExtensionState.getCurrentInstance();
        if (extensionState) {
            await extensionState.dispose();
        }
        // Clear context variable
        await vscode.commands.executeCommand('setContext', 'kiroCommandResearch.active', false);
        console.log('Kiro Command Research Tool deactivated successfully');
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        console.error(`Error during extension deactivation: ${errorMessage}`);
    }
}
exports.deactivate = deactivate;
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
    // Command: Discover Kiro Commands
    console.log('Registering kiroCommandResearch.discoverCommands...');
    const discoverCommandsDisposable = vscode.commands.registerCommand('kiroCommandResearch.discoverCommands', async () => {
        console.log('kiroCommandResearch.discoverCommands command executed!');
        try {
            await handleDiscoverCommands();
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            vscode.window.showErrorMessage(`Command discovery failed: ${errorMessage}`);
        }
    });
    console.log('kiroCommandResearch.discoverCommands registered successfully');
    // Command: Test Command
    const testCommandDisposable = vscode.commands.registerCommand('kiroCommandResearch.testCommand', async (commandId) => {
        try {
            await handleTestCommand(commandId);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            vscode.window.showErrorMessage(`Command testing failed: ${errorMessage}`);
        }
    });
    // Command: Generate Documentation
    const generateDocsDisposable = vscode.commands.registerCommand('kiroCommandResearch.generateDocs', async () => {
        try {
            await handleGenerateDocumentation();
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            vscode.window.showErrorMessage(`Documentation generation failed: ${errorMessage}`);
        }
    });
    // Command: Open Command Explorer
    const openExplorerDisposable = vscode.commands.registerCommand('kiroCommandResearch.openExplorer', async () => {
        try {
            await handleOpenExplorer();
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            vscode.window.showErrorMessage(`Failed to open command explorer: ${errorMessage}`);
        }
    });
    // Command: View Discovery Results
    const viewResultsDisposable = vscode.commands.registerCommand('kiroCommandResearch.viewResults', async () => {
        try {
            await handleViewResults();
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            vscode.window.showErrorMessage(`Failed to view results: ${errorMessage}`);
        }
    });
    // Register disposables for cleanup
    context.subscriptions.push(discoverCommandsDisposable, testCommandDisposable, generateDocsDisposable, openExplorerDisposable, viewResultsDisposable);
    console.log('All commands registered successfully. Total subscriptions:', context.subscriptions.length);
}
/**
 * Handles the discover commands operation.
 *
 * This function initiates the command discovery process to scan
 * and catalog all available Kiro commands in the VS Code environment.
 */
async function handleDiscoverCommands() {
    const extensionState = ExtensionState.getInstance();
    // Show progress indicator
    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: 'Discovering Kiro Commands',
        cancellable: false
    }, async (progress) => {
        try {
            progress.report({ message: 'Scanning command registry...' });
            // Discover Kiro commands
            const discoveredCommands = await extensionState.commandScanner.discoverKiroCommands();
            progress.report({ message: 'Generating statistics...' });
            // Create discovery results
            const results = extensionState.commandScanner.createDiscoveryResults(discoveredCommands);
            progress.report({ message: 'Saving results...' });
            // Save results to file
            await extensionState.storageManager.saveDiscoveryResults(results);
            await extensionState.storageManager.logActivity(`Discovered ${results.totalCommands} commands`);
            // Show detailed results
            const message = `Discovery completed! Found ${results.totalCommands} commands (${results.kiroAgentCommands} kiroAgent, ${results.kiroCommands} kiro). Risk levels: ${results.statistics.safeCommands} safe, ${results.statistics.moderateCommands} moderate, ${results.statistics.destructiveCommands} destructive.`;
            vscode.window.showInformationMessage(message);
            console.log('Command discovery completed successfully:', results);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('Command discovery failed:', error);
            throw new Error(`Command discovery failed: ${errorMessage}`);
        }
    });
}
/**
 * Handles the test command operation.
 *
 * This function opens the command testing interface for the specified
 * command or prompts the user to select a command to test.
 *
 * @param commandId Optional command ID to test directly
 */
async function handleTestCommand(commandId) {
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
async function handleGenerateDocumentation() {
    // Show progress indicator
    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: 'Generating Documentation',
        cancellable: false
    }, async (progress) => {
        progress.report({ message: 'Loading command metadata...' });
        // TODO: Implement documentation generation logic
        // This will be implemented in task 5.1 and 5.2
        await new Promise(resolve => setTimeout(resolve, 1500)); // Placeholder
        progress.report({ message: 'Generating schemas and types...' });
        await new Promise(resolve => setTimeout(resolve, 1000)); // Placeholder
        progress.report({ message: 'Exporting documentation...' });
        await new Promise(resolve => setTimeout(resolve, 500)); // Placeholder
    });
    vscode.window.showInformationMessage('Documentation generation completed successfully!');
}
/**
 * Handles the open command explorer operation.
 *
 * This function focuses the command explorer view or creates it if
 * it doesn't exist, allowing users to browse discovered commands.
 */
async function handleOpenExplorer() {
    // Focus the command explorer view
    await vscode.commands.executeCommand('kiroCommandExplorer.focus');
    // TODO: Populate explorer with discovered commands
    // This will be implemented in task 7.1
    vscode.window.showInformationMessage('Command explorer interface will be implemented in task 7.1');
}
/**
 * Handles the view discovery results operation.
 *
 * This function opens the discovery results file for viewing
 * or shows information about where to find the results.
 */
async function handleViewResults() {
    const extensionState = ExtensionState.getInstance();
    try {
        // Check if results exist
        if (!extensionState.storageManager.hasDiscoveryResults()) {
            const runDiscovery = await vscode.window.showInformationMessage('No discovery results found. Would you like to run command discovery first?', 'Run Discovery', 'Cancel');
            if (runDiscovery === 'Run Discovery') {
                await handleDiscoverCommands();
            }
            return;
        }
        // Get storage info
        const storageInfo = extensionState.storageManager.getStorageInfo();
        const resultsPath = `${storageInfo.storageDir}/discovery-results.json`;
        // Try to open the results file
        try {
            const resultsUri = vscode.Uri.file(resultsPath);
            const document = await vscode.workspace.openTextDocument(resultsUri);
            await vscode.window.showTextDocument(document);
            // Load and show summary
            const results = await extensionState.storageManager.loadDiscoveryResults();
            if (results) {
                const summary = `Discovery Results Summary:
• Total Commands: ${results.totalCommands}
• kiroAgent Commands: ${results.kiroAgentCommands}
• kiro Commands: ${results.kiroCommands}
• Safe Commands: ${results.statistics.safeCommands}
• Moderate Risk: ${results.statistics.moderateCommands}
• Destructive Commands: ${results.statistics.destructiveCommands}
• Discovery Date: ${new Date(results.discoveryTimestamp).toLocaleString()}`;
                vscode.window.showInformationMessage(summary);
            }
        }
        catch (error) {
            // If file can't be opened, show the path
            vscode.window.showInformationMessage(`Discovery results are stored at: ${resultsPath}`, 'Open Folder').then(selection => {
                if (selection === 'Open Folder') {
                    vscode.commands.executeCommand('revealFileInOS', vscode.Uri.file(storageInfo.storageDir));
                }
            });
        }
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        vscode.window.showErrorMessage(`Failed to view results: ${errorMessage}`);
    }
}
//# sourceMappingURL=extension.js.map