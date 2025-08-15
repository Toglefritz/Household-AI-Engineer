"use strict";
/**
 * Command explorer tree view for browsing discovered Kiro commands.
 *
 * This module provides an interactive tree view interface for exploring
 * discovered commands with search, filtering, and detailed command information.
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
exports.CommandExplorer = exports.CommandExplorerProvider = exports.CommandTreeItem = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Tree item representing a command or group.
 */
class CommandTreeItem extends vscode.TreeItem {
    constructor(label, collapsibleState, commandMetadata, itemType = 'command') {
        super(label, collapsibleState);
        this.label = label;
        this.collapsibleState = collapsibleState;
        this.commandMetadata = commandMetadata;
        this.itemType = itemType;
        if (commandMetadata) {
            this.setupCommandItem(commandMetadata);
        }
        else {
            this.setupGroupItem();
        }
    }
    /**
     * Sets up tree item for a command.
     *
     * @param command Command metadata
     */
    setupCommandItem(command) {
        this.tooltip = this.createCommandTooltip(command);
        this.description = command.id;
        this.contextValue = `command-${command.riskLevel}`;
        // Set icon based on risk level
        switch (command.riskLevel) {
            case 'safe':
                this.iconPath = new vscode.ThemeIcon('check', new vscode.ThemeColor('charts.green'));
                break;
            case 'moderate':
                this.iconPath = new vscode.ThemeIcon('warning', new vscode.ThemeColor('charts.yellow'));
                break;
            case 'destructive':
                this.iconPath = new vscode.ThemeIcon('error', new vscode.ThemeColor('charts.red'));
                break;
        }
        // Set command to show details when clicked
        this.command = {
            command: 'kiroCommandResearch.showCommandDetails',
            title: 'Show Command Details',
            arguments: [command]
        };
    }
    /**
     * Sets up tree item for a group.
     */
    setupGroupItem() {
        this.contextValue = 'group';
        this.iconPath = new vscode.ThemeIcon('folder');
    }
    /**
     * Creates tooltip for command item.
     *
     * @param command Command metadata
     * @returns Tooltip text
     */
    createCommandTooltip(command) {
        let tooltip = `${command.displayName}\n`;
        tooltip += `ID: ${command.id}\n`;
        tooltip += `Category: ${command.category} > ${command.subcategory}\n`;
        tooltip += `Risk Level: ${command.riskLevel}\n`;
        if (command.description) {
            tooltip += `Description: ${command.description}\n`;
        }
        if (command.contextRequirements.length > 0) {
            tooltip += `Context: ${command.contextRequirements.join(', ')}\n`;
        }
        if (command.signature) {
            tooltip += `Parameters: ${command.signature.parameters.length}\n`;
            tooltip += `Async: ${command.signature.async ? 'Yes' : 'No'}\n`;
            tooltip += `Confidence: ${command.signature.confidence}\n`;
        }
        return tooltip;
    }
}
exports.CommandTreeItem = CommandTreeItem;
/**
 * Data provider for the command explorer tree view.
 */
