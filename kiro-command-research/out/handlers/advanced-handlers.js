"use strict";
/**
 * Advanced command handlers for parameter validation and execution.
 *
 * This module contains the more complex command handlers that deal with
 * parameter validation, command execution, and interactive interfaces.
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
exports.handleExecuteCommand = exports.handleValidateParameters = void 0;
const vscode = __importStar(require("vscode"));
const extension_state_1 = require("../core/extension-state");
const utility_functions_1 = require("./utility-functions");
/**
 * Handles the validate command parameters operation.
 *
 * This function provides an interactive interface for testing parameter
 * validation with discovered command signatures.
 */
async function handleValidateParameters() {
    const extensionState = extension_state_1.ExtensionState.getInstance();
    try {
        // Check if discovery results exist
        if (!extensionState.storageManager.hasDiscoveryResults()) {
            vscode.window.showInformationMessage('No discovery results found. Please run command discovery first.');
            return;
        }
        // Load discovery results
        const discoveryResults = await extensionState.storageManager.loadDiscoveryResults();
        if (!discoveryResults) {
            vscode.window.showErrorMessage('Failed to load discovery results');
            return;
        }
        // Get commands with signatures
        const commandsWithSignatures = discoveryResults.commands.filter((cmd) => cmd.signature && cmd.signature.parameters && cmd.signature.parameters.length > 0);
        if (commandsWithSignatures.length === 0) {
            const runResearch = await vscode.window.showInformationMessage('No commands with parameter signatures found. Would you like to run parameter research first?', 'Run Parameter Research', 'Cancel');
            if (runResearch === 'Run Parameter Research') {
                const { handleResearchParameters } = await Promise.resolve().then(() => __importStar(require('./command-handlers')));
                await handleResearchParameters();
            }
            return;
        }
        // Let user select a command to validate
        const commandItems = commandsWithSignatures.map((cmd) => ({
            label: cmd.id,
            description: `${cmd.signature.parameters.length} parameters (${cmd.signature.confidence} confidence)`,
            detail: cmd.description,
            command: cmd
        }));
        const selectedItem = await vscode.window.showQuickPick(commandItems, {
            placeHolder: 'Select a command to validate parameters for',
            matchOnDescription: true,
            matchOnDetail: true
        });
        if (!selectedItem) {
            return;
        }
        const command = selectedItem.command;
        const parameters = command.signature.parameters;
        // Show parameter validation interface
        await showParameterValidationInterface(command, parameters, extensionState);
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        vscode.window.showErrorMessage(`Failed to validate parameters: ${errorMessage}`);
    }
}
exports.handleValidateParameters = handleValidateParameters;
/**
 * Shows an interactive parameter validation interface.
 *
 * @param command Command to validate parameters for
 * @param parameters Parameter definitions
 * @param extensionState Extension state
 */
async function showParameterValidationInterface(command, parameters, extensionState) {
    const parameterValues = {};
    // Collect parameter values from user
    for (const parameter of parameters) {
        const prompt = `Enter value for parameter '${parameter.name}' (${parameter.type})${parameter.required ? ' *required*' : ' (optional)'}`;
        const placeholder = parameter.description || `${parameter.type} value`;
        const value = await vscode.window.showInputBox({
            prompt,
            placeHolder: placeholder,
            ignoreFocusOut: true
        });
        if (value === undefined) {
            // User cancelled
            return;
        }
        if (value !== '') {
            // Parse the value based on type
            parameterValues[parameter.name] = (0, utility_functions_1.parseParameterValue)(value, parameter.type);
        }
    }
    // Create validation context
    const context = {
        commandId: command.id,
        workspace: vscode.workspace.workspaceFolders?.[0],
        activeEditor: vscode.window.activeTextEditor,
        context: {}
    };
    // Validate parameters
    const validationResult = await extensionState.parameterValidator.validateParameters(parameters, parameterValues, context);
    // Show validation results
    const resultMessage = (0, utility_functions_1.formatValidationResults)(validationResult, command.id);
    if (validationResult.valid) {
        const testCommand = await vscode.window.showInformationMessage(resultMessage, 'Test Command', 'Close');
        if (testCommand === 'Test Command') {
            await showCommandTestConfirmation(command, validationResult.value, extensionState);
        }
    }
    else {
        vscode.window.showErrorMessage(resultMessage);
    }
}
/**
 * Shows confirmation dialog for testing a command with validated parameters.
 *
 * @param command Command to test
 * @param validatedParams Validated parameter values
 * @param extensionState Extension state
 */
