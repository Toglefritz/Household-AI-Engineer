/**
 * Configuration management for the Kiro Orchestration Extension.
 * 
 * This module handles loading, validation, and management of extension
 * configuration from VS Code settings and provides typed access to
 * configuration values throughout the extension.
 */

import * as vscode from 'vscode';
import { Logger } from './logger';

/**
 * Configuration interface defining all extension settings.
 */
export interface ExtensionConfiguration {
  /** API server configuration */
  api: {
    /** Port for HTTP API server */
    port: number;
    /** Host address to bind to */
    host: string;
    /** API key for authentication */
    apiKey: string;
    /** Request timeout in milliseconds */
    timeoutMs: number;
  };
  
  /** WebSocket server configuration */
  websocket: {
    /** Port for WebSocket server */
    port: number;
    /** Maximum concurrent connections */
    maxConnections: number;
    /** Connection timeout in milliseconds */
    connectionTimeoutMs: number;
  };
  
  /** Workspace management configuration */
  workspace: {
    /** Base directory for all applications */
    appsDirectory: string;
    /** Path to spec template directory */
    specTemplatePath: string;
    /** Maximum workspace size in MB */
    maxWorkspaceSizeMb: number;
  };
  
  /** Job processing configuration */
  jobs: {
    /** Maximum concurrent jobs */
    maxConcurrentJobs: number;
    /** Default job timeout in milliseconds */
    defaultTimeoutMs: number;
    /** Job cleanup interval in milliseconds */
    cleanupIntervalMs: number;
  };
  
  /** Logging configuration */
  logging: {
    /** Log level */
    level: 'debug' | 'info' | 'warn' | 'error';
    /** Log file path */
    logFilePath: string;
    /** Maximum log file size in MB */
    maxLogSizeMb: number;
  };
  
  /** General extension settings */
  general: {
    /** Whether to automatically start servers on extension activation */
    autoStart: boolean;
  };
}

/**
 * Manages extension configuration loading and validation.
 * 
 * This class provides typed access to VS Code settings and handles
 * configuration validation, defaults, and change notifications.
 */
export class ConfigurationManager {
  private readonly logger: Logger;
  private configuration: ExtensionConfiguration | null = null;

  /**
   * Creates a new configuration manager instance.
   */
  constructor() {
    this.logger = new Logger('ConfigurationManager');
  }

  /**
   * Loads configuration from VS Code settings.
   * 
   * This method reads all extension settings, applies defaults for
   * missing values, and validates the configuration.
   */
  public async loadConfiguration(): Promise<void> {
    try {
      this.logger.info('Loading extension configuration...');
      
      const config = vscode.workspace.getConfiguration('kiroOrchestration');
      
      // Generate API key if not provided
      const apiKey: string = config.get('api.apiKey') || this.generateApiKey();
      
      this.configuration = {
        api: {
          port: config.get('api.port') || 3001,
          host: config.get('api.host') || 'localhost',
          apiKey: apiKey,
          timeoutMs: 30000, // 30 seconds default
        },
        websocket: {
          port: config.get('websocket.port') || 3002,
          maxConnections: 100,
          connectionTimeoutMs: 60000, // 1 minute default
        },
        workspace: {
          appsDirectory: config.get('workspace.appsDirectory') || './apps',
          specTemplatePath: './templates/spec-template',
          maxWorkspaceSizeMb: 1024, // 1GB default
        },
        jobs: {
          maxConcurrentJobs: config.get('jobs.maxConcurrentJobs') || 3,
          defaultTimeoutMs: config.get('jobs.defaultTimeoutMs') || 1800000, // 30 minutes
          cleanupIntervalMs: 300000, // 5 minutes default
        },
        logging: {
          level: config.get('logging.level') || 'info',
          logFilePath: './logs/orchestration.log',
          maxLogSizeMb: 100,
        },
        general: {
          autoStart: config.get('autoStart') ?? true,
        },
      };
      
      // Set the logger level based on configuration
      Logger.setLogLevel(this.configuration.logging.level);
      
      this.logger.info('Configuration loaded successfully', {
        apiPort: this.configuration.api.port,
        websocketPort: this.configuration.websocket.port,
        appsDirectory: this.configuration.workspace.appsDirectory,
        maxConcurrentJobs: this.configuration.jobs.maxConcurrentJobs,
        logLevel: this.configuration.logging.level,
        autoStart: this.configuration.general.autoStart,
      });
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to load configuration: ${errorMessage}`);
      throw error;
    }
  }

  /**
   * Gets the current configuration.
   * 
   * @returns The current extension configuration
   * @throws Error if configuration has not been loaded
   */
  public getConfiguration(): ExtensionConfiguration {
    if (!this.configuration) {
      throw new Error('Configuration has not been loaded. Call loadConfiguration() first.');
    }
    
    return this.configuration;
  }

  /**
   * Generates a random API key for authentication.
   * 
   * @returns A randomly generated API key
   */
  private generateApiKey(): string {
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result: string = '';
    
    for (let i = 0; i < 32; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    
    this.logger.info('Generated new API key for authentication');
    return result;
  }
}