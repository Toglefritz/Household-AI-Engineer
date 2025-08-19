/**
 * REST API Server for the Kiro Communication Bridge.
 * 
 * This module provides the main Express.js server that handles HTTP requests
 * for command execution, status queries, and user input management.
 */

import express, { Express, Request, Response, NextFunction } from 'express';
import { Server } from 'http';
import { EventEmitter } from 'events';
import { KiroCommandProxy } from '../kiro/kiro-command-proxy';
import { StatusMonitor } from '../kiro/status-monitor';
import { UserInputHandler } from '../kiro/user-input-handler';
import {
  ExecuteCommandRequest,
  ExecuteCommandResponse,
  KiroStatusResponse
} from '../types/command-execution';

import {
  BridgeError,
  ValidationError
} from '../types/bridge-errors';

/**
 * User input request for interactive commands.
 */
interface UserInputRequest {
  /** Input value provided by user */
  value: string;
  
  /** Type of input being provided */
  type: 'text' | 'choice' | 'file' | 'confirmation';
  
  /** Execution ID this input is for */
  executionId: string;
}

/**
 * Response to user input submission.
 */
interface UserInputResponse {
  /** Whether input was accepted */
  success: boolean;
  
  /** Error message if input was rejected */
  error?: string;
  
  /** Execution ID that received input */
  executionId: string;
}

/**
 * Configuration for the API server.
 */
export interface ApiServerConfig {
  /** Port to bind the server to */
  port: number;
  
  /** Host address to bind to */
  host: string;
  
  /** API key for authentication (optional) */
  apiKey?: string;
  
  /** Request timeout in milliseconds */
  timeoutMs: number;
  
  /** Maximum request body size */
  maxBodySize: string;
  
  /** Whether to enable CORS */
  enableCors: boolean;
  
  /** Whether to enable debug logging */
  enableDebugLogging: boolean;
}

/**
 * Default configuration for the API server.
 */
export const DEFAULT_API_SERVER_CONFIG: ApiServerConfig = {
  port: 3001,
  host: 'localhost',
  timeoutMs: 30000, // 30 seconds
  maxBodySize: '10mb',
  enableCors: true,
  enableDebugLogging: false
};

/**
 * Events emitted by the ApiServer.
 */
export interface ApiServerEvents {
  'server-started': (port: number, host: string) => void;
  'server-stopped': () => void;
  'request-received': (method: string, path: string, ip: string) => void;
  'request-completed': (method: string, path: string, statusCode: number, duration: number) => void;
  'request-error': (method: string, path: string, error: Error) => void;
}

/**
 * Express.js API server for the Kiro Communication Bridge.
 * 
 * Provides REST endpoints for command execution, status queries, and user input.
 * Integrates with KiroCommandProxy, StatusMonitor, and UserInputHandler.
 */
export class ApiServer extends EventEmitter {
  private readonly config: ApiServerConfig;
  private readonly app: Express;
  private server?: Server;
  private readonly kiroProxy: KiroCommandProxy;
  private readonly statusMonitor: StatusMonitor;
  private readonly userInputHandler: UserInputHandler;

  constructor(
    config: Partial<ApiServerConfig> = {},
    kiroProxy: KiroCommandProxy,
    statusMonitor: StatusMonitor,
    userInputHandler: UserInputHandler
  ) {
    super();
    
    this.config = { ...DEFAULT_API_SERVER_CONFIG, ...config };
    this.kiroProxy = kiroProxy;
    this.statusMonitor = statusMonitor;
    this.userInputHandler = userInputHandler;
    
    this.app = express();
    this.setupMiddleware();
    this.setupRoutes();
    this.setupErrorHandling();
  }

  /**
   * Starts the API server.
   * 
   * @returns Promise that resolves when server is listening
   */
  public async start(): Promise<void> {
    if (this.server) {
      throw new Error('Server is already running');
    }

    return new Promise((resolve, reject) => {
      this.server = this.app.listen(this.config.port, this.config.host, () => {
        this.logDebug(`API server started on ${this.config.host}:${this.config.port}`);
        this.emit('server-started', this.config.port, this.config.host);
        resolve();
      });

      this.server.on('error', (error: NodeJS.ErrnoException) => {
        this.logDebug('Server error:', error);
        
        // Enhance EADDRINUSE error with more context
        if (error.code === 'EADDRINUSE') {
          const enhancedError = new Error(
            `listen EADDRINUSE: address already in use ${this.config.host}:${this.config.port}. ` +
            `Another process is already using port ${this.config.port}. This may be from another ` +
            `Kiro IDE window or a previous session that didn't close properly.`
          );
          enhancedError.name = 'EADDRINUSE';
          reject(enhancedError);
        } else {
          reject(error);
        }
      });

      // Set server timeout
      this.server.timeout = this.config.timeoutMs;
      
      // Set up graceful shutdown handlers
      this.setupGracefulShutdown();
    });
  }

