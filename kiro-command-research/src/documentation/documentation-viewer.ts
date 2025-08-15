/**
 * API documentation viewer for browsing generated command documentation.
 * 
 * This module provides interactive UI components for viewing, searching,
 * and filtering command documentation within the VS Code environment.
 */

import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { CommandMetadata } from '../types/command-metadata';
import { TestResult } from '../testing/result-capture';
import { DocumentationExporter, ExportResult, DocumentationMetadata } from '../export/documentation-exporter';

/**
 * Documentation viewer configuration.
 */
export interface ViewerConfig {
  /** Base directory for documentation files */
  readonly documentationDirectory: string;
  
  /** Whether to auto-refresh when files change */
  readonly autoRefresh: boolean;
  
  /** Default view mode */
  readonly defaultView: 'overview' | 'commands' | 'api' | 'examples';
  
  /** Enable search functionality */
  readonly enableSearch: boolean;
  
  /** Enable filtering */
  readonly enableFiltering: boolean;
  
  /** Show test examples */
  readonly showExamples: boolean;
}

/**
 * Search and filter criteria.
 */
export interface ViewerFilters {
  /** Text search query */
  readonly searchQuery?: string;
  
  /** Filter by command category */
  readonly category?: string;
  
  /** Filter by subcategory */
  readonly subcategory?: string;
  
  /** Filter by risk level */
  readonly riskLevel?: string;
  
  /** Show only commands with signatures */
  readonly hasSignature?: boolean;
  
  /** Show only commands with test results */
  readonly hasTestResults?: boolean;
}

/**
 * Documentation view state.
 */
export interface ViewState {
  /** Current view mode */
  readonly currentView: string;
  
  /** Applied filters */
  readonly filters: ViewerFilters;
  
  /** Selected command ID */
  readonly selectedCommand?: string;
  
  /** Expanded sections */
  readonly expandedSections: Set<string>;
  
  /** Sort order */
  readonly sortBy: 'name' | 'category' | 'risk' | 'recent';
  
  /** Sort direction */
  readonly sortDirection: 'asc' | 'desc';
}

/**
 * Documentation content structure.
 */
export interface DocumentationContent {
  /** Documentation metadata */
  readonly metadata: DocumentationMetadata;
  
  /** Available commands */
  readonly commands: CommandMetadata[];
  
  /** Test results if available */
  readonly testResults: TestResult[];
  
  /** Generated documentation files */
  readonly files: Array<{
    name: string;
    path: string;
    type: 'markdown' | 'html' | 'json' | 'typescript';
    size: number;
  }>;
  
  /** Statistics */
  readonly statistics: {
    totalCommands: number;
    byCategory: Record<string, number>;
    bySubcategory: Record<string, number>;
    byRiskLevel: Record<string, number>;
  };
}

/**
 * Interactive documentation viewer for browsing generated command documentation.
 * 
 * The DocumentationViewer provides a comprehensive UI for exploring command
 * documentation, searching commands, and viewing test examples.
 */
export class DocumentationViewer {
  private readonly config: ViewerConfig;
  private readonly context: vscode.ExtensionContext;
  private readonly exporter: DocumentationExporter;
  
  private panel: vscode.WebviewPanel | undefined;
  private currentContent: DocumentationContent | undefined;
  private currentState: ViewState;
  private fileWatcher: vscode.FileSystemWatcher | undefined;
  
  constructor(context: vscode.ExtensionContext, config: Partial<ViewerConfig> = {}) {
    this.context = context;
    
    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath || '.';
    this.config = {
      documentationDirectory: path.join(workspaceRoot, '.kiro', 'command-research', 'exports'),
      autoRefresh: true,
      defaultView: 'overview',
      enableSearch: true,
      enableFiltering: true,
      showExamples: true,
      ...config
    };
    
    this.exporter = new DocumentationExporter({
      outputDirectory: this.config.documentationDirectory
    });
    
    this.currentState = {
      currentView: this.config.defaultView,
      filters: {},
      expandedSections: new Set(['overview']),
      sortBy: 'name',
      sortDirection: 'asc'
    };
  }
  
