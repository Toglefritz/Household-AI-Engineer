/**
 * Main extension entry point for the Kiro Command Research Tool.
 * 
 * This module handles extension activation, command registration,
 * and lifecycle management for the research tool.
 */

import * as vscode from 'vscode';
import { ExtensionState } from './core/extension-state';
import { registerCommands } from './core/command-registration';

/**
 * Called when the extension is activated.
 */
export async function activate(context: vscode.ExtensionContext): Promise<void> {
  try {
    console.log('Activating Kiro Command Research Tool v0.8.0...');

    console.log('Initializing extension state...');
    await ExtensionState.initialize(context);
    console.log('Extension state initialized successfully');

    console.log('Setting context variables...');
    await vscode.commands.executeCommand('setContext', 'kiroCommandResearch.active', true);

    console.log('Registering commands...');
    registerCommands(context);

    vscode.window.showInformationMessage('Kiro Command Research Tool v0.8.0 activated successfully!');
    console.log('Kiro Command Research Tool v0.8.0 activated successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    const stack: string = error instanceof Error && error.stack ? error.stack : 'No stack trace';
    console.error(`Failed to activate extension: ${errorMessage}`);
    console.error('Stack trace:', stack);
    vscode.window.showErrorMessage(`Failed to activate Kiro Command Research Tool: ${errorMessage}`);
  }
}

/**
 * Called when the extension is deactivated.
 */
export async function deactivate(): Promise<void> {
  try {
    console.log('Deactivating Kiro Command Research Tool...');

    const extensionState: ExtensionState | null = ExtensionState.getCurrentInstance();
    if (extensionState) {
      await extensionState.dispose();
    }

    await vscode.commands.executeCommand('setContext', 'kiroCommandResearch.active', false);
    console.log('Kiro Command Research Tool deactivated successfully');
  } catch (error: unknown) {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    console.error(`Error during extension deactivation: ${errorMessage}`);
  }
}

