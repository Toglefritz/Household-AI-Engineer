/**
 * Kiro Command Proxy for the Kiro Communication Bridge.
 * 
 * This module provides a proxy interface for executing Kiro IDE commands
 * and capturing their output. It handles command execution, timeout management,
 * and error handling for communication with the Kiro IDE.
 */

import * as vscode from 'vscode';
import { EventEmitter } from 'events';
import {
  CommandResult,
  KiroStatus,
  KiroStatusType,
  CommandExecution
} from '../types/command-execution';
import {
  CommandExecutionError,
  KiroUnavailableError,
  TimeoutError,
  ValidationError
} from '../types/bridge-errors';

/**
 * Configuration options for the KiroCommandProxy.
 */
export interface KiroCommandProxyConfig {
  /** Default timeout for command execution in milliseconds */
  defaultTimeoutMs: number;
  
  /** Maximum number of concurrent command executions */
  maxConcurrentCommands: number;
  
  /** Interval for status checking in milliseconds */
  statusCheckIntervalMs: number;
  
  /** Whether to enable debug logging */
  enableDebugLogging: boolean;
}

/**
 * Default configuration for the KiroCommandProxy.
 */
export const DEFAULT_KIRO_PROXY_CONFIG: KiroCommandProxyConfig = {
  defaultTimeoutMs: 300000, // 5 minutes
  maxConcurrentCommands: 3,
  statusCheckIntervalMs: 5000, // 5 seconds
  enableDebugLogging: false
};

/**
 * Events emitted by the KiroCommandProxy.
 */
export interface KiroCommandProxyEvents {
  'command-started': (execution: CommandExecution) => void;
  'command-output': (executionId: string, output: string, stream: 'stdout' | 'stderr') => void;
  'command-completed': (executionId: string, result: CommandResult) => void;
  'command-error': (executionId: string, error: CommandExecutionError) => void;
  'status-changed': (status: KiroStatus) => void;
  'availability-changed': (available: boolean) => void;
}

/**
 * Proxy class for executing Kiro IDE commands and managing communication.
 * 
 * This class provides a clean interface for executing Kiro commands through
 * VS Code's command API, with support for output capture, timeout handling,
 * and status monitoring.
 */
export class KiroCommandProxy extends EventEmitter {
  private readonly config: KiroCommandProxyConfig;
  private readonly activeExecutions = new Map<string, CommandExecution>();
  private readonly executionTimeouts = new Map<string, NodeJS.Timeout>();
  private currentStatus: KiroStatus;
  private statusCheckInterval?: NodeJS.Timeout;
  private executionCounter = 0;

  constructor(config: Partial<KiroCommandProxyConfig> = {}) {
    super();
    this.config = { ...DEFAULT_KIRO_PROXY_CONFIG, ...config };
    this.currentStatus = {
      status: 'unavailable',
      version: undefined
    };
    
    this.startStatusMonitoring();
  }

  /**
   * Executes a Kiro command and returns the result.
   * 
   * @param command - The Kiro command to execute
   * @param args - Optional command arguments
   * @param workspacePath - Optional workspace context
   * @param timeoutMs - Optional timeout override
   * @returns Promise that resolves to the command result
   */
  public async executeCommand(
    command: string,
    args: string[] = [],
    workspacePath?: string,
    timeoutMs?: number
  ): Promise<CommandResult> {
    // Validate inputs
    this.validateCommandInput(command, args);
    
    // Check if we can execute commands
    await this.ensureKiroAvailable();
    
    // Check concurrent execution limit
    if (this.activeExecutions.size >= this.config.maxConcurrentCommands) {
      throw new CommandExecutionError(
        command,
        args,
        `Maximum concurrent commands limit reached (${this.config.maxConcurrentCommands})`
      );
    }

    const executionId = this.generateExecutionId();
    const timeout = timeoutMs || this.config.defaultTimeoutMs;
    
    const execution: CommandExecution = {
      id: executionId,
      command,
      args,
      workspacePath,
      startedAt: new Date(),
      status: 'running',
      output: ''
    };

    this.activeExecutions.set(executionId, execution);
    this.emit('command-started', execution);
    
    try {
      // Set up timeout
      const timeoutHandle = setTimeout(() => {
        this.handleCommandTimeout(executionId, timeout);
      }, timeout);
      this.executionTimeouts.set(executionId, timeoutHandle);

      // Execute the command
      const result = await this.executeKiroCommand(execution);
      
      // Clean up
      this.cleanupExecution(executionId);
      
      // Update execution status
      execution.status = result.success ? 'completed' : 'failed';
      execution.completedAt = new Date();
      execution.output = result.output;
      execution.error = result.error;

      this.emit('command-completed', executionId, result);
      
      return result;
      
    } catch (error) {
      this.cleanupExecution(executionId);
      
      const commandError = error instanceof CommandExecutionError 
        ? error 
        : new CommandExecutionError(command, args, String(error));
      
      execution.status = 'failed';
      execution.completedAt = new Date();
      execution.error = commandError.message;
      
      this.emit('command-error', executionId, commandError);
      throw commandError;
    }
  }

