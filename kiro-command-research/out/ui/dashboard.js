"use strict";
/**
 * Centralized dashboard interface for the Kiro Command Research Tool.
 *
 * This module provides a workflow-based dashboard that serves as the main
 * entry point for all extension functionality, organized in logical workflow steps.
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
exports.Dashboard = void 0;
const vscode = __importStar(require("vscode"));
class Dashboard {
    constructor(context, storageManager, config) {
        this.context = context;
        this.storageManager = storageManager;
        this.config = config;
    }
    /**
     * Opens the dashboard interface.
     *
     * @returns Promise that resolves when dashboard is opened
     */
    async openDashboard() {
        console.log('Dashboard: Opening dashboard interface...');
        // Create or show existing panel
        if (this.panel) {
            this.panel.reveal(vscode.ViewColumn.One);
        }
        else {
            this.panel = vscode.window.createWebviewPanel('kiroDashboard', 'Kiro Command Research', vscode.ViewColumn.One, {
                enableScripts: true,
                retainContextWhenHidden: true,
                localResourceRoots: [
                    vscode.Uri.file(this.context.extensionPath)
                ]
            });
            this.setupWebviewHandlers();
        }
        // Load current state and update content
        await this.refreshDashboardState();
        await this.updateWebviewContent();
        // Start auto-refresh if enabled
        if (this.config.autoRefresh) {
            this.startAutoRefresh();
        }
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
                    case 'discoverCommands':
                        await vscode.commands.executeCommand('kiroCommandResearch.discoverCommands');
                        await this.refreshDashboardState();
                        break;
                    case 'researchParameters':
                        await vscode.commands.executeCommand('kiroCommandResearch.researchParameters');
                        await this.refreshDashboardState();
                        break;
                    case 'editParameters':
                        await vscode.commands.executeCommand('kiroCommandResearch.editParameters');
                        break;
                    case 'testCommand':
                        await vscode.commands.executeCommand('kiroCommandResearch.testCommand');
                        break;
                    case 'generateDocs':
                        await vscode.commands.executeCommand('kiroCommandResearch.generateDocs');
                        await this.refreshDashboardState();
                        break;
                    case 'viewResults':
                        await vscode.commands.executeCommand('kiroCommandResearch.viewResults');
                        break;
                    case 'openExplorer':
                        await vscode.commands.executeCommand('kiroCommandResearch.openExplorer');
                        break;
                    case 'validateParameters':
                        await vscode.commands.executeCommand('kiroCommandResearch.validateParameters');
                        break;
                    case 'executeCommand':
                        await vscode.commands.executeCommand('kiroCommandResearch.executeCommand');
                        break;
                    case 'refresh':
                        await this.refreshDashboardState();
                        break;
                }
                // Update dashboard after command execution
                await this.updateWebviewContent();
            }
            catch (error) {
                const errorMessage = error instanceof Error ? error.message : 'Unknown error';
                console.error('Dashboard: Message handling error:', errorMessage);
                this.panel?.webview.postMessage({
                    command: 'error',
                    message: errorMessage
                });
            }
        });
        this.panel.onDidDispose(() => {
            this.panel = undefined;
            this.stopAutoRefresh();
        });
    }
    /**
      * Refreshes the dashboard state by loading current data.
      */
    async refreshDashboardState() {
        try {
            console.log('Dashboard: Refreshing state...');
            // Load discovery results
            const discoveryResults = await this.storageManager.loadDiscoveryResults();
            // Calculate discovery stats
            const discovery = {
                totalCommands: discoveryResults?.totalCommands || 0,
                safeCommands: discoveryResults?.statistics?.safeCommands || 0,
                moderateCommands: discoveryResults?.statistics?.moderateCommands || 0,
                destructiveCommands: discoveryResults?.statistics?.destructiveCommands || 0,
                lastDiscovery: discoveryResults?.discoveryTimestamp ? new Date(discoveryResults.discoveryTimestamp) : null
            };
            // Calculate research stats
            const commandsWithSignatures = discoveryResults?.commands?.filter((cmd) => cmd.signature)?.length || 0;
            const research = {
                commandsWithSignatures,
                highConfidence: discoveryResults?.commands?.filter((cmd) => cmd.signature?.confidence === 'high')?.length || 0,
                mediumConfidence: discoveryResults?.commands?.filter((cmd) => cmd.signature?.confidence === 'medium')?.length || 0,
                lowConfidence: discoveryResults?.commands?.filter((cmd) => cmd.signature?.confidence === 'low')?.length || 0,
                lastResearch: discoveryResults?.parameterResearch?.researchedAt ? new Date(discoveryResults.parameterResearch.researchedAt) : null
            };
            // TODO: Load testing stats from test results storage when implemented
            const testing = {
                totalTests: 0,
                successfulTests: 0,
                failedTests: 0,
                lastTest: null
            };
            // TODO: Load documentation status when implemented
            const documentation = {
                hasDocumentation: false,
                exportFormats: [],
                lastGenerated: null
            };
            this.currentState = {
                discovery,
                research,
                testing,
                documentation
            };
            console.log('Dashboard: State refreshed successfully');
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('Dashboard: Failed to refresh state:', errorMessage);
            // Set default state on error
            this.currentState = {
                discovery: { totalCommands: 0, safeCommands: 0, moderateCommands: 0, destructiveCommands: 0, lastDiscovery: null },
                research: { commandsWithSignatures: 0, highConfidence: 0, mediumConfidence: 0, lowConfidence: 0, lastResearch: null },
                testing: { totalTests: 0, successfulTests: 0, failedTests: 0, lastTest: null },
                documentation: { hasDocumentation: false, exportFormats: [], lastGenerated: null }
            };
        }
    }
    /**
     * Updates the webview content with current state.
     */
    async updateWebviewContent() {
        if (!this.panel || !this.currentState) {
            return;
        }
        this.panel.webview.html = this.generateDashboardHtml();
    }
    /**
     * Starts auto-refresh timer.
     */
    startAutoRefresh() {
        this.stopAutoRefresh();
        this.refreshTimer = setInterval(async () => {
            await this.refreshDashboardState();
            await this.updateWebviewContent();
        }, this.config.refreshInterval);
    }
    /**
     * Stops auto-refresh timer.
     */
    stopAutoRefresh() {
        if (this.refreshTimer) {
            clearInterval(this.refreshTimer);
            this.refreshTimer = undefined;
        }
    } /*
  *
     * Generates HTML content for the dashboard webview.
     */
    generateDashboardHtml() {
        if (!this.currentState) {
            return '<html><body><h1>Loading dashboard...</h1></body></html>';
        }
        const state = this.currentState;
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kiro Command Research Dashboard</title>
    <style>${this.getDashboardStyles()}</style>
</head>
<body>
    <div class="dashboard">
        <header class="dashboard-header">
            <h1>🔬 Kiro Command Research</h1>
            <p class="subtitle">Workflow-based command discovery and testing</p>
            <button class="refresh-btn" onclick="refreshDashboard()" 
                    title="Refresh dashboard data (Ctrl+R or Cmd+R)"
                    aria-label="Refresh Dashboard - Refresh dashboard data">
              🔄 Refresh
            </button>
        </header>
        
        <div class="workflow-container">
            ${this.generateDiscoverySection(state)}
            ${this.generateResearchSection(state)}
            ${this.generateTestingSection(state)}
            ${this.generateDocumentationSection(state)}
        </div>
        
        ${this.config.showGuidance ? this.generateGuidanceSection() : ''}
        
        <footer class="dashboard-footer">
            <div class="quick-actions">
                <h3>Quick Actions</h3>
                <div class="action-buttons">
                    <button class="action-btn secondary" onclick="openExplorer()"
                            title="Open command explorer (Ctrl+Shift+K E)"
                            aria-label="Command Explorer - Browse discovered commands">
                      📁 Command Explorer
                    </button>
                    <button class="action-btn secondary" onclick="viewResults()"
                            title="View discovery and test results"
                            aria-label="View Results - View discovery and test results">
                      📊 View Results
                    </button>
                </div>
            </div>
        </footer>
    </div>
    
    <script>${this.getDashboardScript()}</script>
</body>
</html>`;
    }
    /**
       * Generates the discovery workflow section.
       */
    generateDiscoverySection(state) {
        const { discovery } = state;
        const hasDiscovered = discovery.totalCommands > 0;
        const statusClass = hasDiscovered ? 'completed' : 'pending';
        return `
      <div class="workflow-section ${statusClass}">
        <div class="section-help">
          💡 Scan the VS Code command registry to find all available Kiro commands and categorize them by safety level.
        </div>
        <div class="section-header">
          <h2>🔍 1. Discovery</h2>
          <div class="section-status">
            ${hasDiscovered ? '✅ Complete' : '⏳ Pending'}
          </div>
        </div>
        
        <div class="section-content">
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-number">${discovery.totalCommands}</div>
              <div class="stat-label">Total Commands</div>
            </div>
            <div class="stat-card safe">
              <div class="stat-number">${discovery.safeCommands}</div>
              <div class="stat-label">Safe</div>
            </div>
            <div class="stat-card moderate">
              <div class="stat-number">${discovery.moderateCommands}</div>
              <div class="stat-label">Moderate</div>
            </div>
            <div class="stat-card destructive">
              <div class="stat-number">${discovery.destructiveCommands}</div>
              <div class="stat-label">Destructive</div>
            </div>
          </div>
          
          <div class="section-actions">
            <button class="action-btn primary" onclick="discoverCommands()" 
                    title="Scan for all available Kiro commands (Ctrl+Shift+K 1)"
                    aria-label="Discover Commands - Scan for all available Kiro commands">
              🔍 Discover Commands
            </button>
            ${discovery.lastDiscovery ? `
              <div class="last-activity">
                Last discovery: ${discovery.lastDiscovery.toLocaleString()}
              </div>
            ` : ''}
          </div>
          
          ${!hasDiscovered ? `
            <div class="guidance">
              <p>Start by discovering all available Kiro commands. This scans the command registry and categorizes commands by risk level.</p>
            </div>
          ` : ''}
        </div>
      </div>
    `;
    }
    /**
     * Generates the research workflow section.
     */
    generateResearchSection(state) {
        const { research, discovery } = state;
        const hasResearched = research.commandsWithSignatures > 0;
        const canResearch = discovery.totalCommands > 0;
        const statusClass = hasResearched ? 'completed' : canResearch ? 'available' : 'disabled';
        return `
      <div class="workflow-section ${statusClass}">
        <div class="section-help">
          💡 Analyze command signatures, parameters, and return types to understand how to use each command effectively.
        </div>
        <div class="section-header">
          <h2>🔬 2. Research</h2>
          <div class="section-status">
            ${hasResearched ? '✅ Complete' : canResearch ? '🔄 Available' : '🔒 Requires Discovery'}
          </div>
        </div>
        
        <div class="section-content">
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-number">${research.commandsWithSignatures}</div>
              <div class="stat-label">With Signatures</div>
            </div>
            <div class="stat-card high-confidence">
              <div class="stat-number">${research.highConfidence}</div>
              <div class="stat-label">High Confidence</div>
            </div>
            <div class="stat-card medium-confidence">
              <div class="stat-number">${research.mediumConfidence}</div>
              <div class="stat-label">Medium Confidence</div>
            </div>
            <div class="stat-card low-confidence">
              <div class="stat-number">${research.lowConfidence}</div>
              <div class="stat-label">Low Confidence</div>
            </div>
          </div>
          
          <div class="section-actions">
            <div class="action-row">
              <button class="action-btn primary" onclick="researchParameters()" ${!canResearch ? 'disabled' : ''}
                      title="Analyze command signatures and parameters (Ctrl+Shift+K 2)"
                      aria-label="Research Parameters - Analyze command signatures and parameters">
                🔬 Research Parameters
              </button>
              <button class="action-btn secondary" onclick="editParameters()" ${!canResearch ? 'disabled' : ''}
                      title="Manually add parameter information"
                      aria-label="Edit Parameters - Manually add parameter information">
                ✏️ Edit Parameters
              </button>
            </div>
            ${research.lastResearch ? `
              <div class="last-activity">
                Last research: ${research.lastResearch.toLocaleString()}
              </div>
            ` : ''}
          </div>
          
          ${!hasResearched && canResearch ? `
            <div class="guidance">
              <p>Research command parameters to understand their signatures and enable advanced testing capabilities.</p>
            </div>
          ` : ''}
        </div>
      </div>
    `;
    }
    /**
      * Generates the testing workflow section.
      */
    generateTestingSection(state) {
        const { testing, discovery } = state;
        const canTest = discovery.totalCommands > 0;
        const hasTests = testing.totalTests > 0;
        const statusClass = hasTests ? 'completed' : canTest ? 'available' : 'disabled';
        return `
      <div class="workflow-section ${statusClass}">
        <div class="section-help">
          💡 Safely test commands with parameter validation, workspace snapshots, and side effect monitoring.
        </div>
        <div class="section-header">
          <h2>🧪 3. Testing</h2>
          <div class="section-status">
            ${hasTests ? '✅ Active' : canTest ? '🔄 Available' : '🔒 Requires Discovery'}
          </div>
        </div>
        
        <div class="section-content">
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-number">${testing.totalTests}</div>
              <div class="stat-label">Total Tests</div>
            </div>
            <div class="stat-card success">
              <div class="stat-number">${testing.successfulTests}</div>
              <div class="stat-label">Successful</div>
            </div>
            <div class="stat-card failure">
              <div class="stat-number">${testing.failedTests}</div>
              <div class="stat-label">Failed</div>
            </div>
            <div class="stat-card">
              <div class="stat-number">${testing.totalTests > 0 ? Math.round((testing.successfulTests / testing.totalTests) * 100) : 0}%</div>
              <div class="stat-label">Success Rate</div>
            </div>
          </div>
          
          <div class="section-actions">
            <div class="action-row">
              <button class="action-btn primary" onclick="testCommand()" ${!canTest ? 'disabled' : ''}
                      title="Test commands with safety checks (Ctrl+Shift+K 3)"
                      aria-label="Test Command - Test commands with safety checks">
                🧪 Test Command
              </button>
              <button class="action-btn secondary" onclick="validateParameters()" ${!canTest ? 'disabled' : ''}
                      title="Validate command parameters before execution"
                      aria-label="Validate Parameters - Validate command parameters before execution">
                ✅ Validate Parameters
              </button>
            </div>
            <div class="action-row">
              <button class="action-btn secondary" onclick="executeCommand()" ${!canTest ? 'disabled' : ''}
                      title="Execute commands with monitoring and rollback"
                      aria-label="Execute Command Safely - Execute commands with monitoring and rollback">
                ⚡ Execute Command Safely
              </button>
            </div>
            ${testing.lastTest ? `
              <div class="last-activity">
                Last test: ${testing.lastTest.toLocaleString()}
              </div>
            ` : ''}
          </div>
          
          ${!hasTests && canTest ? `
            <div class="guidance">
              <p>Test commands safely with parameter validation, workspace snapshots, and side effect monitoring.</p>
            </div>
          ` : ''}
        </div>
      </div>
    `;
    }
    /**
     * Generates the documentation workflow section.
     */
    generateDocumentationSection(state) {
        const { documentation, discovery } = state;
        const canDocument = discovery.totalCommands > 0;
        const hasDocumentation = documentation.hasDocumentation;
        const statusClass = hasDocumentation ? 'completed' : canDocument ? 'available' : 'disabled';
        return `
      <div class="workflow-section ${statusClass}">
        <div class="section-help">
          💡 Generate comprehensive documentation in multiple formats including JSON schemas and TypeScript definitions.
        </div>
        <div class="section-header">
          <h2>📚 4. Documentation</h2>
          <div class="section-status">
            ${hasDocumentation ? '✅ Generated' : canDocument ? '🔄 Available' : '🔒 Requires Discovery'}
          </div>
        </div>
        
        <div class="section-content">
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-number">${documentation.exportFormats.length}</div>
              <div class="stat-label">Export Formats</div>
            </div>
            <div class="stat-card">
              <div class="stat-number">${hasDocumentation ? '✅' : '❌'}</div>
              <div class="stat-label">Generated</div>
            </div>
          </div>
          
          <div class="section-actions">
            <button class="action-btn primary" onclick="generateDocs()" ${!canDocument ? 'disabled' : ''}
                    title="Generate comprehensive documentation (Ctrl+Shift+K 4)"
                    aria-label="Generate Documentation - Generate comprehensive documentation">
              📚 Generate Documentation
            </button>
            ${documentation.lastGenerated ? `
              <div class="last-activity">
                Last generated: ${documentation.lastGenerated.toLocaleString()}
              </div>
            ` : ''}
          </div>
          
          ${!hasDocumentation && canDocument ? `
            <div class="guidance">
              <p>Generate comprehensive documentation in multiple formats for discovered commands and test results.</p>
            </div>
          ` : ''}
        </div>
      </div>
    `;
    } /**
  
     * Generates the guidance section for new users.
     */
    generateGuidanceSection() {
        return `
      <div class="guidance-section">
        <h3>🎯 Getting Started</h3>
        <div class="workflow-steps">
          <div class="step">
            <div class="step-number">1</div>
            <div class="step-content">
              <strong>Discover Commands</strong>
              <p>Start by scanning for all available Kiro commands</p>
              <small>Keyboard: Ctrl+Shift+K 1</small>
            </div>
          </div>
          <div class="step">
            <div class="step-number">2</div>
            <div class="step-content">
              <strong>Research Parameters</strong>
              <p>Analyze command signatures and parameter requirements</p>
              <small>Keyboard: Ctrl+Shift+K 2</small>
            </div>
          </div>
          <div class="step">
            <div class="step-number">3</div>
            <div class="step-content">
              <strong>Test Commands</strong>
              <p>Safely test commands with validation and monitoring</p>
              <small>Keyboard: Ctrl+Shift+K 3</small>
            </div>
          </div>
          <div class="step">
            <div class="step-number">4</div>
            <div class="step-content">
              <strong>Generate Documentation</strong>
              <p>Create comprehensive documentation for your findings</p>
              <small>Keyboard: Ctrl+Shift+K 4</small>
            </div>
          </div>
        </div>
        
        <div class="keyboard-shortcuts">
          <h4>⌨️ Keyboard Shortcuts</h4>
          <div class="shortcuts-grid">
            <div class="shortcut">
              <kbd>Ctrl+Shift+K D</kbd>
              <span>Open Dashboard</span>
            </div>
            <div class="shortcut">
              <kbd>Ctrl+Shift+K E</kbd>
              <span>Command Explorer</span>
            </div>
            <div class="shortcut">
              <kbd>Ctrl+R</kbd>
              <span>Refresh Dashboard</span>
            </div>
          </div>
        </div>
      </div>
    `;
    } /**
    
   * Gets CSS styles for the dashboard.
     */
    getDashboardStyles() {
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
      
      .dashboard {
        max-width: 1200px;
        margin: 0 auto;
        padding: 20px;
      }
      
      .dashboard-header {
        text-align: center;
        margin-bottom: 40px;
        padding-bottom: 20px;
        border-bottom: 2px solid var(--vscode-panel-border);
        position: relative;
      }
      
      .dashboard-header h1 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 10px;
        font-size: 2.5em;
      }
      
      .subtitle {
        color: var(--vscode-descriptionForeground);
        font-size: 1.1em;
        margin-bottom: 20px;
      }
      
      .refresh-btn {
        position: absolute;
        top: 0;
        right: 0;
        background: var(--vscode-button-secondaryBackground);
        color: var(--vscode-button-secondaryForeground);
        border: none;
        padding: 8px 16px;
        border-radius: 4px;
        cursor: pointer;
        font-size: 14px;
      }
      
      .refresh-btn:hover {
        background: var(--vscode-button-secondaryHoverBackground);
      }
      
      .workflow-container {
        display: grid;
        gap: 30px;
        margin-bottom: 40px;
      }
      
      .workflow-section {
        background: var(--vscode-panel-background);
        border-radius: 12px;
        padding: 24px;
        border: 2px solid var(--vscode-panel-border);
        transition: all 0.3s ease;
        position: relative;
      }
      
      .workflow-section:hover .section-help {
        opacity: 1;
        visibility: visible;
      }
      
      .section-help {
        position: absolute;
        top: 10px;
        right: 10px;
        background: var(--vscode-textCodeBlock-background);
        color: var(--vscode-foreground);
        padding: 8px 12px;
        border-radius: 4px;
        font-size: 0.8em;
        opacity: 0;
        visibility: hidden;
        transition: all 0.2s ease;
        max-width: 200px;
        z-index: 10;
        border: 1px solid var(--vscode-panel-border);
      }
      
      .workflow-section.completed {
        border-color: #4CAF50;
        background: rgba(76, 175, 80, 0.05);
      }
      
      .workflow-section.available {
        border-color: var(--vscode-textLink-foreground);
        background: rgba(0, 122, 204, 0.05);
      }
      
      .workflow-section.disabled {
        opacity: 0.6;
        border-color: var(--vscode-descriptionForeground);
      }
      
      .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
      }
      
      .section-header h2 {
        color: var(--vscode-textLink-foreground);
        font-size: 1.5em;
      }
      
      .section-status {
        padding: 6px 12px;
        border-radius: 20px;
        background: var(--vscode-badge-background);
        color: var(--vscode-badge-foreground);
        font-size: 0.9em;
        font-weight: bold;
      }
      
      .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
        gap: 16px;
        margin-bottom: 20px;
      }
      
      .stat-card {
        background: var(--vscode-editor-background);
        padding: 16px;
        border-radius: 8px;
        text-align: center;
        border: 1px solid var(--vscode-panel-border);
      }
      
      .stat-number {
        font-size: 2em;
        font-weight: bold;
        color: var(--vscode-textLink-foreground);
        margin-bottom: 4px;
      }
      
      .stat-label {
        color: var(--vscode-descriptionForeground);
        font-size: 0.9em;
      }
      
      .stat-card.safe .stat-number { color: #4CAF50; }
      .stat-card.moderate .stat-number { color: #FF9800; }
      .stat-card.destructive .stat-number { color: #f44336; }
      .stat-card.success .stat-number { color: #4CAF50; }
      .stat-card.failure .stat-number { color: #f44336; }
      .stat-card.high-confidence .stat-number { color: #4CAF50; }
      .stat-card.medium-confidence .stat-number { color: #FF9800; }
      .stat-card.low-confidence .stat-number { color: #f44336; }
      
      .section-actions {
        margin-bottom: 16px;
      }
      
      .action-row {
        display: flex;
        gap: 12px;
        margin-bottom: 12px;
        flex-wrap: wrap;
      }
      
      .action-btn {
        padding: 12px 24px;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: 14px;
        font-weight: 600;
        transition: all 0.2s ease;
        flex: 1;
        min-width: 160px;
      }
      
      .action-btn.primary {
        background: var(--vscode-button-background);
        color: var(--vscode-button-foreground);
      }
      
      .action-btn.primary:hover {
        background: var(--vscode-button-hoverBackground);
      }
      
      .action-btn.secondary {
        background: var(--vscode-button-secondaryBackground);
        color: var(--vscode-button-secondaryForeground);
      }
      
      .action-btn.secondary:hover {
        background: var(--vscode-button-secondaryHoverBackground);
      }
      
      .action-btn:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }
      
      .action-btn:focus {
        outline: 2px solid var(--vscode-focusBorder);
        outline-offset: 2px;
      }
      
      .refresh-btn:focus {
        outline: 2px solid var(--vscode-focusBorder);
        outline-offset: 2px;
      }
      
      .last-activity {
        color: var(--vscode-descriptionForeground);
        font-size: 0.9em;
        margin-top: 8px;
        font-style: italic;
      }
      
      .guidance {
        background: rgba(0, 122, 204, 0.1);
        padding: 16px;
        border-radius: 6px;
        border-left: 4px solid var(--vscode-textLink-foreground);
        margin-top: 16px;
      }
      
      .guidance p {
        color: var(--vscode-descriptionForeground);
        margin: 0;
      }
      
      .guidance-section {
        background: var(--vscode-panel-background);
        padding: 24px;
        border-radius: 12px;
        margin-bottom: 30px;
        border: 1px solid var(--vscode-panel-border);
      }
      
      .guidance-section h3 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 20px;
        text-align: center;
      }
      
      .workflow-steps {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 20px;
      }
      
      .step {
        display: flex;
        align-items: flex-start;
        gap: 16px;
      }
      
      .step-number {
        background: var(--vscode-textLink-foreground);
        color: var(--vscode-editor-background);
        width: 32px;
        height: 32px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        flex-shrink: 0;
      }
      
      .step-content strong {
        color: var(--vscode-textLink-foreground);
        display: block;
        margin-bottom: 4px;
      }
      
      .step-content p {
        color: var(--vscode-descriptionForeground);
        font-size: 0.9em;
        margin: 0 0 4px 0;
      }
      
      .step-content small {
        color: var(--vscode-descriptionForeground);
        font-size: 0.8em;
        font-style: italic;
      }
      
      .keyboard-shortcuts {
        margin-top: 30px;
        padding-top: 20px;
        border-top: 1px solid var(--vscode-panel-border);
      }
      
      .keyboard-shortcuts h4 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 16px;
        text-align: center;
      }
      
      .shortcuts-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 12px;
      }
      
      .shortcut {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 12px;
        background: var(--vscode-editor-background);
        border-radius: 4px;
        border: 1px solid var(--vscode-panel-border);
      }
      
      .shortcut kbd {
        background: var(--vscode-textCodeBlock-background);
        color: var(--vscode-textPreformat-foreground);
        padding: 4px 8px;
        border-radius: 3px;
        font-family: monospace;
        font-size: 0.8em;
        border: 1px solid var(--vscode-panel-border);
      }
      
      .shortcut span {
        color: var(--vscode-foreground);
        font-size: 0.9em;
      }
      
      .dashboard-footer {
        background: var(--vscode-panel-background);
        padding: 24px;
        border-radius: 12px;
        border: 1px solid var(--vscode-panel-border);
      }
      
      .quick-actions h3 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 16px;
        text-align: center;
      }
      
      .action-buttons {
        display: flex;
        gap: 16px;
        justify-content: center;
        flex-wrap: wrap;
      }
      
      @media (max-width: 768px) {
        .dashboard {
          padding: 16px;
        }
        
        .stats-grid {
          grid-template-columns: repeat(2, 1fr);
        }
        
        .action-row {
          flex-direction: column;
        }
        
        .action-btn {
          min-width: auto;
        }
        
        .workflow-steps {
          grid-template-columns: 1fr;
        }
        
        .action-buttons {
          flex-direction: column;
        }
      }
    `;
    } /**
     *
   Gets JavaScript code for the dashboard.
     */
    getDashboardScript() {
        return `
      const vscode = acquireVsCodeApi();
      
      // Command handlers
      function discoverCommands() {
        vscode.postMessage({ command: 'discoverCommands' });
      }
      
      function researchParameters() {
        vscode.postMessage({ command: 'researchParameters' });
      }
      
      function editParameters() {
        vscode.postMessage({ command: 'editParameters' });
      }
      
      function testCommand() {
        vscode.postMessage({ command: 'testCommand' });
      }
      
      function generateDocs() {
        vscode.postMessage({ command: 'generateDocs' });
      }
      
      function viewResults() {
        vscode.postMessage({ command: 'viewResults' });
      }
      
      function openExplorer() {
        vscode.postMessage({ command: 'openExplorer' });
      }
      
      function validateParameters() {
        vscode.postMessage({ command: 'validateParameters' });
      }
      
      function executeCommand() {
        vscode.postMessage({ command: 'executeCommand' });
      }
      
      function refreshDashboard() {
        vscode.postMessage({ command: 'refresh' });
      }
      
      // Handle messages from extension
      window.addEventListener('message', event => {
        const message = event.data;
        
        switch (message.command) {
          case 'error':
            showError(message.message);
            break;
        }
      });
      
      function showError(message) {
        // Create error notification
        const errorDiv = document.createElement('div');
        errorDiv.className = 'error-notification';
        errorDiv.style.cssText = \`
          position: fixed;
          top: 20px;
          right: 20px;
          background: var(--vscode-inputValidation-errorBackground);
          color: var(--vscode-inputValidation-errorForeground);
          border: 1px solid var(--vscode-inputValidation-errorBorder);
          padding: 12px 16px;
          border-radius: 6px;
          z-index: 1000;
          max-width: 400px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        \`;
        errorDiv.textContent = \`Error: \${message}\`;
        
        document.body.appendChild(errorDiv);
        
        // Remove after 5 seconds
        setTimeout(() => {
          if (errorDiv.parentNode) {
            errorDiv.parentNode.removeChild(errorDiv);
          }
        }, 5000);
      }
      
      // Add keyboard shortcuts
      document.addEventListener('keydown', function(event) {
        if (event.ctrlKey || event.metaKey) {
          switch (event.key) {
            case '1':
              event.preventDefault();
              discoverCommands();
              break;
            case '2':
              event.preventDefault();
              researchParameters();
              break;
            case '3':
              event.preventDefault();
              testCommand();
              break;
            case '4':
              event.preventDefault();
              generateDocs();
              break;
            case 'r':
              event.preventDefault();
              refreshDashboard();
              break;
          }
        }
      });
    `;
    }
    /**
     * Disposes resources used by the dashboard.
     */
    dispose() {
        this.stopAutoRefresh();
        if (this.panel) {
            this.panel.dispose();
            this.panel = undefined;
        }
    }
}
exports.Dashboard = Dashboard;
//# sourceMappingURL=dashboard.js.map