  /**
   * Stops the API server.
   * 
   * @returns Promise that resolves when server is closed
   */
  public async stop(): Promise<void> {
    if (!this.server) {
      return;
    }

    return new Promise((resolve) => {
      const server = this.server!;
      this.server = undefined;
      
      // Close server and all connections
      server.close(() => {
        this.logDebug('API server stopped');
        this.emit('server-stopped');
        resolve();
      });
      
      // Force close after timeout
      setTimeout(() => {
        if (server.listening) {
          this.logDebug('Force closing API server after timeout');
          (server as any).closeAllConnections?.();
        }
        resolve();
      }, 5000);
    });
  }

  /**
   * Gets the current server status.
   * 
   * @returns Server status information
   */
  public getServerStatus(): {
    running: boolean;
    port?: number;
    host?: string;
    uptime?: number;
  } {
    return {
      running: !!this.server,
      port: this.server ? this.config.port : undefined,
      host: this.server ? this.config.host : undefined,
      uptime: this.server ? process.uptime() : undefined
    };
  }

  /**
   * Disposes of the server and cleans up resources.
   */
  public async dispose(): Promise<void> {
    await this.stop();
    this.removeAllListeners();
  }

  /**
   * Sets up Express middleware.
   */
  private setupMiddleware(): void {
    // Request logging middleware
    this.app.use((req: Request, res: Response, next: NextFunction) => {
      const startTime = Date.now();
      const clientIp = req.ip || req.connection.remoteAddress || 'unknown';
      
      this.emit('request-received', req.method, req.path, clientIp);
      this.logDebug(`${req.method} ${req.path} from ${clientIp}`);

      // Log response when finished
      res.on('finish', () => {
        const duration = Date.now() - startTime;
        this.emit('request-completed', req.method, req.path, res.statusCode, duration);
        this.logDebug(`${req.method} ${req.path} -> ${res.statusCode} (${duration}ms)`);
      });

      next();
    });

    // CORS middleware
    if (this.config.enableCors) {
      this.app.use((req: Request, res: Response, next: NextFunction) => {
        res.header('Access-Control-Allow-Origin', '*');
        res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
        res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
        
        if (req.method === 'OPTIONS') {
          res.sendStatus(200);
          return;
        }
        
        next();
      });
    }

    // Body parsing middleware
    this.app.use(express.json({ limit: this.config.maxBodySize }));
    this.app.use(express.urlencoded({ extended: true, limit: this.config.maxBodySize }));

    // Authentication middleware (if API key is configured)
    if (this.config.apiKey) {
      this.app.use((req: Request, res: Response, next: NextFunction) => {
        const authHeader = req.headers.authorization;
        const apiKey = authHeader?.replace('Bearer ', '') || req.query.apiKey as string;

        if (!apiKey || apiKey !== this.config.apiKey) {
          res.status(401).json({
            error: 'Unauthorized',
            message: 'Valid API key required'
          });
          return;
        }

        next();
      });
    }

    // Request timeout middleware
    this.app.use((req: Request, res: Response, next: NextFunction) => {
      res.setTimeout(this.config.timeoutMs, () => {
        res.status(408).json({
          error: 'Request Timeout',
          message: 'Request timed out'
        });
      });
      next();
    });
  }

