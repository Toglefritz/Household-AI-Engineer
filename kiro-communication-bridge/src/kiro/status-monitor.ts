/**
 * Status monitoring system for the Kiro Communication Bridge.
 * 
 * This module provides comprehensive monitoring of Kiro IDE availability,
 * status changes, and command discovery. It maintains real-time awareness
 * of Kiro's state and capabilities.
 */

import * as vscode from 'vscode';
import { EventEmitter } from 'events';
import {
  KiroStatus,
  KiroStatusType,
  KiroStatusResponse
} from '../types/command-execution';
import {
  KiroUnavailableError,
  TimeoutError
} from '../types/bridge-errors';

/**
 * Configuration for the status monitoring system.
 */
export interface StatusMonitorConfig {
  /** Interval for status checks in milliseconds */
  checkIntervalMs: number;
  
  /** Timeout for status check operations in milliseconds */
  checkTimeoutMs: number;
  
  /** Number of consecutive failures before marking as unavailable */
  failureThreshold: number;
  
  /** Interval for command discovery in milliseconds */
  commandDiscoveryIntervalMs: number;
  
  /** Whether to enable debug logging */
  enableDebugLogging: boolean;
}

/**
 * Default configuration for status monitoring.
 */
export const DEFAULT_STATUS_MONITOR_CONFIG: StatusMonitorConfig = {
  checkIntervalMs: 5000, // 5 seconds
  checkTimeoutMs: 3000, // 3 seconds
  failureThreshold: 3,
  commandDiscoveryIntervalMs: 30000, // 30 seconds
  enableDebugLogging: false
};

/**
 * Events emitted by the StatusMonitor.
 */
export interface StatusMonitorEvents {
  'status-changed': (status: KiroStatus, previousStatus: KiroStatus) => void;
  'availability-changed': (available: boolean, reason?: string) => void;
  'commands-updated': (commands: string[]) => void;
  'health-check-failed': (error: Error, consecutiveFailures: number) => void;
  'health-check-recovered': (afterFailures: number) => void;
}

/**
 * Detailed status information including health metrics.
 */
export interface DetailedKiroStatus extends KiroStatus {
  /** Whether Kiro is currently available */
  available: boolean;
  
  /** Last successful status check timestamp */
  lastCheckAt: string;
  
  /** Number of consecutive health check failures */
  consecutiveFailures: number;
  
  /** Average response time for status checks in milliseconds */
  averageResponseTimeMs: number;
  
  /** List of available commands */
  availableCommands: string[];
  
  /** Last time commands were discovered */
  lastCommandDiscoveryAt: string;
  
  /** Additional health metrics */
  healthMetrics: {
    /** Total number of status checks performed */
    totalChecks: number;
    
    /** Number of successful checks */
    successfulChecks: number;
    
    /** Number of failed checks */
    failedChecks: number;
    
    /** Uptime percentage */
    uptimePercentage: number;
  };
}

/**
 * Status monitoring system for Kiro IDE.
 * 
 * Provides continuous monitoring of Kiro's availability, status changes,
 * and command capabilities with health metrics and failure detection.
 */
export class StatusMonitor extends EventEmitter {
  private readonly config: StatusMonitorConfig;
  private currentStatus: DetailedKiroStatus;
  private statusCheckInterval?: NodeJS.Timeout;
  private commandDiscoveryInterval?: NodeJS.Timeout;
  private consecutiveFailures = 0;
  private responseTimeHistory: number[] = [];
  private readonly maxResponseTimeHistory = 10;

  constructor(config: Partial<StatusMonitorConfig> = {}) {
    super();
    this.config = { ...DEFAULT_STATUS_MONITOR_CONFIG, ...config };
    
    this.currentStatus = {
      status: 'unavailable',
      available: false,
      lastCheckAt: new Date().toISOString(),
      consecutiveFailures: 0,
      averageResponseTimeMs: 0,
      availableCommands: [],
      lastCommandDiscoveryAt: new Date().toISOString(),
      healthMetrics: {
        totalChecks: 0,
        successfulChecks: 0,
        failedChecks: 0,
        uptimePercentage: 0
      }
    };

    this.startMonitoring();
  }

  /**
   * Gets the current detailed status of Kiro IDE.
   * 
   * @returns Current detailed status
   */
  public getDetailedStatus(): DetailedKiroStatus {
    return { ...this.currentStatus };
  }

  /**
   * Gets the basic Kiro status for API responses.
   * 
   * @returns Basic Kiro status
   */
  public getStatus(): KiroStatus {
    return {
      status: this.currentStatus.status,
      currentCommand: this.currentStatus.currentCommand,
      version: this.currentStatus.version
    };
  }

