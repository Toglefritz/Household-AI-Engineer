/**
 * Side effect detection system for monitoring workspace changes during command execution.
 * 
 * This module provides comprehensive monitoring of workspace state changes,
 * file system modifications, and other side effects that occur during command testing.
 */

import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { SideEffect } from './command-executor';

/**
 * Configuration for side effect detection.
 */
export interface DetectionConfig {
  /** Whether to monitor file system changes */
  readonly monitorFileSystem: boolean;
  
  /** Whether to monitor workspace settings changes */
  readonly monitorSettings: boolean;
  
  /** Whether to monitor editor state changes */
  readonly monitorEditorState: boolean;
  
  /** Whether to monitor view and panel changes */
  readonly monitorViews: boolean;
  
  /** File patterns to exclude from monitoring */
  readonly excludePatterns: string[];
  
  /** Maximum number of side effects to track */
  readonly maxSideEffects: number;
  
  /** Whether to capture detailed change information */
  readonly captureDetails: boolean;
}

/**
 * Detailed information about a workspace state change.
 */
export interface DetailedSideEffect extends SideEffect {
  /** Detailed change information */
  readonly details: {
    /** File size before and after (for file changes) */
    fileSizes?: { before: number; after: number };
    
    /** Content hash before and after (for content changes) */
    contentHashes?: { before: string; after: string };
    
    /** Line count changes (for text files) */
    lineChanges?: { before: number; after: number };
    
    /** Setting value changes */
    settingChanges?: { before: any; after: any };
    
    /** View state information */
    viewState?: { visible: boolean; active: boolean };
    
    /** Additional metadata */
    metadata?: Record<string, any>;
  };
  
  /** Severity level of the side effect */
  readonly severity: 'low' | 'medium' | 'high' | 'critical';
  
  /** Whether this side effect was expected */
  readonly expected: boolean;
  
  /** Category for grouping similar side effects */
  readonly category: string;
}

/**
 * Snapshot of workspace state for comparison.
 */
export interface WorkspaceStateSnapshot {
  /** Snapshot identifier */
  readonly id: string;
  
  /** When snapshot was taken */
  readonly timestamp: Date;
  
  /** File system state */
  readonly fileSystem: {
    files: Map<string, FileInfo>;
    directories: Set<string>;
  };
  
  /** Editor state */
  readonly editorState: {
    openDocuments: DocumentInfo[];
    activeDocument?: string;
    visibleEditors: EditorInfo[];
  };
  
  /** Workspace settings */
  readonly settings: Map<string, any>;
  
  /** View and panel state */
  readonly viewState: {
    openViews: string[];
    activeView?: string;
    panelState: Record<string, boolean>;
  };
}

/**
 * Information about a file in the workspace.
 */
export interface FileInfo {
  /** File path */
  readonly path: string;
  
  /** File size in bytes */
  readonly size: number;
  
  /** Last modified timestamp */
  readonly lastModified: Date;
  
  /** Content hash (for text files) */
  readonly contentHash?: string;
  
  /** Line count (for text files) */
  readonly lineCount?: number;
  
  /** File type */
  readonly type: 'file' | 'directory' | 'symlink';
  
  /** Whether file is readable */
  readonly readable: boolean;
}

/**
 * Information about an open document.
 */
export interface DocumentInfo {
  /** Document URI */
  readonly uri: string;
  
  /** Language identifier */
  readonly languageId: string;
  
  /** Whether document is dirty */
  readonly isDirty: boolean;
  
  /** Line count */
  readonly lineCount: number;
  
  /** Content hash */
  readonly contentHash: string;
}

/**
 * Information about a visible editor.
 */
export interface EditorInfo {
  /** Document URI */
  readonly documentUri: string;
  
  /** Editor column */
  readonly column: vscode.ViewColumn;
  
  /** Selection range */
  readonly selection: vscode.Range;
  
  /** Visible ranges */
  readonly visibleRanges: vscode.Range[];
}

/**
 * Detects and analyzes side effects during command execution.
 * 
 * The SideEffectDetector provides comprehensive monitoring of workspace changes
 * to understand the impact of command execution on the development environment.
 */
export class SideEffectDetector {
  private readonly config: DetectionConfig;
  private readonly detectedEffects: DetailedSideEffect[] = [];
  private readonly disposables: vscode.Disposable[] = [];
  