  /**
   * Opens the documentation viewer.
   * 
   * @param commands Optional commands to display
   * @param testResults Optional test results to include
   * @returns Promise that resolves when viewer is opened
   */
  public async openViewer(
    commands?: CommandMetadata[],
    testResults?: TestResult[]
  ): Promise<void> {
    console.log('DocumentationViewer: Opening documentation viewer');
    
    try {
      // Load or generate documentation content
      if (commands) {
        await this.generateDocumentation(commands, testResults || []);
      }
      
      await this.loadDocumentationContent();
      
      // Create webview panel
      this.panel = vscode.window.createWebviewPanel(
        'kiroDocumentationViewer',
        'Kiro Command Documentation',
        vscode.ViewColumn.One,
        {
          enableScripts: true,
          retainContextWhenHidden: true,
          localResourceRoots: [
            vscode.Uri.file(this.config.documentationDirectory),
            vscode.Uri.file(path.join(this.context.extensionPath, 'resources'))
          ]
        }
      );
      
      // Set up webview content
      await this.updateWebviewContent();
      
      // Set up message handling
      this.setupMessageHandling();
      
      // Set up file watching if enabled
      if (this.config.autoRefresh) {
        this.setupFileWatching();
      }
      
      // Handle panel disposal
      this.panel.onDidDispose(() => {
        this.dispose();
      });
      
      console.log('DocumentationViewer: Viewer opened successfully');
      
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('DocumentationViewer: Failed to open viewer:', errorMessage);
      
      vscode.window.showErrorMessage(`Failed to open documentation viewer: ${errorMessage}`);
    }
  }
  
  /**
   * Refreshes the documentation viewer content.
   * 
   * @returns Promise that resolves when content is refreshed
   */
  public async refresh(): Promise<void> {
    console.log('DocumentationViewer: Refreshing content');
    
    try {
      await this.loadDocumentationContent();
      await this.updateWebviewContent();
      
      console.log('DocumentationViewer: Content refreshed successfully');
      
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('DocumentationViewer: Failed to refresh content:', errorMessage);
      
      vscode.window.showErrorMessage(`Failed to refresh documentation: ${errorMessage}`);
    }
  }
  
  /**
   * Searches commands based on query.
   * 
   * @param query Search query
   * @returns Promise that resolves to search results
   */
  public async searchCommands(query: string): Promise<CommandMetadata[]> {
    if (!this.currentContent) {
      return [];
    }
    
    const lowerQuery = query.toLowerCase();
    return this.currentContent.commands.filter(command => 
      command.id.toLowerCase().includes(lowerQuery) ||
      command.displayName.toLowerCase().includes(lowerQuery) ||
      (command.description && command.description.toLowerCase().includes(lowerQuery)) ||
      command.subcategory.toLowerCase().includes(lowerQuery)
    );
  }
  
  /**
   * Applies filters to commands.
   * 
   * @param filters Filter criteria
   * @returns Promise that resolves to filtered commands
   */
  public async applyFilters(filters: ViewerFilters): Promise<CommandMetadata[]> {
    if (!this.currentContent) {
      return [];
    }
    
    let filteredCommands = [...this.currentContent.commands];
    
    if (filters.searchQuery) {
      filteredCommands = await this.searchCommands(filters.searchQuery);
    }
    
    if (filters.category) {
      filteredCommands = filteredCommands.filter(cmd => cmd.category === filters.category);
    }
    
    if (filters.subcategory) {
      filteredCommands = filteredCommands.filter(cmd => cmd.subcategory === filters.subcategory);
    }
    
    if (filters.riskLevel) {
      filteredCommands = filteredCommands.filter(cmd => cmd.riskLevel === filters.riskLevel);
    }
    
    if (filters.hasSignature) {
      filteredCommands = filteredCommands.filter(cmd => !!cmd.signature);
    }
    
    if (filters.hasTestResults) {
      const commandsWithResults = new Set(
        this.currentContent.testResults.map(result => result.commandId)
      );
      filteredCommands = filteredCommands.filter(cmd => commandsWithResults.has(cmd.id));
    }
    
    return filteredCommands;
  }
  
  /**
   * Generates documentation from commands and test results.
   * 
   * @param commands Commands to document
   * @param testResults Test results to include
   * @returns Promise that resolves when documentation is generated
   */
  private async generateDocumentation(
    commands: CommandMetadata[],
    testResults: TestResult[]
  ): Promise<void> {
    console.log('DocumentationViewer: Generating documentation');
    
    const exportResult = await this.exporter.exportDocumentation(commands, testResults);
    
    if (!exportResult.success) {
      throw new Error(`Documentation generation failed: ${exportResult.error}`);
    }
    
    console.log(`DocumentationViewer: Generated ${exportResult.files.length} documentation files`);
  }
  
