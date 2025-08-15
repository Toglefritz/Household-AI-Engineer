/**
 * Utility functions for command handling and parameter processing.
 * 
 * This module contains helper functions used by command handlers
 * for parameter parsing, validation, and result formatting.
 */

import * as vscode from 'vscode';
import { ParameterInfo } from '../types/command-metadata';
import { ValidationResult } from '../testing/parameter-validator';
import { ExecutionResult } from '../testing/command-executor';
import { ExtensionState } from '../core/extension-state';

/**
 * Parses a parameter value from string input based on expected type.
 * 
 * @param value String value from user input
 * @param type Expected parameter type
 * @returns Parsed value
 */
export function parseParameterValue(value: string, type: string): any {
  const lowerType = type.toLowerCase();
  
  switch (lowerType) {
    case 'number':
      const numValue = Number(value);
      return isNaN(numValue) ? value : numValue;
      
    case 'boolean':
      if (value.toLowerCase() === 'true' || value === '1') return true;
      if (value.toLowerCase() === 'false' || value === '0') return false;
      return value;
      
    case 'object':
      try {
        return JSON.parse(value);
      } catch {
        return value;
      }
      
    case 'array':
      try {
        return JSON.parse(value);
      } catch {
        // Try comma-separated values
        return value.split(',').map(v => v.trim());
      }
      
    case 'vscode.uri':
      return value; // Will be converted by validator
      
    default:
      return value;
  }
}

/**
 * Formats validation results for display.
 * 
 * @param result Validation result
 * @param commandId Command ID
 * @returns Formatted message
 */
export function formatValidationResults(result: ValidationResult, commandId: string): string {
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
  } else {
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

/**
 * Collects parameters for command execution.
 * 
 * @param parameters Parameter definitions
 * @returns Promise that resolves to parameter values
 */
export async function collectParametersForExecution(parameters: ParameterInfo[]): Promise<Record<string, any>> {
  const parameterValues: Record<string, any> = {};
  
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

/**
 * Shows detailed execution results to the user.
 * 
 * @param result Execution result
 * @param extensionState Extension state
 */
export async function showExecutionResults(result: ExecutionResult, extensionState: ExtensionState): Promise<void> {
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

  const actions: string[] = ['Close'];
  
  if (result.snapshotId) {
    actions.unshift('Restore Snapshot');
  }
  
  if (result.sideEffects.length > 0) {
    actions.unshift('View Side Effects');
  }

  const action = await vscode.window.showInformationMessage(message, ...actions);
  
  if (action === 'Restore Snapshot' && result.snapshotId) {
    await handleRestoreSnapshot(result.snapshotId, extensionState);
  } else if (action === 'View Side Effects') {
    await showSideEffectsDetails(result.sideEffects);
  }
}

/**
 * Handles snapshot restoration.
 * 
 * @param snapshotId Snapshot ID to restore
 * @param extensionState Extension state
 */
export async function handleRestoreSnapshot(snapshotId: string, extensionState: ExtensionState): Promise<void> {
  try {
    await extensionState.commandExecutor.restoreWorkspaceSnapshot(snapshotId);
    vscode.window.showInformationMessage(`✅ Workspace restored from snapshot ${snapshotId}`);
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    vscode.window.showErrorMessage(`Failed to restore snapshot: ${errorMessage}`);
  }
}

/**
 * Shows detailed side effects information.
 * 
 * @param sideEffects Array of side effects
 */
export async function showSideEffectsDetails(sideEffects: any[]): Promise<void> {
  const details = sideEffects.map(effect => 
    `${effect.timestamp.toLocaleTimeString()}: ${effect.description}`
  ).join('\n');
  
  const document = await vscode.workspace.openTextDocument({
    content: `Side Effects Detected:\n\n${details}`,
    language: 'plaintext'
  });
  
  await vscode.window.showTextDocument(document);
}