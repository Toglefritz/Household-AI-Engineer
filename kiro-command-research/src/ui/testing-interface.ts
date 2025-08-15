/**
 * Interactive testing interface for command execution and validation.
 * 
 * This module provides a webview-based interface for testing Kiro commands
 * with parameter input forms, validation feedback, and result display.
 */

import * as vscode from 'vscode';
import * as path from 'path';
import { CommandMetadata, ParameterInfo } from '../types/command-metadata';
import { CommandExecutor, ExecutionContext, ExecutionResult } from '../testing/command-executor';
import { ParameterValidator, ValidationResult } from '../testing/parameter-validator';
import { TestResult } from '../testing/result-capture';

/**
 * Testing interface configuration.
 */
export interface TestingConfig {
  /** Default timeout for command execution */
  readonly defaultTimeout: number;
  
  /** Whether to create snapshots by default */
  readonly defaultCreateSnapshot: boolean;
  
  /** Whether to require confirmation for destructive commands */
  readonly requireConfirmation: boolean;
  
  /** Whether to show advanced options */
  readonly showAdvancedOptions: boolean;
  
  /** Maximum number of recent tests to remember */
  readonly maxRecentTests: number;
}

/**
 * Test execution request from webview.
 */
export interface TestExecutionRequest {
  /** Command to test */
  readonly command: CommandMetadata;
  
  /** Parameter values */
  readonly parameters: Record<string, any>;
  
  /** Execution options */
  readonly options: {
    timeoutMs: number;
    createSnapshot: boolean;
    requireConfirmation: boolean;
  };
  
  /** Optional notes */
  readonly notes?: string;
}/**
 * In
teractive testing interface for Kiro commands.
 * 
 * The TestingInterface provides a comprehensive webview-based UI for testing
 * commands with parameter input forms, validation, and result visualization.
 */
export class TestingInterface {
  private panel: vscode.WebviewPanel | undefined;
  private currentCommand: CommandMetadata | undefined;
  private recentTests: TestResult[] = [];
  
  constructor(
    private readonly context: vscode.ExtensionContext,
    private readonly executor: CommandExecutor,
    private readonly validator: ParameterValidator,
    private readonly config: TestingConfig
  ) {}
  
  /**
   * Opens the testing interface for a specific command.
   * 
   * @param command Command to test
   * @returns Promise that resolves when interface is opened
   */
  public async openTestingInterface(command: CommandMetadata): Promise<void> {
    console.log(`TestingInterface: Opening interface for ${command.id}`);
    
    this.currentCommand = command;
    
    // Create or show existing panel
    if (this.panel) {
      this.panel.reveal(vscode.ViewColumn.One);
    } else {
      this.panel = vscode.window.createWebviewPanel(
        'kiroCommandTesting',
        `Test: ${command.displayName}`,
        vscode.ViewColumn.One,
        {
          enableScripts: true,
          retainContextWhenHidden: true,
          localResourceRoots: [
            vscode.Uri.file(path.join(this.context.extensionPath, 'resources'))
          ]
        }
      );
      
      this.setupWebviewHandlers();
    }
    
    // Update panel title and content
    this.panel.title = `Test: ${command.displayName}`;
    await this.updateWebviewContent();
  }
  