  /**
   * Gets the current status of Kiro IDE.
   * 
   * @returns Current Kiro status
   */
  public async getStatus(): Promise<KiroStatus> {
    await this.checkKiroAvailability();
    return { ...this.currentStatus };
  }

  /**
   * Checks if Kiro IDE is available and responding.
   * 
   * @returns True if Kiro is available
   */
  public async isAvailable(): Promise<boolean> {
    try {
      await this.checkKiroAvailability();
      return this.currentStatus.status !== 'unavailable';
    } catch {
      return false;
    }
  }

  /**
   * Gets a list of available Kiro commands.
   * 
   * @returns Array of available command names
   */
  public async getAvailableCommands(): Promise<string[]> {
    try {
      // Get all available commands from VS Code
      const allCommands = await vscode.commands.getCommands(true);
      
      // Filter for Kiro-related commands
      const kiroCommands = allCommands.filter(cmd => 
        cmd.startsWith('kiro.') || 
        cmd.startsWith('workbench.action.') ||
        cmd.includes('kiro') ||
        cmd.includes('ai') ||
        cmd.includes('assistant')
      );
      
      return kiroCommands.sort();
    } catch (error) {
      this.logDebug('Failed to get available commands:', error);
      return [];
    }
  }

  /**
   * Gets information about currently active command executions.
   * 
   * @returns Array of active executions
   */
  public getActiveExecutions(): CommandExecution[] {
    return Array.from(this.activeExecutions.values()).map(exec => ({ ...exec }));
  }

  /**
   * Cancels a running command execution.
   * 
   * @param executionId - ID of the execution to cancel
   * @returns True if cancellation was successful
   */
  public async cancelExecution(executionId: string): Promise<boolean> {
    const execution = this.activeExecutions.get(executionId);
    if (!execution) {
      return false;
    }

    try {
      // Clean up the execution
      this.cleanupExecution(executionId);
      
      execution.status = 'failed';
      execution.completedAt = new Date();
      execution.error = 'Command execution was cancelled';
      
      const error = new CommandExecutionError(
        execution.command,
        execution.args,
        'Command execution was cancelled'
      );
      
      this.emit('command-error', executionId, error);
      return true;
      
    } catch (error) {
      this.logDebug('Failed to cancel execution:', error);
      return false;
    }
  }

  /**
   * Disposes of the proxy and cleans up resources.
   */
  public dispose(): void {
    // Cancel all active executions
    for (const executionId of this.activeExecutions.keys()) {
      this.cancelExecution(executionId);
    }

    // Clear status monitoring
    if (this.statusCheckInterval) {
      clearInterval(this.statusCheckInterval);
      this.statusCheckInterval = undefined;
    }

    // Clear all timeouts
    for (const timeout of this.executionTimeouts.values()) {
      clearTimeout(timeout);
    }
    this.executionTimeouts.clear();

    // Remove all listeners
    this.removeAllListeners();
  }

  /**
   * Validates command input parameters.
   */
  private validateCommandInput(command: string, args: string[]): void {
    if (!command || typeof command !== 'string' || command.trim() === '') {
      throw new ValidationError('Command must be a non-empty string', {
        field: 'command',
        value: command,
        rule: 'required'
      });
    }

    if (!Array.isArray(args)) {
      throw new ValidationError('Args must be an array', {
        field: 'args',
        value: args,
        rule: 'type'
      });
    }

    if (!args.every(arg => typeof arg === 'string')) {
      throw new ValidationError('All args must be strings', {
        field: 'args',
        value: args,
        rule: 'type'
      });
    }
  }

  /**
   * Ensures Kiro is available before executing commands.
   */
  private async ensureKiroAvailable(): Promise<void> {
    const available = await this.isAvailable();
    if (!available) {
      throw new KiroUnavailableError('not_responding');
    }
  }

