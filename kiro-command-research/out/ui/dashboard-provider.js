"use strict";
/**
 * Dashboard tree data provider for the sidebar view.
 *
 * This module provides a simple tree view for the dashboard sidebar
 * that shows the main dashboard button.
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
exports.DashboardProvider = exports.DashboardTreeItem = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Tree item for dashboard view.
 */
class DashboardTreeItem extends vscode.TreeItem {
    constructor(label, collapsibleState, itemType = 'action') {
        super(label, collapsibleState);
        this.label = label;
        this.collapsibleState = collapsibleState;
        this.itemType = itemType;
        if (itemType === 'dashboard') {
            this.iconPath = new vscode.ThemeIcon('dashboard');
            this.command = {
                command: 'kiroCommandResearch.openDashboard',
                title: 'Open Dashboard'
            };
        }
    }
}
exports.DashboardTreeItem = DashboardTreeItem;
/**
 * Data provider for the dashboard tree view.
 */
class DashboardProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }
    /**
     * Gets tree item for element.
     */
    getTreeItem(element) {
        return element;
    }
    /**
     * Gets children for tree element.
     */
    async getChildren(element) {
        if (!element) {
            // Root level - return dashboard button
            return [
                new DashboardTreeItem('Open Dashboard', vscode.TreeItemCollapsibleState.None, 'dashboard')
            ];
        }
        return [];
    }
    /**
     * Refreshes the tree view.
     */
    refresh() {
        this._onDidChangeTreeData.fire();
    }
}
exports.DashboardProvider = DashboardProvider;
//# sourceMappingURL=dashboard-provider.js.map