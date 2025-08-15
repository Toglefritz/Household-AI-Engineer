"use strict";
/**
 * Command handlers for the Kiro Command Research Tool.
 *
 * This module contains all the command handler functions that were
 * previously in the main extension.ts file.
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
exports.handleResearchParameters = exports.handleViewResults = exports.handleOpenExplorer = exports.handleGenerateDocumentation = exports.handleTestCommand = exports.handleDiscoverCommands = void 0;
const vscode = __importStar(require("vscode"));
const extension_state_1 = require("../core/extension-state");
/**
 * Handles the discover commands operation.
 */
async function handleDiscoverCommands() {
    const extensionState = extension_state_1.ExtensionState.getInstance();
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
} /**
 * Handles the test command operation.
 */
exports.handleDiscoverCommands = handleDiscoverCommands;
async function handleTestCommand(commandId) {
    const extensionState = extension_state_1.ExtensionState.getInstance();
    let command;
    if (typeof commandId === 'string') {
        // Load command metadata from storage
        const discoveryResults = await extensionState.storageManager.loadDiscoveryResults();
        if (discoveryResults) {
            command = discoveryResults.commands.find((cmd) => cmd.id === commandId);
        }
    }
    else if (commandId && typeof commandId === 'object') {
        // Command metadata passed directly
        command = commandId;
    }
    if (!command) {
        // Show command picker
        const discoveryResults = await extensionState.storageManager.loadDiscoveryResults();
        if (!discoveryResults || discoveryResults.commands.length === 0) {
            vscode.window.showInformationMessage('No commands found. Please run command discovery first.');
            return;
        }
        const commandItems = discoveryResults.commands.map((cmd) => ({
            label: cmd.displayName,
            description: cmd.id,
            detail: cmd.description,
            command: cmd
        }));
        const selectedItem = await vscode.window.showQuickPick(commandItems, {
            placeHolder: 'Select a command to test',
            matchOnDescription: true,
            matchOnDetail: true
        });
        if (!selectedItem) {
            return;
        }
        command = selectedItem.command;
    }
    // Open testing interface
    if (command) {
        await extensionState.testingInterface.openTestingInterface(command);
    }
}
exports.handleTestCommand = handleTestCommand;
/**
 * Handles the generate documentation operation.
 */
async function handleGenerateDocumentation() {
    const extensionState = extension_state_1.ExtensionState.getInstance();
    // Open documentation manager
    await extensionState.documentationManager.openManager();
}
exports.handleGenerateDocumentation = handleGenerateDocumentation;
/**
 * Handles the open command explorer operation.
 */
async function handleOpenExplorer() {
    const extensionState = extension_state_1.ExtensionState.getInstance();
    // Refresh the command explorer
    await extensionState.commandExplorer.refresh();
    // Focus the command explorer view
    await vscode.commands.executeCommand('kiroCommandExplorer.focus');
} /**
 * Handles the view discovery results operation.
 */
exports.handleOpenExplorer = handleOpenExplorer;
async function handleViewResults() {
    const extensionState = extension_state_1.ExtensionState.getInstance();
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
exports.handleViewResults = handleViewResults;
/**
 * Handles the research command parameters operation.
 */
async function handleResearchParameters() {
    const extensionState = extension_state_1.ExtensionState.getInstance();
    try {
        // Check if discovery results exist
        if (!extensionState.storageManager.hasDiscoveryResults()) {
            const runDiscovery = await vscode.window.showInformationMessage('No discovery results found. Would you like to run command discovery first?', 'Run Discovery', 'Cancel');
            if (runDiscovery === 'Run Discovery') {
                await handleDiscoverCommands();
                // Continue with parameter research after discovery
            }
            else {
                return;
            }
        }
        // Load existing discovery results
        const discoveryResults = await extensionState.storageManager.loadDiscoveryResults();
        if (!discoveryResults) {
            vscode.window.showErrorMessage('Failed to load discovery results');
            return;
        }
        // Show progress indicator
        await vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: 'Researching Command Parameters',
            cancellable: false
        }, async (progress) => {
            try {
                progress.report({ message: 'Analyzing command signatures...' });
                // Extract command IDs from discovery results
                const commandIds = discoveryResults.commands.map((cmd) => cmd.id);
                // Research parameters for all commands
                const signatures = await extensionState.parameterResearcher.researchCommands(commandIds);
                progress.report({ message: 'Updating command metadata...' });
                // Update commands with signature information
                const updatedCommands = discoveryResults.commands.map((cmd) => {
                    const signature = signatures.find(s => s.commandId === cmd.id);
                    return {
                        ...cmd,
                        signature: signature ? {
                            parameters: signature.parameters,
                            returnType: signature.returnType,
                            async: signature.async,
                            confidence: signature.confidence,
                            sources: signature.sources,
                            researchedAt: signature.researchedAt
                        } : undefined
                    };
                });
                // Update discovery results with parameter information
                const updatedResults = {
                    ...discoveryResults,
                    commands: updatedCommands,
                    parameterResearch: {
                        researchedAt: new Date(),
                        statistics: extensionState.parameterResearcher.getResearchStatistics(signatures)
                    }
                };
                progress.report({ message: 'Saving updated results...' });
                // Save updated results
                await extensionState.storageManager.saveDiscoveryResults(updatedResults);
                await extensionState.storageManager.logActivity(`Researched parameters for ${signatures.length} commands`);
                // Generate statistics
                const stats = extensionState.parameterResearcher.getResearchStatistics(signatures);
                // Show detailed results
                const message = `Parameter research completed! Analyzed ${stats.totalCommands} commands. Confidence levels: ${stats.highConfidence} high, ${stats.mediumConfidence} medium, ${stats.lowConfidence} low. Found parameters for ${stats.withParameters} commands.`;
                vscode.window.showInformationMessage(message);
                console.log('Parameter research completed successfully:', stats);
            }
            catch (error) {
                const errorMessage = error instanceof Error ? error.message : 'Unknown error';
                console.error('Parameter research failed:', error);
                throw new Error(`Parameter research failed: ${errorMessage}`);
            }
        });
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        vscode.window.showErrorMessage(`Failed to research parameters: ${errorMessage}`);
    }
}
exports.handleResearchParameters = handleResearchParameters;
//# sourceMappingURL=command-handlers.js.map