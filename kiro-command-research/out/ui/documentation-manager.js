"use strict";
/**
 * Documentation management interface for viewing and editing documentation.
 *
 * This module provides a comprehensive interface for managing generated
 * documentation with export configuration and quality assessment tools.
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
exports.DocumentationManager = void 0;
const vscode = __importStar(require("vscode"));
const path = __importStar(require("path"));
const documentation_exporter_1 = require("../export/documentation-exporter");
class DocumentationManager {
    constructor(context, exporter, storageManager, config) {
        this.context = context;
        this.exporter = exporter;
        this.storageManager = storageManager;
        this.config = config;
        this.currentCommands = [];
        this.currentTestResults = [];
    }
    /**
     * Opens the documentation management interface.
     *
     * @returns Promise that resolves when interface is opened
     */
    async openManager() {
        console.log('DocumentationManager: Opening management interface');
        // Load current data
        await this.loadCurrentData();
        // Create or show existing panel
        if (this.panel) {
            this.panel.reveal(vscode.ViewColumn.One);
        }
        else {
            this.panel = vscode.window.createWebviewPanel('kiroDocumentationManager', 'Documentation Manager', vscode.ViewColumn.One, {
                enableScripts: true,
                retainContextWhenHidden: true,
                localResourceRoots: [
                    vscode.Uri.file(path.join(this.context.extensionPath, 'resources'))
                ]
            });
            this.setupWebviewHandlers();
        }
        await this.updateWebviewContent();
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
                    case 'exportDocumentation':
                        await this.handleExportDocumentation(message.config);
                        break;
                    case 'assessQuality':
                        await this.handleQualityAssessment();
                        break;
                    case 'openExportDirectory':
                        await this.handleOpenExportDirectory();
                        break;
                    case 'refreshData':
                        await this.handleRefreshData();
                        break;
                    case 'previewFormat':
                        await this.handlePreviewFormat(message.format);
                        break;
                }
            }
            catch (error) {
                const errorMessage = error instanceof Error ? error.message : 'Unknown error';
                console.error('DocumentationManager: Message handling error:', errorMessage);
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
     * Loads current commands and test results.
     */
    async loadCurrentData() {
        try {
            const discoveryResults = await this.storageManager.loadDiscoveryResults();
            const testResults = []; // TODO: Implement loadTestResults in FileStorageManager
            this.currentCommands = discoveryResults?.commands || [];
            this.currentTestResults = testResults || [];
            console.log(`DocumentationManager: Loaded ${this.currentCommands.length} commands and ${this.currentTestResults.length} test results`);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('DocumentationManager: Failed to load data:', errorMessage);
            this.currentCommands = [];
            this.currentTestResults = [];
        }
    }
    /**
      * Handles documentation export requests.
      */
    async handleExportDocumentation(exportConfig) {
        try {
            this.panel?.webview.postMessage({
                command: 'exportStarted'
            });
            // Create exporter with custom config
            const customExporter = new documentation_exporter_1.DocumentationExporter(exportConfig);
            // Export documentation
            const result = await customExporter.exportDocumentation(this.currentCommands, this.currentTestResults);
            this.lastExportResult = result;
            this.panel?.webview.postMessage({
                command: 'exportCompleted',
                result: result
            });
            if (result.success) {
                vscode.window.showInformationMessage(`Documentation exported successfully! Generated ${result.files.length} files.`);
            }
            else {
                vscode.window.showErrorMessage(`Documentation export failed: ${result.error}`);
            }
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            this.panel?.webview.postMessage({
                command: 'exportError',
                error: errorMessage
            });
            vscode.window.showErrorMessage(`Export failed: ${errorMessage}`);
        }
    }
    /**
     * Handles quality assessment requests.
     */
    async handleQualityAssessment() {
        const metrics = this.assessDocumentationQuality();
        this.panel?.webview.postMessage({
            command: 'qualityAssessment',
            metrics: metrics
        });
    }
    /**
     * Handles opening export directory.
     */
    async handleOpenExportDirectory() {
        const uri = vscode.Uri.file(this.config.exportDirectory);
        await vscode.commands.executeCommand('vscode.openFolder', uri, { forceNewWindow: false });
    }
    /**
     * Handles data refresh requests.
     */
    async handleRefreshData() {
        await this.loadCurrentData();
        await this.updateWebviewContent();
        vscode.window.showInformationMessage('Documentation data refreshed');
    }
    /**
     * Handles format preview requests.
     */
    async handlePreviewFormat(format) {
        // This would open a preview of the specified format
        // For now, just show a message
        vscode.window.showInformationMessage(`Preview for ${format} format would open here`);
    }
    /**
     * Assesses documentation quality.
     */
    assessDocumentationQuality() {
        const totalCommands = this.currentCommands.length;
        if (totalCommands === 0) {
            return {
                overallScore: 0,
                coverage: {
                    commandsWithDescriptions: 0,
                    commandsWithSignatures: 0,
                    commandsWithExamples: 0,
                    totalCommands: 0
                },
                completeness: {
                    missingDescriptions: [],
                    missingSignatures: [],
                    missingExamples: []
                },
                issues: [],
                recommendations: ['No commands found. Run command discovery first.']
            };
        }
        // Calculate coverage
        const commandsWithDescriptions = this.currentCommands.filter(cmd => !!cmd.description).length;
        const commandsWithSignatures = this.currentCommands.filter(cmd => !!cmd.signature).length;
        const testResultCommandIds = new Set(this.currentTestResults.map(result => result.commandId));
        const commandsWithExamples = this.currentCommands.filter(cmd => testResultCommandIds.has(cmd.id)).length;
        // Find missing items
        const missingDescriptions = this.currentCommands
            .filter(cmd => !cmd.description)
            .map(cmd => cmd.id);
        const missingSignatures = this.currentCommands
            .filter(cmd => !cmd.signature)
            .map(cmd => cmd.id);
        const missingExamples = this.currentCommands
            .filter(cmd => !testResultCommandIds.has(cmd.id))
            .map(cmd => cmd.id);
        // Calculate overall score
        const descriptionScore = (commandsWithDescriptions / totalCommands) * 40;
        const signatureScore = (commandsWithSignatures / totalCommands) * 40;
        const exampleScore = (commandsWithExamples / totalCommands) * 20;
        const overallScore = Math.round(descriptionScore + signatureScore + exampleScore);
        // Generate issues and recommendations
        const issues = [];
        const recommendations = [];
        if (commandsWithDescriptions < totalCommands * 0.8) {
            issues.push({
                type: 'warning',
                message: `${totalCommands - commandsWithDescriptions} commands missing descriptions`
            });
            recommendations.push('Add descriptions to commands for better documentation');
        }
        if (commandsWithSignatures < totalCommands * 0.6) {
            issues.push({
                type: 'error',
                message: `${totalCommands - commandsWithSignatures} commands missing signatures`
            });
            recommendations.push('Research command signatures for better API documentation');
        }
        if (commandsWithExamples < totalCommands * 0.3) {
            issues.push({
                type: 'suggestion',
                message: `${totalCommands - commandsWithExamples} commands missing test examples`
            });
            recommendations.push('Test more commands to provide usage examples');
        }
        // Check for high-risk commands without proper documentation
        const destructiveCommands = this.currentCommands.filter(cmd => cmd.riskLevel === 'destructive');
        const undocumentedDestructive = destructiveCommands.filter(cmd => !cmd.description || !cmd.signature);
        if (undocumentedDestructive.length > 0) {
            issues.push({
                type: 'error',
                message: `${undocumentedDestructive.length} destructive commands lack proper documentation`
            });
            recommendations.push('Prioritize documenting destructive commands for safety');
        }
        return {
            overallScore,
            coverage: {
                commandsWithDescriptions,
                commandsWithSignatures,
                commandsWithExamples,
                totalCommands
            },
            completeness: {
                missingDescriptions,
                missingSignatures,
                missingExamples
            },
            issues,
            recommendations
        };
    } /**
  
     * Updates webview content.
     */
    async updateWebviewContent() {
        if (!this.panel)
            return;
        this.panel.webview.html = this.generateWebviewHtml();
    }
    /**
     * Generates HTML content for the webview.
     */
    generateWebviewHtml() {
        const qualityMetrics = this.assessDocumentationQuality();
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Documentation Manager</title>
    <style>${this.getWebviewStyles()}</style>
</head>
<body>
    <div class="container">
        <header class="header">
            <h1>Documentation Manager</h1>
            <div class="header-stats">
                <span>Commands: ${this.currentCommands.length}</span>
                <span>Test Results: ${this.currentTestResults.length}</span>
                <span>Quality Score: ${qualityMetrics.overallScore}/100</span>
            </div>
        </header>
        
        <div class="content">
            <div class="main-panel">
                ${this.generateExportSection()}
                ${this.generateQualitySection(qualityMetrics)}
            </div>
            
            <div class="side-panel">
                ${this.generateStatusSection()}
                ${this.generateActionsSection()}
            </div>
        </div>
        
        <div id="results" class="results-panel" style="display: none;">
            <h2>Export Results</h2>
            <div id="resultsContent"></div>
        </div>
    </div>
    
    <script>${this.getWebviewScript()}</script>
</body>
</html>`;
    }
    /**
     * Generates export configuration section.
     */
    generateExportSection() {
        return `
      <div class="section">
        <h2>Export Configuration</h2>
        <form id="exportForm" class="export-form">
          <div class="form-group">
            <label>Export Formats</label>
            <div class="checkbox-group">
              <label><input type="checkbox" name="formats" value="markdown" checked> Markdown</label>
              <label><input type="checkbox" name="formats" value="html"> HTML</label>
              <label><input type="checkbox" name="formats" value="json" checked> JSON</label>
              <label><input type="checkbox" name="formats" value="typescript" checked> TypeScript</label>
              <label><input type="checkbox" name="formats" value="openapi"> OpenAPI</label>
            </div>
          </div>
          
          <div class="form-group">
            <label for="version">Documentation Version</label>
            <input type="text" id="version" value="1.0.0" placeholder="1.0.0">
          </div>
          
          <div class="form-group">
            <label for="author">Author (optional)</label>
            <input type="text" id="author" placeholder="Your name">
          </div>
          
          <div class="form-group">
            <label for="organization">Organization (optional)</label>
            <input type="text" id="organization" placeholder="Organization name">
          </div>
          
          <div class="form-group">
            <label>Options</label>
            <div class="checkbox-group">
              <label><input type="checkbox" name="includeExamples" checked> Include test examples</label>
              <label><input type="checkbox" name="includeStatistics" checked> Include statistics</label>
              <label><input type="checkbox" name="includeChangeTracking"> Include change tracking</label>
            </div>
          </div>
          
          <div class="form-actions">
            <button type="button" id="exportBtn" class="primary-button">Export Documentation</button>
            <button type="button" id="previewBtn" class="secondary-button">Preview</button>
          </div>
        </form>
      </div>
    `;
    }
    /**
     * Generates quality assessment section.
     */
    generateQualitySection(metrics) {
        return `
      <div class="section">
        <h2>Quality Assessment</h2>
        
        <div class="quality-score">
          <div class="score-circle ${this.getScoreClass(metrics.overallScore)}">
            <span class="score-number">${metrics.overallScore}</span>
            <span class="score-label">/ 100</span>
          </div>
          <div class="score-details">
            <h3>Overall Quality Score</h3>
            <p>${this.getScoreDescription(metrics.overallScore)}</p>
          </div>
        </div>
        
        <div class="coverage-grid">
          <div class="coverage-item">
            <h4>Descriptions</h4>
            <div class="progress-bar">
              <div class="progress-fill" style="width: ${(metrics.coverage.commandsWithDescriptions / metrics.coverage.totalCommands) * 100}%"></div>
            </div>
            <span>${metrics.coverage.commandsWithDescriptions} / ${metrics.coverage.totalCommands}</span>
          </div>
          
          <div class="coverage-item">
            <h4>Signatures</h4>
            <div class="progress-bar">
              <div class="progress-fill" style="width: ${(metrics.coverage.commandsWithSignatures / metrics.coverage.totalCommands) * 100}%"></div>
            </div>
            <span>${metrics.coverage.commandsWithSignatures} / ${metrics.coverage.totalCommands}</span>
          </div>
          
          <div class="coverage-item">
            <h4>Examples</h4>
            <div class="progress-bar">
              <div class="progress-fill" style="width: ${(metrics.coverage.commandsWithExamples / metrics.coverage.totalCommands) * 100}%"></div>
            </div>
            <span>${metrics.coverage.commandsWithExamples} / ${metrics.coverage.totalCommands}</span>
          </div>
        </div>
        
        ${metrics.issues.length > 0 ? `
          <div class="issues-section">
            <h3>Issues</h3>
            <ul class="issues-list">
              ${metrics.issues.map(issue => `
                <li class="issue-item issue-${issue.type}">
                  <span class="issue-icon">${this.getIssueIcon(issue.type)}</span>
                  <span class="issue-message">${issue.message}</span>
                </li>
              `).join('')}
            </ul>
          </div>
        ` : ''}
        
        ${metrics.recommendations.length > 0 ? `
          <div class="recommendations-section">
            <h3>Recommendations</h3>
            <ul class="recommendations-list">
              ${metrics.recommendations.map(rec => `
                <li class="recommendation-item">💡 ${rec}</li>
              `).join('')}
            </ul>
          </div>
        ` : ''}
        
        <div class="quality-actions">
          <button id="assessBtn" class="secondary-button">Refresh Assessment</button>
        </div>
      </div>
    `;
    }
    /**
     * Generates status section.
     */
    generateStatusSection() {
        return `
      <div class="side-section">
        <h3>Status</h3>
        <div class="status-items">
          <div class="status-item">
            <span class="status-label">Commands:</span>
            <span class="status-value">${this.currentCommands.length}</span>
          </div>
          <div class="status-item">
            <span class="status-label">Test Results:</span>
            <span class="status-value">${this.currentTestResults.length}</span>
          </div>
          <div class="status-item">
            <span class="status-label">Last Export:</span>
            <span class="status-value">${this.lastExportResult ?
            this.lastExportResult.metadata.generatedAt.toLocaleString() : 'Never'}</span>
          </div>
        </div>
      </div>
    `;
    }
    /**
     * Generates actions section.
     */
    generateActionsSection() {
        return `
      <div class="side-section">
        <h3>Actions</h3>
        <div class="action-buttons">
          <button id="refreshBtn" class="action-button">🔄 Refresh Data</button>
          <button id="openDirBtn" class="action-button">📁 Open Export Directory</button>
          <button id="viewDocsBtn" class="action-button">📖 View Documentation</button>
        </div>
      </div>
    `;
    }
    /**
      * Gets CSS styles for the webview.
      */
    getWebviewStyles() {
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
      
      .header-stats {
        display: flex;
        justify-content: center;
        gap: 30px;
        font-size: 14px;
        color: var(--vscode-descriptionForeground);
      }
      
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
        margin-bottom: 20px;
      }
      
      .export-form {
        display: grid;
        gap: 20px;
      }
      
      .form-group {
        display: grid;
        gap: 8px;
      }
      
      .form-group label {
        font-weight: bold;
        color: var(--vscode-foreground);
      }
      
      .checkbox-group {
        display: grid;
        gap: 8px;
        padding-left: 10px;
      }
      
      .checkbox-group label {
        display: flex;
        align-items: center;
        gap: 8px;
        font-weight: normal;
      }
      
      input[type="text"], input[type="number"] {
        padding: 8px 12px;
        border: 1px solid var(--vscode-input-border);
        background-color: var(--vscode-input-background);
        color: var(--vscode-input-foreground);
        border-radius: 4px;
      }
      
      input:focus {
        outline: none;
        border-color: var(--vscode-focusBorder);
      }
      
      .form-actions {
        display: flex;
        gap: 10px;
        justify-content: center;
        margin-top: 10px;
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
      
      .quality-score {
        display: flex;
        align-items: center;
        gap: 20px;
        margin-bottom: 30px;
      }
      
      .score-circle {
        width: 80px;
        height: 80px;
        border-radius: 50%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        border: 4px solid;
      }
      
      .score-circle.excellent {
        border-color: #4CAF50;
        background-color: rgba(76, 175, 80, 0.1);
      }
      
      .score-circle.good {
        border-color: #8BC34A;
        background-color: rgba(139, 195, 74, 0.1);
      }
      
      .score-circle.fair {
        border-color: #FF9800;
        background-color: rgba(255, 152, 0, 0.1);
      }
      
      .score-circle.poor {
        border-color: #f44336;
        background-color: rgba(244, 67, 54, 0.1);
      }
      
      .score-number {
        font-size: 24px;
      }
      
      .score-label {
        font-size: 12px;
        opacity: 0.7;
      }
      
      .score-details h3 {
        margin-bottom: 5px;
      }
      
      .coverage-grid {
        display: grid;
        gap: 20px;
        margin-bottom: 30px;
      }
      
      .coverage-item {
        display: grid;
        gap: 8px;
      }
      
      .coverage-item h4 {
        color: var(--vscode-textLink-foreground);
        font-size: 14px;
      }
      
      .progress-bar {
        height: 8px;
        background-color: var(--vscode-progressBar-background);
        border-radius: 4px;
        overflow: hidden;
      }
      
      .progress-fill {
        height: 100%;
        background-color: var(--vscode-progressBar-foreground);
        transition: width 0.3s ease;
      }
      
      .issues-section, .recommendations-section {
        margin-bottom: 20px;
      }
      
      .issues-section h3, .recommendations-section h3 {
        font-size: 16px;
        margin-bottom: 10px;
      }
      
      .issues-list, .recommendations-list {
        list-style: none;
        display: grid;
        gap: 8px;
      }
      
      .issue-item {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 8px 12px;
        border-radius: 4px;
      }
      
      .issue-error {
        background-color: rgba(244, 67, 54, 0.1);
        border-left: 3px solid #f44336;
      }
      
      .issue-warning {
        background-color: rgba(255, 152, 0, 0.1);
        border-left: 3px solid #FF9800;
      }
      
      .issue-suggestion {
        background-color: rgba(33, 150, 243, 0.1);
        border-left: 3px solid #2196F3;
      }
      
      .recommendation-item {
        padding: 8px 12px;
        background-color: rgba(76, 175, 80, 0.1);
        border-radius: 4px;
        border-left: 3px solid #4CAF50;
      }
      
      .quality-actions {
        text-align: center;
        margin-top: 20px;
      }
      
      .status-items {
        display: grid;
        gap: 10px;
      }
      
      .status-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 0;
        border-bottom: 1px solid var(--vscode-panel-border);
      }
      
      .status-label {
        color: var(--vscode-descriptionForeground);
      }
      
      .status-value {
        font-weight: bold;
      }
      
      .action-buttons {
        display: grid;
        gap: 10px;
      }
      
      .action-button {
        padding: 12px;
        background-color: var(--vscode-button-secondaryBackground);
        color: var(--vscode-button-secondaryForeground);
        border: none;
        border-radius: 4px;
        cursor: pointer;
        text-align: left;
        transition: background-color 0.2s;
      }
      
      .action-button:hover {
        background-color: var(--vscode-button-secondaryHoverBackground);
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
      
      @media (max-width: 768px) {
        .content {
          grid-template-columns: 1fr;
        }
        
        .quality-score {
          flex-direction: column;
          text-align: center;
        }
        
        .header-stats {
          flex-direction: column;
          gap: 10px;
        }
      }
    `;
    }
    /**
     * Gets JavaScript code for the webview.
     */
    getWebviewScript() {
        return `
      const vscode = acquireVsCodeApi();
      
      document.addEventListener('DOMContentLoaded', function() {
        setupEventListeners();
      });
      
      function setupEventListeners() {
        const exportBtn = document.getElementById('exportBtn');
        const previewBtn = document.getElementById('previewBtn');
        const assessBtn = document.getElementById('assessBtn');
        const refreshBtn = document.getElementById('refreshBtn');
        const openDirBtn = document.getElementById('openDirBtn');
        const viewDocsBtn = document.getElementById('viewDocsBtn');
        
        if (exportBtn) {
          exportBtn.addEventListener('click', exportDocumentation);
        }
        
        if (previewBtn) {
          previewBtn.addEventListener('click', previewDocumentation);
        }
        
        if (assessBtn) {
          assessBtn.addEventListener('click', assessQuality);
        }
        
        if (refreshBtn) {
          refreshBtn.addEventListener('click', refreshData);
        }
        
        if (openDirBtn) {
          openDirBtn.addEventListener('click', openExportDirectory);
        }
        
        if (viewDocsBtn) {
          viewDocsBtn.addEventListener('click', viewDocumentation);
        }
      }
      
      function exportDocumentation() {
        const config = collectExportConfig();
        
        vscode.postMessage({
          command: 'exportDocumentation',
          config: config
        });
      }
      
      function previewDocumentation() {
        const formats = collectSelectedFormats();
        if (formats.length > 0) {
          vscode.postMessage({
            command: 'previewFormat',
            format: formats[0]
          });
        }
      }
      
      function assessQuality() {
        vscode.postMessage({
          command: 'assessQuality'
        });
      }
      
      function refreshData() {
        vscode.postMessage({
          command: 'refreshData'
        });
      }
      
      function openExportDirectory() {
        vscode.postMessage({
          command: 'openExportDirectory'
        });
      }
      
      function viewDocumentation() {
        // This would open the documentation viewer
        vscode.postMessage({
          command: 'viewDocumentation'
        });
      }
      
      function collectExportConfig() {
        const formats = collectSelectedFormats();
        const version = document.getElementById('version')?.value || '1.0.0';
        const author = document.getElementById('author')?.value || undefined;
        const organization = document.getElementById('organization')?.value || undefined;
        
        const includeExamples = document.querySelector('input[name="includeExamples"]')?.checked || false;
        const includeStatistics = document.querySelector('input[name="includeStatistics"]')?.checked || false;
        const includeChangeTracking = document.querySelector('input[name="includeChangeTracking"]')?.checked || false;
        
        return {
          formats: formats,
          version: version,
          author: author,
          organization: organization,
          includeExamples: includeExamples,
          includeStatistics: includeStatistics,
          includeChangeTracking: includeChangeTracking
        };
      }
      
      function collectSelectedFormats() {
        const checkboxes = document.querySelectorAll('input[name="formats"]:checked');
        return Array.from(checkboxes).map(cb => cb.value);
      }
      
      // Handle messages from extension
      window.addEventListener('message', event => {
        const message = event.data;
        
        switch (message.command) {
          case 'exportStarted':
            handleExportStarted();
            break;
          case 'exportCompleted':
            handleExportCompleted(message.result);
            break;
          case 'exportError':
            handleExportError(message.error);
            break;
          case 'qualityAssessment':
            handleQualityAssessment(message.metrics);
            break;
          case 'error':
            handleError(message.message);
            break;
        }
      });
      
      function handleExportStarted() {
        const exportBtn = document.getElementById('exportBtn');
        if (exportBtn) {
          exportBtn.disabled = true;
          exportBtn.textContent = 'Exporting...';
        }
        
        showResults('Exporting documentation...');
      }
      
      function handleExportCompleted(result) {
        const exportBtn = document.getElementById('exportBtn');
        if (exportBtn) {
          exportBtn.disabled = false;
          exportBtn.textContent = 'Export Documentation';
        }
        
        let html = \`
          <div class="export-result \${result.success ? 'success' : 'failure'}">
            <h3>\${result.success ? '✓ Export Successful' : '✗ Export Failed'}</h3>
            <p>Duration: \${result.duration}ms</p>
          </div>
        \`;
        
        if (result.success && result.files.length > 0) {
          html += \`
            <div class="export-files">
              <h4>Generated Files (\${result.files.length})</h4>
              <ul>
                \${result.files.map(file => \`
                  <li>
                    <strong>\${file.format}:</strong> \${file.path.split('/').pop()} 
                    <span class="file-size">(\${formatFileSize(file.size)})</span>
                  </li>
                \`).join('')}
              </ul>
            </div>
          \`;
        }
        
        if (result.warnings && result.warnings.length > 0) {
          html += \`
            <div class="export-warnings">
              <h4>Warnings</h4>
              <ul>
                \${result.warnings.map(warning => \`<li>\${warning}</li>\`).join('')}
              </ul>
            </div>
          \`;
        }
        
        if (result.error) {
          html += \`
            <div class="export-error">
              <h4>Error</h4>
              <p>\${result.error}</p>
            </div>
          \`;
        }
        
        showResults(html);
      }
      
      function handleExportError(error) {
        const exportBtn = document.getElementById('exportBtn');
        if (exportBtn) {
          exportBtn.disabled = false;
          exportBtn.textContent = 'Export Documentation';
        }
        
        showResults(\`
          <div class="export-result failure">
            <h3>✗ Export Failed</h3>
            <p>\${error}</p>
          </div>
        \`);
      }
      
      function handleQualityAssessment(metrics) {
        // This would update the quality section with new metrics
        // For now, just refresh the page
        location.reload();
      }
      
      function handleError(message) {
        showResults(\`
          <div class="error-message">
            <strong>Error:</strong> \${message}
          </div>
        \`);
      }
      
      function showResults(content) {
        const resultsPanel = document.getElementById('results');
        const resultsContent = document.getElementById('resultsContent');
        
        if (resultsPanel && resultsContent) {
          resultsContent.innerHTML = content;
          resultsPanel.style.display = 'block';
        }
      }
      
      function formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
      }
    `;
    }
    /**
     * Gets score class based on score value.
     */
    getScoreClass(score) {
        if (score >= 90)
            return 'excellent';
        if (score >= 70)
            return 'good';
        if (score >= 50)
            return 'fair';
        return 'poor';
    }
    /**
     * Gets score description based on score value.
     */
    getScoreDescription(score) {
        if (score >= 90)
            return 'Excellent documentation quality';
        if (score >= 70)
            return 'Good documentation quality';
        if (score >= 50)
            return 'Fair documentation quality - room for improvement';
        return 'Poor documentation quality - needs significant improvement';
    }
    /**
     * Gets issue icon based on issue type.
     */
    getIssueIcon(type) {
        switch (type) {
            case 'error': return '❌';
            case 'warning': return '⚠️';
            case 'suggestion': return '💡';
            default: return 'ℹ️';
        }
    }
    /**
     * Disposes resources used by the manager.
     */
    dispose() {
        if (this.panel) {
            this.panel.dispose();
            this.panel = undefined;
        }
    }
}
exports.DocumentationManager = DocumentationManager;
//# sourceMappingURL=documentation-manager.js.map