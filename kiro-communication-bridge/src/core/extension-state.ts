/**
 * Central state management for the Kiro Communication Bridge Extension.
 * 
 * This class manages the extension's lifecycle, configuration, and core services
 * including the API server and Kiro communication components.
 */

import * as vscode from 'vscode';
import { Logger } from './logger';
import { ConfigurationManager } from './configuration-manager';
import { ApiServer } from '../api/api-server';

import { KiroCommandProxy } from '../kiro/kiro-command-proxy';
import { StatusMonitor } from '../kiro/status-monitor';
import { UserInputHandler } from '../kiro/user-input-handler';
import { checkPortsAvailability, getProcessUsingPort } from '../utils/port-utils';

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
   * Starts the API server.
   * 
   * This method launches the server and sets up communication channels
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
      
      this.serversStarted = true;
      this.logger.info('API server started successfully');
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to start servers: ${errorMessage}`);
      throw error;
    }
  }

  /**
   * Starts servers with automatic port conflict handling.
   * 
   * This method attempts to start servers and handles EADDRINUSE errors
   * by checking for existing processes and optionally terminating them.
   */
  public async startServersWithPortConflictHandling(): Promise<void> {
    const config = this.configurationManager.getConfiguration();
    const apiPort: number = config.api?.port || 3001;
    
    // Check port availability before attempting to start
    this.logger.info(`Checking port availability: API=${apiPort}`);
    const portStatus = await checkPortsAvailability([apiPort]);
    
    const unavailablePorts: number[] = [];
    for (const [port, available] of Object.entries(portStatus)) {
      if (!available) {
        unavailablePorts.push(parseInt(port, 10));
      }
    }
    
    if (unavailablePorts.length > 0) {
      this.logger.warn(`Ports not available: ${unavailablePorts.join(', ')}`);
      
      // Get information about processes using the ports
      const processInfo: Array<{ port: number; process: any }> = [];
      for (const port of unavailablePorts) {
        const process = await getProcessUsingPort(port);
        if (process) {
          processInfo.push({ port, process });
          this.logger.info(`Port ${port} is being used by process ${process.pid}`);
        }
      }
      
      // Attempt to kill the processes
      await this.killProcessesOnPorts(unavailablePorts);
      
      // Wait for ports to be released
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Verify ports are now available
      const retryPortStatus = await checkPortsAvailability(unavailablePorts);
      const stillUnavailable = unavailablePorts.filter(port => !retryPortStatus[port]);
      
      if (stillUnavailable.length > 0) {
        throw new Error(
          `Unable to free ports ${stillUnavailable.join(', ')} after attempting to kill processes. ` +
          `Please manually close any applications using these ports and try again.`
        );
      }
    }
    
    try {
      await this.startServers();
    } catch (error: unknown) {
      if (error instanceof Error && error.message.includes('EADDRINUSE')) {
        // This shouldn't happen after our port checks, but handle it anyway
        this.logger.error('Port conflict occurred despite pre-checks');
        throw new Error(
          `Port conflict detected even after clearing ports. This may indicate a race condition ` +
          `or another process quickly claimed the port. Please try the force restart command.`
        );
      } else {
        throw error;
      }
    }
  }

  /**
   * Forces a restart of all servers by stopping existing ones and starting new ones.
   * 
   * This method is more aggressive than startServersWithPortConflictHandling
   * and will attempt to kill processes on the required ports before starting.
   */
  public async forceRestartServers(): Promise<void> {
    this.logger.info('Force restarting servers...');
    
    try {
      // Stop our own servers first if they're running
      if (this.serversStarted) {
        await this.stopServers();
      }
      
      // Get port configuration
      const config = this.configurationManager.getConfiguration();
      const apiPort: number = config.api?.port || 3001;
      
      // Kill any processes using our ports
      await this.killProcessesOnPorts([apiPort]);
      
      // Wait for ports to be released
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Start servers
      await this.startServers();
      
      this.logger.info('Servers force restarted successfully');
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to force restart servers: ${errorMessage}`);
      throw error;
    }
  }

  /**
   * Attempts to kill processes using the specified ports.
   * 
   * This method uses platform-specific commands to find and terminate
   * processes that are listening on the given ports.
   * 
   * @param ports - Array of port numbers to check and kill processes for
   */
  private async killProcessesOnPorts(ports: number[]): Promise<void> {
    const { spawn } = await import('child_process');
    const os = await import('os');
    
    for (const port of ports) {
      try {
        this.logger.info(`Checking for processes on port ${port}...`);
        
        if (os.platform() === 'win32') {
          // Windows: Use netstat and taskkill
          await this.killProcessOnPortWindows(port);
        } else {
          // Unix-like systems: Use lsof and kill
          await this.killProcessOnPortUnix(port);
        }
      } catch (error: unknown) {
        const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
        this.logger.warn(`Failed to kill process on port ${port}: ${errorMessage}`);
        // Continue with other ports even if one fails
      }
    }
  }

  /**
   * Kills processes on a specific port on Windows systems.
   */
  private async killProcessOnPortWindows(port: number): Promise<void> {
    const { spawn } = await import('child_process');
    
    return new Promise((resolve, reject) => {
      // Find process using the port
      const netstat = spawn('netstat', ['-ano']);
      let output = '';
      
      netstat.stdout.on('data', (data) => {
        output += data.toString();
      });
      
      netstat.on('close', (code) => {
        if (code !== 0) {
          resolve(); // No error if netstat fails
          return;
        }
        
        // Parse netstat output to find PID
        const lines: string[] = output.split('\n');
        const portPattern = new RegExp(`127\\.0\\.0\\.1:${port}\\s+.*?LISTENING\\s+(\\d+)`);
        
        for (const line of lines) {
          const match: RegExpMatchArray | null = line.match(portPattern);
          if (match) {
            const pid: string = match[1];
            this.logger.info(`Found process ${pid} using port ${port}, attempting to kill...`);
            
            // Kill the process
            const taskkill = spawn('taskkill', ['/F', '/PID', pid]);
            taskkill.on('close', (killCode) => {
              if (killCode === 0) {
                this.logger.info(`Successfully killed process ${pid}`);
              } else {
                this.logger.warn(`Failed to kill process ${pid}`);
              }
              resolve();
            });
            return;
          }
        }
        
        resolve(); // No process found using the port
      });
      
      netstat.on('error', () => resolve()); // Ignore netstat errors
    });
  }

  /**
   * Kills processes on a specific port on Unix-like systems.
   */
  private async killProcessOnPortUnix(port: number): Promise<void> {
    const { spawn } = await import('child_process');
    
    return new Promise((resolve, reject) => {
      // Find process using the port
      const lsof = spawn('lsof', ['-ti', `tcp:${port}`]);
      let output = '';
      
      lsof.stdout.on('data', (data) => {
        output += data.toString();
      });
      
      lsof.on('close', (code) => {
        if (code !== 0) {
          resolve(); // No process found or lsof failed
          return;
        }
        
        const pids: string[] = output.trim().split('\n').filter(pid => pid.length > 0);
        
        if (pids.length === 0) {
          resolve();
          return;
        }
        
        // Kill all processes using the port
        let killedCount = 0;
        const totalPids = pids.length;
        
        for (const pid of pids) {
          this.logger.info(`Found process ${pid} using port ${port}, attempting to kill...`);
          
          const kill = spawn('kill', ['-9', pid]);
          kill.on('close', (killCode) => {
            if (killCode === 0) {
              this.logger.info(`Successfully killed process ${pid}`);
            } else {
              this.logger.warn(`Failed to kill process ${pid}`);
            }
            
            killedCount++;
            if (killedCount === totalPids) {
              resolve();
            }
          });
          
          kill.on('error', () => {
            killedCount++;
            if (killedCount === totalPids) {
              resolve();
            }
          });
        }
      });
      
      lsof.on('error', () => resolve()); // Ignore lsof errors
    });
  }

  /**
   * Stops the API server.
   * 
   * This method gracefully shuts down the server and cleans up
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
      
      this.serversStarted = false;
      this.logger.info('API server stopped successfully');
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
  } {
    return {
      initialized: this.isInitialized,
      serversStarted: this.serversStarted,
      kiroAvailable: this.statusMonitor.isAvailable(),
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
   * Performs a health check on all servers.
   * 
   * This method verifies that servers are actually responding to requests
   * and not just marked as started in our internal state.
   * 
   * @returns Promise that resolves to health check results
   */
  public async performHealthCheck(): Promise<{
    apiServer: { running: boolean; responding: boolean; error?: string };
    overall: boolean;
  }> {
    const results = {
      apiServer: { running: false, responding: false, error: undefined as string | undefined },
      overall: false
    };

    // Check API server
    try {
      const apiStatus = this.apiServer.getServerStatus();
      results.apiServer.running = apiStatus.running;
      
      if (apiStatus.running && apiStatus.port) {
        // Try to make a health check request using Node.js http module
        const config = this.configurationManager.getConfiguration();
        const healthUrl = `http://${config.api.host}:${config.api.port}/health`;
        
        const response = await this.makeHttpRequest(healthUrl, 5000);
        results.apiServer.responding = response.success;
        if (!response.success) {
          results.apiServer.error = response.error || 'Health check failed';
        }
      }
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      results.apiServer.error = errorMessage;
      this.logger.warn(`API server health check failed: ${errorMessage}`);
    }

    // Overall health is good if the API server is running and responding
    results.overall = results.apiServer.running && results.apiServer.responding;

    return results;
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

  /**
   * Makes an HTTP request for health checking.
   * 
   * @param url - URL to request
   * @param timeoutMs - Request timeout in milliseconds
   * @returns Promise that resolves to request result
   */
  private async makeHttpRequest(url: string, timeoutMs: number): Promise<{
    success: boolean;
    error?: string;
    statusCode?: number;
  }> {
    const http = await import('http');
    const { URL } = await import('url');
    
    return new Promise((resolve) => {
      try {
        const parsedUrl = new URL(url);
        const options = {
          hostname: parsedUrl.hostname,
          port: parsedUrl.port,
          path: parsedUrl.pathname,
          method: 'GET',
          timeout: timeoutMs
        };
        
        const req = http.request(options, (res) => {
          resolve({
            success: res.statusCode === 200,
            statusCode: res.statusCode,
            error: res.statusCode !== 200 ? `HTTP ${res.statusCode}` : undefined
          });
        });
        
        req.on('error', (error) => {
          resolve({
            success: false,
            error: error.message
          });
        });
        
        req.on('timeout', () => {
          req.destroy();
          resolve({
            success: false,
            error: 'Request timeout'
          });
        });
        
        req.end();
      } catch (error) {
        resolve({
          success: false,
          error: error instanceof Error ? error.message : 'Unknown error'
        });
      }
    });
  }
}