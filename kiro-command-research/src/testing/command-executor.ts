/**
 * Safe command execution engine for testing Kiro commands.
 * 
 * This module provides controlled command execution with safety checks,
 * workspace state snapshots, and rollback capabilities for safe testing.
 */

import * as vscode from 'vscode';
import { CommandMetadata, ParameterInfo } from '../types/command-metadata';
import { ValidationResult, ValidationContext, ParameterValidator } from './parameter-validator';
import { ResultCapture, TestConfiguration } from './result-capture';
import { SideEffectDetector, DetectionConfig } from './side-effect-detector';

/**
 * Execution context for command testing.
 */
export interface ExecutionContext {
  /** Command being executed */
  readonly command: CommandMetadata;
  
  /** Validated parameters */
  readonly parameters: Record<string, any>;
  
  /** Execution timeout in milliseconds */
  readonly timeoutMs: number;
  
  /** Whether to create workspace snapshot before execution */
  readonly createSnapshot: boolean;
  
  /** Whether to require user confirmation */
  readonly requireConfirmation: boolean;
  
  /** Additional context data */
  readonly context: Record<string, any>;
}

/**
 * Result of command execution.
 */
export interface ExecutionResult {
  /** Whether execution was successful */
  readonly success: boolean;
  
  /** Command that was executed */
  readonly commandId: string;
  
  /** Parameters used in execution */
  readonly parameters: Record<string, any>;
  
  /** Execution start time */
  readonly startTime: Date;
  
  /** Execution end time */
  readonly endTime: Date;
  
  /** Execution duration in milliseconds */
  readonly duration: number;
  
  /** Return value from command (if any) */
  readonly result?: any;
  
  /** Error information if execution failed */
  readonly error?: ExecutionError;
  
  /** Detected side effects */
  readonly sideEffects: SideEffect[];
  
  /** Workspace snapshot ID (if created) */
  readonly snapshotId?: string;
}

/**
 * Execution error information.
 */
export interface ExecutionError {
  /** Error message */
  readonly message: string;
  
  /** Error type/category */
  readonly type: string;
  
  /** Stack trace if available */
  readonly stack?: string;
  
  /** Error code if available */
  readonly code?: string;
  
  /** Whether error is recoverable */
  readonly recoverable: boolean;
}

/**
 * Side effect detected during execution.
 */
export interface SideEffect {
  /** Type of side effect */
  readonly type: 'file_created' | 'file_modified' | 'file_deleted' | 'view_opened' | 'view_closed' | 'setting_changed' | 'workspace_changed';
  
  /** Description of the side effect */
  readonly description: string;
  
  /** Affected resource (file path, setting key, etc.) */
  readonly resource?: string;
  
  /** Before and after values (if applicable) */
  readonly changes?: {
    before?: any;
    after?: any;
  };
  
  /** When the side effect was detected */
  readonly timestamp: Date;
}

/**
 * Workspace state snapshot for rollback capabilities.
 */
export interface WorkspaceSnapshot {
  /** Unique snapshot identifier */
  readonly id: string;
  
  /** When snapshot was created */
  readonly timestamp: Date;
  
  /** Open files and their content */
  readonly openFiles: Array<{
    uri: string;
    content: string;
    isDirty: boolean;
  }>;
  
  /** Workspace settings */
  readonly settings: Record<string, any>;
  
  /** Active editor information */
  readonly activeEditor?: {
    uri: string;
    selection: vscode.Range;
    visibleRanges: vscode.Range[];
  };
  
  /** Open views and panels */
  readonly openViews: string[];
}

/**
 * Safely executes Kiro commands with comprehensive safety checks and monitoring.
 * 
 * The CommandExecutor provides controlled command execution for testing purposes,
 * including workspace state snapshots, timeout handling, and rollback capabilities.
 */
export class CommandExecutor {
  private readonly parameterValidator: ParameterValidator;
  private readonly resultCapture: ResultCapture;
  private readonly sideEffectDetector: SideEffectDetector;
  private readonly snapshots: Map<string, WorkspaceSnapshot> = new Map();
  private executionCounter = 0;
  
  constructor(
    parameterValidator: ParameterValidator,
    resultCapture?: ResultCapture,
    sideEffectDetector?: SideEffectDetector
  ) {
    this.parameterValidator = parameterValidator;
    this.resultCapture = resultCapture || new ResultCapture();
    this.sideEffectDetector = sideEffectDetector || new SideEffectDetector();
  }
  
