"use strict";
/**
 * Manual parameter information editor for the Kiro Command Research Tool.
 *
 * This module provides a UI interface for manually adding and editing
 * parameter information for discovered commands, integrating user research
 * findings with automatic discovery results.
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
exports.ManualParameterEditor = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Manual parameter editor interface.
 *
 * This class provides a webview-based interface for users to manually
 * add and edit parameter information for discovered commands.
 */
class ManualParameterEditor {
    constructor(context, storageManager, config) {
        this.context = context;
        this.storageManager = storageManager;
        this.config = config;
        this.manualEntries = new Map();
        this.loadManualEntries();
    }
    /**
     * Opens the manual parameter editor for a specific command.
     *
     * @param command Command to edit parameters for
     * @returns Promise that resolves when editor is opened
     */
    async openEditor(command) {
        console.log(`ManualParameterEditor: Opening editor for command ${command.id}...`);
        this.currentCommand = command;
        // Create or show existing panel
        if (this.panel) {
            this.panel.reveal(vscode.ViewColumn.One);
        }
        else {
            this.panel = vscode.window.createWebviewPanel('manualParameterEditor', `Edit Parameters: ${command.displayName}`, vscode.ViewColumn.One, {
                enableScripts: true,
                retainContextWhenHidden: true,
                localResourceRoots: [
                    vscode.Uri.file(this.context.extensionPath)
                ]
            });
            this.setupWebviewHandlers();
        }
        // Update panel title and content
        this.panel.title = `Edit Parameters: ${command.displayName}`;
        await this.updateWebviewContent();
    }
    /**
     * Gets manual parameter entries for a command.
     *
     * @param commandId Command ID to get entries for
     * @returns Array of manual parameter entries
     */
    getManualEntries(commandId) {
        return this.manualEntries.get(commandId) || [];
    }
    /**
     * Adds or updates a manual parameter entry.
     *
     * @param entry Manual parameter entry to add or update
     * @returns Promise that resolves when entry is saved
     */
    async addOrUpdateEntry(entry) {
        const commandEntries = this.manualEntries.get(entry.commandId) || [];
        // Find existing entry with same parameter name
        const existingIndex = commandEntries.findIndex(e => e.parameter.name === entry.parameter.name);
        if (existingIndex >= 0) {
            // Update existing entry
            commandEntries[existingIndex] = {
                ...entry,
                modifiedAt: new Date()
            };
        }
        else {
            // Add new entry
            commandEntries.push(entry);
        }
        this.manualEntries.set(entry.commandId, commandEntries);
        await this.saveManualEntries();
        console.log(`ManualParameterEditor: Added/updated parameter ${entry.parameter.name} for command ${entry.commandId}`);
    }
    /**
     * Removes a manual parameter entry.
     *
     * @param commandId Command ID
     * @param parameterName Parameter name to remove
     * @returns Promise that resolves when entry is removed
     */
    async removeEntry(commandId, parameterName) {
        const commandEntries = this.manualEntries.get(commandId) || [];
        const filteredEntries = commandEntries.filter(e => e.parameter.name !== parameterName);
        if (filteredEntries.length !== commandEntries.length) {
            this.manualEntries.set(commandId, filteredEntries);
            await this.saveManualEntries();
            console.log(`ManualParameterEditor: Removed parameter ${parameterName} for command ${commandId}`);
        }
    }
    /**
     * Merges manual parameter entries with automatic discovery results.
     *
     * @param command Command metadata with automatic signature
     * @returns Command metadata with merged parameter information
     */
    mergeWithAutomatic(command) {
        const manualEntries = this.getManualEntries(command.id);
        if (manualEntries.length === 0) {
            return command;
        }
        // Create merged signature
        const automaticParams = command.signature?.parameters || [];
        const manualParams = manualEntries.map(entry => entry.parameter);
        // Merge parameters, preferring manual entries for conflicts
        const mergedParams = [];
        const processedNames = new Set();
        // Add manual parameters first
        for (const manualParam of manualParams) {
            mergedParams.push(manualParam);
            processedNames.add(manualParam.name);
        }
        // Add automatic parameters that don't conflict
        for (const autoParam of automaticParams) {
            if (!processedNames.has(autoParam.name)) {
                mergedParams.push(autoParam);
            }
        }
        const mergedSignature = {
            parameters: mergedParams,
            returnType: command.signature?.returnType,
            async: command.signature?.async || false,
            confidence: manualParams.length > 0 ? 'high' : (command.signature?.confidence || 'low'),
            sources: [
                ...(command.signature?.sources || []),
                'manual'
            ],
            researchedAt: new Date()
        };
        return {
            ...command,
            signature: mergedSignature
        };
    }
    /**
     * Sets up webview message handlers.
     */
    setupWebviewHandlers() {
        if (!this.panel)
            return;
        this.panel.webview.onDidReceiveMessage(async (message) => {
            try {
                switch (message.command) {
                    case 'addParameter':
                        await this.handleAddParameter(message.data);
                        break;
                    case 'updateParameter':
                        await this.handleUpdateParameter(message.data);
                        break;
                    case 'removeParameter':
                        await this.handleRemoveParameter(message.data);
                        break;
                    case 'saveAll':
                        await this.handleSaveAll();
                        break;
                    case 'preview':
                        await this.handlePreview();
                        break;
                }
                // Refresh content after any change
                await this.updateWebviewContent();
            }
            catch (error) {
                const errorMessage = error instanceof Error ? error.message : 'Unknown error';
                console.error('ManualParameterEditor: Message handling error:', errorMessage);
                this.panel?.webview.postMessage({
                    command: 'error',
                    message: errorMessage
                });
            }
        });
        this.panel.onDidDispose(() => {
            this.panel = undefined;
        });
    }
    /**
     * Handles adding a new parameter.
     */
    async handleAddParameter(data) {
        if (!this.currentCommand)
            return;
        const entry = {
            commandId: this.currentCommand.id,
            parameter: {
                name: data.name,
                type: data.type,
                required: data.required || false,
                description: data.description,
                defaultValue: data.defaultValue,
                source: 'manual'
            },
            notes: data.notes,
            examples: data.examples || [],
            validationRules: data.validationRules || [],
            createdAt: new Date(),
            modifiedAt: new Date(),
            createdBy: 'user'
        };
        await this.addOrUpdateEntry(entry);
    }
    /**
     * Handles updating an existing parameter.
     */
    async handleUpdateParameter(data) {
        if (!this.currentCommand)
            return;
        const existingEntries = this.getManualEntries(this.currentCommand.id);
        const existingEntry = existingEntries.find(e => e.parameter.name === data.originalName);
        if (existingEntry) {
            const updatedEntry = {
                ...existingEntry,
                parameter: {
                    ...existingEntry.parameter,
                    name: data.name,
                    type: data.type,
                    required: data.required || false,
                    description: data.description,
                    defaultValue: data.defaultValue
                },
                notes: data.notes,
                examples: data.examples || [],
                validationRules: data.validationRules || [],
                modifiedAt: new Date()
            };
            // If name changed, remove old entry first
            if (data.originalName !== data.name) {
                await this.removeEntry(this.currentCommand.id, data.originalName);
            }
            await this.addOrUpdateEntry(updatedEntry);
        }
    }
    /**
     * Handles removing a parameter.
     */
    async handleRemoveParameter(data) {
        if (!this.currentCommand)
            return;
        await this.removeEntry(this.currentCommand.id, data.name);
    }
    /**
     * Handles saving all changes.
     */
    async handleSaveAll() {
        await this.saveManualEntries();
        this.panel?.webview.postMessage({
            command: 'saved',
            message: 'All changes saved successfully'
        });
    }
    /**
     * Handles preview of merged parameters.
     */
    async handlePreview() {
        if (!this.currentCommand)
            return;
        const mergedCommand = this.mergeWithAutomatic(this.currentCommand);
        this.panel?.webview.postMessage({
            command: 'preview',
            data: mergedCommand.signature
        });
    }
    /**
     * Updates the webview content.
     */
    async updateWebviewContent() {
        if (!this.panel || !this.currentCommand)
            return;
        this.panel.webview.html = this.generateEditorHtml();
    }
    /**
     * Loads manual entries from storage.
     */
    async loadManualEntries() {
        try {
            const data = await this.storageManager.loadData('manual-parameters.json');
            if (data) {
                // Convert stored data back to Map
                const entries = JSON.parse(data);
                for (const [commandId, commandEntries] of Object.entries(entries)) {
                    this.manualEntries.set(commandId, commandEntries);
                }
                console.log('ManualParameterEditor: Loaded manual entries from storage');
            }
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('ManualParameterEditor: Failed to load manual entries:', errorMessage);
        }
    }
    /**
     * Saves manual entries to storage.
     */
    async saveManualEntries() {
        try {
            // Convert Map to object for JSON serialization
            const entries = {};
            for (const [commandId, commandEntries] of this.manualEntries) {
                entries[commandId] = commandEntries;
            }
            await this.storageManager.saveData('manual-parameters.json', JSON.stringify(entries, null, 2));
            console.log('ManualParameterEditor: Saved manual entries to storage');
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('ManualParameterEditor: Failed to save manual entries:', errorMessage);
        }
    }
    /**
     * Generates HTML content for the editor.
     */
    generateEditorHtml() {
        if (!this.currentCommand) {
            return '<html><body><h1>No command selected</h1></body></html>';
        }
        const command = this.currentCommand;
        const manualEntries = this.getManualEntries(command.id);
        const automaticParams = command.signature?.parameters || [];
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manual Parameter Editor</title>
    <style>${this.getEditorStyles()}</style>
</head>
<body>
    <div class="editor">
        <header class="editor-header">
            <h1>📝 Manual Parameter Editor</h1>
            <div class="command-info">
                <h2>${command.displayName}</h2>
                <p class="command-id">${command.id}</p>
                <p class="command-description">${command.description || 'No description available'}</p>
            </div>
        </header>
        
        <div class="editor-content">
            <div class="section">
                <h3>🔍 Current Parameters</h3>
                <div class="parameters-overview">
                    <div class="param-stats">
                        <div class="stat">
                            <span class="stat-number">${manualEntries.length}</span>
                            <span class="stat-label">Manual</span>
                        </div>
                        <div class="stat">
                            <span class="stat-number">${automaticParams.length}</span>
                            <span class="stat-label">Automatic</span>
                        </div>
                        <div class="stat">
                            <span class="stat-number">${manualEntries.length + automaticParams.length}</span>
                            <span class="stat-label">Total</span>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="section">
                <h3>➕ Add New Parameter</h3>
                <form id="addParameterForm" class="parameter-form">
                    <div class="form-row">
                        <div class="form-group">
                            <label for="paramName">Parameter Name *</label>
                            <input type="text" id="paramName" name="name" required 
                                   placeholder="e.g., filePath, options, callback">
                        </div>
                        <div class="form-group">
                            <label for="paramType">Type *</label>
                            <select id="paramType" name="type" required>
                                <option value="">Select type...</option>
                                <option value="string">string</option>
                                <option value="number">number</option>
                                <option value="boolean">boolean</option>
                                <option value="object">object</option>
                                <option value="array">array</option>
                                <option value="function">function</option>
                                <option value="any">any</option>
                                <option value="unknown">unknown</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="checkbox-label">
                                <input type="checkbox" id="paramRequired" name="required">
                                Required
                            </label>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label for="paramDescription">Description</label>
                        <textarea id="paramDescription" name="description" rows="2"
                                  placeholder="Describe what this parameter does..."></textarea>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="paramDefault">Default Value</label>
                            <input type="text" id="paramDefault" name="defaultValue"
                                   placeholder="e.g., null, '', 0, true">
                        </div>
                        <div class="form-group">
                            <label for="paramNotes">Notes</label>
                            <input type="text" id="paramNotes" name="notes"
                                   placeholder="Additional context or research notes">
                        </div>
                    </div>
                    
                    ${this.config.showAdvancedOptions ? `
                    <div class="advanced-options">
                        <h4>Advanced Options</h4>
                        <div class="form-group">
                            <label for="paramExamples">Examples (one per line)</label>
                            <textarea id="paramExamples" name="examples" rows="3"
                                      placeholder="Example values or usage patterns..."></textarea>
                        </div>
                        <div class="form-group">
                            <label for="paramValidation">Validation Rules (one per line)</label>
                            <textarea id="paramValidation" name="validationRules" rows="2"
                                      placeholder="Constraints, patterns, or validation rules..."></textarea>
                        </div>
                    </div>
                    ` : ''}
                    
                    <div class="form-actions">
                        <button type="submit" class="btn btn-primary">Add Parameter</button>
                        <button type="reset" class="btn btn-secondary">Clear Form</button>
                    </div>
                </form>
            </div>
            
            <div class="section">
                <h3>📋 Manual Parameters</h3>
                <div id="manualParametersList">
                    ${this.generateParametersList(manualEntries, 'manual')}
                </div>
            </div>
            
            ${automaticParams.length > 0 ? `
            <div class="section">
                <h3>🤖 Automatic Parameters</h3>
                <div id="automaticParametersList">
                    ${this.generateParametersList(automaticParams.map(p => ({
            commandId: command.id,
            parameter: p,
            createdAt: new Date(),
            modifiedAt: new Date()
        })), 'automatic')}
                </div>
            </div>
            ` : ''}
            
            <div class="section">
                <h3>🔄 Actions</h3>
                <div class="action-buttons">
                    <button id="previewBtn" class="btn btn-secondary">Preview Merged Parameters</button>
                    <button id="saveAllBtn" class="btn btn-primary">Save All Changes</button>
                </div>
            </div>
        </div>
    </div>
    
    <script>${this.getEditorScript()}</script>
</body>
</html>`;
    } /**
  
     * Generates HTML for parameters list.
     */
    generateParametersList(entries, type) {
        if (entries.length === 0) {
            return `<div class="empty-state">No ${type} parameters found</div>`;
        }
        return entries.map(entry => `
      <div class="parameter-item ${type}" data-name="${entry.parameter.name}">
        <div class="parameter-header">
          <div class="parameter-info">
            <span class="parameter-name">${entry.parameter.name}</span>
            <span class="parameter-type">${entry.parameter.type}</span>
            ${entry.parameter.required ? '<span class="parameter-required">Required</span>' : ''}
          </div>
          ${type === 'manual' ? `
          <div class="parameter-actions">
            <button class="btn-icon edit-param" data-name="${entry.parameter.name}" title="Edit Parameter">
              ✏️
            </button>
            <button class="btn-icon delete-param" data-name="${entry.parameter.name}" title="Delete Parameter">
              🗑️
            </button>
          </div>
          ` : ''}
        </div>
        
        ${entry.parameter.description ? `
        <div class="parameter-description">${entry.parameter.description}</div>
        ` : ''}
        
        ${entry.parameter.defaultValue !== undefined ? `
        <div class="parameter-default">
          <strong>Default:</strong> <code>${JSON.stringify(entry.parameter.defaultValue)}</code>
        </div>
        ` : ''}
        
        ${entry.notes ? `
        <div class="parameter-notes">
          <strong>Notes:</strong> ${entry.notes}
        </div>
        ` : ''}
        
        ${entry.examples && entry.examples.length > 0 ? `
        <div class="parameter-examples">
          <strong>Examples:</strong>
          <ul>
            ${entry.examples.map(example => `<li><code>${example}</code></li>`).join('')}
          </ul>
        </div>
        ` : ''}
        
        <div class="parameter-meta">
          <span class="parameter-source">Source: ${entry.parameter.source}</span>
          ${type === 'manual' ? `
          <span class="parameter-modified">Modified: ${new Date(entry.modifiedAt).toLocaleString()}</span>
          ` : ''}
        </div>
      </div>
    `).join('');
    }
    /**
     * Gets CSS styles for the editor.
     */
    getEditorStyles() {
        return `
      * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
      }
      