class CommandExplorerProvider {
    constructor(config, storageManager) {
        this.config = config;
        this.storageManager = storageManager;
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
        this.commands = [];
        this.testResults = [];
        this.filteredCommands = [];
        this.groupingMode = 'category';
        this.searchQuery = '';
        this.groupingMode = config.defaultGrouping;
    }
    /**
     * Gets tree item for element.
     *
     * @param element Tree item element
     * @returns Tree item
     */
    getTreeItem(element) {
        return element;
    }
    /**
     * Gets children for tree element.
     *
     * @param element Parent element
     * @returns Promise that resolves to child elements
     */
    async getChildren(element) {
        if (!element) {
            // Root level - return grouped commands
            return this.getGroupedCommands();
        }
        if (element.itemType === 'group') {
            // Group level - return commands in group
            return this.getCommandsInGroup(element.label);
        }
        // Command level - no children
        return [];
    }
    /**
     * Refreshes the tree view with new data.
     *
     * @param commands Updated commands
     * @param testResults Updated test results
     */
    async refresh(commands, testResults) {
        if (commands) {
            this.commands = commands;
            this.filteredCommands = this.applyFilters(commands);
        }
        if (testResults) {
            this.testResults = testResults;
        }
        this._onDidChangeTreeData.fire();
    }
    /**
     * Sets search query and refreshes tree.
     *
     * @param query Search query
     */
    setSearchQuery(query) {
        this.searchQuery = query;
        this.filteredCommands = this.applyFilters(this.commands);
        this._onDidChangeTreeData.fire();
    }
    /**
     * Sets grouping mode and refreshes tree.
     *
     * @param mode Grouping mode
     */
    setGroupingMode(mode) {
        this.groupingMode = mode;
        this._onDidChangeTreeData.fire();
    }
    /**
     * Gets commands grouped by current grouping mode.
     *
     * @returns Promise that resolves to grouped tree items
     */
    async getGroupedCommands() {
        if (this.filteredCommands.length === 0) {
            return [];
        }
        const groups = new Map();
        // Group commands based on current mode
        for (const command of this.filteredCommands) {
            let groupKey;
            switch (this.groupingMode) {
                case 'category':
                    groupKey = command.category;
                    break;
                case 'subcategory':
                    groupKey = `${command.category} > ${command.subcategory}`;
                    break;
                case 'risk':
                    groupKey = command.riskLevel;
                    break;
                case 'alphabetical':
                    groupKey = command.displayName.charAt(0).toUpperCase();
                    break;
                default:
                    groupKey = command.category;
            }
            if (!groups.has(groupKey)) {
                groups.set(groupKey, []);
            }
            groups.get(groupKey).push(command);
        }
        // Create tree items for groups
        const groupItems = [];
        for (const [groupName, groupCommands] of groups) {
            const groupLabel = `${groupName} (${groupCommands.length})`;
            const groupItem = new CommandTreeItem(groupLabel, vscode.TreeItemCollapsibleState.Expanded, undefined, 'group');
            groupItems.push(groupItem);
        }
        // Sort groups alphabetically
        groupItems.sort((a, b) => a.label.localeCompare(b.label));
        return groupItems;
    }
    /**
     * Gets commands in a specific group.
     *
     * @param groupLabel Group label
     * @returns Array of command tree items
     */
    getCommandsInGroup(groupLabel) {
        // Extract group name from label (remove count)
        const groupName = groupLabel.replace(/ \(\d+\)$/, '');
        const groupCommands = this.filteredCommands.filter(command => {
            switch (this.groupingMode) {
                case 'category':
                    return command.category === groupName;
                case 'subcategory':
                    return `${command.category} > ${command.subcategory}` === groupName;
                case 'risk':
                    return command.riskLevel === groupName;
                case 'alphabetical':
                    return command.displayName.charAt(0).toUpperCase() === groupName;
                default:
                    return command.category === groupName;
            }
        });
        // Sort commands within group
        groupCommands.sort((a, b) => a.displayName.localeCompare(b.displayName));
        // Create tree items for commands
        return groupCommands.map(command => {
            let label = command.displayName;
            // Add additional info based on config
            if (this.config.showRiskLevels) {
                const riskIcon = this.getRiskIcon(command.riskLevel);
                label = `${riskIcon} ${label}`;
            }
            if (this.config.showTestResults) {
                const hasTestResults = this.testResults.some(result => result.commandId === command.id);
                if (hasTestResults) {
                    label = `${label} ✓`;
                }
            }
            return new CommandTreeItem(label, vscode.TreeItemCollapsibleState.None, command, 'command');
        });
    }
    /**
     * Applies search and other filters to commands.
     *
     * @param commands Commands to filter
     * @returns Filtered commands
     */
    applyFilters(commands) {
        let filtered = [...commands];
        // Apply search query
        if (this.searchQuery.trim()) {
            const query = this.searchQuery.toLowerCase();
            filtered = filtered.filter(command => command.id.toLowerCase().includes(query) ||
                command.displayName.toLowerCase().includes(query) ||
                (command.description && command.description.toLowerCase().includes(query)) ||
                command.subcategory.toLowerCase().includes(query));
        }
        return filtered;
    }
    /**
     * Gets risk level icon.
     *
     * @param riskLevel Risk level
     * @returns Icon string
     */
    getRiskIcon(riskLevel) {
        switch (riskLevel) {
            case 'safe':
                return '🟢';
            case 'moderate':
                return '🟡';
            case 'destructive':
                return '🔴';
            default:
                return '⚪';
        }
    }
}
exports.CommandExplorerProvider = CommandExplorerProvider;
/**
 * Command explorer tree view manager.
 *
 * The CommandExplorer provides an interactive tree view for browsing
 * discovered Kiro commands with search, filtering, and grouping capabilities.
 */