  /**
   * Loads documentation content from files.
   * 
   * @returns Promise that resolves when content is loaded
   */
  private async loadDocumentationContent(): Promise<void> {
    console.log('DocumentationViewer: Loading documentation content');
    
    try {
      // Load commands data
      const commandsPath = path.join(this.config.documentationDirectory, 'commands.json');
      let commands: CommandMetadata[] = [];
      let testResults: TestResult[] = [];
      let metadata: DocumentationMetadata | undefined;
      
      if (fs.existsSync(commandsPath)) {
        const commandsData = JSON.parse(await fs.promises.readFile(commandsPath, 'utf8'));
        commands = commandsData.commands || [];
        testResults = commandsData.testResults || [];
        metadata = commandsData.metadata;
      }
      
      // Scan for generated files
      const files: DocumentationContent['files'] = [];
      
      if (fs.existsSync(this.config.documentationDirectory)) {
        const dirEntries = await fs.promises.readdir(this.config.documentationDirectory, { withFileTypes: true });
        
        for (const entry of dirEntries) {
          if (entry.isFile()) {
            const filePath = path.join(this.config.documentationDirectory, entry.name);
            const stats = await fs.promises.stat(filePath);
            
            let type: DocumentationContent['files'][0]['type'] = 'markdown';
            if (entry.name.endsWith('.html')) type = 'html';
            else if (entry.name.endsWith('.json')) type = 'json';
            else if (entry.name.endsWith('.ts') || entry.name.endsWith('.d.ts')) type = 'typescript';
            
            files.push({
              name: entry.name,
              path: filePath,
              type,
              size: stats.size
            });
          }
        }
      }
      
      // Calculate statistics
      const statistics = {
        totalCommands: commands.length,
        byCategory: commands.reduce((acc, cmd) => {
          acc[cmd.category] = (acc[cmd.category] || 0) + 1;
          return acc;
        }, {} as Record<string, number>),
        bySubcategory: commands.reduce((acc, cmd) => {
          acc[cmd.subcategory] = (acc[cmd.subcategory] || 0) + 1;
          return acc;
        }, {} as Record<string, number>),
        byRiskLevel: commands.reduce((acc, cmd) => {
          acc[cmd.riskLevel] = (acc[cmd.riskLevel] || 0) + 1;
          return acc;
        }, {} as Record<string, number>)
      };
      
      this.currentContent = {
        metadata: metadata || {
          version: '1.0.0',
          generatedAt: new Date(),
          commandCount: commands.length,
          testResultCount: testResults.length,
          generatorVersion: '1.0.0'
        },
        commands,
        testResults,
        files,
        statistics
      };
      
      console.log(`DocumentationViewer: Loaded ${commands.length} commands and ${files.length} files`);
      
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('DocumentationViewer: Failed to load content:', errorMessage);
      
      // Create empty content as fallback
      this.currentContent = {
        metadata: {
          version: '1.0.0',
          generatedAt: new Date(),
          commandCount: 0,
          testResultCount: 0,
          generatorVersion: '1.0.0'
        },
        commands: [],
        testResults: [],
        files: [],
        statistics: {
          totalCommands: 0,
          byCategory: {},
          bySubcategory: {},
          byRiskLevel: {}
        }
      };
    }
  }
  
  /**
   * Updates the webview content.
   * 
   * @returns Promise that resolves when content is updated
   */
  private async updateWebviewContent(): Promise<void> {
    if (!this.panel || !this.currentContent) {
      return;
    }
    
    const html = await this.generateWebviewHtml();
    this.panel.webview.html = html;
  }
  