  /**
   * Executes a command with comprehensive safety checks and result capture.
   * 
   * @param context Execution context
   * @param captureResult Whether to capture detailed test results
   * @param notes Optional notes about this test execution
   * @returns Promise that resolves to execution result
   */
  public async executeCommand(
    context: ExecutionContext, 
    captureResult = true,
    notes?: string
  ): Promise<ExecutionResult> {
    const startTime = new Date();
    let snapshotId: string | undefined;
    
    console.log(`CommandExecutor: Starting execution of ${context.command.id}`);
    
    try {
      // Pre-execution safety checks
      await this.performSafetyChecks(context);
      
      // Create workspace snapshot if requested
      if (context.createSnapshot) {
        snapshotId = await this.createWorkspaceSnapshot();
        console.log(`CommandExecutor: Created workspace snapshot ${snapshotId}`);
      }
      
      // Start side effect monitoring
      await this.sideEffectDetector.startMonitoring();
      
      // Execute command with timeout
      const result = await this.executeWithTimeout(context);
      
      // Stop side effect monitoring and collect results
      const detectedSideEffects = await this.sideEffectDetector.stopMonitoring();
      
      const endTime = new Date();
      const duration = endTime.getTime() - startTime.getTime();
      
      console.log(`CommandExecutor: Command executed successfully in ${duration}ms`);
      
      const executionResult: ExecutionResult = {
        success: true,
        commandId: context.command.id,
        parameters: context.parameters,
        startTime,
        endTime,
        duration,
        result,
        sideEffects: detectedSideEffects,
        snapshotId
      };
      
      // Capture detailed test result if requested
      if (captureResult) {
        await this.captureTestResult(context, executionResult, notes);
      }
      
      return executionResult;
      
    } catch (error: unknown) {
      const endTime = new Date();
      const duration = endTime.getTime() - startTime.getTime();
      
      const executionError: ExecutionError = this.createExecutionError(error);
      
      console.error(`CommandExecutor: Command execution failed after ${duration}ms:`, executionError);
      
      // Stop side effect monitoring even on failure
      let detectedSideEffects: SideEffect[] = [];
      try {
        if (this.sideEffectDetector.isActive()) {
          detectedSideEffects = await this.sideEffectDetector.stopMonitoring();
        }
      } catch (monitoringError) {
        console.warn('Failed to stop side effect monitoring:', monitoringError);
      }
      
      const executionResult: ExecutionResult = {
        success: false,
        commandId: context.command.id,
        parameters: context.parameters,
        startTime,
        endTime,
        duration,
        error: executionError,
        sideEffects: detectedSideEffects,
        snapshotId
      };
      
      // Capture detailed test result even on failure if requested
      if (captureResult) {
        try {
          await this.captureTestResult(context, executionResult, notes);
        } catch (captureError) {
          console.warn('Failed to capture test result:', captureError);
        }
      }
      
      return executionResult;
    }
  }
  
  /**
   * Performs pre-execution safety checks.
   * 
   * @param context Execution context
   * @returns Promise that resolves when checks pass
   * @throws Error if safety checks fail
   */
  private async performSafetyChecks(context: ExecutionContext): Promise<void> {
    // Check if command is too risky
    if (context.command.riskLevel === 'destructive' && !context.requireConfirmation) {
      throw new Error('Destructive commands require explicit confirmation');
    }
    
    // Validate workspace state
    if (context.command.contextRequirements.includes('Open workspace') && !vscode.workspace.workspaceFolders) {
      throw new Error('Command requires an open workspace');
    }
    
    if (context.command.contextRequirements.includes('Active file editor') && !vscode.window.activeTextEditor) {
      throw new Error('Command requires an active file editor');
    }
    
    // Check for conflicting operations
    if (this.hasActiveExecution()) {
      throw new Error('Another command execution is already in progress');
    }
    
    // Validate parameters one more time
    const validationContext: ValidationContext = {
      commandId: context.command.id,
      workspace: vscode.workspace.workspaceFolders?.[0],
      activeEditor: vscode.window.activeTextEditor,
      context: context.context
    };
    
    const signature = context.command.signature;
    if (signature && signature.parameters) {
      const validationResult: ValidationResult = await this.parameterValidator.validateParameters(
        signature.parameters,
        context.parameters,
        validationContext
      );
      
      if (!validationResult.valid) {
        throw new Error(`Parameter validation failed: ${validationResult.errors.map(e => e.message).join(', ')}`);
      }
    }
  }
  
