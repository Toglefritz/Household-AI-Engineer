/**
 * Central state management for the Kiro Communication Bridge Extension.
 * 
 * This class manages the extension's lifecycle, configuration, and core services
 * including the API server, WebSocket server, and Kiro communication components.
 */

import * as vscode from 'vscode';
import { Logger } from './logger';
import { ConfigurationManager } from './configuration-manager';
import { ApiServer } from '../api/api-server';
import { WebSocketServer } from '../websocket/websocket-server';
import { KiroCommandProxy } from '../kiro/kiro-command-proxy';
import { StatusMonitor } from '../kiro/status-monitor';
import { UserInputHandler } from '../kiro/user-input-handler';

/**
 * Manages the global state and lifecycle of the communication bridge extension.
 * 
 * This singleton class coordinates all major components of the extension
 * and provides a central point for initialization, configuration, and cleanup.
 */
export class ExtensionState {
  private static instance: ExtensionState | null = null;
  
  private readonly logger: Logger;
  private readonly configurationManager: ConfigurationManager;
  private readonly kiroProxy: KiroCommandProxy;
  private readonly statusMonitor: StatusMonitor;
  private readonly userInputHandler: UserInputHandler;
  private readonly apiServer: ApiServer;
  private readonly webSocketServer: WebSocketServer;
  
  private context: vscode.ExtensionContext | null = null;
  private isInitialized: boolean = false;
  private serversStarted: boolean = false;

  /**
   * Creates a new extension state instance.
   * 
   * This constructor initializes all core services but does not start them.
   * Use the static initialize() method to properly set up the extension.
   */
  private constructor() {
    this.logger = new Logger('ExtensionState');
    this.configurationManager = new ConfigurationManager();
    
    // Initialize Kiro communication components
    this.kiroProxy = new KiroCommandProxy();
    this.statusMonitor = new StatusMonitor();
    this.userInputHandler = new UserInputHandler();
    
    // Initialize servers with communication components
    this.apiServer = new ApiServer(
      {},
      this.kiroProxy,
      this.statusMonitor,
      this.userInputHandler
    );
    this.webSocketServer = new WebSocketServer(
      {},
      this.kiroProxy,
      this.statusMonitor,
      this.userInputHandler
    );
    
    this.logger.info('Extension state instance created');
  }

  /**
   * Initializes the extension state with the provided context.
   * 
   * This method sets up the singleton instance, loads configuration,
   * and prepares all services for operation.
   * 
   * @param context - VS Code extension context
   */
  public static async initialize(context: vscode.ExtensionContext): Promise<void> {
    if (ExtensionState.instance) {
      throw new Error('Extension state is already initialized');
    }

    ExtensionState.instance = new ExtensionState();
    await ExtensionState.instance.initializeInternal(context);
  }

  /**
   * Gets the current extension state instance.
   * 
   * @returns The current extension state instance, or null if not initialized
   */
  public static getCurrentInstance(): ExtensionState | null {
    return ExtensionState.instance;
  }

  /**
   * Internal initialization method that sets up the extension state.
   * 
   * @param context - VS Code extension context
   */
  private async initializeInternal(context: vscode.ExtensionContext): Promise<void> {
    try {
      this.context = context;
      
      this.logger.info('Loading configuration...');
      await this.configurationManager.loadConfiguration();
      
      this.isInitialized = true;
      this.logger.info('Extension state initialized successfully');
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to initialize extension state: ${errorMessage}`);
      throw error;
    }
  }

  /**
   * Starts the API and WebSocket servers.
   * 
   * This method launches both servers and sets up communication channels
   * for the Flutter frontend to interact with Kiro IDE.
   */
  public async startServers(): Promise<void> {
    if (!this.isInitialized) {
      throw new Error('Extension state must be initialized before starting servers');
    }

    if (this.serversStarted) {
      this.logger.warn('Servers are already started');
      return;
    }

    try {
      this.logger.info('Starting API server...');
      await this.apiServer.start();
      
      this.logger.info('Starting WebSocket server...');
      await this.webSocketServer.start();
      
      this.serversStarted = true;
      this.logger.info('All servers started successfully');
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to start servers: ${errorMessage}`);
      throw error;
    }
  }

  /**
   * Stops the API and WebSocket servers.
   * 
   * This method gracefully shuts down both servers and cleans up
   * any active connections or resources.
   */
  public async stopServers(): Promise<void> {
    if (!this.serversStarted) {
      this.logger.warn('Servers are not currently running');
      return;
    }

    try {
      this.logger.info('Stopping API server...');
      await this.apiServer.stop();
      
      this.logger.info('Stopping WebSocket server...');
      await this.webSocketServer.stop();
      
      this.serversStarted = false;
      this.logger.info('All servers stopped successfully');
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to stop servers: ${errorMessage}`);
      throw error;
    }
  }

  /**
   * Gets the current server status.
   * 
   * @returns Object containing the status of all servers and services
   */
  public getServerStatus(): {
    initialized: boolean;
    serversStarted: boolean;
    kiroAvailable: boolean;
    connectedClients: number;
  } {
    return {
      initialized: this.isInitialized,
      serversStarted: this.serversStarted,
      kiroAvailable: this.statusMonitor.isAvailable(),
      connectedClients: this.webSocketServer.getClientCount(),
    };
  }

  /**
   * Gets the Kiro command proxy instance.
   * 
   * @returns The Kiro command proxy instance
   */
  public getKiroProxy(): KiroCommandProxy {
    return this.kiroProxy;
  }

  /**
   * Gets the status monitor instance.
   * 
   * @returns The status monitor instance
   */
  public getStatusMonitor(): StatusMonitor {
    return this.statusMonitor;
  }

  /**
   * Gets the user input handler instance.
   * 
   * @returns The user input handler instance
   */
  public getUserInputHandler(): UserInputHandler {
    return this.userInputHandler;
  }

  /**
   * Gets the configuration manager instance.
   * 
   * @returns The configuration manager instance
   */
  public getConfigurationManager(): ConfigurationManager {
    return this.configurationManager;
  }

  /**
   * Disposes of the extension state and cleans up all resources.
   * 
   * This method should be called during extension deactivation to ensure
   * proper cleanup of all services and resources.
   */
  public async dispose(): Promise<void> {
    try {
      this.logger.info('Disposing extension state...');
      
      // Stop servers if they're running
      if (this.serversStarted) {
        await this.stopServers();
      }
      
      // Dispose of all services
      this.kiroProxy.dispose();
      this.statusMonitor.dispose();
      this.userInputHandler.dispose();
      await this.apiServer.dispose();
      await this.webSocketServer.dispose();
      
      // Clear the singleton instance
      ExtensionState.instance = null;
      this.isInitialized = false;
      
      this.logger.info('Extension state disposed successfully');
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Error during extension state disposal: ${errorMessage}`);
      throw error;
    }
  }
}