  private baselineSnapshot?: WorkspaceStateSnapshot;
  private isMonitoring = false;
  private monitoringStartTime?: Date;
  
  constructor(config: Partial<DetectionConfig> = {}) {
    this.config = {
      monitorFileSystem: true,
      monitorSettings: true,
      monitorEditorState: true,
      monitorViews: true,
      excludePatterns: [
        '**/node_modules/**',
        '**/.git/**',
        '**/dist/**',
        '**/build/**',
        '**/*.log',
        '**/tmp/**'
      ],
      maxSideEffects: 1000,
      captureDetails: true,
      ...config
    };
  }
  
  /**
   * Starts monitoring for side effects.
   * 
   * @returns Promise that resolves when monitoring is active
   */
  public async startMonitoring(): Promise<void> {
    if (this.isMonitoring) {
      throw new Error('Side effect monitoring is already active');
    }
    
    console.log('SideEffectDetector: Starting monitoring');
    
    // Clear previous results
    this.detectedEffects.length = 0;
    this.disposables.forEach(d => d.dispose());
    this.disposables.length = 0;
    
    // Create baseline snapshot
    this.baselineSnapshot = await this.createWorkspaceSnapshot();
    this.monitoringStartTime = new Date();
    
    // Set up monitoring
    this.setupFileSystemMonitoring();
    this.setupEditorStateMonitoring();
    this.setupSettingsMonitoring();
    this.setupViewMonitoring();
    
    this.isMonitoring = true;
    console.log('SideEffectDetector: Monitoring started');
  }
  
  /**
   * Stops monitoring and returns detected side effects.
   * 
   * @returns Promise that resolves to detected side effects
   */
  public async stopMonitoring(): Promise<DetailedSideEffect[]> {
    if (!this.isMonitoring) {
      return [];
    }
    
    console.log('SideEffectDetector: Stopping monitoring');
    
    // Dispose all listeners
    this.disposables.forEach(d => d.dispose());
    this.disposables.length = 0;
    
    // Create final snapshot and compare
    if (this.baselineSnapshot) {
      const finalSnapshot = await this.createWorkspaceSnapshot();
      const comparisonEffects = await this.compareSnapshots(this.baselineSnapshot, finalSnapshot);
      
      // Add comparison effects that weren't already detected
      for (const effect of comparisonEffects) {
        if (!this.detectedEffects.some(e => this.effectsMatch(e, effect))) {
          this.detectedEffects.push(effect);
        }
      }
    }
    
    this.isMonitoring = false;
    
    // Sort effects by timestamp
    const sortedEffects = [...this.detectedEffects].sort(
      (a, b) => a.timestamp.getTime() - b.timestamp.getTime()
    );
    
    console.log(`SideEffectDetector: Monitoring stopped, detected ${sortedEffects.length} side effects`);
    
    return sortedEffects;
  }
  
  /**
   * Gets currently detected side effects without stopping monitoring.
   * 
   * @returns Array of detected side effects
   */
  public getCurrentEffects(): DetailedSideEffect[] {
    return [...this.detectedEffects];
  }
  
  /**
   * Checks if monitoring is currently active.
   * 
   * @returns True if monitoring is active
   */
  public isActive(): boolean {
    return this.isMonitoring;
  }
  