class CommandExplorer {
    constructor(context, storageManager, config = {}) {
        this.context = context;
        this.storageManager = storageManager;
        this.disposables = [];
        const fullConfig = {
            showSignatures: true,
            showRiskLevels: true,
            showTestResults: true,
            defaultGrouping: 'category',
            autoRefresh: true,
            ...config
        };
        this.provider = new CommandExplorerProvider(fullConfig, storageManager);
        this.treeView = vscode.window.createTreeView('kiroCommandExplorer', {
            treeDataProvider: this.provider,
            showCollapseAll: true,
            canSelectMany: false
        });
        this.setupCommands();
        this.setupEventHandlers();
        // Initial load
        this.loadCommands();
    }
    /**
     * Sets up VS Code commands for the explorer.
     */
    setupCommands() {
        // Refresh command
        const refreshCommand = vscode.commands.registerCommand('kiroCommandResearch.refreshExplorer', () => this.refresh());
        this.disposables.push(refreshCommand);
        // Search command
        const searchCommand = vscode.commands.registerCommand('kiroCommandResearch.searchCommands', () => this.showSearchInput());
        this.disposables.push(searchCommand);
        // Change grouping command
        const groupingCommand = vscode.commands.registerCommand('kiroCommandResearch.changeGrouping', () => this.showGroupingOptions());
        this.disposables.push(groupingCommand);
        // Show command details command
        const detailsCommand = vscode.commands.registerCommand('kiroCommandResearch.showCommandDetails', (command) => this.showCommandDetails(command));
        this.disposables.push(detailsCommand);
        // Test command
        const testCommand = vscode.commands.registerCommand('kiroCommandResearch.testCommandFromExplorer', (item) => {
            if (item.command) {
                vscode.commands.executeCommand('kiroCommandResearch.testCommand', item.command);
            }
        });
        this.disposables.push(testCommand);
    }
    /**
     * Sets up event handlers.
     */
    setupEventHandlers() {
        // Handle tree view selection
        this.treeView.onDidChangeSelection(event => {
            if (event.selection.length > 0) {
                const item = event.selection[0];
                if (item.commandMetadata) {
                    this.showCommandDetails(item.commandMetadata);
                }
            }
        });
        this.disposables.push(this.treeView);
    }
    /**
     * Loads commands from storage.
     */
    async loadCommands() {
        try {
            const discoveryResults = await this.storageManager.loadDiscoveryResults();
            const testResults = []; // TODO: Implement loadTestResults in FileStorageManager
            await this.provider.refresh(discoveryResults?.commands || [], testResults || []);
            // Update tree view title with count
            const commandCount = discoveryResults?.commands?.length || 0;
            this.treeView.title = `Kiro Commands (${commandCount})`;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('CommandExplorer: Failed to load commands:', errorMessage);
            vscode.window.showErrorMessage(`Failed to load commands: ${errorMessage}`);
        }
    }
    /**
     * Refreshes the explorer.
     */
    async refresh() {
        await this.loadCommands();
        vscode.window.showInformationMessage('Command explorer refreshed');
    }
    /**
     * Shows search input dialog.
     */
    async showSearchInput() {
        const query = await vscode.window.showInputBox({
            prompt: 'Search commands by name, ID, or description',
            placeHolder: 'Enter search query...'
        });
        if (query !== undefined) {
            this.provider.setSearchQuery(query);
            if (query.trim()) {
                vscode.window.showInformationMessage(`Searching for: ${query}`);
            }
            else {
                vscode.window.showInformationMessage('Search cleared');
            }
        }
    }
    /**
     * Shows grouping options.
     */
    async showGroupingOptions() {
        const options = [
            { label: 'Category', value: 'category' },
            { label: 'Subcategory', value: 'subcategory' },
            { label: 'Risk Level', value: 'risk' },
            { label: 'Alphabetical', value: 'alphabetical' }
        ];
        const selected = await vscode.window.showQuickPick(options, {
            placeHolder: 'Select grouping mode'
        });
        if (selected) {
            this.provider.setGroupingMode(selected.value);
            vscode.window.showInformationMessage(`Grouped by: ${selected.label}`);
        }
    }
    /**
     * Shows detailed information for a command.
     *
     * @param command Command to show details for
     */
    async showCommandDetails(command) {
        const panel = vscode.window.createWebviewPanel('commandDetails', `Command: ${command.displayName}`, vscode.ViewColumn.Two, {
            enableScripts: true,
            retainContextWhenHidden: true
        });
        panel.webview.html = this.generateCommandDetailsHtml(command);
        // Handle messages from webview
        panel.webview.onDidReceiveMessage(async (message) => {
            switch (message.command) {
                case 'testCommand':
                    await vscode.commands.executeCommand('kiroCommandResearch.testCommand', command);
                    break;
                case 'copyCommandId':
                    await vscode.env.clipboard.writeText(command.id);
                    vscode.window.showInformationMessage('Command ID copied to clipboard');
                    break;
            }
        });
    }
    /**
     * Generates HTML for command details webview.
     *
     * @param command Command to generate details for
     * @returns HTML content
     */
    generateCommandDetailsHtml(command) {
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Command Details</title>
    <style>
        body {
            font-family: var(--vscode-font-family);
            color: var(--vscode-foreground);
            background-color: var(--vscode-editor-background);
            padding: 20px;
            line-height: 1.6;
        }
        
        .header {
            border-bottom: 1px solid var(--vscode-panel-border);
            padding-bottom: 20px;
            margin-bottom: 20px;
        }
        
        .command-title {
            font-size: 24px;
            font-weight: bold;
            color: var(--vscode-textLink-foreground);
            margin-bottom: 10px;
        }
        
        .command-id {
            font-family: monospace;
            background-color: var(--vscode-textCodeBlock-background);
            padding: 8px 12px;
            border-radius: 4px;
            font-size: 14px;
            margin-bottom: 10px;
            display: inline-block;
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
        
        .section {
            margin-bottom: 30px;
        }
        
        .section-title {
            font-size: 18px;
            font-weight: bold;
            color: var(--vscode-textLink-foreground);
            margin-bottom: 10px;
        }
        
        .meta-grid {
            display: grid;
            grid-template-columns: auto 1fr;
            gap: 10px 20px;
            margin-bottom: 20px;
        }
        
        .meta-label {
            font-weight: bold;
            color: var(--vscode-descriptionForeground);
        }
        
        .parameter-list {
            list-style: none;
            padding: 0;
        }
        
        .parameter-item {
            background-color: var(--vscode-panel-background);
            padding: 10px;
            margin-bottom: 8px;
            border-radius: 4px;
            border-left: 3px solid var(--vscode-textLink-foreground);
        }
        
        .parameter-name {
            font-family: monospace;
            font-weight: bold;
            color: var(--vscode-textLink-foreground);
        }
        
        .parameter-type {
            color: var(--vscode-descriptionForeground);
            font-style: italic;
        }
        
        .required {
            color: var(--vscode-errorForeground);
            font-weight: bold;
        }
        
        .optional {
            color: var(--vscode-descriptionForeground);
        }
        
        .actions {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid var(--vscode-panel-border);
        }
        
        button {
            background-color: var(--vscode-button-background);
            color: var(--vscode-button-foreground);
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin-right: 10px;
            font-size: 14px;
        }
        
        button:hover {
            background-color: var(--vscode-button-hoverBackground);
        }
        
        .secondary-button {
            background-color: var(--vscode-button-secondaryBackground);
            color: var(--vscode-button-secondaryForeground);
        }
        
        .secondary-button:hover {
            background-color: var(--vscode-button-secondaryHoverBackground);
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="command-title">${command.displayName}</div>
        <div class="command-id">${command.id}</div>
        <span class="risk-badge risk-${command.riskLevel}">${command.riskLevel}</span>
    </div>
    
    <div class="section">
        <div class="section-title">Information</div>
        <div class="meta-grid">
            <span class="meta-label">Category:</span>
            <span>${command.category}</span>
            
            <span class="meta-label">Subcategory:</span>
            <span>${command.subcategory}</span>
            
            <span class="meta-label">Risk Level:</span>
            <span>${command.riskLevel}</span>
            
            <span class="meta-label">Discovered:</span>
            <span>${command.discoveredAt.toLocaleDateString()}</span>
            
            ${command.contextRequirements.length > 0 ? `
                <span class="meta-label">Context Requirements:</span>
                <span>${command.contextRequirements.join(', ')}</span>
            ` : ''}
        </div>
        
        ${command.description ? `
            <div class="section-title">Description</div>
            <p>${command.description}</p>
        ` : ''}
    </div>
    
    ${command.signature ? `
        <div class="section">
            <div class="section-title">Signature</div>
            <div class="meta-grid">
                <span class="meta-label">Async:</span>
                <span>${command.signature.async ? 'Yes' : 'No'}</span>
                
                <span class="meta-label">Confidence:</span>
                <span>${command.signature.confidence}</span>
                
                ${command.signature.returnType ? `
                    <span class="meta-label">Return Type:</span>
                    <span class="parameter-type">${command.signature.returnType}</span>
                ` : ''}
            </div>
            
            ${command.signature.parameters.length > 0 ? `
                <div class="section-title">Parameters</div>
                <ul class="parameter-list">
                    ${command.signature.parameters.map(param => `
                        <li class="parameter-item">
                            <div>
                                <span class="parameter-name">${param.name}</span>
                                <span class="parameter-type">(${param.type})</span>
                                <span class="${param.required ? 'required' : 'optional'}">
                                    ${param.required ? 'required' : 'optional'}
                                </span>
                            </div>
                            ${param.description ? `<div>${param.description}</div>` : ''}
                            ${param.defaultValue !== undefined ? `<div>Default: ${JSON.stringify(param.defaultValue)}</div>` : ''}
                        </li>
                    `).join('')}
                </ul>
            ` : '<p>No parameters</p>'}
        </div>
    ` : ''}
    
    <div class="actions">
        <button onclick="testCommand()">Test Command</button>
        <button class="secondary-button" onclick="copyCommandId()">Copy Command ID</button>
    </div>
    
    <script>
        const vscode = acquireVsCodeApi();
        
        function testCommand() {
            vscode.postMessage({ command: 'testCommand' });
        }
        
        function copyCommandId() {
            vscode.postMessage({ command: 'copyCommandId' });
        }
    </script>
</body>
</html>`;
    }
    /**
     * Disposes resources used by the explorer.
     */
    dispose() {
        this.disposables.forEach(d => d.dispose());
    }
}
exports.CommandExplorer = CommandExplorer;
//# sourceMappingURL=command-explorer.js.map