  /**
   * Executes a Kiro command through VS Code's command API.
   */
  private async executeKiroCommand(execution: CommandExecution): Promise<CommandResult> {
    const startTime = Date.now();
    
    try {
      // Update status to busy
      this.updateStatus('busy', execution.command);
      
      // Execute the command through VS Code API
      let result: any;
      if (execution.args.length > 0) {
        result = await vscode.commands.executeCommand(execution.command, ...execution.args);
      } else {
        result = await vscode.commands.executeCommand(execution.command);
      }
      
      const executionTime = Date.now() - startTime;
      const output = this.formatCommandOutput(result);
      
      // Emit output event
      this.emit('command-output', execution.id, output, 'stdout');
      
      return {
        success: true,
        output,
        executionTimeMs: executionTime,
        command: execution.command,
        args: execution.args,
        exitCode: 0
      };
      
    } catch (error) {
      const executionTime = Date.now() - startTime;
      const errorMessage = error instanceof Error ? error.message : String(error);
      
      // Emit error output
      this.emit('command-output', execution.id, errorMessage, 'stderr');
      
      return {
        success: false,
        output: '',
        error: errorMessage,
        executionTimeMs: executionTime,
        command: execution.command,
        args: execution.args,
        exitCode: 1
      };
      
    } finally {
      // Update status back to ready if no other commands are running
      if (this.activeExecutions.size <= 1) {
        this.updateStatus('ready');
      }
    }
  }

  /**
   * Formats command output for consistent handling.
   */
  private formatCommandOutput(result: any): string {
    if (result === undefined || result === null) {
      return '';
    }
    
    if (typeof result === 'string') {
      return result;
    }
    
    if (typeof result === 'object') {
      try {
        return JSON.stringify(result, null, 2);
      } catch {
        return String(result);
      }
    }
    
    return String(result);
  }

  /**
   * Handles command execution timeout.
   */
  private handleCommandTimeout(executionId: string, timeoutMs: number): void {
    const execution = this.activeExecutions.get(executionId);
    if (!execution) {
      return;
    }

    const elapsedMs = Date.now() - execution.startedAt.getTime();
    const error = new TimeoutError('command-execution', timeoutMs, elapsedMs, {
      executionId,
      command: execution.command,
      args: execution.args
    });

    this.cleanupExecution(executionId);
    
    execution.status = 'failed';
    execution.completedAt = new Date();
    execution.error = error.message;

    const commandError = new CommandExecutionError(
      execution.command,
      execution.args,
      error.message
    );

    this.emit('command-error', executionId, commandError);
  }

  /**
   * Cleans up resources for a command execution.
   */
  private cleanupExecution(executionId: string): void {
    this.activeExecutions.delete(executionId);
    
    const timeout = this.executionTimeouts.get(executionId);
    if (timeout) {
      clearTimeout(timeout);
      this.executionTimeouts.delete(executionId);
    }
  }

  /**
   * Generates a unique execution ID.
   */
  private generateExecutionId(): string {
    return `exec-${Date.now()}-${++this.executionCounter}`;
  }

  /**
   * Starts monitoring Kiro status.
   */
  private startStatusMonitoring(): void {
    // Initial status check
    this.checkKiroAvailability().catch(() => {
      // Ignore initial check failures
    });

    // Set up periodic status checking
    this.statusCheckInterval = setInterval(() => {
      this.checkKiroAvailability().catch(() => {
        // Ignore periodic check failures
      });
    }, this.config.statusCheckIntervalMs);
  }

  /**
   * Checks Kiro availability and updates status.
   */
  private async checkKiroAvailability(): Promise<void> {
    try {
      // Try to get VS Code version as a basic availability check
      const commands = await vscode.commands.getCommands();
      const hasKiroCommands = commands.some(cmd => 
        cmd.includes('kiro') || cmd.includes('ai') || cmd.includes('assistant')
      );

      const newStatus: KiroStatusType = hasKiroCommands ? 'ready' : 'unavailable';
      const version = vscode.version;

      this.updateStatus(newStatus, undefined, version);
      
    } catch (error) {
      this.updateStatus('unavailable');
      this.logDebug('Kiro availability check failed:', error);
    }
  }

  /**
   * Updates the current Kiro status and emits events if changed.
   */
  private updateStatus(
    status: KiroStatusType, 
    currentCommand?: string, 
    version?: string
  ): void {
    const previousStatus = this.currentStatus.status;
    const wasAvailable = previousStatus !== 'unavailable';
    
    this.currentStatus = {
      status,
      currentCommand,
      version: version || this.currentStatus.version
    };

    // Emit status change event
    if (previousStatus !== status) {
      this.emit('status-changed', { ...this.currentStatus });
    }

    // Emit availability change event
    const isAvailable = status !== 'unavailable';
    if (wasAvailable !== isAvailable) {
      this.emit('availability-changed', isAvailable);
    }
  }

  /**
   * Logs debug messages if debug logging is enabled.
   */
  private logDebug(message: string, ...args: any[]): void {
    if (this.config.enableDebugLogging) {
      console.debug(`[KiroCommandProxy] ${message}`, ...args);
    }
  }
}