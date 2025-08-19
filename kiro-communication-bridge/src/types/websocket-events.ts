/**
 * WebSocket event interfaces for the Kiro Communication Bridge.
 * 
 * This module defines the event types and payloads used for real-time
 * communication between the bridge and connected clients.
 */

/**
 * Base interface for all WebSocket events.
 */
export interface BaseWebSocketEvent {
  /** Event type identifier */
  type: string;
  
  /** Timestamp when event was created */
  timestamp: string;
  
  /** Optional event ID for tracking */
  eventId?: string;
}

/**
 * Event emitted when a command starts executing.
 */
export interface CommandStartedEvent extends BaseWebSocketEvent {
  type: 'command-started';
  
  /** Command that started */
  command: string;
  
  /** Command arguments */
  args: string[];
  
  /** Execution ID for tracking */
  executionId: string;
}

/**
 * Event emitted when command produces output.
 */
export interface CommandOutputEvent extends BaseWebSocketEvent {
  type: 'command-output';
  
  /** Output text from the command */
  output: string;
  
  /** Execution ID this output belongs to */
  executionId: string;
  
  /** Whether this is stdout or stderr */
  stream: 'stdout' | 'stderr';
}

/**
 * Event emitted when a command completes.
 */
export interface CommandCompletedEvent extends BaseWebSocketEvent {
  type: 'command-completed';
  
  /** Whether command completed successfully */
  success: boolean;
  
  /** Final output from the command */
  output: string;
  
  /** Execution ID that completed */
  executionId: string;
  
  /** Exit code if available */
  exitCode?: number;
  
  /** Total execution time in milliseconds */
  executionTimeMs: number;
}

/**
 * Event emitted when a command encounters an error.
 */
export interface CommandErrorEvent extends BaseWebSocketEvent {
  type: 'command-error';
  
  /** Error message */
  error: string;
  
  /** Execution ID that failed */
  executionId: string;
  
  /** Error code if available */
  errorCode?: string;
  
  /** Whether the error is recoverable */
  recoverable: boolean;
}

/**
 * Event emitted when user input is required.
 */
export interface UserInputRequiredEvent extends BaseWebSocketEvent {
  type: 'user-input-required';
  
  /** Question or prompt for the user */
  prompt: string;
  
  /** Type of input expected */
  inputType: 'text' | 'choice' | 'file' | 'confirmation';
  
  /** Available choices for choice-type inputs */
  choices?: string[];
  
  /** Execution ID waiting for input */
  executionId: string;
  
  /** Timeout for input in milliseconds */
  timeoutMs?: number;
}

/**
 * Event emitted when user input is accepted.
 */
export interface InputAcceptedEvent extends BaseWebSocketEvent {
  type: 'input-accepted';
  
  /** Execution ID that received input */
  executionId: string;
  
  /** Input value provided */
  inputValue: string;
}

/**
 * Event emitted when Kiro status changes.
 */
export interface StatusChangedEvent extends BaseWebSocketEvent {
  type: 'status-changed';
  
  /** New Kiro status */
  status: 'ready' | 'busy' | 'unavailable';
  
  /** Currently executing command if busy */
  currentCommand?: string;
  
  /** Previous status */
  previousStatus?: 'ready' | 'busy' | 'unavailable';
}

/**
 * Event emitted when WebSocket connection is established.
 */
export interface ConnectionReadyEvent extends BaseWebSocketEvent {
  type: 'connection-ready';
  
  /** Server information */
  serverInfo: {
    /** Server version */
    version: string;
    
    /** Supported features */
    features: string[];
  };
}

/**
 * Union type for all WebSocket events.
 */
export type WebSocketEvent = 
  | CommandStartedEvent
  | CommandOutputEvent
  | CommandCompletedEvent
  | CommandErrorEvent
  | UserInputRequiredEvent
  | InputAcceptedEvent
  | StatusChangedEvent
  | ConnectionReadyEvent;

/**
 * User input request for interactive commands.
 */
export interface UserInputRequest {
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
export interface UserInputResponse {
  /** Whether input was accepted */
  success: boolean;
  
  /** Error message if input was rejected */
  error?: string;
  