      body {
        font-family: var(--vscode-font-family);
        color: var(--vscode-foreground);
        background-color: var(--vscode-editor-background);
        line-height: 1.6;
        padding: 0;
        margin: 0;
      }
      
      .editor {
        max-width: 1200px;
        margin: 0 auto;
        padding: 20px;
      }
      
      .editor-header {
        margin-bottom: 30px;
        padding-bottom: 20px;
        border-bottom: 2px solid var(--vscode-panel-border);
      }
      
      .editor-header h1 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 15px;
        font-size: 2em;
      }
      
      .command-info h2 {
        color: var(--vscode-foreground);
        margin-bottom: 5px;
      }
      
      .command-id {
        color: var(--vscode-descriptionForeground);
        font-family: monospace;
        font-size: 0.9em;
        margin-bottom: 10px;
      }
      
      .command-description {
        color: var(--vscode-descriptionForeground);
        font-style: italic;
      }
      
      .section {
        background: var(--vscode-panel-background);
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
        border: 1px solid var(--vscode-panel-border);
      }
      
      .section h3 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 15px;
        font-size: 1.3em;
      }
      
      .parameters-overview {
        margin-bottom: 15px;
      }
      
      .param-stats {
        display: flex;
        gap: 20px;
        justify-content: center;
      }
      
      .stat {
        text-align: center;
        padding: 10px;
        background: var(--vscode-editor-background);
        border-radius: 6px;
        border: 1px solid var(--vscode-panel-border);
        min-width: 80px;
      }
      
      .stat-number {
        display: block;
        font-size: 1.5em;
        font-weight: bold;
        color: var(--vscode-textLink-foreground);
      }
      
      .stat-label {
        font-size: 0.9em;
        color: var(--vscode-descriptionForeground);
      }
      
      .parameter-form {
        background: var(--vscode-editor-background);
        padding: 20px;
        border-radius: 6px;
        border: 1px solid var(--vscode-panel-border);
      }
      
      .form-row {
        display: grid;
        grid-template-columns: 1fr 1fr 1fr;
        gap: 15px;
        margin-bottom: 15px;
      }
      
      .form-group {
        display: flex;
        flex-direction: column;
      }
      
      .form-group label {
        color: var(--vscode-foreground);
        margin-bottom: 5px;
        font-weight: 500;
      }
      
      .form-group input,
      .form-group select,
      .form-group textarea {
        background: var(--vscode-input-background);
        color: var(--vscode-input-foreground);
        border: 1px solid var(--vscode-input-border);
        border-radius: 4px;
        padding: 8px 12px;
        font-family: inherit;
      }
      
      .form-group input:focus,
      .form-group select:focus,
      .form-group textarea:focus {
        outline: none;
        border-color: var(--vscode-focusBorder);
        box-shadow: 0 0 0 1px var(--vscode-focusBorder);
      }
      
      .checkbox-label {
        flex-direction: row !important;
        align-items: center;
        gap: 8px;
        margin-top: 25px;
      }
      
      .checkbox-label input[type="checkbox"] {
        width: auto;
        margin: 0;
      }
      
      .advanced-options {
        margin-top: 20px;
        padding-top: 20px;
        border-top: 1px solid var(--vscode-panel-border);
      }
      
      .advanced-options h4 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 15px;
      }
      
      .form-actions {
        display: flex;
        gap: 10px;
        margin-top: 20px;
        justify-content: flex-end;
      }
      
      .btn {
        padding: 10px 20px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 14px;
        font-weight: 500;
        transition: all 0.2s ease;
      }
      
      .btn-primary {
        background: var(--vscode-button-background);
        color: var(--vscode-button-foreground);
      }
      
      .btn-primary:hover {
        background: var(--vscode-button-hoverBackground);
      }
      
      .btn-secondary {
        background: var(--vscode-button-secondaryBackground);
        color: var(--vscode-button-secondaryForeground);
      }
      
      .btn-secondary:hover {
        background: var(--vscode-button-secondaryHoverBackground);
      }
      
      .btn-icon {
        background: none;
        border: none;
        cursor: pointer;
        padding: 4px;
        border-radius: 3px;
        font-size: 14px;
      }
      
      .btn-icon:hover {
        background: var(--vscode-toolbar-hoverBackground);
      }
      
      .parameter-item {
        background: var(--vscode-editor-background);
        border: 1px solid var(--vscode-panel-border);
        border-radius: 6px;
        padding: 15px;
        margin-bottom: 10px;
      }
      
      .parameter-item.manual {
        border-left: 4px solid var(--vscode-textLink-foreground);
      }
      
      .parameter-item.automatic {
        border-left: 4px solid var(--vscode-descriptionForeground);
      }
      
      .parameter-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 10px;
      }
      
      .parameter-info {
        display: flex;
        align-items: center;
        gap: 10px;
      }
      
      .parameter-name {
        font-weight: bold;
        color: var(--vscode-foreground);
        font-family: monospace;
      }
      
      .parameter-type {
        background: var(--vscode-textCodeBlock-background);
        color: var(--vscode-textPreformat-foreground);
        padding: 2px 6px;
        border-radius: 3px;
        font-size: 0.85em;
        font-family: monospace;
      }
      
      .parameter-required {
        background: var(--vscode-errorForeground);
        color: var(--vscode-errorBackground);
        padding: 2px 6px;
        border-radius: 3px;
        font-size: 0.8em;
        font-weight: bold;
      }
      
      .parameter-actions {
        display: flex;
        gap: 5px;
      }
      
      .parameter-description {
        color: var(--vscode-foreground);
        margin-bottom: 8px;
      }
      
      .parameter-default,
      .parameter-notes {
        color: var(--vscode-descriptionForeground);
        font-size: 0.9em;
        margin-bottom: 5px;
      }
      
      .parameter-examples {
        margin-bottom: 8px;
      }
      
      .parameter-examples ul {
        margin-left: 20px;
        margin-top: 5px;
      }
      
      .parameter-examples code {
        background: var(--vscode-textCodeBlock-background);
        color: var(--vscode-textPreformat-foreground);
        padding: 1px 4px;
        border-radius: 2px;
        font-family: monospace;
      }
      
      .parameter-meta {
        display: flex;
        justify-content: space-between;
        font-size: 0.8em;
        color: var(--vscode-descriptionForeground);
        margin-top: 10px;
        padding-top: 8px;
        border-top: 1px solid var(--vscode-panel-border);
      }
      
      .empty-state {
        text-align: center;
        color: var(--vscode-descriptionForeground);
        font-style: italic;
        padding: 20px;
      }
      
      .action-buttons {
        display: flex;
        gap: 15px;
        justify-content: center;
      }
      
      @media (max-width: 768px) {
        .editor {
          padding: 15px;
        }
        
        .form-row {
          grid-template-columns: 1fr;
        }
        
        .param-stats {
          flex-direction: column;
          align-items: center;
        }
        
        .parameter-header {
          flex-direction: column;
          align-items: flex-start;
          gap: 10px;
        }
        
        .action-buttons {
          flex-direction: column;
        }
      }
    `;
    }
    /**
     * Gets JavaScript code for the editor.
     */
    getEditorScript() {
        return `
      const vscode = acquireVsCodeApi();
      
      // Form submission handler
      document.getElementById('addParameterForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        const data = {
          name: formData.get('name'),
          type: formData.get('type'),
          required: formData.has('required'),
          description: formData.get('description'),
          defaultValue: formData.get('defaultValue') || undefined,
          notes: formData.get('notes'),
          examples: formData.get('examples') ? formData.get('examples').split('\\n').filter(e => e.trim()) : [],
          validationRules: formData.get('validationRules') ? formData.get('validationRules').split('\\n').filter(r => r.trim()) : []
        };
        
        if (!data.name || !data.type) {
          alert('Parameter name and type are required');
          return;
        }
        
        vscode.postMessage({
          command: 'addParameter',
          data: data
        });
        
        // Clear form
        e.target.reset();
      });
      
      // Edit parameter handlers
      document.addEventListener('click', function(e) {
        if (e.target.classList.contains('edit-param')) {
          const paramName = e.target.dataset.name;
          editParameter(paramName);
        } else if (e.target.classList.contains('delete-param')) {
          const paramName = e.target.dataset.name;
          if (confirm(\`Are you sure you want to delete parameter "\${paramName}"?\`)) {
            vscode.postMessage({
              command: 'removeParameter',
              data: { name: paramName }
            });
          }
        }
      });
      
      // Preview button
      document.getElementById('previewBtn').addEventListener('click', function() {
        vscode.postMessage({ command: 'preview' });
      });
      
      // Save all button
      document.getElementById('saveAllBtn').addEventListener('click', function() {
        vscode.postMessage({ command: 'saveAll' });
      });
      
      // Edit parameter function
      function editParameter(paramName) {
        // Find parameter in the DOM to get current values
        const paramElement = document.querySelector(\`[data-name="\${paramName}"]\`);
        if (!paramElement) return;
        
        // Extract current values (simplified - in real implementation would parse from DOM)
        const name = paramName;
        const type = paramElement.querySelector('.parameter-type').textContent;
        const required = paramElement.querySelector('.parameter-required') !== null;
        const description = paramElement.querySelector('.parameter-description')?.textContent || '';
        
        // Populate form with current values
        document.getElementById('paramName').value = name;
        document.getElementById('paramType').value = type;
        document.getElementById('paramRequired').checked = required;
        document.getElementById('paramDescription').value = description;
        
        // Change form to update mode
        const form = document.getElementById('addParameterForm');
        const submitBtn = form.querySelector('button[type="submit"]');
        submitBtn.textContent = 'Update Parameter';
        
        // Store original name for update
        form.dataset.originalName = name;
        form.dataset.mode = 'update';
        
        // Scroll to form
        form.scrollIntoView({ behavior: 'smooth' });
      }
      
      // Handle form mode changes
      document.getElementById('addParameterForm').addEventListener('submit', function(e) {
        const form = e.target;
        if (form.dataset.mode === 'update') {
          e.preventDefault();
          
          const formData = new FormData(form);
          const data = {
            originalName: form.dataset.originalName,
            name: formData.get('name'),
            type: formData.get('type'),
            required: formData.has('required'),
            description: formData.get('description'),
            defaultValue: formData.get('defaultValue') || undefined,
            notes: formData.get('notes'),
            examples: formData.get('examples') ? formData.get('examples').split('\\n').filter(e => e.trim()) : [],
            validationRules: formData.get('validationRules') ? formData.get('validationRules').split('\\n').filter(r => r.trim()) : []
          };
          
          vscode.postMessage({
            command: 'updateParameter',
            data: data
          });
          
          // Reset form to add mode
          form.reset();
          form.removeAttribute('data-original-name');
          form.removeAttribute('data-mode');
          form.querySelector('button[type="submit"]').textContent = 'Add Parameter';
        }
      });
      
      // Handle messages from extension
      window.addEventListener('message', event => {
        const message = event.data;
        
        switch (message.command) {
          case 'error':
            alert('Error: ' + message.message);
            break;
          case 'saved':
            showNotification(message.message, 'success');
            break;
          case 'preview':
            showPreview(message.data);
            break;
        }
      });
      
      function showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = \`notification \${type}\`;
        notification.textContent = message;
        notification.style.cssText = \`
          position: fixed;
          top: 20px;
          right: 20px;
          background: var(--vscode-notifications-background);
          color: var(--vscode-notifications-foreground);
          padding: 12px 16px;
          border-radius: 4px;
          z-index: 1000;
          box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        \`;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
          if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
          }
        }, 3000);
      }
      
      function showPreview(signature) {
        const preview = \`
          <h4>Preview: Merged Parameters</h4>
          <pre>\${JSON.stringify(signature, null, 2)}</pre>
        \`;
        
        // Create or update preview section
        let previewSection = document.getElementById('previewSection');
        if (!previewSection) {
          previewSection = document.createElement('div');
          previewSection.id = 'previewSection';
          previewSection.className = 'section';
          document.querySelector('.editor-content').appendChild(previewSection);
        }
        
        previewSection.innerHTML = preview;
        previewSection.scrollIntoView({ behavior: 'smooth' });
      }
    `;
    }
    /**
     * Disposes resources used by the editor.
     */
    dispose() {
        if (this.panel) {
            this.panel.dispose();
            this.panel = undefined;
        }
    }
}
exports.ManualParameterEditor = ManualParameterEditor;
//# sourceMappingURL=manual-parameter-editor.js.map