  /**
   * Gets the full status response including available commands.
   * 
   * @returns Complete status response
   */
  public getStatusResponse(): KiroStatusResponse {
    return {
      status: this.currentStatus.status,
      currentCommand: this.currentStatus.currentCommand,
      version: this.currentStatus.version,
      availableCommands: [...this.currentStatus.availableCommands],
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Checks if Kiro is currently available.
   * 
   * @returns True if Kiro is available
   */
  public isAvailable(): boolean {
    return this.currentStatus.available;
  }

  /**
   * Gets the list of available Kiro commands.
   * 
   * @returns Array of available command names
   */
  public getAvailableCommands(): string[] {
    return [...this.currentStatus.availableCommands];
  }

  /**
   * Forces an immediate status check.
   * 
   * @returns Promise that resolves to the updated status
   */
  public async forceStatusCheck(): Promise<KiroStatus> {
    await this.performStatusCheck();
    return this.getStatus();
  }

  /**
   * Forces an immediate command discovery.
   * 
   * @returns Promise that resolves to the discovered commands
   */
  public async forceCommandDiscovery(): Promise<string[]> {
    await this.discoverCommands();
    return this.getAvailableCommands();
  }

  /**
   * Gets health metrics for monitoring and diagnostics.
   * 
   * @returns Health metrics object
   */
  public getHealthMetrics(): DetailedKiroStatus['healthMetrics'] {
    return { ...this.currentStatus.healthMetrics };
  }

  /**
   * Resets health metrics and failure counters.
   */
  public resetHealthMetrics(): void {
    this.consecutiveFailures = 0;
    this.responseTimeHistory = [];
    this.currentStatus.consecutiveFailures = 0;
    this.currentStatus.averageResponseTimeMs = 0;
    this.currentStatus.healthMetrics = {
      totalChecks: 0,
      successfulChecks: 0,
      failedChecks: 0,
      uptimePercentage: 0
    };
    
    this.logDebug('Health metrics reset');
  }

  /**
   * Starts the monitoring system.
   */
  public startMonitoring(): void {
    if (this.statusCheckInterval || this.commandDiscoveryInterval) {
      this.logDebug('Monitoring already started');
      return;
    }

    this.logDebug('Starting status monitoring');

    // Perform initial checks
    this.performStatusCheck().catch(error => {
      this.logDebug('Initial status check failed:', error);
    });

    this.discoverCommands().catch(error => {
      this.logDebug('Initial command discovery failed:', error);
    });

    // Set up periodic status checking
    this.statusCheckInterval = setInterval(() => {
      this.performStatusCheck().catch(error => {
        this.logDebug('Periodic status check failed:', error);
      });
    }, this.config.checkIntervalMs);

    // Set up periodic command discovery
    this.commandDiscoveryInterval = setInterval(() => {
      this.discoverCommands().catch(error => {
        this.logDebug('Periodic command discovery failed:', error);
      });
    }, this.config.commandDiscoveryIntervalMs);
  }

  /**
   * Stops the monitoring system.
   */
  public stopMonitoring(): void {
    this.logDebug('Stopping status monitoring');

    if (this.statusCheckInterval) {
      clearInterval(this.statusCheckInterval);
      this.statusCheckInterval = undefined;
    }

    if (this.commandDiscoveryInterval) {
      clearInterval(this.commandDiscoveryInterval);
      this.commandDiscoveryInterval = undefined;
    }
  }

  /**
   * Disposes of the monitor and cleans up resources.
   */
  public dispose(): void {
    this.stopMonitoring();
    this.removeAllListeners();
  }

  /**
   * Performs a status check with timeout handling.
   */
  private async performStatusCheck(): Promise<void> {
    const startTime = Date.now();
    const previousStatus = { ...this.currentStatus };

    try {
      // Create a timeout promise
      const timeoutPromise = new Promise<never>((_, reject) => {
        setTimeout(() => {
          reject(new TimeoutError(
            'status-check',
            this.config.checkTimeoutMs,
            Date.now() - startTime
          ));
        }, this.config.checkTimeoutMs);
      });

      // Race the status check against the timeout
      await Promise.race([
        this.checkKiroStatus(),
        timeoutPromise
      ]);

      // Success - update metrics
      const responseTime = Date.now() - startTime;
      this.updateResponseTime(responseTime);
      this.handleSuccessfulCheck(previousStatus);

    } catch (error) {
      this.handleFailedCheck(error, previousStatus);
    }
  }

  /**
   * Checks Kiro status by attempting to interact with VS Code API.
   */
  private async checkKiroStatus(): Promise<void> {
    try {
      // Check if VS Code is responsive
      const commands = await vscode.commands.getCommands();
      
      // Look for Kiro-related functionality
      const hasKiroCommands = commands.some(cmd => 
        cmd.includes('kiro') || 
        cmd.includes('ai') || 
        cmd.includes('assistant') ||
        cmd.startsWith('workbench.action.')
      );

      // Try to get VS Code version
      const version = vscode.version;

      // Determine status based on availability
      let status: KiroStatusType;
      if (hasKiroCommands) {
        status = this.currentStatus.currentCommand ? 'busy' : 'ready';
      } else {
        status = 'unavailable';
      }

      // Update current status
      this.updateStatus({
        status,
        version,
        available: status !== 'unavailable',
        lastCheckAt: new Date().toISOString()
      });

    } catch (error) {
      throw new KiroUnavailableError('not_responding', {
        originalError: error instanceof Error ? error.message : String(error)
      });
    }
  }

  /**
   * Discovers available Kiro commands.
   */
  private async discoverCommands(): Promise<void> {
    try {
      const allCommands = await vscode.commands.getCommands(true);
      
      // Filter for relevant commands
      const kiroCommands = allCommands.filter(cmd => 
        cmd.startsWith('kiro.') ||
        cmd.startsWith('workbench.action.') ||
        cmd.includes('kiro') ||
        cmd.includes('ai') ||
        cmd.includes('assistant') ||
        cmd.includes('chat') ||
        cmd.includes('copilot')
      ).sort();

      // Update available commands if they changed
      if (!this.arraysEqual(kiroCommands, this.currentStatus.availableCommands)) {
        this.currentStatus.availableCommands = kiroCommands;
        this.currentStatus.lastCommandDiscoveryAt = new Date().toISOString();
        this.emit('commands-updated', kiroCommands);
        this.logDebug(`Discovered ${kiroCommands.length} commands`);
      }

    } catch (error) {
      this.logDebug('Command discovery failed:', error);
    }
  }

  /**
   * Handles a successful status check.
   */
  private handleSuccessfulCheck(previousStatus: DetailedKiroStatus): void {
    // Reset failure counter if we had failures
    if (this.consecutiveFailures > 0) {
      const failureCount = this.consecutiveFailures;
      this.consecutiveFailures = 0;
      this.currentStatus.consecutiveFailures = 0;
      this.emit('health-check-recovered', failureCount);
      this.logDebug(`Health check recovered after ${failureCount} failures`);
    }

    // Update health metrics
    this.currentStatus.healthMetrics.totalChecks++;
    this.currentStatus.healthMetrics.successfulChecks++;
    this.updateUptimePercentage();

    // Emit status change event if status changed
    if (previousStatus.status !== this.currentStatus.status) {
      this.emit('status-changed', this.getStatus(), {
        status: previousStatus.status,
        currentCommand: previousStatus.currentCommand,
        version: previousStatus.version
      });
    }

    // Emit availability change event if availability changed
    if (previousStatus.available !== this.currentStatus.available) {
      this.emit('availability-changed', this.currentStatus.available);
    }
  }

  /**
   * Handles a failed status check.
   */
  private handleFailedCheck(error: unknown, previousStatus: DetailedKiroStatus): void {
    this.consecutiveFailures++;
    this.currentStatus.consecutiveFailures = this.consecutiveFailures;

    // Update health metrics
    this.currentStatus.healthMetrics.totalChecks++;
    this.currentStatus.healthMetrics.failedChecks++;
    this.updateUptimePercentage();

    // Emit failure event
    const errorObj = error instanceof Error ? error : new Error(String(error));
    this.emit('health-check-failed', errorObj, this.consecutiveFailures);

    // Mark as unavailable if we've exceeded the failure threshold
    if (this.consecutiveFailures >= this.config.failureThreshold) {
      const wasAvailable = this.currentStatus.available;
      
      this.updateStatus({
        status: 'unavailable',
        available: false,
        lastCheckAt: new Date().toISOString()
      });

      // Emit availability change if we just became unavailable
      if (wasAvailable) {
        const reason = error instanceof KiroUnavailableError 
          ? error.reason 
          : 'health_check_failed';
        this.emit('availability-changed', false, reason);
      }
    }

    this.logDebug(`Status check failed (${this.consecutiveFailures}/${this.config.failureThreshold}):`, error);
  }

  /**
   * Updates the current status with new values.
   */
  private updateStatus(updates: Partial<DetailedKiroStatus>): void {
    Object.assign(this.currentStatus, updates);
  }

  /**
   * Updates response time metrics.
   */
  private updateResponseTime(responseTime: number): void {
    this.responseTimeHistory.push(responseTime);
    
    // Keep only the most recent response times
    if (this.responseTimeHistory.length > this.maxResponseTimeHistory) {
      this.responseTimeHistory.shift();
    }

    // Calculate average response time
    const average = this.responseTimeHistory.reduce((sum, time) => sum + time, 0) / 
                   this.responseTimeHistory.length;
    this.currentStatus.averageResponseTimeMs = Math.round(average);
  }

  /**
   * Updates uptime percentage based on health metrics.
   */
  private updateUptimePercentage(): void {
    const { totalChecks, successfulChecks } = this.currentStatus.healthMetrics;
    if (totalChecks > 0) {
      this.currentStatus.healthMetrics.uptimePercentage = 
        Math.round((successfulChecks / totalChecks) * 100);
    }
  }

  /**
   * Compares two arrays for equality.
   */
  private arraysEqual<T>(a: T[], b: T[]): boolean {
    if (a.length !== b.length) {
      return false;
    }
    return a.every((val, index) => val === b[index]);
  }

  /**
   * Logs debug messages if debug logging is enabled.
   */
  private logDebug(message: string, ...args: any[]): void {
    if (this.config.enableDebugLogging) {
      console.debug(`[StatusMonitor] ${message}`, ...args);
    }
  }
}