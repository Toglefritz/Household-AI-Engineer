/**
 * WebSocket server for the Kiro Communication Bridge.
 * 
 * This module provides real-time communication capabilities between
 * the bridge and connected clients for command execution updates,
 * status changes, and user input requests.
 */

import { EventEmitter } from 'events';
import { Server as HttpServer, createServer } from 'http';
import { WebSocketServer as WSServer, WebSocket } from 'ws';
import { KiroCommandProxy } from '../kiro/kiro-command-proxy';
import { StatusMonitor } from '../kiro/status-monitor';
import { UserInputHandler } from '../kiro/user-input-handler';
import {
  WebSocketEvent,
  UserInputRequest,
  WebSocketValidation
} from '../types/websocket-events';
import {
  ValidationError,
  WebSocketError
} from '../types/bridge-errors';

/**
 * Configuration for the WebSocket server.
 */
export interface WebSocketServerConfig {
  /** Port to bind the server to */
  port: number;
  
  /** Maximum number of concurrent connections */
  maxConnections: number;
  
  /** Whether to enable debug logging */
  enableDebugLogging: boolean;
}

/**
 * Default configuration for the WebSocket server.
 */
export const DEFAULT_WEBSOCKET_SERVER_CONFIG: WebSocketServerConfig = {
  port: 3002,
  maxConnections: 10,
  enableDebugLogging: false
};

/**
 * Events emitted by the WebSocketServer.
 */
export interface WebSocketServerEvents {
  'server-started': (port: number) => void;
  'server-stopped': () => void;
  'client-connected': (clientId: string, clientInfo: any) => void;
  'client-disconnected': (clientId: string, reason: string) => void;
  'message-received': (clientId: string, message: any) => void;
  'message-sent': (clientId: string, message: any) => void;
  'broadcast-sent': (message: any, clientCount: number) => void;
}

/**
 * Represents a connected WebSocket client.
 */
interface WebSocketClient {
  /** Unique client identifier */
  id: string;
  
  /** WebSocket connection */
  socket: WebSocket;
  
  /** Connection timestamp */
  connectedAt: Date;
  
  /** Client information */
  info: {
    userAgent?: string;
    remoteAddress?: string;
  };
  
  /** Whether client is authenticated */
  authenticated: boolean;
}

/**
 * WebSocket server for real-time communication with Kiro Communication Bridge.
 * 
 * Provides real-time updates for command execution, status changes, and
 * handles user input requests from connected clients.
 */
export class WebSocketServer extends EventEmitter {
  private readonly config: WebSocketServerConfig;
  private httpServer?: HttpServer;
  private wsServer?: WSServer;
  private readonly clients = new Map<string, WebSocketClient>();
  private clientCounter = 0;
  private readonly kiroProxy: KiroCommandProxy;
  private readonly statusMonitor: StatusMonitor;
  private readonly userInputHandler: UserInputHandler;

  constructor(
    config: Partial<WebSocketServerConfig> = {},
    kiroProxy: KiroCommandProxy,
    statusMonitor: StatusMonitor,
    userInputHandler: UserInputHandler
  ) {
    super();
    
    this.config = { ...DEFAULT_WEBSOCKET_SERVER_CONFIG, ...config };
    this.kiroProxy = kiroProxy;
    this.statusMonitor = statusMonitor;
    this.userInputHandler = userInputHandler;
  }

  /**
   * Starts the WebSocket server.
   * 
   * @returns Promise that resolves when server is listening
   */
  public async start(): Promise<void> {
    if (this.httpServer) {
      throw new Error('WebSocket server is already running');
    }

    return new Promise((resolve, reject) => {
      // Create HTTP server
      this.httpServer = createServer();
      
      // Create WebSocket server
      this.wsServer = new WSServer({ 
        server: this.httpServer,
        maxPayload: 1024 * 1024 // 1MB max payload
      });

      // Set up WebSocket server event handlers
      this.setupWebSocketHandlers();

      // Start HTTP server
      this.httpServer.listen(this.config.port, () => {
        this.logDebug(`WebSocket server started on port ${this.config.port}`);
        this.emit('server-started', this.config.port);
        resolve();
      });

      this.httpServer.on('error', (error) => {
        this.logDebug('WebSocket server error:', error);
        reject(error);
      });
    });
  }