  /**
   * Executes command with timeout protection.
   * 
   * @param context Execution context
   * @returns Promise that resolves to command result
   */
  private async executeWithTimeout(context: ExecutionContext): Promise<any> {
    const paramArray = Object.values(context.parameters);
    
    return new Promise((resolve, reject) => {
      // Set up timeout
      const timeoutHandle = setTimeout(() => {
        reject(new Error(`Command execution timed out after ${context.timeoutMs}ms`));
      }, context.timeoutMs);
      
      // Execute command
      const commandPromise = vscode.commands.executeCommand(context.command.id, ...paramArray);
      
      // Handle the promise
      Promise.resolve(commandPromise)
        .then(result => {
          clearTimeout(timeoutHandle);
          resolve(result);
        })
        .catch((error: any) => {
          clearTimeout(timeoutHandle);
          reject(error);
        });
    });
  }
  
  /**
   * Creates a workspace state snapshot for rollback purposes.
   * 
   * @returns Promise that resolves to snapshot ID
   */
  public async createWorkspaceSnapshot(): Promise<string> {
    const snapshotId = `snapshot_${++this.executionCounter}_${Date.now()}`;
    
    try {
      // Capture open files and their content
      const openFiles: Array<{ uri: string; content: string; isDirty: boolean }> = [];
      
      for (const document of vscode.workspace.textDocuments) {
        if (!document.isUntitled && document.uri.scheme === 'file') {
          openFiles.push({
            uri: document.uri.toString(),
            content: document.getText(),
            isDirty: document.isDirty
          });
        }
      }
      
      // Capture workspace settings (limited to what's accessible)
      const settings: Record<string, any> = {};
      const config = vscode.workspace.getConfiguration();
      
      // Capture some key settings that might be affected by commands
      const settingsToCapture = [
        'editor.fontSize',
        'editor.tabSize',
        'files.autoSave',
        'workbench.colorTheme',
        'terminal.integrated.shell'
      ];
      
      for (const setting of settingsToCapture) {
        try {
          settings[setting] = config.get(setting);
        } catch (error) {
          // Ignore settings we can't access
        }
      }
      
      // Capture active editor state
      let activeEditor: WorkspaceSnapshot['activeEditor'];
      if (vscode.window.activeTextEditor) {
        const editor = vscode.window.activeTextEditor;
        activeEditor = {
          uri: editor.document.uri.toString(),
          selection: editor.selection,
          visibleRanges: [...editor.visibleRanges]
        };
      }
      
      // Capture open views (limited to what we can detect)
      const openViews: string[] = [];
      // Note: VS Code API doesn't provide direct access to all open views
      // We can only capture what's available through the API
      
      const snapshot: WorkspaceSnapshot = {
        id: snapshotId,
        timestamp: new Date(),
        openFiles,
        settings,
        activeEditor,
        openViews
      };
      
      this.snapshots.set(snapshotId, snapshot);
      
      console.log(`CommandExecutor: Created snapshot ${snapshotId} with ${openFiles.length} files`);
      
      return snapshotId;
      
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Failed to create workspace snapshot: ${errorMessage}`);
    }
  }
  
  /**
   * Restores workspace state from a snapshot.
   * 
   * @param snapshotId Snapshot ID to restore
   * @returns Promise that resolves when restoration is complete
   */
  public async restoreWorkspaceSnapshot(snapshotId: string): Promise<void> {
    const snapshot = this.snapshots.get(snapshotId);
    if (!snapshot) {
      throw new Error(`Snapshot ${snapshotId} not found`);
    }
    
    console.log(`CommandExecutor: Restoring snapshot ${snapshotId}`);
    
    try {
      // Restore file contents
      for (const fileInfo of snapshot.openFiles) {
        try {
          const uri = vscode.Uri.parse(fileInfo.uri);
          const document = await vscode.workspace.openTextDocument(uri);
          
          if (document.getText() !== fileInfo.content) {
            const edit = new vscode.WorkspaceEdit();
            const fullRange = new vscode.Range(
              document.positionAt(0),
              document.positionAt(document.getText().length)
            );
            edit.replace(uri, fullRange, fileInfo.content);
            await vscode.workspace.applyEdit(edit);
          }
        } catch (error) {
          console.warn(`Failed to restore file ${fileInfo.uri}:`, error);
        }
      }
      
      // Restore active editor state
      if (snapshot.activeEditor) {
        try {
          const uri = vscode.Uri.parse(snapshot.activeEditor.uri);
          const document = await vscode.workspace.openTextDocument(uri);
          const editor = await vscode.window.showTextDocument(document);
          
          // Create new Selection from the stored range
          const selection = new vscode.Selection(
            snapshot.activeEditor.selection.start,
            snapshot.activeEditor.selection.end
          );
          editor.selection = selection;
          editor.revealRange(selection);
        } catch (error) {
          console.warn('Failed to restore active editor:', error);
        }
      }
      
      console.log(`CommandExecutor: Successfully restored snapshot ${snapshotId}`);
      
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Failed to restore snapshot: ${errorMessage}`);
    }
  }
  
  /**
   * Captures detailed test result using the result capture system.
   * 
   * @param context Execution context
   * @param executionResult Execution result
   * @param notes Optional notes about the test
   * @returns Promise that resolves when result is captured
   */
  private async captureTestResult(
    context: ExecutionContext,
    executionResult: ExecutionResult,
    notes?: string
  ): Promise<void> {
    try {
      const testConfiguration: TestConfiguration = {
        timeoutMs: context.timeoutMs,
        snapshotEnabled: context.createSnapshot,
        confirmationRequired: context.requireConfirmation,
        monitoringLevel: 'comprehensive',
        options: context.context
      };
      
      await this.resultCapture.captureResult(
        context.command,
        context.parameters,
        executionResult,
        testConfiguration,
        notes
      );
      
      console.log(`CommandExecutor: Captured detailed test result for ${context.command.id}`);
      
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.warn(`CommandExecutor: Failed to capture test result: ${errorMessage}`);
    }
  }
  
  /**
   * Creates an execution error from a caught exception.
   * 
   * @param error Caught error
   * @returns Structured execution error
   */
  private createExecutionError(error: unknown): ExecutionError {
    if (error instanceof Error) {
      return {
        message: error.message,
        type: error.constructor.name,
        stack: error.stack,
        recoverable: this.isRecoverableError(error)
      };
    }
    
    return {
      message: String(error),
      type: 'UnknownError',
      recoverable: false
    };
  }
  
  /**
   * Determines if an error is recoverable.
   * 
   * @param error Error to analyze
   * @returns True if error is recoverable
   */
  private isRecoverableError(error: Error): boolean {
    const recoverablePatterns = [
      'timeout',
      'cancelled',
      'not found',
      'permission denied',
      'invalid parameter'
    ];
    
    const errorMessage = error.message.toLowerCase();
    return recoverablePatterns.some(pattern => errorMessage.includes(pattern));
  }
  
  /**
   * Checks if there's an active command execution.
   * 
   * @returns True if execution is in progress
   */
  private hasActiveExecution(): boolean {
    // Simple implementation - could be enhanced with actual tracking
    return false;
  }
  
  /**
   * Gets all available snapshots.
   * 
   * @returns Array of snapshot IDs and timestamps
   */
  public getAvailableSnapshots(): Array<{ id: string; timestamp: Date; fileCount: number }> {
    return Array.from(this.snapshots.values()).map(snapshot => ({
      id: snapshot.id,
      timestamp: snapshot.timestamp,
      fileCount: snapshot.openFiles.length
    }));
  }
  
  /**
   * Deletes a workspace snapshot.
   * 
   * @param snapshotId Snapshot ID to delete
   * @returns True if snapshot was deleted
   */
  public deleteSnapshot(snapshotId: string): boolean {
    return this.snapshots.delete(snapshotId);
  }
  
  /**
   * Clears all snapshots.
   */
  public clearAllSnapshots(): void {
    this.snapshots.clear();
  }
  
  /**
   * Gets the result capture instance for accessing captured results.
   * 
   * @returns Result capture instance
   */
  public getResultCapture(): ResultCapture {
    return this.resultCapture;
  }
  
  /**
   * Gets the side effect detector instance for advanced monitoring.
   * 
   * @returns Side effect detector instance
   */
  public getSideEffectDetector(): SideEffectDetector {
    return this.sideEffectDetector;
  }
  
  /**
   * Disposes all resources used by the executor.
   */
  public dispose(): void {
    this.clearAllSnapshots();
    this.sideEffectDetector.dispose();
  }
}