async function showCommandTestConfirmation(command, validatedParams, extensionState) {
    const riskLevel = command.riskLevel || 'unknown';
    const riskEmoji = riskLevel === 'safe' ? '🟢' : riskLevel === 'moderate' ? '🟡' : '🔴';
    const confirmMessage = `${riskEmoji} Test command '${command.id}' with validated parameters?

Risk Level: ${riskLevel}
Parameters: ${JSON.stringify(validatedParams, null, 2)}

⚠️ This will execute the actual command in Kiro IDE with safety monitoring.`;
    const options = ['Execute Safely', 'Execute with Snapshot', 'Cancel'];
    const confirm = await vscode.window.showWarningMessage(confirmMessage, { modal: true }, ...options);
    if (confirm && confirm !== 'Cancel') {
        const createSnapshot = confirm === 'Execute with Snapshot';
        // Create execution context
        const executionContext = {
            command,
            parameters: validatedParams,
            timeoutMs: 30000,
            createSnapshot,
            requireConfirmation: true,
            context: {}
        };
        // Execute with progress indicator
        await vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: `Executing ${command.id}`,
            cancellable: false
        }, async (progress) => {
            progress.report({ message: 'Preparing execution...' });
            if (createSnapshot) {
                progress.report({ message: 'Creating workspace snapshot...' });
            }
            progress.report({ message: 'Executing command...' });
            const result = await extensionState.commandExecutor.executeCommand(executionContext);
            progress.report({ message: 'Processing results...' });
            // Log the execution result
            await extensionState.storageManager.logActivity(`Command execution result for '${command.id}': ${result.success ? 'SUCCESS' : 'FAILED'} (${result.duration}ms)`);
            // Show detailed results
            await (0, utility_functions_1.showExecutionResults)(result, extensionState);
        });
    }
}
/**
 * Handles the execute command operation with full safety features.
 */
async function handleExecuteCommand() {
    const extensionState = extension_state_1.ExtensionState.getInstance();
    try {
        // Check if discovery results exist
        if (!extensionState.storageManager.hasDiscoveryResults()) {
            vscode.window.showInformationMessage('No discovery results found. Please run command discovery first.');
            return;
        }
        // Load discovery results
        const discoveryResults = await extensionState.storageManager.loadDiscoveryResults();
        if (!discoveryResults) {
            vscode.window.showErrorMessage('Failed to load discovery results');
            return;
        }
        // Get all commands (not just those with signatures)
        const allCommands = discoveryResults.commands;
        if (allCommands.length === 0) {
            vscode.window.showInformationMessage('No commands found in discovery results.');
            return;
        }
        // Let user select a command to execute
        const commandItems = allCommands.map((cmd) => ({
            label: cmd.id,
            description: `${cmd.riskLevel} risk${cmd.signature ? ` • ${cmd.signature.parameters.length} params` : ' • no params'}`,
            detail: cmd.description,
            command: cmd
        }));
        const selectedItem = await vscode.window.showQuickPick(commandItems, {
            placeHolder: 'Select a command to execute safely',
            matchOnDescription: true,
            matchOnDetail: true
        });
        if (!selectedItem) {
            return;
        }
        const command = selectedItem.command;
        // If command has parameters, collect them
        let parameters = {};
        if (command.signature && command.signature.parameters && command.signature.parameters.length > 0) {
            parameters = await (0, utility_functions_1.collectParametersForExecution)(command.signature.parameters);
            if (Object.keys(parameters).length === 0 && command.signature.parameters.some((p) => p.required)) {
                return; // User cancelled or didn't provide required parameters
            }
        }
        // Create execution context with safety settings
        const executionContext = {
            command,
            parameters,
            timeoutMs: command.riskLevel === 'destructive' ? 10000 : 30000,
            createSnapshot: command.riskLevel !== 'safe',
            requireConfirmation: true,
            context: {}
        };
        // Show final confirmation
        const riskEmoji = command.riskLevel === 'safe' ? '🟢' : command.riskLevel === 'moderate' ? '🟡' : '🔴';
        const snapshotText = executionContext.createSnapshot ? ' (with workspace snapshot)' : '';
        const confirm = await vscode.window.showWarningMessage(`${riskEmoji} Execute '${command.id}' safely${snapshotText}?`, { modal: true }, 'Execute', 'Cancel');
        if (confirm === 'Execute') {
            // Execute with progress indicator
            await vscode.window.withProgress({
                location: vscode.ProgressLocation.Notification,
                title: `Safely executing ${command.id}`,
                cancellable: false
            }, async (progress) => {
                const result = await extensionState.commandExecutor.executeCommand(executionContext);
                await (0, utility_functions_1.showExecutionResults)(result, extensionState);
            });
        }
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        vscode.window.showErrorMessage(`Failed to execute command: ${errorMessage}`);
    }
}
exports.handleExecuteCommand = handleExecuteCommand;
//# sourceMappingURL=advanced-handlers.js.map