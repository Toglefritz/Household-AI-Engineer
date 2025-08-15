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
const extension_state_1 = require("./core/extension-state");
const command_registration_1 = require("./core/command-registration");
/**
 * Called when the extension is activated.
 */
async function activate(context) {
    try {
        console.log('Activating Kiro Command Research Tool v0.8.0...');
        console.log('Initializing extension state...');
        await extension_state_1.ExtensionState.initialize(context);
        console.log('Extension state initialized successfully');
        console.log('Setting context variables...');
        await vscode.commands.executeCommand('setContext', 'kiroCommandResearch.active', true);
        console.log('Registering commands...');
        (0, command_registration_1.registerCommands)(context);
        vscode.window.showInformationMessage('Kiro Command Research Tool v0.8.0 activated successfully!');
        console.log('Kiro Command Research Tool v0.8.0 activated successfully');
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
 */
async function deactivate() {
    try {
        console.log('Deactivating Kiro Command Research Tool...');
        const extensionState = extension_state_1.ExtensionState.getCurrentInstance();
        if (extensionState) {
            await extensionState.dispose();
        }
        await vscode.commands.executeCommand('setContext', 'kiroCommandResearch.active', false);
        console.log('Kiro Command Research Tool deactivated successfully');
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        console.error(`Error during extension deactivation: ${errorMessage}`);
    }
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map