  /**
   * Sets up webview message handlers.
   */
  private setupWebviewHandlers(): void {
    if (!this.panel) return;
    
    this.panel.webview.onDidReceiveMessage(async (message) => {
      try {
        switch (message.command) {
          case 'validateParameters':
            await this.handleParameterValidation(message.parameters);
            break;
          case 'executeTest':
            await this.handleTestExecution(message.request);
            break;
          case 'loadRecentTest':
            await this.handleLoadRecentTest(message.testId);
            break;
          case 'clearResults':
            await this.handleClearResults();
            break;
        }
      } catch (error: unknown) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        console.error('TestingInterface: Message handling error:', errorMessage);
        
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
   * Handles parameter validation requests.
   * 
   * @param parameters Parameters to validate
   */
  private async handleParameterValidation(parameters: Record<string, any>): Promise<void> {
    if (!this.currentCommand?.signature) {
      return;
    }
    
    const validationResult = await this.validator.validateParameters(
      this.currentCommand.signature.parameters,
      parameters,
      {
        commandId: this.currentCommand.id,
        workspace: vscode.workspace.workspaceFolders?.[0],
        activeEditor: vscode.window.activeTextEditor,
        context: {}
      }
    );
    
    this.panel?.webview.postMessage({
      command: 'validationResult',
      result: validationResult
    });
  }
  
  /**
   * Handles test execution requests.
   * 
   * @param request Test execution request
   */
  private async handleTestExecution(request: TestExecutionRequest): Promise<void> {
    if (!this.currentCommand) {
      return;
    }
    
    try {
      // Show execution started
      this.panel?.webview.postMessage({
        command: 'executionStarted'
      });
      
      // Create execution context
      const executionContext: ExecutionContext = {
        command: this.currentCommand,
        parameters: request.parameters,
        timeoutMs: request.options.timeoutMs,
        createSnapshot: request.options.createSnapshot,
        requireConfirmation: request.options.requireConfirmation,
        context: {}
      };
      
      // Execute command
      const result = await this.executor.executeCommand(executionContext, true, request.notes);
      
      // Send result to webview
      this.panel?.webview.postMessage({
        command: 'executionResult',
        result: result
      });
      
      // Add to recent tests
      const testResult = this.executor.getResultCapture().getResult(result.commandId);
      if (testResult) {
        this.recentTests.unshift(testResult);
        this.recentTests = this.recentTests.slice(0, this.config.maxRecentTests);
      }
      
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      
      this.panel?.webview.postMessage({
        command: 'executionError',
        error: errorMessage
      });
    }
  }  /**
   
* Handles loading a recent test.
   * 
   * @param testId Test ID to load
   */
  private async handleLoadRecentTest(testId: string): Promise<void> {
    const test = this.recentTests.find(t => t.id === testId);
    if (test) {
      this.panel?.webview.postMessage({
        command: 'loadTest',
        test: test
      });
    }
  }
  
  /**
   * Handles clearing results.
   */
  private async handleClearResults(): Promise<void> {
    this.panel?.webview.postMessage({
      command: 'resultsCleared'
    });
  }
  
  /**
   * Updates webview content.
   */
  private async updateWebviewContent(): Promise<void> {
    if (!this.panel || !this.currentCommand) {
      return;
    }
    
    this.panel.webview.html = this.generateWebviewHtml();
  }
  
  /**
   * Generates HTML content for the webview.
   */
  private generateWebviewHtml(): string {
    if (!this.currentCommand) {
      return '<html><body><h1>No command selected</h1></body></html>';
    }
    
    const command = this.currentCommand;
    
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Command</title>
    <style>${this.getWebviewStyles()}</style>
</head>
<body>
    <div class="container">
        <header class="header">
            <h1>Test Command: ${command.displayName}</h1>
            <div class="command-info">
                <span class="command-id">${command.id}</span>
                <span class="risk-badge risk-${command.riskLevel}">${command.riskLevel}</span>
            </div>
        </header>
        
        <div class="content">
            <div class="main-panel">
                ${this.generateParameterForm(command)}
                ${this.generateExecutionOptions()}
                ${this.generateActionButtons()}
            </div>
            
            <div class="side-panel">
                ${this.generateRecentTests()}
                ${this.generateCommandInfo(command)}
            </div>
        </div>
        
        <div id="results" class="results-panel" style="display: none;">
            <h2>Execution Results</h2>
            <div id="resultsContent"></div>
        </div>
    </div>
    
    <script>${this.getWebviewScript()}</script>
</body>
</html>`;
  }  /**
   *
 Generates parameter input form.
   */
  private generateParameterForm(command: CommandMetadata): string {
    if (!command.signature || command.signature.parameters.length === 0) {
      return `
        <div class="section">
          <h2>Parameters</h2>
          <p class="no-parameters">This command has no parameters.</p>
        </div>
      `;
    }
    
    return `
      <div class="section">
        <h2>Parameters</h2>
        <form id="parameterForm" class="parameter-form">
          ${command.signature.parameters.map(param => this.generateParameterInput(param)).join('')}
        </form>
        <div id="validationErrors" class="validation-errors"></div>
      </div>
    `;
  }
  
  /**
   * Generates input for a single parameter.
   */
  private generateParameterInput(param: ParameterInfo): string {
    const inputId = `param_${param.name}`;
    const isRequired = param.required;
    
    let inputElement = '';
    
    // Generate appropriate input based on type
    switch (param.type.toLowerCase()) {
      case 'boolean':
        inputElement = `
          <input type="checkbox" id="${inputId}" name="${param.name}" 
                 ${param.defaultValue ? 'checked' : ''}>
        `;
        break;
      case 'number':
        inputElement = `
          <input type="number" id="${inputId}" name="${param.name}" 
                 ${isRequired ? 'required' : ''} 
                 ${param.defaultValue !== undefined ? `value="${param.defaultValue}"` : ''}
                 placeholder="Enter number...">
        `;
        break;
      case 'string':
        inputElement = `
          <input type="text" id="${inputId}" name="${param.name}" 
                 ${isRequired ? 'required' : ''} 
                 ${param.defaultValue !== undefined ? `value="${param.defaultValue}"` : ''}
                 placeholder="Enter text...">
        `;
        break;
      default:
        // For complex types, use textarea with JSON input
        inputElement = `
          <textarea id="${inputId}" name="${param.name}" 
                    ${isRequired ? 'required' : ''} 
                    placeholder="Enter JSON value..."
                    rows="3">${param.defaultValue !== undefined ? JSON.stringify(param.defaultValue, null, 2) : ''}</textarea>
        `;
    }
    
    return `
      <div class="parameter-group">
        <label for="${inputId}" class="parameter-label">
          ${param.name}
          <span class="parameter-type">(${param.type})</span>
          ${isRequired ? '<span class="required">*</span>' : '<span class="optional">optional</span>'}
        </label>
        ${inputElement}
        ${param.description ? `<div class="parameter-description">${param.description}</div>` : ''}
      </div>
    `;
  }  /**

   * Generates execution options form.
   */
  private generateExecutionOptions(): string {
    return `
      <div class="section">
        <h2>Execution Options</h2>
        <div class="options-form">
          <div class="option-group">
            <label for="timeout">Timeout (ms)</label>
            <input type="number" id="timeout" value="${this.config.defaultTimeout}" min="1000" max="300000">
          </div>
          
          <div class="option-group">
            <label>
              <input type="checkbox" id="createSnapshot" ${this.config.defaultCreateSnapshot ? 'checked' : ''}>
              Create workspace snapshot
            </label>
          </div>
          
          <div class="option-group">
            <label>
              <input type="checkbox" id="requireConfirmation" ${this.config.requireConfirmation ? 'checked' : ''}>
              Require confirmation for destructive commands
            </label>
          </div>
          
          <div class="option-group">
            <label for="notes">Notes (optional)</label>
            <textarea id="notes" placeholder="Add notes about this test..." rows="2"></textarea>
          </div>
        </div>
      </div>
    `;
  }
  
  /**
   * Generates action buttons.
   */
  private generateActionButtons(): string {
    return `
      <div class="section">
        <div class="actions">
          <button id="validateBtn" class="secondary-button">Validate Parameters</button>
          <button id="executeBtn" class="primary-button">Execute Command</button>
          <button id="clearBtn" class="secondary-button">Clear Results</button>
        </div>
      </div>
    `;
  }
  
  /**
   * Generates recent tests panel.
   */
  private generateRecentTests(): string {
    if (this.recentTests.length === 0) {
      return `
        <div class="side-section">
          <h3>Recent Tests</h3>
          <p class="no-tests">No recent tests</p>
        </div>
      `;
    }
    
    return `
      <div class="side-section">
        <h3>Recent Tests</h3>
        <div class="recent-tests">
          ${this.recentTests.slice(0, 5).map(test => `
            <div class="test-item" onclick="loadRecentTest('${test.id}')">
              <div class="test-status ${test.executionResult.success ? 'success' : 'failure'}">
                ${test.executionResult.success ? '✓' : '✗'}
              </div>
              <div class="test-info">
                <div class="test-time">${test.timestamp.toLocaleTimeString()}</div>
                <div class="test-duration">${test.executionResult.duration}ms</div>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  }  /*
*
   * Generates command information panel.
   */
  private generateCommandInfo(command: CommandMetadata): string {
    return `
      <div class="side-section">
        <h3>Command Information</h3>
        <div class="command-details">
          <div class="detail-item">
            <span class="detail-label">Category:</span>
            <span>${command.category}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">Subcategory:</span>
            <span>${command.subcategory}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">Risk Level:</span>
            <span class="risk-${command.riskLevel}">${command.riskLevel}</span>
          </div>
          ${command.contextRequirements.length > 0 ? `
            <div class="detail-item">
              <span class="detail-label">Context:</span>
              <span>${command.contextRequirements.join(', ')}</span>
            </div>
          ` : ''}
          ${command.description ? `
            <div class="detail-item">
              <span class="detail-label">Description:</span>
              <span>${command.description}</span>
            </div>
          ` : ''}
        </div>
      </div>
    `;
  }
  
  /**
   * Gets CSS styles for the webview.
   */
  private getWebviewStyles(): string {
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
      }
      
      .container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 20px;
      }
      
      .header {
        text-align: center;
        margin-bottom: 30px;
        padding-bottom: 20px;
        border-bottom: 1px solid var(--vscode-panel-border);
      }
      
      .header h1 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 10px;
      }
      
      .command-info {
        display: flex;
        justify-content: center;
        gap: 20px;
        align-items: center;
      }
      
      .command-id {
        font-family: monospace;
        background-color: var(--vscode-textCodeBlock-background);
        padding: 4px 8px;
        border-radius: 4px;
        font-size: 14px;
      }
      
      .risk-badge {
        padding: 4px 8px;
        border-radius: 4px;
        font-size: 12px;
        font-weight: bold;
        text-transform: uppercase;
      }
      
      .risk-safe { background-color: #4CAF50; color: white; }
      .risk-moderate { background-color: #FF9800; color: white; }
      .risk-destructive { background-color: #f44336; color: white; }
      
      .content {
        display: grid;
        grid-template-columns: 2fr 1fr;
        gap: 30px;
        margin-bottom: 30px;
      }
      
      .section, .side-section {
        background-color: var(--vscode-panel-background);
        padding: 20px;
        border-radius: 8px;
        margin-bottom: 20px;
      }
      
      .section h2, .side-section h3 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 15px;
      }
      
      .parameter-form {
        display: grid;
        gap: 20px;
      }
      
      .parameter-group {
        display: grid;
        gap: 8px;
      }
      
      .parameter-label {
        font-weight: bold;
        display: flex;
        align-items: center;
        gap: 8px;
      }
      
      .parameter-type {
        color: var(--vscode-descriptionForeground);
        font-weight: normal;
        font-style: italic;
      }
      
      .required {
        color: var(--vscode-errorForeground);
      }
      
      .optional {
        color: var(--vscode-descriptionForeground);
        font-size: 0.9em;
      }
      
      input, textarea, select {
        padding: 8px 12px;
        border: 1px solid var(--vscode-input-border);
        background-color: var(--vscode-input-background);
        color: var(--vscode-input-foreground);
        border-radius: 4px;
        font-family: inherit;
      }
      
      input:focus, textarea:focus, select:focus {
        outline: none;
        border-color: var(--vscode-focusBorder);
      }
      
      .parameter-description {
        font-size: 0.9em;
        color: var(--vscode-descriptionForeground);
        font-style: italic;
      }
      
      .options-form {
        display: grid;
        gap: 15px;
      }
      
      .option-group {
        display: grid;
        gap: 5px;
      }
      
      .option-group label {
        display: flex;
        align-items: center;
        gap: 8px;
      }
      
      .actions {
        display: flex;
        gap: 10px;
        justify-content: center;
      }
      
      button {
        padding: 10px 20px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 14px;
        font-family: inherit;
        transition: background-color 0.2s;
      }
      
      .primary-button {
        background-color: var(--vscode-button-background);
        color: var(--vscode-button-foreground);
      }
      
      .primary-button:hover {
        background-color: var(--vscode-button-hoverBackground);
      }
      
      .secondary-button {
        background-color: var(--vscode-button-secondaryBackground);
        color: var(--vscode-button-secondaryForeground);
      }
      
      .secondary-button:hover {
        background-color: var(--vscode-button-secondaryHoverBackground);
      }
      
      .recent-tests {
        display: grid;
        gap: 8px;
      }
      
      .test-item {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 8px;
        background-color: var(--vscode-list-inactiveSelectionBackground);
        border-radius: 4px;
        cursor: pointer;
        transition: background-color 0.2s;
      }
      
      .test-item:hover {
        background-color: var(--vscode-list-hoverBackground);
      }
      
      .test-status {
        width: 20px;
        height: 20px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        font-size: 12px;
      }
      
      .test-status.success {
        background-color: #4CAF50;
        color: white;
      }
      
      .test-status.failure {
        background-color: #f44336;
        color: white;
      }
      
      .test-info {
        display: grid;
        gap: 2px;
      }
      
      .test-time {
        font-size: 0.9em;
        font-weight: bold;
      }
      
      .test-duration {
        font-size: 0.8em;
        color: var(--vscode-descriptionForeground);
      }
      
      .command-details {
        display: grid;
        gap: 10px;
      }
      
      .detail-item {
        display: grid;
        grid-template-columns: auto 1fr;
        gap: 10px;
      }
      
      .detail-label {
        font-weight: bold;
        color: var(--vscode-descriptionForeground);
      }
      
      .results-panel {
        background-color: var(--vscode-panel-background);
        padding: 20px;
        border-radius: 8px;
        margin-top: 20px;
      }
      
      .results-panel h2 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 15px;
      }
      
      .validation-errors {
        margin-top: 10px;
      }
      
      .error-message {
        background-color: var(--vscode-inputValidation-errorBackground);
        color: var(--vscode-inputValidation-errorForeground);
        border: 1px solid var(--vscode-inputValidation-errorBorder);
        padding: 8px 12px;
        border-radius: 4px;
        margin-bottom: 8px;
      }
      
      .no-parameters, .no-tests {
        color: var(--vscode-descriptionForeground);
        font-style: italic;
        text-align: center;
        padding: 20px;
      }
      
      .result-summary {
        padding: 15px;
        border-radius: 8px;
        margin-bottom: 20px;
        text-align: center;
      }
      
      .result-summary.success {
        background-color: rgba(76, 175, 80, 0.1);
        border: 1px solid #4CAF50;
        color: #4CAF50;
      }
      
      .result-summary.failure {
        background-color: rgba(244, 67, 54, 0.1);
        border: 1px solid #f44336;
        color: #f44336;
      }
      
      .result-summary h3 {
        margin: 0 0 10px 0;
        font-size: 18px;
      }
      
      .result-section {
        margin-bottom: 20px;
        padding: 15px;
        background-color: var(--vscode-editor-background);
        border-radius: 6px;
        border: 1px solid var(--vscode-panel-border);
      }
      
      .result-section h4 {
        margin: 0 0 10px 0;
        color: var(--vscode-textLink-foreground);
      }
      
      .result-data, .error-stack {
        background-color: var(--vscode-textCodeBlock-background);
        padding: 10px;
        border-radius: 4px;
        font-family: monospace;
        font-size: 12px;
        overflow-x: auto;
        white-space: pre-wrap;
        word-break: break-all;
      }
      
      .side-effects-list {
        list-style: none;
        padding: 0;
      }
      
      .side-effects-list li {
        padding: 8px;
        margin-bottom: 8px;
        background-color: var(--vscode-list-inactiveSelectionBackground);
        border-radius: 4px;
        border-left: 3px solid var(--vscode-textLink-foreground);
      }
      
      .side-effects-list small {
        color: var(--vscode-descriptionForeground);
        font-style: italic;
      }
      
      @media (max-width: 768px) {
        .content {
          grid-template-columns: 1fr;
        }
        
        .actions {
          flex-direction: column;
        }
      }
    `;
  }  /**
   
* Gets JavaScript code for the webview.
   */
  private getWebviewScript(): string {
    return `
      const vscode = acquireVsCodeApi();
      let isExecuting = false;
      
      // Set up event listeners
      document.addEventListener('DOMContentLoaded', function() {
        const validateBtn = document.getElementById('validateBtn');
        const executeBtn = document.getElementById('executeBtn');
        const clearBtn = document.getElementById('clearBtn');
        const parameterForm = document.getElementById('parameterForm');
        
        if (validateBtn) {
          validateBtn.addEventListener('click', validateParameters);
        }
        
        if (executeBtn) {
          executeBtn.addEventListener('click', executeCommand);
        }
        
        if (clearBtn) {
          clearBtn.addEventListener('click', clearResults);
        }
        
        // Auto-validate on parameter changes
        if (parameterForm) {
          parameterForm.addEventListener('input', debounce(validateParameters, 500));
        }
      });
      
      // Handle messages from extension
      window.addEventListener('message', event => {
        const message = event.data;
        
        switch (message.command) {
          case 'validationResult':
            handleValidationResult(message.result);
            break;
          case 'executionStarted':
            handleExecutionStarted();
            break;
          case 'executionResult':
            handleExecutionResult(message.result);
            break;
          case 'executionError':
            handleExecutionError(message.error);
            break;
          case 'loadTest':
            handleLoadTest(message.test);
            break;
          case 'resultsCleared':
            handleResultsCleared();
            break;
          case 'error':
            handleError(message.message);
            break;
        }
      });
      
      function validateParameters() {
        const parameters = collectParameters();
        
        vscode.postMessage({
          command: 'validateParameters',
          parameters: parameters
        });
      }
      
      function executeCommand() {
        if (isExecuting) {
          return;
        }
        
        const parameters = collectParameters();
        const options = collectOptions();
        const notes = document.getElementById('notes')?.value || '';
        
        const request = {
          command: null, // Will be set by extension
          parameters: parameters,
          options: options,
          notes: notes
        };
        
        vscode.postMessage({
          command: 'executeTest',
          request: request
        });
      }
      
      function clearResults() {
        vscode.postMessage({
          command: 'clearResults'
        });
      }
      
      function loadRecentTest(testId) {
        vscode.postMessage({
          command: 'loadRecentTest',
          testId: testId
        });
      }
      
      function collectParameters() {
        const parameters = {};
        const form = document.getElementById('parameterForm');
        
        if (!form) {
          return parameters;
        }
        
        const inputs = form.querySelectorAll('input, textarea, select');
        
        for (const input of inputs) {
          const name = input.name;
          if (!name) continue;
          
          let value;
          
          if (input.type === 'checkbox') {
            value = input.checked;
          } else if (input.type === 'number') {
            value = input.value ? parseFloat(input.value) : undefined;
          } else if (input.tagName === 'TEXTAREA') {
            // Try to parse as JSON for complex types
            try {
              value = input.value ? JSON.parse(input.value) : undefined;
            } catch (e) {
              value = input.value;
            }
          } else {
            value = input.value || undefined;
          }
          
          if (value !== undefined && value !== '') {
            parameters[name] = value;
          }
        }
        
        return parameters;
      }
      
      function collectOptions() {
        return {
          timeoutMs: parseInt(document.getElementById('timeout')?.value || '30000'),
          createSnapshot: document.getElementById('createSnapshot')?.checked || false,
          requireConfirmation: document.getElementById('requireConfirmation')?.checked || false
        };
      }
      
      function handleValidationResult(result) {
        const errorsContainer = document.getElementById('validationErrors');
        if (!errorsContainer) return;
        
        errorsContainer.innerHTML = '';
        
        if (!result.valid && result.errors.length > 0) {
          for (const error of result.errors) {
            const errorDiv = document.createElement('div');
            errorDiv.className = 'error-message';
            errorDiv.textContent = error.message;
            errorsContainer.appendChild(errorDiv);
          }
        }
        
        // Update execute button state
        const executeBtn = document.getElementById('executeBtn');
        if (executeBtn) {
          executeBtn.disabled = !result.valid;
        }
      }
      
      function handleExecutionStarted() {
        isExecuting = true;
        
        const executeBtn = document.getElementById('executeBtn');
        if (executeBtn) {
          executeBtn.disabled = true;
          executeBtn.textContent = 'Executing...';
        }
        
        // Show results panel
        const resultsPanel = document.getElementById('results');
        if (resultsPanel) {
          resultsPanel.style.display = 'block';
          resultsPanel.querySelector('#resultsContent').innerHTML = '<p>Executing command...</p>';
        }
      }
      
      function handleExecutionResult(result) {
        isExecuting = false;
        
        const executeBtn = document.getElementById('executeBtn');
        if (executeBtn) {
          executeBtn.disabled = false;
          executeBtn.textContent = 'Execute Command';
        }
        
        displayExecutionResult(result);
      }
      
      function handleExecutionError(error) {
        isExecuting = false;
        
        const executeBtn = document.getElementById('executeBtn');
        if (executeBtn) {
          executeBtn.disabled = false;
          executeBtn.textContent = 'Execute Command';
        }
        
        const resultsContent = document.getElementById('resultsContent');
        if (resultsContent) {
          resultsContent.innerHTML = \`
            <div class="error-message">
              <strong>Execution Error:</strong> \${error}
            </div>
          \`;
        }
      }
      
      function handleLoadTest(test) {
        // Load test parameters into form
        const form = document.getElementById('parameterForm');
        if (form && test.parameters) {
          for (const [name, value] of Object.entries(test.parameters)) {
            const input = form.querySelector(\`[name="\${name}"]\`);
            if (input) {
              if (input.type === 'checkbox') {
                input.checked = !!value;
              } else if (typeof value === 'object') {
                input.value = JSON.stringify(value, null, 2);
              } else {
                input.value = value;
              }
            }
          }
        }
        
        // Load notes
        const notesInput = document.getElementById('notes');
        if (notesInput && test.notes) {
          notesInput.value = test.notes;
        }
        
        // Display previous result
        displayExecutionResult(test.executionResult);
      }
      
      function handleResultsCleared() {
        const resultsPanel = document.getElementById('results');
        if (resultsPanel) {
          resultsPanel.style.display = 'none';
        }
      }
      
      function handleError(message) {
        const resultsContent = document.getElementById('resultsContent');
        if (resultsContent) {
          resultsContent.innerHTML = \`
            <div class="error-message">
              <strong>Error:</strong> \${message}
            </div>
          \`;
        }
      }
      
      function displayExecutionResult(result) {
        const resultsContent = document.getElementById('resultsContent');
        if (!resultsContent) return;
        
        const statusClass = result.success ? 'success' : 'failure';
        const statusIcon = result.success ? '✓' : '✗';
        
        let html = \`
          <div class="result-summary \${statusClass}">
            <h3>\${statusIcon} \${result.success ? 'Success' : 'Failed'}</h3>
            <p>Duration: \${result.duration}ms</p>
          </div>
        \`;
        
        if (result.result) {
          html += \`
            <div class="result-section">
              <h4>Result</h4>
              <pre class="result-data">\${JSON.stringify(result.result, null, 2)}</pre>
            </div>
          \`;
        }
        
        if (result.error) {
          html += \`
            <div class="result-section">
              <h4>Error</h4>
              <div class="error-message">
                <strong>\${result.error.type}:</strong> \${result.error.message}
              </div>
              \${result.error.stack ? \`<pre class="error-stack">\${result.error.stack}</pre>\` : ''}
            </div>
          \`;
        }
        
        if (result.sideEffects && result.sideEffects.length > 0) {
          html += \`
            <div class="result-section">
              <h4>Side Effects (\${result.sideEffects.length})</h4>
              <ul class="side-effects-list">
                \${result.sideEffects.map(effect => \`
                  <li>
                    <strong>\${effect.type}:</strong> \${effect.description}
                    \${effect.resource ? \`<br><small>Resource: \${effect.resource}</small>\` : ''}
                  </li>
                \`).join('')}
              </ul>
            </div>
          \`;
        }
        
        resultsContent.innerHTML = html;
      }
      
      function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
          const later = () => {
            clearTimeout(timeout);
            func(...args);
          };
          clearTimeout(timeout);
          timeout = setTimeout(later, wait);
        };
      }
    `;
  }
  
  /**
   * Disposes resources used by the interface.
   */
  public dispose(): void {
    if (this.panel) {
      this.panel.dispose();
      this.panel = undefined;
    }
  }
}