  /**
   * Generates HTML content for the webview.
   * 
   * @returns Promise that resolves to HTML content
   */
  private async generateWebviewHtml(): Promise<string> {
    if (!this.currentContent) {
      return '<html><body><h1>No documentation available</h1></body></html>';
    }
    
    const { metadata, commands, statistics, files } = this.currentContent;
    
    // Apply current filters
    const filteredCommands = await this.applyFilters(this.currentState.filters);
    
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kiro Command Documentation</title>
    <style>${this.getWebviewStyles()}</style>
</head>
<body>
    <div class="container">
        <header class="header">
            <h1>Kiro Command Documentation</h1>
            <div class="header-info">
                <span>Version: ${metadata.version}</span>
                <span>Commands: ${metadata.commandCount}</span>
                <span>Generated: ${metadata.generatedAt.toLocaleDateString()}</span>
            </div>
        </header>
        
        <nav class="nav">
            <button class="nav-btn ${this.currentState.currentView === 'overview' ? 'active' : ''}" 
                    onclick="switchView('overview')">Overview</button>
            <button class="nav-btn ${this.currentState.currentView === 'commands' ? 'active' : ''}" 
                    onclick="switchView('commands')">Commands</button>
            <button class="nav-btn ${this.currentState.currentView === 'api' ? 'active' : ''}" 
                    onclick="switchView('api')">API</button>
            ${this.currentContent.testResults.length > 0 ? 
              `<button class="nav-btn ${this.currentState.currentView === 'examples' ? 'active' : ''}" 
                       onclick="switchView('examples')">Examples</button>` : ''}
            <button class="nav-btn" onclick="refreshContent()">Refresh</button>
        </nav>
        
        <div class="content">
            ${this.generateViewContent(filteredCommands)}
        </div>
    </div>
    
    <script>${this.getWebviewScript()}</script>
</body>
</html>`;
  }
  
  /**
   * Generates content for the current view.
   * 
   * @param filteredCommands Filtered commands to display
   * @returns HTML content
   */
  private generateViewContent(filteredCommands: CommandMetadata[]): string {
    if (!this.currentContent) {
      return '<p>No content available</p>';
    }
    
    switch (this.currentState.currentView) {
      case 'overview':
        return this.generateOverviewContent();
      case 'commands':
        return this.generateCommandsContent(filteredCommands);
      case 'api':
        return this.generateApiContent();
      case 'examples':
        return this.generateExamplesContent();
      default:
        return this.generateOverviewContent();
    }
  }
  
  /**
   * Generates overview content.
   * 
   * @returns HTML content
   */
  private generateOverviewContent(): string {
    if (!this.currentContent) {
      return '';
    }
    
    const { metadata, statistics, files } = this.currentContent;
    
    return `
      <div class="overview">
        <section class="stats-section">
          <h2>Statistics</h2>
          <div class="stats-grid">
            <div class="stat-card">
              <h3>Total Commands</h3>
              <div class="stat-number">${statistics.totalCommands}</div>
            </div>
            <div class="stat-card">
              <h3>kiroAgent Commands</h3>
              <div class="stat-number">${statistics.byCategory['kiroAgent'] || 0}</div>
            </div>
            <div class="stat-card">
              <h3>kiro Commands</h3>
              <div class="stat-number">${statistics.byCategory['kiro'] || 0}</div>
            </div>
          </div>
          
          <div class="stats-details">
            <div class="stat-group">
              <h4>By Risk Level</h4>
              ${Object.entries(statistics.byRiskLevel)
                .map(([risk, count]) => `<div class="stat-item">${risk}: ${count}</div>`)
                .join('')}
            </div>
            
            <div class="stat-group">
              <h4>By Subcategory</h4>
              ${Object.entries(statistics.bySubcategory)
                .map(([sub, count]) => `<div class="stat-item">${sub}: ${count}</div>`)
                .join('')}
            </div>
          </div>
        </section>
        
        <section class="files-section">
          <h2>Generated Files</h2>
          <div class="file-list">
            ${files.map(file => `
              <div class="file-item">
                <span class="file-name">${file.name}</span>
                <span class="file-type">${file.type}</span>
                <span class="file-size">${this.formatFileSize(file.size)}</span>
                <button onclick="openFile('${file.path}')">Open</button>
              </div>
            `).join('')}
          </div>
        </section>
        
        ${metadata.changeSummary ? `
          <section class="changes-section">
            <h2>Recent Changes</h2>
            <div class="changes-content">
              ${metadata.changeSummary.commandsAdded.length > 0 ? 
                `<div class="change-group">
                  <h4>Added Commands (${metadata.changeSummary.commandsAdded.length})</h4>
                  ${metadata.changeSummary.commandsAdded.map(id => `<div class="change-item">${id}</div>`).join('')}
                </div>` : ''}
              
              ${metadata.changeSummary.commandsModified.length > 0 ? 
                `<div class="change-group">
                  <h4>Modified Commands (${metadata.changeSummary.commandsModified.length})</h4>
                  ${metadata.changeSummary.commandsModified.map(mod => 
                    `<div class="change-item">${mod.commandId}: ${mod.changes.join(', ')}</div>`
                  ).join('')}
                </div>` : ''}
            </div>
          </section>
        ` : ''}
      </div>
    `;
  }
  
  /**
   * Generates commands content.
   * 
   * @param filteredCommands Filtered commands to display
   * @returns HTML content
   */
  private generateCommandsContent(filteredCommands: CommandMetadata[]): string {
    return `
      <div class="commands">
        <div class="commands-header">
          <div class="search-filters">
            <input type="text" id="searchInput" placeholder="Search commands..." 
                   value="${this.currentState.filters.searchQuery || ''}"
                   onkeyup="handleSearch(event)">
            
            <select id="categoryFilter" onchange="handleFilter('category', this.value)">
              <option value="">All Categories</option>
              <option value="kiroAgent" ${this.currentState.filters.category === 'kiroAgent' ? 'selected' : ''}>kiroAgent</option>
              <option value="kiro" ${this.currentState.filters.category === 'kiro' ? 'selected' : ''}>kiro</option>
            </select>
            
            <select id="riskFilter" onchange="handleFilter('riskLevel', this.value)">
              <option value="">All Risk Levels</option>
              <option value="safe" ${this.currentState.filters.riskLevel === 'safe' ? 'selected' : ''}>Safe</option>
              <option value="moderate" ${this.currentState.filters.riskLevel === 'moderate' ? 'selected' : ''}>Moderate</option>
              <option value="destructive" ${this.currentState.filters.riskLevel === 'destructive' ? 'selected' : ''}>Destructive</option>
            </select>
            
            <button onclick="clearFilters()">Clear Filters</button>
          </div>
          
          <div class="sort-controls">
            <select id="sortBy" onchange="handleSort(this.value, document.getElementById('sortDirection').value)">
              <option value="name" ${this.currentState.sortBy === 'name' ? 'selected' : ''}>Name</option>
              <option value="category" ${this.currentState.sortBy === 'category' ? 'selected' : ''}>Category</option>
              <option value="risk" ${this.currentState.sortBy === 'risk' ? 'selected' : ''}>Risk Level</option>
            </select>
            
            <select id="sortDirection" onchange="handleSort(document.getElementById('sortBy').value, this.value)">
              <option value="asc" ${this.currentState.sortDirection === 'asc' ? 'selected' : ''}>Ascending</option>
              <option value="desc" ${this.currentState.sortDirection === 'desc' ? 'selected' : ''}>Descending</option>
            </select>
          </div>
        </div>
        
        <div class="commands-list">
          ${this.sortCommands(filteredCommands).map(command => `
            <div class="command-card ${command.riskLevel}" onclick="selectCommand('${command.id}')">
              <div class="command-header">
                <h3>${command.displayName}</h3>
                <span class="command-id">${command.id}</span>
              </div>
              
              <div class="command-meta">
                <span class="category">${command.category} > ${command.subcategory}</span>
                <span class="risk-level risk-${command.riskLevel}">${command.riskLevel}</span>
              </div>
              
              ${command.description ? `<p class="description">${command.description}</p>` : ''}
              
              ${command.contextRequirements.length > 0 ? 
                `<div class="context-requirements">
                  <strong>Context:</strong> ${command.contextRequirements.join(', ')}
                </div>` : ''}
              
              ${command.signature ? `
                <div class="signature-info">
                  <strong>Parameters:</strong> ${command.signature.parameters.length}
                  <strong>Async:</strong> ${command.signature.async ? 'Yes' : 'No'}
                  <strong>Confidence:</strong> ${command.signature.confidence}
                </div>
              ` : ''}
            </div>
          `).join('')}
        </div>
        
        ${filteredCommands.length === 0 ? '<p class="no-results">No commands match the current filters.</p>' : ''}
      </div>
    `;
  }
  
  /**
   * Generates API content.
   * 
   * @returns HTML content
   */
  private generateApiContent(): string {
    return `
      <div class="api">
        <section class="api-overview">
          <h2>WebSocket API</h2>
          <p>This API enables remote execution of Kiro commands via WebSocket connection.</p>
          
          <div class="api-endpoint">
            <h3>Connection</h3>
            <code>ws://localhost:8080/ws</code>
          </div>
        </section>
        
        <section class="api-messages">
          <h3>Message Format</h3>
          <pre class="code-block">{
  "type": "execute" | "result" | "error" | "ping" | "pong",
  "id": "unique-message-id",
  "timestamp": "2025-01-10T14:30:00Z",
  "payload": { ... }
}</pre>
        </section>
        
        <section class="api-examples">
          <h3>Execution Request</h3>
          <pre class="code-block">{
  "type": "execute",
  "id": "req-123",
  "timestamp": "2025-01-10T14:30:00Z",
  "payload": {
    "commandId": "kiroAgent.agent.chatAgent",
    "parameters": {
      "message": "Hello, Kiro!"
    },
    "timeoutMs": 30000,
    "createSnapshot": false,
    "requireConfirmation": false
  }
}</pre>
          
          <h3>Execution Response</h3>
          <pre class="code-block">{
  "type": "result",
  "id": "req-123",
  "timestamp": "2025-01-10T14:30:05Z",
  "payload": {
    "success": true,
    "commandId": "kiroAgent.agent.chatAgent",
    "duration": 1250,
    "result": { ... },
    "sideEffects": []
  }
}</pre>
        </section>
      </div>
    `;
  }
  
  /**
   * Generates examples content.
   * 
   * @returns HTML content
   */
  private generateExamplesContent(): string {
    if (!this.currentContent || this.currentContent.testResults.length === 0) {
      return '<p>No test examples available.</p>';
    }
    
    const successfulResults = this.currentContent.testResults
      .filter(result => result.executionResult.success)
      .slice(0, 10); // Limit to 10 examples
    
    return `
      <div class="examples">
        <h2>Usage Examples</h2>
        <p>Real usage examples based on test results.</p>
        
        ${successfulResults.map(result => `
          <div class="example-card">
            <h3>${result.commandMetadata.displayName}</h3>
            <div class="example-meta">
              <span class="command-id">${result.commandId}</span>
              <span class="duration">${result.executionResult.duration}ms</span>
              <span class="timestamp">${result.timestamp.toLocaleDateString()}</span>
            </div>
            
            ${Object.keys(result.parameters).length > 0 ? `
              <div class="example-section">
                <h4>Parameters</h4>
                <pre class="code-block">${JSON.stringify(result.parameters, null, 2)}</pre>
              </div>
            ` : ''}
            
            ${result.executionResult.result ? `
              <div class="example-section">
                <h4>Result</h4>
                <pre class="code-block">${JSON.stringify(result.executionResult.result, null, 2)}</pre>
              </div>
            ` : ''}
            
            ${result.notes ? `
              <div class="example-section">
                <h4>Notes</h4>
                <p>${result.notes}</p>
              </div>
            ` : ''}
            
            ${result.executionResult.sideEffects.length > 0 ? `
              <div class="example-section">
                <h4>Side Effects</h4>
                <ul>
                  ${result.executionResult.sideEffects.map(effect => 
                    `<li>${effect.type}: ${effect.description}</li>`
                  ).join('')}
                </ul>
              </div>
            ` : ''}
          </div>
        `).join('')}
      </div>
    `;
  }
  
  /**
   * Sorts commands based on current sort criteria.
   * 
   * @param commands Commands to sort
   * @returns Sorted commands
   */
  private sortCommands(commands: CommandMetadata[]): CommandMetadata[] {
    const { sortBy, sortDirection } = this.currentState;
    
    return [...commands].sort((a, b) => {
      let comparison = 0;
      
      switch (sortBy) {
        case 'name':
          comparison = a.displayName.localeCompare(b.displayName);
          break;
        case 'category':
          comparison = a.category.localeCompare(b.category) || 
                      a.subcategory.localeCompare(b.subcategory);
          break;
        case 'risk':
          const riskOrder = ['safe', 'moderate', 'destructive'];
          comparison = riskOrder.indexOf(a.riskLevel) - riskOrder.indexOf(b.riskLevel);
          break;
      }
      
      return sortDirection === 'asc' ? comparison : -comparison;
    });
  }
  
  /**
   * Formats file size for display.
   * 
   * @param bytes File size in bytes
   * @returns Formatted size string
   */
  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }
  
  /**
   * Gets CSS styles for the webview.
   * 
   * @returns CSS content
   */
  private getWebviewStyles(): string {
    return `
      * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
      }
      
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        line-height: 1.6;
        color: var(--vscode-foreground);
        background-color: var(--vscode-editor-background);
      }
      
      .container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 1rem;
      }
      
      .header {
        text-align: center;
        margin-bottom: 2rem;
        padding: 1rem;
        border-bottom: 1px solid var(--vscode-panel-border);
      }
      
      .header h1 {
        color: var(--vscode-textLink-foreground);
        margin-bottom: 0.5rem;
      }
      
      .header-info {
        display: flex;
        justify-content: center;
        gap: 2rem;
        font-size: 0.9rem;
        color: var(--vscode-descriptionForeground);
      }
      
      .nav {
        display: flex;
        gap: 0.5rem;
        margin-bottom: 2rem;
        padding: 0.5rem;
        background-color: var(--vscode-panel-background);
        border-radius: 4px;
      }
      
      .nav-btn {
        padding: 0.5rem 1rem;
        border: none;
        background-color: transparent;
        color: var(--vscode-foreground);
        cursor: pointer;
        border-radius: 4px;
        transition: background-color 0.2s;
      }
      
      .nav-btn:hover {
        background-color: var(--vscode-list-hoverBackground);
      }
      
      .nav-btn.active {
        background-color: var(--vscode-button-background);
        color: var(--vscode-button-foreground);
      }
      
      .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1rem;
        margin: 1rem 0;
      }
      
      .stat-card {
        padding: 1rem;
        background-color: var(--vscode-panel-background);
        border-radius: 4px;
        text-align: center;
      }
      
      .stat-number {
        font-size: 2rem;
        font-weight: bold;
        color: var(--vscode-textLink-foreground);
      }
      
      .stats-details {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 2rem;
        margin-top: 2rem;
      }
      
      .stat-group h4 {
        margin-bottom: 0.5rem;
        color: var(--vscode-textLink-foreground);
      }
      
      .stat-item {
        padding: 0.25rem 0;
        border-bottom: 1px solid var(--vscode-panel-border);
      }
      
      .file-list {
        display: grid;
        gap: 0.5rem;
      }
      
      .file-item {
        display: grid;
        grid-template-columns: 1fr auto auto auto;
        gap: 1rem;
        align-items: center;
        padding: 0.5rem;
        background-color: var(--vscode-panel-background);
        border-radius: 4px;
      }
      
      .file-name {
        font-family: monospace;
      }
      
      .file-type {
        font-size: 0.8rem;
        color: var(--vscode-descriptionForeground);
        text-transform: uppercase;
      }
      
      .file-size {
        font-size: 0.8rem;
        color: var(--vscode-descriptionForeground);
      }
      
      .commands-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1rem;
        gap: 1rem;
        flex-wrap: wrap;
      }
      
      .search-filters {
        display: flex;
        gap: 0.5rem;
        align-items: center;
        flex-wrap: wrap;
      }
      
      .search-filters input,
      .search-filters select {
        padding: 0.5rem;
        border: 1px solid var(--vscode-input-border);
        background-color: var(--vscode-input-background);
        color: var(--vscode-input-foreground);
        border-radius: 4px;
      }
      
      .sort-controls {
        display: flex;
        gap: 0.5rem;
        align-items: center;
      }
      
      .commands-list {
        display: grid;
        gap: 1rem;
      }
      
      .command-card {
        padding: 1rem;
        background-color: var(--vscode-panel-background);
        border-radius: 4px;
        border-left: 4px solid var(--vscode-panel-border);
        cursor: pointer;
        transition: background-color 0.2s;
      }
      
      .command-card:hover {
        background-color: var(--vscode-list-hoverBackground);
      }
      
      .command-card.safe {
        border-left-color: #4CAF50;
      }
      
      .command-card.moderate {
        border-left-color: #FF9800;
      }
      
      .command-card.destructive {
        border-left-color: #f44336;
      }
      
      .command-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 0.5rem;
      }
      
      .command-header h3 {
        margin: 0;
        color: var(--vscode-textLink-foreground);
      }
      
      .command-id {
        font-family: monospace;
        font-size: 0.8rem;
        color: var(--vscode-descriptionForeground);
        background-color: var(--vscode-textCodeBlock-background);
        padding: 0.25rem 0.5rem;
        border-radius: 4px;
      }
      
      .command-meta {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.5rem;
        font-size: 0.9rem;
      }
      
      .category {
        color: var(--vscode-descriptionForeground);
      }
      
      .risk-level {
        font-weight: bold;
        padding: 0.25rem 0.5rem;
        border-radius: 4px;
        font-size: 0.8rem;
      }
      
      .risk-safe {
        background-color: #4CAF50;
        color: white;
      }
      
      .risk-moderate {
        background-color: #FF9800;
        color: white;
      }
      
      .risk-destructive {
        background-color: #f44336;
        color: white;
      }
      
      .description {
        color: var(--vscode-descriptionForeground);
        font-style: italic;
        margin: 0.5rem 0;
      }
      
      .context-requirements,
      .signature-info {
        font-size: 0.8rem;
        color: var(--vscode-descriptionForeground);
        margin-top: 0.5rem;
      }
      
      .signature-info {
        display: flex;
        gap: 1rem;
      }
      
      .code-block {
        background-color: var(--vscode-textCodeBlock-background);
        padding: 1rem;
        border-radius: 4px;
        overflow-x: auto;
        font-family: monospace;
        font-size: 0.9rem;
        margin: 0.5rem 0;
      }
      
      .example-card {
        background-color: var(--vscode-panel-background);
        padding: 1rem;
        border-radius: 4px;
        margin-bottom: 1rem;
      }
      
      .example-meta {
        display: flex;
        gap: 1rem;
        margin-bottom: 1rem;
        font-size: 0.9rem;
        color: var(--vscode-descriptionForeground);
      }
      
      .example-section {
        margin: 1rem 0;
      }
      
      .example-section h4 {
        margin-bottom: 0.5rem;
        color: var(--vscode-textLink-foreground);
      }
      
      .no-results {
        text-align: center;
        color: var(--vscode-descriptionForeground);
        font-style: italic;
        padding: 2rem;
      }
      
      button {
        padding: 0.5rem 1rem;
        border: none;
        background-color: var(--vscode-button-background);
        color: var(--vscode-button-foreground);
        border-radius: 4px;
        cursor: pointer;
        transition: background-color 0.2s;
      }
      
      button:hover {
        background-color: var(--vscode-button-hoverBackground);
      }
    `;
  }
  
  /**
   * Gets JavaScript code for the webview.
   * 
   * @returns JavaScript content
   */
  private getWebviewScript(): string {
    return `
      const vscode = acquireVsCodeApi();
      
      function switchView(view) {
        vscode.postMessage({
          command: 'switchView',
          view: view
        });
      }
      
      function refreshContent() {
        vscode.postMessage({
          command: 'refresh'
        });
      }
      
      function handleSearch(event) {
        if (event.key === 'Enter' || event.type === 'input') {
          vscode.postMessage({
            command: 'search',
            query: event.target.value
          });
        }
      }
      
      function handleFilter(type, value) {
        vscode.postMessage({
          command: 'filter',
          filterType: type,
          filterValue: value
        });
      }
      
      function handleSort(sortBy, sortDirection) {
        vscode.postMessage({
          command: 'sort',
          sortBy: sortBy,
          sortDirection: sortDirection
        });
      }
      
      function clearFilters() {
        vscode.postMessage({
          command: 'clearFilters'
        });
      }
      
      function selectCommand(commandId) {
        vscode.postMessage({
          command: 'selectCommand',
          commandId: commandId
        });
      }
      
      function openFile(filePath) {
        vscode.postMessage({
          command: 'openFile',
          filePath: filePath
        });
      }
      
      // Auto-search as user types
      document.addEventListener('DOMContentLoaded', function() {
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
          let searchTimeout;
          searchInput.addEventListener('input', function(event) {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(() => {
              handleSearch(event);
            }, 300);
          });
        }
      });
    `;
  }
  
  /**
   * Sets up message handling for webview communication.
   */
  private setupMessageHandling(): void {
    if (!this.panel) {
      return;
    }
    
    this.panel.webview.onDidReceiveMessage(async (message) => {
      try {
        switch (message.command) {
          case 'switchView':
            this.currentState = {
              ...this.currentState,
              currentView: message.view
            };
            await this.updateWebviewContent();
            break;
            
          case 'refresh':
            await this.refresh();
            break;
            
          case 'search':
            this.currentState = {
              ...this.currentState,
              filters: {
                ...this.currentState.filters,
                searchQuery: message.query
              }
            };
            await this.updateWebviewContent();
            break;
            
          case 'filter':
            this.currentState = {
              ...this.currentState,
              filters: {
                ...this.currentState.filters,
                [message.filterType]: message.filterValue || undefined
              }
            };
            await this.updateWebviewContent();
            break;
            
          case 'sort':
            this.currentState = {
              ...this.currentState,
              sortBy: message.sortBy,
              sortDirection: message.sortDirection
            };
            await this.updateWebviewContent();
            break;
            
          case 'clearFilters':
            this.currentState = {
              ...this.currentState,
              filters: {}
            };
            await this.updateWebviewContent();
            break;
            
          case 'selectCommand':
            this.currentState = {
              ...this.currentState,
              selectedCommand: message.commandId
            };
            // Could show command details in a separate panel
            break;
            
          case 'openFile':
            const uri = vscode.Uri.file(message.filePath);
            await vscode.window.showTextDocument(uri);
            break;
        }
      } catch (error: unknown) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        console.error('DocumentationViewer: Message handling error:', errorMessage);
      }
    });
  }
  
  /**
   * Sets up file watching for auto-refresh.
   */
  private setupFileWatching(): void {
    if (this.fileWatcher) {
      this.fileWatcher.dispose();
    }
    
    const pattern = path.join(this.config.documentationDirectory, '**/*');
    this.fileWatcher = vscode.workspace.createFileSystemWatcher(pattern);
    
    const refreshHandler = () => {
      // Debounce refresh calls
      setTimeout(() => {
        this.refresh();
      }, 1000);
    };
    
    this.fileWatcher.onDidCreate(refreshHandler);
    this.fileWatcher.onDidChange(refreshHandler);
    this.fileWatcher.onDidDelete(refreshHandler);
  }
  
  /**
   * Disposes resources used by the viewer.
   */
  public dispose(): void {
    if (this.fileWatcher) {
      this.fileWatcher.dispose();
      this.fileWatcher = undefined;
    }
    
    if (this.panel) {
      this.panel.dispose();
      this.panel = undefined;
    }
    
    this.currentContent = undefined;
  }
}