  /**
   * Sets up API routes.
   */
  private setupRoutes(): void {
    // Health check endpoint
    this.app.get('/health', (req: Request, res: Response) => {
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        server: this.getServerStatus()
      });
    });

    // Command execution endpoint
    this.app.post('/api/kiro/execute', async (req: Request, res: Response, next: NextFunction) => {
      try {
        await this.handleExecuteCommand(req, res);
      } catch (error) {
        next(error);
      }
    });

    // Status query endpoint
    this.app.get('/api/kiro/status', async (req: Request, res: Response, next: NextFunction) => {
      try {
        await this.handleGetStatus(req, res);
      } catch (error) {
        next(error);
      }
    });

    // User input endpoint
    this.app.post('/api/kiro/input', async (req: Request, res: Response, next: NextFunction) => {
      try {
        await this.handleUserInput(req, res);
      } catch (error) {
        next(error);
      }
    });

    // 404 handler for unknown routes
    this.app.use('*', (req: Request, res: Response) => {
      res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.originalUrl} not found`
      });
    });
  }

  /**
   * Sets up error handling middleware.
   */
  private setupErrorHandling(): void {
    this.app.use((error: Error, req: Request, res: Response, next: NextFunction) => {
      this.emit('request-error', req.method, req.path, error);
      this.logDebug('Request error:', error);

      // Handle different types of errors
      if (error instanceof BridgeError) {
        const clientInfo = error.toClientInfo();
        res.status(this.getHttpStatusForError(error)).json(clientInfo);
        return;
      }

      if (error instanceof SyntaxError && 'body' in error) {
        res.status(400).json({
          error: 'Bad Request',
          message: 'Invalid JSON in request body'
        });
        return;
      }

      // Generic error response
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'An unexpected error occurred'
      });
    });
  }

  /**
   * Handles command execution requests.
   */
  private async handleExecuteCommand(req: Request, res: Response): Promise<void> {
    const requestData = req.body as ExecuteCommandRequest;

    // Validate request
    if (!requestData.command || typeof requestData.command !== 'string') {
      throw new ValidationError('Command is required and must be a string', {
        field: 'command',
        value: requestData.command
      });
    }

    if (requestData.args && !Array.isArray(requestData.args)) {
      throw new ValidationError('Args must be an array', {
        field: 'args',
        value: requestData.args
      });
    }

    if (requestData.workspacePath && typeof requestData.workspacePath !== 'string') {
      throw new ValidationError('WorkspacePath must be a string', {
        field: 'workspacePath',
        value: requestData.workspacePath
      });
    }

    // Execute command
    const result = await this.kiroProxy.executeCommand(
      requestData.command,
      requestData.args || [],
      requestData.workspacePath
    );

    const response: ExecuteCommandResponse = {
      success: result.success,
      output: result.output,
      error: result.error,
      executionTimeMs: result.executionTimeMs
    };

    res.json(response);
  }

  /**
   * Handles status query requests.
   */
  private async handleGetStatus(req: Request, res: Response): Promise<void> {
    const statusResponse = this.statusMonitor.getStatusResponse();
    res.json(statusResponse);
  }

  /**
   * Handles user input requests.
   */
  private async handleUserInput(req: Request, res: Response): Promise<void> {
    const inputData = req.body as UserInputRequest;

    // Validate request
    if (!inputData.value || typeof inputData.value !== 'string') {
      throw new ValidationError('Value is required and must be a string', {
        field: 'value',
        value: inputData.value
      });
    }

    if (!inputData.executionId || typeof inputData.executionId !== 'string') {
      throw new ValidationError('ExecutionId is required and must be a string', {
        field: 'executionId',
        value: inputData.executionId
      });
    }

    const validTypes = ['text', 'choice', 'file', 'confirmation'];
    if (!inputData.type || !validTypes.includes(inputData.type)) {
      throw new ValidationError(`Type must be one of: ${validTypes.join(', ')}`, {
        field: 'type',
        value: inputData.type
      });
    }

    // Forward to user input handler
    const response = this.userInputHandler.provideUserInput(
      inputData.executionId,
      inputData.value
    );

    res.json(response);
  }

  /**
   * Maps BridgeError types to HTTP status codes.
   */
  private getHttpStatusForError(error: BridgeError): number {
    switch (error.code) {
      case 'VALIDATION_FAILED':
        return 400;
      case 'KIRO_UNAVAILABLE':
        return 503;
      case 'OPERATION_TIMEOUT':
        return 408;
      case 'COMMAND_EXECUTION_FAILED':
        return 422;
      case 'CONFIGURATION_ERROR':
        return 500;
      default:
        return 500;
    }
  }

  /**
   * Sets up graceful shutdown handlers for the server.
   * 
   * This method ensures that the server can be properly closed when
   * the extension is deactivated or when port conflicts need to be resolved.
   */
  private setupGracefulShutdown(): void {
    if (!this.server) {
      return;
    }

    // Track active connections for graceful shutdown
    const connections = new Set<any>();
    
    this.server.on('connection', (connection) => {
      connections.add(connection);
      
      connection.on('close', () => {
        connections.delete(connection);
      });
    });

    // Store reference to connections for forced shutdown
    (this.server as any)._connections = connections;
    
    // Add method to close all connections
    (this.server as any).closeAllConnections = () => {
      for (const connection of connections) {
        connection.destroy();
      }
      connections.clear();
    };
  }

  /**
   * Logs debug messages if debug logging is enabled.
   */
  private logDebug(message: string, ...args: any[]): void {
    if (this.config.enableDebugLogging) {
      console.debug(`[ApiServer] ${message}`, ...args);
    }
  }
}