  /**
   * Creates a snapshot of the current workspace state.
   * 
   * @returns Promise that resolves to workspace snapshot
   */
  public async createWorkspaceSnapshot(): Promise<WorkspaceStateSnapshot> {
    const id = `snapshot_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const timestamp = new Date();
    
    console.log('SideEffectDetector: Creating workspace snapshot');
    
    // Capture file system state
    const fileSystem = await this.captureFileSystemState();
    
    // Capture editor state
    const editorState = this.captureEditorState();
    
    // Capture settings
    const settings = this.captureSettings();
    
    // Capture view state
    const viewState = this.captureViewState();
    
    return {
      id,
      timestamp,
      fileSystem,
      editorState,
      settings,
      viewState
    };
  }
  
  /**
   * Sets up file system change monitoring.
   */
  private setupFileSystemMonitoring(): void {
    if (!this.config.monitorFileSystem) {
      return;
    }
    
    // Monitor all files in workspace
    const watcher = vscode.workspace.createFileSystemWatcher('**/*');
    
    watcher.onDidCreate(uri => {
      if (this.shouldMonitorFile(uri.fsPath)) {
        this.recordSideEffect({
          type: 'file_created',
          description: `File created: ${uri.fsPath}`,
          resource: uri.fsPath,
          timestamp: new Date(),
          details: {},
          severity: 'low',
          expected: false,
          category: 'file_system'
        });
      }
    });
    
    watcher.onDidChange(uri => {
      if (this.shouldMonitorFile(uri.fsPath)) {
        this.recordFileChange(uri);
      }
    });
    
    watcher.onDidDelete(uri => {
      if (this.shouldMonitorFile(uri.fsPath)) {
        this.recordSideEffect({
          type: 'file_deleted',
          description: `File deleted: ${uri.fsPath}`,
          resource: uri.fsPath,
          timestamp: new Date(),
          details: {},
          severity: 'medium',
          expected: false,
          category: 'file_system'
        });
      }
    });
    
    this.disposables.push(watcher);
  }
  
  /**
   * Sets up editor state change monitoring.
   */
  private setupEditorStateMonitoring(): void {
    if (!this.config.monitorEditorState) {
      return;
    }
    
    // Monitor document opens
    const onDidOpenTextDocument = vscode.workspace.onDidOpenTextDocument(document => {
      this.recordSideEffect({
        type: 'view_opened',
        description: `Document opened: ${document.uri.fsPath}`,
        resource: document.uri.fsPath,
        timestamp: new Date(),
        details: {
          metadata: {
            languageId: document.languageId,
            lineCount: document.lineCount
          }
        },
        severity: 'low',
        expected: false,
        category: 'editor'
      });
    });
    
    // Monitor document closes
    const onDidCloseTextDocument = vscode.workspace.onDidCloseTextDocument(document => {
      this.recordSideEffect({
        type: 'view_closed',
        description: `Document closed: ${document.uri.fsPath}`,
        resource: document.uri.fsPath,
        timestamp: new Date(),
        details: {},
        severity: 'low',
        expected: false,
        category: 'editor'
      });
    });
    
    // Monitor active editor changes
    const onDidChangeActiveTextEditor = vscode.window.onDidChangeActiveTextEditor(editor => {
      if (editor) {
        this.recordSideEffect({
          type: 'view_opened',
          description: `Active editor changed: ${editor.document.uri.fsPath}`,
          resource: editor.document.uri.fsPath,
          timestamp: new Date(),
          details: {
            viewState: { visible: true, active: true }
          },
          severity: 'low',
          expected: false,
          category: 'editor'
        });
      }
    });
    
    this.disposables.push(onDidOpenTextDocument, onDidCloseTextDocument, onDidChangeActiveTextEditor);
  }
  
  /**
   * Sets up workspace settings change monitoring.
   */
  private setupSettingsMonitoring(): void {
    if (!this.config.monitorSettings) {
      return;
    }
    
    const onDidChangeConfiguration = vscode.workspace.onDidChangeConfiguration(event => {
      // Try to identify which settings changed
      const changedSettings: string[] = [];
      
      const settingsToCheck = [
        'editor.fontSize',
        'editor.tabSize',
        'files.autoSave',
        'workbench.colorTheme',
        'terminal.integrated.shell'
      ];
      
      for (const setting of settingsToCheck) {
        if (event.affectsConfiguration(setting)) {
          changedSettings.push(setting);
        }
      }
      
      if (changedSettings.length > 0) {
        this.recordSideEffect({
          type: 'setting_changed',
          description: `Settings changed: ${changedSettings.join(', ')}`,
          resource: changedSettings.join(','),
          timestamp: new Date(),
          details: {
            metadata: { changedSettings }
          },
          severity: 'medium',
          expected: false,
          category: 'settings'
        });
      }
    });
    
    this.disposables.push(onDidChangeConfiguration);
  }
  
  /**
   * Sets up view and panel change monitoring.
   */
  private setupViewMonitoring(): void {
    if (!this.config.monitorViews) {
      return;
    }
    
    // Monitor visible text editors changes
    const onDidChangeVisibleTextEditors = vscode.window.onDidChangeVisibleTextEditors(editors => {
      this.recordSideEffect({
        type: 'view_opened',
        description: `Visible editors changed: ${editors.length} editors visible`,
        timestamp: new Date(),
        details: {
          metadata: {
            editorCount: editors.length,
            editorPaths: editors.map(e => e.document.uri.fsPath)
          }
        },
        severity: 'low',
        expected: false,
        category: 'views'
      });
    });
    
    this.disposables.push(onDidChangeVisibleTextEditors);
  }
  
  /**
   * Records a file change with detailed information.
   * 
   * @param uri File URI that changed
   */
  private async recordFileChange(uri: vscode.Uri): Promise<void> {
    try {
      const filePath = uri.fsPath;
      let details: DetailedSideEffect['details'] = {};
      
      if (this.config.captureDetails) {
        // Get file stats
        const stats = await fs.promises.stat(filePath);
        details.fileSizes = { before: 0, after: stats.size }; // Before size not available
        
        // For text files, get line count
        if (this.isTextFile(filePath)) {
          try {
            const content = await fs.promises.readFile(filePath, 'utf8');
            const lineCount = content.split('\n').length;
            details.lineChanges = { before: 0, after: lineCount }; // Before count not available
            
            // Generate content hash
            const contentHash = this.generateHash(content);
            details.contentHashes = { before: '', after: contentHash };
          } catch (error) {
            // File might not be readable as text
          }
        }
      }
      
      this.recordSideEffect({
        type: 'file_modified',
        description: `File modified: ${filePath}`,
        resource: filePath,
        timestamp: new Date(),
        details,
        severity: 'low',
        expected: false,
        category: 'file_system'
      });
    } catch (error) {
      console.warn('Failed to record file change details:', error);
    }
  }
  
  /**
   * Records a side effect.
   * 
   * @param effect Side effect to record
   */
  private recordSideEffect(effect: DetailedSideEffect): void {
    if (this.detectedEffects.length >= this.config.maxSideEffects) {
      console.warn('SideEffectDetector: Maximum side effects reached, ignoring new effects');
      return;
    }
    
    // Filter out effects that occurred before monitoring started
    if (this.monitoringStartTime && effect.timestamp < this.monitoringStartTime) {
      return;
    }
    
    this.detectedEffects.push(effect);
  }
  
  /**
   * Captures current file system state.
   * 
   * @returns Promise that resolves to file system state
   */
  private async captureFileSystemState(): Promise<WorkspaceStateSnapshot['fileSystem']> {
    const files = new Map<string, FileInfo>();
    const directories = new Set<string>();
    
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders) {
      return { files, directories };
    }
    
    for (const folder of workspaceFolders) {
      try {
        await this.scanDirectory(folder.uri.fsPath, files, directories);
      } catch (error) {
        console.warn(`Failed to scan directory ${folder.uri.fsPath}:`, error);
      }
    }
    
    return { files, directories };
  }
  
  /**
   * Recursively scans a directory for files and subdirectories.
   * 
   * @param dirPath Directory path to scan
   * @param files Map to store file information
   * @param directories Set to store directory paths
   */
  private async scanDirectory(
    dirPath: string,
    files: Map<string, FileInfo>,
    directories: Set<string>
  ): Promise<void> {
    try {
      const entries = await fs.promises.readdir(dirPath, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dirPath, entry.name);
        
        if (!this.shouldMonitorFile(fullPath)) {
          continue;
        }
        
        if (entry.isDirectory()) {
          directories.add(fullPath);
          // Recursively scan subdirectories (with depth limit)
          if (this.getPathDepth(fullPath) < 10) {
            await this.scanDirectory(fullPath, files, directories);
          }
        } else if (entry.isFile()) {
          try {
            const stats = await fs.promises.stat(fullPath);
            let fileInfo: FileInfo = {
              path: fullPath,
              size: stats.size,
              lastModified: stats.mtime,
              type: 'file',
              readable: true
            };
            
            // Add additional info for text files
            if (this.isTextFile(fullPath) && stats.size < 1024 * 1024) { // Max 1MB for text analysis
              try {
                const content = await fs.promises.readFile(fullPath, 'utf8');
                fileInfo = {
                  ...fileInfo,
                  lineCount: content.split('\n').length,
                  contentHash: this.generateHash(content)
                };
              } catch (error) {
                // File not readable as text
                fileInfo = {
                  ...fileInfo,
                  readable: false
                };
              }
            }
            
            files.set(fullPath, fileInfo);
          } catch (error) {
            // File not accessible
          }
        }
      }
    } catch (error) {
      console.warn(`Failed to read directory ${dirPath}:`, error);
    }
  }
  
  /**
   * Captures current editor state.
   * 
   * @returns Editor state information
   */
  private captureEditorState(): WorkspaceStateSnapshot['editorState'] {
    const openDocuments: DocumentInfo[] = [];
    let activeDocument: string | undefined;
    const visibleEditors: EditorInfo[] = [];
    
    // Capture open documents
    for (const document of vscode.workspace.textDocuments) {
      if (document.uri.scheme === 'file') {
        const content = document.getText();
        openDocuments.push({
          uri: document.uri.toString(),
          languageId: document.languageId,
          isDirty: document.isDirty,
          lineCount: document.lineCount,
          contentHash: this.generateHash(content)
        });
      }
    }
    
    // Capture active document
    if (vscode.window.activeTextEditor) {
      activeDocument = vscode.window.activeTextEditor.document.uri.toString();
    }
    
    // Capture visible editors
    for (const editor of vscode.window.visibleTextEditors) {
      visibleEditors.push({
        documentUri: editor.document.uri.toString(),
        column: editor.viewColumn || vscode.ViewColumn.One,
        selection: editor.selection,
        visibleRanges: [...editor.visibleRanges]
      });
    }
    
    return {
      openDocuments,
      activeDocument,
      visibleEditors
    };
  }
  
  /**
   * Captures current workspace settings.
   * 
   * @returns Map of setting keys to values
   */
  private captureSettings(): Map<string, any> {
    const settings = new Map<string, any>();
    const config = vscode.workspace.getConfiguration();
    
    const settingsToCapture = [
      'editor.fontSize',
      'editor.tabSize',
      'files.autoSave',
      'workbench.colorTheme',
      'terminal.integrated.shell'
    ];
    
    for (const setting of settingsToCapture) {
      try {
        const value = config.get(setting);
        settings.set(setting, value);
      } catch (error) {
        // Setting not accessible
      }
    }
    
    return settings;
  }
  
  /**
   * Captures current view and panel state.
   * 
   * @returns View state information
   */
  private captureViewState(): WorkspaceStateSnapshot['viewState'] {
    const openViews: string[] = [];
    let activeView: string | undefined;
    const panelState: Record<string, boolean> = {};
    
    // Note: VS Code API doesn't provide direct access to all view states
    // We can only capture what's available through the API
    
    // Capture visible editors as "views"
    for (const editor of vscode.window.visibleTextEditors) {
      openViews.push(editor.document.uri.toString());
    }
    
    if (vscode.window.activeTextEditor) {
      activeView = vscode.window.activeTextEditor.document.uri.toString();
    }
    
    return {
      openViews,
      activeView,
      panelState
    };
  }
  
  /**
   * Compares two workspace snapshots to identify changes.
   * 
   * @param before Baseline snapshot
   * @param after Final snapshot
   * @returns Promise that resolves to detected side effects
   */
  private async compareSnapshots(
    before: WorkspaceStateSnapshot,
    after: WorkspaceStateSnapshot
  ): Promise<DetailedSideEffect[]> {
    const effects: DetailedSideEffect[] = [];
    
    // Compare file system changes
    effects.push(...this.compareFileSystemState(before.fileSystem, after.fileSystem));
    
    // Compare editor state changes
    effects.push(...this.compareEditorState(before.editorState, after.editorState));
    
    // Compare settings changes
    effects.push(...this.compareSettings(before.settings, after.settings));
    
    // Compare view state changes
    effects.push(...this.compareViewState(before.viewState, after.viewState));
    
    return effects;
  }
  
  /**
   * Compares file system states between snapshots.
   * 
   * @param before Baseline file system state
   * @param after Final file system state
   * @returns Array of detected file system side effects
   */
  private compareFileSystemState(
    before: WorkspaceStateSnapshot['fileSystem'],
    after: WorkspaceStateSnapshot['fileSystem']
  ): DetailedSideEffect[] {
    const effects: DetailedSideEffect[] = [];
    
    // Find new files
    for (const [filePath, fileInfo] of after.files) {
      if (!before.files.has(filePath)) {
        effects.push({
          type: 'file_created',
          description: `File created: ${filePath}`,
          resource: filePath,
          timestamp: new Date(),
          details: {
            fileSizes: { before: 0, after: fileInfo.size }
          },
          severity: 'low',
          expected: false,
          category: 'file_system'
        });
      }
    }
    
    // Find deleted files
    for (const [filePath] of before.files) {
      if (!after.files.has(filePath)) {
        effects.push({
          type: 'file_deleted',
          description: `File deleted: ${filePath}`,
          resource: filePath,
          timestamp: new Date(),
          details: {},
          severity: 'medium',
          expected: false,
          category: 'file_system'
        });
      }
    }
    
    // Find modified files
    for (const [filePath, afterInfo] of after.files) {
      const beforeInfo = before.files.get(filePath);
      if (beforeInfo && this.filesAreDifferent(beforeInfo, afterInfo)) {
        const details: DetailedSideEffect['details'] = {};
        
        if (beforeInfo.size !== afterInfo.size) {
          details.fileSizes = { before: beforeInfo.size, after: afterInfo.size };
        }
        
        if (beforeInfo.contentHash && afterInfo.contentHash && 
            beforeInfo.contentHash !== afterInfo.contentHash) {
          details.contentHashes = { before: beforeInfo.contentHash, after: afterInfo.contentHash };
        }
        
        if (beforeInfo.lineCount && afterInfo.lineCount && 
            beforeInfo.lineCount !== afterInfo.lineCount) {
          details.lineChanges = { before: beforeInfo.lineCount, after: afterInfo.lineCount };
        }
        
        effects.push({
          type: 'file_modified',
          description: `File modified: ${filePath}`,
          resource: filePath,
          timestamp: new Date(),
          details,
          severity: 'low',
          expected: false,
          category: 'file_system'
        });
      }
    }
    
    return effects;
  }
  
  /**
   * Compares editor states between snapshots.
   * 
   * @param before Baseline editor state
   * @param after Final editor state
   * @returns Array of detected editor side effects
   */
  private compareEditorState(
    before: WorkspaceStateSnapshot['editorState'],
    after: WorkspaceStateSnapshot['editorState']
  ): DetailedSideEffect[] {
    const effects: DetailedSideEffect[] = [];
    
    // Find newly opened documents
    const beforeUris = new Set(before.openDocuments.map(d => d.uri));
    for (const doc of after.openDocuments) {
      if (!beforeUris.has(doc.uri)) {
        effects.push({
          type: 'view_opened',
          description: `Document opened: ${doc.uri}`,
          resource: doc.uri,
          timestamp: new Date(),
          details: {
            metadata: {
              languageId: doc.languageId,
              lineCount: doc.lineCount
            }
          },
          severity: 'low',
          expected: false,
          category: 'editor'
        });
      }
    }
    
    // Find closed documents
    const afterUris = new Set(after.openDocuments.map(d => d.uri));
    for (const doc of before.openDocuments) {
      if (!afterUris.has(doc.uri)) {
        effects.push({
          type: 'view_closed',
          description: `Document closed: ${doc.uri}`,
          resource: doc.uri,
          timestamp: new Date(),
          details: {},
          severity: 'low',
          expected: false,
          category: 'editor'
        });
      }
    }
    
    // Check for active document changes
    if (before.activeDocument !== after.activeDocument) {
      effects.push({
        type: 'view_opened',
        description: `Active document changed: ${after.activeDocument || 'none'}`,
        resource: after.activeDocument,
        timestamp: new Date(),
        details: {
          viewState: { visible: true, active: true }
        },
        severity: 'low',
        expected: false,
        category: 'editor'
      });
    }
    
    return effects;
  }
  
  /**
   * Compares settings between snapshots.
   * 
   * @param before Baseline settings
   * @param after Final settings
   * @returns Array of detected settings side effects
   */
  private compareSettings(
    before: Map<string, any>,
    after: Map<string, any>
  ): DetailedSideEffect[] {
    const effects: DetailedSideEffect[] = [];
    
    // Find changed settings
    for (const [key, afterValue] of after) {
      const beforeValue = before.get(key);
      if (beforeValue !== afterValue) {
        effects.push({
          type: 'setting_changed',
          description: `Setting changed: ${key}`,
          resource: key,
          timestamp: new Date(),
          details: {
            settingChanges: { before: beforeValue, after: afterValue }
          },
          severity: 'medium',
          expected: false,
          category: 'settings'
        });
      }
    }
    
    return effects;
  }
  
  /**
   * Compares view states between snapshots.
   * 
   * @param before Baseline view state
   * @param after Final view state
   * @returns Array of detected view side effects
   */
  private compareViewState(
    before: WorkspaceStateSnapshot['viewState'],
    after: WorkspaceStateSnapshot['viewState']
  ): DetailedSideEffect[] {
    const effects: DetailedSideEffect[] = [];
    
    // Find newly opened views
    const beforeViews = new Set(before.openViews);
    for (const view of after.openViews) {
      if (!beforeViews.has(view)) {
        effects.push({
          type: 'view_opened',
          description: `View opened: ${view}`,
          resource: view,
          timestamp: new Date(),
          details: {},
          severity: 'low',
          expected: false,
          category: 'views'
        });
      }
    }
    
    // Find closed views
    const afterViews = new Set(after.openViews);
    for (const view of before.openViews) {
      if (!afterViews.has(view)) {
        effects.push({
          type: 'view_closed',
          description: `View closed: ${view}`,
          resource: view,
          timestamp: new Date(),
          details: {},
          severity: 'low',
          expected: false,
          category: 'views'
        });
      }
    }
    
    return effects;
  }
  
  /**
   * Checks if a file should be monitored based on configuration.
   * 
   * @param filePath File path to check
   * @returns True if file should be monitored
   */
  private shouldMonitorFile(filePath: string): boolean {
    for (const pattern of this.config.excludePatterns) {
      if (this.matchesPattern(filePath, pattern)) {
        return false;
      }
    }
    return true;
  }
  
  /**
   * Checks if a file path matches a glob pattern.
   * 
   * @param filePath File path to check
   * @param pattern Glob pattern
   * @returns True if path matches pattern
   */
  private matchesPattern(filePath: string, pattern: string): boolean {
    // Simple glob pattern matching (could be enhanced with a proper glob library)
    const regexPattern = pattern
      .replace(/\*\*/g, '.*')
      .replace(/\*/g, '[^/]*')
      .replace(/\?/g, '[^/]');
    
    const regex = new RegExp(`^${regexPattern}$`);
    return regex.test(filePath);
  }
  
  /**
   * Checks if a file is a text file based on extension.
   * 
   * @param filePath File path to check
   * @returns True if file is likely a text file
   */
  private isTextFile(filePath: string): boolean {
    const textExtensions = [
      '.txt', '.md', '.js', '.ts', '.json', '.html', '.css', '.scss',
      '.py', '.java', '.cpp', '.c', '.h', '.xml', '.yaml', '.yml',
      '.sh', '.bat', '.ps1', '.sql', '.php', '.rb', '.go', '.rs'
    ];
    
    const ext = path.extname(filePath).toLowerCase();
    return textExtensions.includes(ext);
  }
  
  /**
   * Generates a simple hash for content comparison.
   * 
   * @param content Content to hash
   * @returns Hash string
   */
  private generateHash(content: string): string {
    // Simple hash function (could be enhanced with crypto.createHash)
    let hash = 0;
    for (let i = 0; i < content.length; i++) {
      const char = content.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toString(36);
  }
  
  /**
   * Gets the depth of a file path.
   * 
   * @param filePath File path
   * @returns Path depth
   */
  private getPathDepth(filePath: string): number {
    return filePath.split(path.sep).length;
  }
  
  /**
   * Checks if two file info objects represent different files.
   * 
   * @param before Before file info
   * @param after After file info
   * @returns True if files are different
   */
  private filesAreDifferent(before: FileInfo, after: FileInfo): boolean {
    if (before.size !== after.size) {
      return true;
    }
    
    if (before.lastModified.getTime() !== after.lastModified.getTime()) {
      return true;
    }
    
    if (before.contentHash && after.contentHash && before.contentHash !== after.contentHash) {
      return true;
    }
    
    return false;
  }
  
  /**
   * Checks if two side effects are essentially the same.
   * 
   * @param effect1 First side effect
   * @param effect2 Second side effect
   * @returns True if effects match
   */
  private effectsMatch(effect1: DetailedSideEffect, effect2: DetailedSideEffect): boolean {
    return effect1.type === effect2.type &&
           effect1.resource === effect2.resource &&
           Math.abs(effect1.timestamp.getTime() - effect2.timestamp.getTime()) < 1000; // Within 1 second
  }
  
  /**
   * Disposes all resources used by the detector.
   */
  public dispose(): void {
    this.disposables.forEach(d => d.dispose());
    this.disposables.length = 0;
    this.isMonitoring = false;
  }
}