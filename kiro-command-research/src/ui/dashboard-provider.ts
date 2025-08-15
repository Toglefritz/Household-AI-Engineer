/**
 * Dashboard tree data provider for the sidebar view.
 * 
 * This module provides a simple tree view for the dashboard sidebar
 * that shows the main dashboard button.
 */

import * as vscode from 'vscode';

/**
 * Tree item for dashboard view.
 */
export class DashboardTreeItem extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly itemType: 'dashboard' | 'action' = 'action'
  ) {
    super(label, collapsibleState);
    
    if (itemType === 'dashboard') {
      this.iconPath = new vscode.ThemeIcon('dashboard');
      this.command = {
        command: 'kiroCommandResearch.openDashboard',
        title: 'Open Dashboard'
      };
    }
  }
}

/**
 * Data provider for the dashboard tree view.
 */
export class DashboardProvider implements vscode.TreeDataProvider<DashboardTreeItem> {
  private _onDidChangeTreeData: vscode.EventEmitter<DashboardTreeItem | undefined | null | void> = new vscode.EventEmitter<DashboardTreeItem | undefined | null | void>();
  readonly onDidChangeTreeData: vscode.Event<DashboardTreeItem | undefined | null | void> = this._onDidChangeTreeData.event;
  
  /**
   * Gets tree item for element.
   */
  getTreeItem(element: DashboardTreeItem): vscode.TreeItem {
    return element;
  }
  
  /**
   * Gets children for tree element.
   */
  async getChildren(element?: DashboardTreeItem): Promise<DashboardTreeItem[]> {
    if (!element) {
      // Root level - return dashboard button
      return [
        new DashboardTreeItem(
          'Open Dashboard',
          vscode.TreeItemCollapsibleState.None,
          'dashboard'
        )
      ];
    }
    
    return [];
  }
  
  /**
   * Refreshes the tree view.
   */
  public refresh(): void {
    this._onDidChangeTreeData.fire();
  }
}