  /** Execution ID that received input */
  executionId: string;
}

/**
 * Validation functions for WebSocket events and payloads.
 */
export const WebSocketValidation = {
  /**
   * Validates a WebSocket event structure.
   */
  isValidWebSocketEvent(obj: unknown): obj is WebSocketEvent {
    if (typeof obj !== 'object' || obj === null) {
      return false;
    }
    
    const event = obj as Record<string, unknown>;
    
    // All events must have type and timestamp
    if (typeof event.type !== 'string' || typeof event.timestamp !== 'string') {
      return false;
    }
    
    // Validate specific event types
    switch (event.type) {
      case 'command-started':
        return this.isValidCommandStartedEvent(event);
      case 'command-output':
        return this.isValidCommandOutputEvent(event);
      case 'command-completed':
        return this.isValidCommandCompletedEvent(event);
      case 'command-error':
        return this.isValidCommandErrorEvent(event);
      case 'user-input-required':
        return this.isValidUserInputRequiredEvent(event);
      case 'input-accepted':
        return this.isValidInputAcceptedEvent(event);
      case 'status-changed':
        return this.isValidStatusChangedEvent(event);
      case 'connection-ready':
        return this.isValidConnectionReadyEvent(event);
      default:
        return false;
    }
  },

  /**
   * Validates a UserInputRequest.
   */
  isValidUserInputRequest(obj: unknown): obj is UserInputRequest {
    if (typeof obj !== 'object' || obj === null) {
      return false;
    }
    
    const req = obj as Record<string, unknown>;
    const validTypes = ['text', 'choice', 'file', 'confirmation'];
    
    return (
      typeof req.value === 'string' &&
      validTypes.includes(req.type as string) &&
      typeof req.executionId === 'string'
    );
  },

  // Private validation methods for specific event types
  private isValidCommandStartedEvent(event: Record<string, unknown>): boolean {
    return (
      typeof event.command === 'string' &&
      Array.isArray(event.args) &&
      event.args.every(arg => typeof arg === 'string') &&
      typeof event.executionId === 'string'
    );
  },

  private isValidCommandOutputEvent(event: Record<string, unknown>): boolean {
    return (
      typeof event.output === 'string' &&
      typeof event.executionId === 'string' &&
      (event.stream === 'stdout' || event.stream === 'stderr')
    );
  },

  private isValidCommandCompletedEvent(event: Record<string, unknown>): boolean {
    return (
      typeof event.success === 'boolean' &&
      typeof event.output === 'string' &&
      typeof event.executionId === 'string' &&
      typeof event.executionTimeMs === 'number' &&
      (event.exitCode === undefined || typeof event.exitCode === 'number')
    );
  },

  private isValidCommandErrorEvent(event: Record<string, unknown>): boolean {
    return (
      typeof event.error === 'string' &&
      typeof event.executionId === 'string' &&
      typeof event.recoverable === 'boolean' &&
      (event.errorCode === undefined || typeof event.errorCode === 'string')
    );
  },

  private isValidUserInputRequiredEvent(event: Record<string, unknown>): boolean {
    const validInputTypes = ['text', 'choice', 'file', 'confirmation'];
    return (
      typeof event.prompt === 'string' &&
      validInputTypes.includes(event.inputType as string) &&
      typeof event.executionId === 'string' &&
      (event.choices === undefined || (Array.isArray(event.choices) && 
        event.choices.every(choice => typeof choice === 'string'))) &&
      (event.timeoutMs === undefined || typeof event.timeoutMs === 'number')
    );
  },

  private isValidInputAcceptedEvent(event: Record<string, unknown>): boolean {
    return (
      typeof event.executionId === 'string' &&
      typeof event.inputValue === 'string'
    );
  },

  private isValidStatusChangedEvent(event: Record<string, unknown>): boolean {
    const validStatuses = ['ready', 'busy', 'unavailable'];
    return (
      validStatuses.includes(event.status as string) &&
      (event.currentCommand === undefined || typeof event.currentCommand === 'string') &&
      (event.previousStatus === undefined || validStatuses.includes(event.previousStatus as string))
    );
  },

  private isValidConnectionReadyEvent(event: Record<string, unknown>): boolean {
    return (
      typeof event.serverInfo === 'object' &&
      event.serverInfo !== null &&
      typeof (event.serverInfo as any).version === 'string' &&
      Array.isArray((event.serverInfo as any).features) &&
      (event.serverInfo as any).features.every((feature: unknown) => typeof feature === 'string')
    );
  }
};