  /**
   * Stops the WebSocket server.
   * 
   * @returns Promise that resolves when server is closed
   */
  public async stop(): Promise<void> {
    if (!this.httpServer || !this.wsServer) {
      return;
    }

    // Close all client connections
    for (const client of this.clients.values()) {
      client.socket.close(1001, 'Server shutting down');
    }
    this.clients.clear();

    // Close WebSocket server
    this.wsServer.close();

    // Close HTTP server
    return new Promise((resolve) => {
      this.httpServer!.close(() => {
        this.httpServer = undefined;
        this.wsServer = undefined;
        this.logDebug('WebSocket server stopped');
        this.emit('server-stopped');
        resolve();
      });
    });
  }

  /**
   * Broadcasts an event to all connected clients.
   * 
   * @param event - Event to broadcast
   */
  public broadcastEvent(event: WebSocketEvent): void {
    if (!this.wsServer) {
      this.logDebug('Cannot broadcast: WebSocket server not running');
      return;
    }

    const message = JSON.stringify(event);
    let sentCount = 0;

    for (const client of this.clients.values()) {
      if (client.socket.readyState === WebSocket.OPEN) {
        try {
          client.socket.send(message);
          sentCount++;
          this.emit('message-sent', client.id, event);
        } catch (error) {
          this.logDebug(`Failed to send message to client ${client.id}:`, error);
        }
      }
    }

    this.emit('broadcast-sent', event, sentCount);
    this.logDebug(`Broadcasted event to ${sentCount} clients:`, event.type);
  }

  /**
   * Sends an event to a specific client.
   * 
   * @param clientId - ID of the client to send to
   * @param event - Event to send
   * @returns True if message was sent successfully
   */
  public sendEventToClient(clientId: string, event: WebSocketEvent): boolean {
    const client = this.clients.get(clientId);
    if (!client || client.socket.readyState !== WebSocket.OPEN) {
      return false;
    }

    try {
      const message = JSON.stringify(event);
      client.socket.send(message);
      this.emit('message-sent', clientId, event);
      return true;
    } catch (error) {
      this.logDebug(`Failed to send message to client ${clientId}:`, error);
      return false;
    }
  }

  /**
   * Gets information about connected clients.
   * 
   * @returns Array of client information
   */
  public getConnectedClients(): Array<{
    id: string;
    connectedAt: string;
    authenticated: boolean;
    info: any;
  }> {
    return Array.from(this.clients.values()).map(client => ({
      id: client.id,
      connectedAt: client.connectedAt.toISOString(),
      authenticated: client.authenticated,
      info: client.info
    }));
  }

  /**
   * Gets the number of connected clients.
   * 
   * @returns Number of connected clients
   */
  public getClientCount(): number {
    return this.clients.size;
  }

  /**
   * Disposes of the server and cleans up resources.
   */
  public async dispose(): Promise<void> {
    await this.stop();
    this.removeAllListeners();
  }

  /**
   * Sets up WebSocket server event handlers.
   */
  private setupWebSocketHandlers(): void {
    if (!this.wsServer) {
      return;
    }

    this.wsServer.on('connection', (socket, request) => {
      this.handleClientConnection(socket, request);
    });

    this.wsServer.on('error', (error) => {
      this.logDebug('WebSocket server error:', error);
    });
  }

