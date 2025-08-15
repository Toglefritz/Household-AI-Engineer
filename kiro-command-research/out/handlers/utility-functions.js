"use strict";
/**
 * Utility functions for command handling and parameter processing.
 *
 * This module contains helper functions used by command handlers
 * for parameter parsing, validation, and result formatting.
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
exports.showSideEffectsDetails = exports.handleRestoreSnapshot = exports.showExecutionResults = exports.collectParametersForExecution = exports.formatValidationResults = exports.parseParameterValue = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Parses a parameter value from string input based on expected type.
 *
 * @param value String value from user input
 * @param type Expected parameter type
 * @returns Parsed value
 */
function parseParameterValue(value, type) {
    const lowerType = type.toLowerCase();
    switch (lowerType) {
        case 'number':
            const numValue = Number(value);
            return isNaN(numValue) ? value : numValue;
        case 'boolean':
            if (value.toLowerCase() === 'true' || value === '1')
                return true;
            if (value.toLowerCase() === 'false' || value === '0')
                return false;
            return value;
        case 'object':
            try {
                return JSON.parse(value);
            }
            catch {
                return value;
            }
        case 'array':
            try {
                return JSON.parse(value);
            }
            catch {
                // Try comma-separated values
                return value.split(',').map(v => v.trim());
            }
        case 'vscode.uri':
            return value; // Will be converted by validator
        default:
            return value;
    }
}
exports.parseParameterValue = parseParameterValue;
/**
 * Formats validation results for display.
 *
 * @param result Validation result
 * @param commandId Command ID
 * @returns Formatted message
 */
function formatValidationResults(result, commandId) {
    let message = `Parameter validation for '${commandId}':\n\n`;
    if (result.valid) {
        message += '✅ Validation PASSED\n\n';
        if (result.value && Object.keys(result.value).length > 0) {
            message += 'Validated parameters:\n';
            for (const [key, value] of Object.entries(result.value)) {
                message += `  • ${key}: ${JSON.stringify(value)}\n`;
            }
            message += '\n';
        }
    }
    else {
        message += '❌ Validation FAILED\n\n';
        message += 'Errors:\n';
        for (const error of result.errors) {
            message += `  • ${error.message}\n`;
        }
        message += '\n';
    }
    if (result.warnings.length > 0) {
        message += 'Warnings:\n';
        for (const warning of result.warnings) {
            message += `  ⚠️ ${warning.message}\n`;
        }
    }
    return message;
}
exports.formatValidationResults = formatValidationResults;
/**
 * Collects parameters for command execution.
 *
 * @param parameters Parameter definitions
 * @returns Promise that resolves to parameter values
 */
async function collectParametersForExecution(parameters) {
    const parameterValues = {};
    for (const parameter of parameters) {
        const prompt = `Enter value for '${parameter.name}' (${parameter.type})${parameter.required ? ' *required*' : ' (optional)'}`;
        const placeholder = parameter.description || `${parameter.type} value`;
        const value = await vscode.window.showInputBox({
            prompt,
            placeHolder: placeholder,
            ignoreFocusOut: true
        });
        if (value === undefined) {
            return {}; // User cancelled
        }
        if (value !== '') {
            parameterValues[parameter.name] = parseParameterValue(value, parameter.type);
        }
    }
    return parameterValues;
}
exports.collectParametersForExecution = collectParametersForExecution;
/**
 * Shows detailed execution results to the user.
 *
 * @param result Execution result
 * @param extensionState Extension state
 */
async function showExecutionResults(result, extensionState) {
    const statusEmoji = result.success ? '✅' : '❌';
    const statusText = result.success ? 'SUCCESS' : 'FAILED';
    let message = `${statusEmoji} Command Execution ${statusText}

Command: ${result.commandId}
Duration: ${result.duration}ms
Parameters: ${JSON.stringify(result.parameters, null, 2)}`;
    if (result.sideEffects.length > 0) {
        message += `\n\nSide Effects Detected (${result.sideEffects.length}):`;
        for (const effect of result.sideEffects.slice(0, 5)) { // Show first 5
            message += `\n• ${effect.description}`;
        }
        if (result.sideEffects.length > 5) {
            message += `\n• ... and ${result.sideEffects.length - 5} more`;
        }
    }
    if (result.error) {
        message += `\n\nError: ${result.error.message}`;
        if (result.error.recoverable) {
            message += ' (Recoverable)';
        }
    }
    if (result.snapshotId) {
        message += `\n\nWorkspace snapshot created: ${result.snapshotId}`;
    }
    const actions = ['Close'];
    if (result.snapshotId) {
        actions.unshift('Restore Snapshot');
    }
    if (result.sideEffects.length > 0) {
        actions.unshift('View Side Effects');
    }
    const action = await vscode.window.showInformationMessage(message, ...actions);
    if (action === 'Restore Snapshot' && result.snapshotId) {
        await handleRestoreSnapshot(result.snapshotId, extensionState);
    }
    else if (action === 'View Side Effects') {
        await showSideEffectsDetails(result.sideEffects);
    }
}
exports.showExecutionResults = showExecutionResults;
/**
 * Handles snapshot restoration.
 *
 * @param snapshotId Snapshot ID to restore
 * @param extensionState Extension state
 */
async function handleRestoreSnapshot(snapshotId, extensionState) {
    try {
        await extensionState.commandExecutor.restoreWorkspaceSnapshot(snapshotId);
        vscode.window.showInformationMessage(`✅ Workspace restored from snapshot ${snapshotId}`);
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        vscode.window.showErrorMessage(`Failed to restore snapshot: ${errorMessage}`);
    }
}
exports.handleRestoreSnapshot = handleRestoreSnapshot;
/**
 * Shows detailed side effects information.
 *
 * @param sideEffects Array of side effects
 */
async function showSideEffectsDetails(sideEffects) {
    const details = sideEffects.map(effect => `${effect.timestamp.toLocaleTimeString()}: ${effect.description}`).join('\n');
    const document = await vscode.workspace.openTextDocument({
        content: `Side Effects Detected:\n\n${details}`,
        language: 'plaintext'
    });
    await vscode.window.showTextDocument(document);
}
exports.showSideEffectsDetails = showSideEffectsDetails;
//# sourceMappingURL=utility-functions.js.map