  /**
   * Handles new client connections.
   */
  private handleClientConnection(socket: WebSocket, request: any): void {
    // Check connection limit
    if (this.clients.size >= this.config.maxConnections) {
      socket.close(1013, 'Maximum connections exceeded');
      return;
    }

    // Create client
    const clientId = this.generateClientId();
    const client: WebSocketClient = {
      id: clientId,
      socket,
      connectedAt: new Date(),
      info: {
        userAgent: request.headers['user-agent'],
        remoteAddress: request.socket.remoteAddress
      },
      authenticated: true // For now, all connections are authenticated
    };

    this.clients.set(clientId, client);
    this.emit('client-connected', clientId, client.info);
    this.logDebug(`Client connected: ${clientId} (${this.clients.size}/${this.config.maxConnections})`);

    // Send connection ready event
    this.sendEventToClient(clientId, {
      type: 'connection-ready',
      timestamp: new Date().toISOString(),
      serverInfo: {
        version: '1.0.0',
        features: ['command-execution', 'status-monitoring', 'user-input']
      }
    });

    // Set up client event handlers
    socket.on('message', (data) => {
      this.handleClientMessage(clientId, data);
    });

    socket.on('close', (code, reason) => {
      this.handleClientDisconnection(clientId, `${code}: ${reason}`);
    });

    socket.on('error', (error) => {
      this.logDebug(`Client ${clientId} error:`, error);
      this.handleClientDisconnection(clientId, `Error: ${error.message}`);
    });

    // Set up ping/pong for connection health
    socket.on('pong', () => {
      // Client is alive
    });

    // Send periodic pings
    const pingInterval = setInterval(() => {
      if (socket.readyState === WebSocket.OPEN) {
        socket.ping();
      } else {
        clearInterval(pingInterval);
      }
    }, 30000); // Ping every 30 seconds
  }

  /**
   * Handles messages from clients.
   */
  private handleClientMessage(clientId: string, data: any): void {
    const client = this.clients.get(clientId);
    if (!client) {
      return;
    }

    try {
      const message = JSON.parse(data.toString());
      this.emit('message-received', clientId, message);
      this.logDebug(`Message from client ${clientId}:`, message);

      // Handle different message types
      if (message.type === 'user-input') {
        this.handleUserInputMessage(clientId, message);
      } else {
        this.logDebug(`Unknown message type from client ${clientId}: ${message.type}`);
      }

    } catch (error) {
      this.logDebug(`Invalid message from client ${clientId}:`, error);
      this.sendEventToClient(clientId, {
        type: 'error',
        timestamp: new Date().toISOString(),
        error: 'Invalid message format'
      } as any);
    }
  }

  /**
   * Handles user input messages from clients.
   */
  private handleUserInputMessage(clientId: string, message: any): void {
    try {
      // Validate user input request
      if (!WebSocketValidation.isValidUserInputRequest(message)) {
        throw new ValidationError('Invalid user input request format', {
          field: 'message',
          value: message
        });
      }

      const inputRequest = message as UserInputRequest;
      
      // Forward to user input handler
      const response = this.userInputHandler.provideUserInput(
        inputRequest.executionId,
        inputRequest.value
      );

      // Send response back to client
      this.sendEventToClient(clientId, {
        type: 'input-response',
        timestamp: new Date().toISOString(),
        success: response.success,
        error: response.error,
        executionId: response.executionId
      } as any);

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.logDebug(`Error handling user input from client ${clientId}:`, error);
      
      this.sendEventToClient(clientId, {
        type: 'input-response',
        timestamp: new Date().toISOString(),
        success: false,
        error: errorMessage,
        executionId: ''
      } as any);
    }
  }

  /**
   * Handles client disconnections.
   */
  private handleClientDisconnection(clientId: string, reason: string): void {
    const client = this.clients.get(clientId);
    if (client) {
      this.clients.delete(clientId);
      this.emit('client-disconnected', clientId, reason);
      this.logDebug(`Client disconnected: ${clientId} - ${reason} (${this.clients.size}/${this.config.maxConnections})`);
    }
  }

  /**
   * Generates a unique client ID.
   */
  private generateClientId(): string {
    return `client-${Date.now()}-${++this.clientCounter}`;
  }

  /**
   * Logs debug messages if debug logging is enabled.
   */
  private logDebug(message: string, ...args: any[]): void {
    if (this.config.enableDebugLogging) {
      console.debug(`[WebSocketServer] ${message}`, ...args);
    }
  }
}