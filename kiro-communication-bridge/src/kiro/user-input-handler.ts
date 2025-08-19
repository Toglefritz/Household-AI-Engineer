/**
 * User input handling system for the Kiro Communication Bridge.
 * 
 * This module manages user input requests from Kiro commands, forwards them
 * to connected clients, and handles the responses. It provides a bridge for
 * interactive command execution.
 */

import { EventEmitter } from 'events';
import {
  UserInputRequest,
  UserInputResponse
} from '../types/websocket-events';
import {
  ValidationError,
  TimeoutError
} from '../types/bridge-errors';

/**
 * Configuration for user input handling.
 */
export interface UserInputHandlerConfig {
  /** Default timeout for user input in milliseconds */
  defaultTimeoutMs: number;
  
  /** Maximum number of pending input requests */
  maxPendingRequests: number;
  
  /** Whether to enable debug logging */
  enableDebugLogging: boolean;
}

/**
 * Default configuration for user input handling.
 */
export const DEFAULT_USER_INPUT_CONFIG: UserInputHandlerConfig = {
  defaultTimeoutMs: 300000, // 5 minutes
  maxPendingRequests: 10,
  enableDebugLogging: false
};

/**
 * Represents a pending user input request.
 */
export interface PendingInputRequest {
  /** Unique request ID */
  id: string;
  
  /** Execution ID this input is for */
  executionId: string;
  
  /** Question or prompt for the user */
  prompt: string;
  
  /** Type of input expected */
  inputType: 'text' | 'choice' | 'file' | 'confirmation';
  
  /** Available choices for choice-type inputs */
  choices?: string[];
  
  /** Timestamp when request was created */
  createdAt: Date;
  
  /** Timeout for this request in milliseconds */
  timeoutMs: number;
  
  /** Timeout handle */
  timeoutHandle: NodeJS.Timeout;
  
  /** Promise resolver for the input */
  resolve: (value: string) => void;
  
  /** Promise rejector for the input */
  reject: (error: Error) => void;
}

/**
 * Events emitted by the UserInputHandler.
 */
export interface UserInputHandlerEvents {
  'input-required': (request: PendingInputRequest) => void;
  'input-received': (requestId: string, value: string) => void;
  'input-timeout': (requestId: string, request: PendingInputRequest) => void;
  'input-cancelled': (requestId: string, reason: string) => void;
}

/**
 * User input handler for managing interactive command execution.
 * 
 * Handles the flow of user input requests from Kiro commands to the frontend
 * and back, with timeout management and validation.
 */
export class UserInputHandler extends EventEmitter {
  private readonly config: UserInputHandlerConfig;
  private readonly pendingRequests = new Map<string, PendingInputRequest>();
  private requestCounter = 0;

  constructor(config: Partial<UserInputHandlerConfig> = {}) {
    super();
    this.config = { ...DEFAULT_USER_INPUT_CONFIG, ...config };
  }

  /**
   * Requests user input for a command execution.
   * 
   * @param executionId - ID of the command execution requesting input
   * @param prompt - Question or prompt to display to the user
   * @param inputType - Type of input expected
   * @param options - Additional options for the input request
   * @returns Promise that resolves to the user's input
   */
  public async requestUserInput(
    executionId: string,
    prompt: string,
    inputType: 'text' | 'choice' | 'file' | 'confirmation',
    options: {
      choices?: string[];
      timeoutMs?: number;
    } = {}
  ): Promise<string> {
    // Validate inputs
    this.validateInputRequest(executionId, prompt, inputType, options);

    // Check if we've reached the maximum pending requests
    if (this.pendingRequests.size >= this.config.maxPendingRequests) {
      throw new ValidationError(
        `Maximum pending input requests limit reached (${this.config.maxPendingRequests})`,
        { field: 'pendingRequests', rule: 'limit' }
      );
    }

    const requestId = this.generateRequestId();
    const timeoutMs = options.timeoutMs || this.config.defaultTimeoutMs;

    return new Promise<string>((resolve, reject) => {
      // Create timeout handler
      const timeoutHandle = setTimeout(() => {
        this.handleInputTimeout(requestId);
      }, timeoutMs);

      // Create pending request
      const request: PendingInputRequest = {
        id: requestId,
        executionId,
        prompt,
        inputType,
        choices: options.choices,
        createdAt: new Date(),
        timeoutMs,
        timeoutHandle,
        resolve,
        reject
      };

      // Store the request
      this.pendingRequests.set(requestId, request);

      // Emit event for external handlers (WebSocket server, etc.)
      this.emit('input-required', request);

      this.logDebug(`User input requested: ${requestId} for execution ${executionId}`);
    });
  }

  /**
   * Provides user input for a pending request.
   * 
   * @param requestId - ID of the input request
   * @param value - User's input value
   * @returns Response indicating success or failure
   */
  public provideUserInput(requestId: string, value: string): UserInputResponse {
    const request = this.pendingRequests.get(requestId);
    
    if (!request) {
      return {
        success: false,
        error: `No pending input request found with ID: ${requestId}`,
        executionId: ''
      };
    }

    try {
      // Validate the input value
      this.validateInputValue(request, value);

      // Clean up the request
      this.cleanupRequest(requestId);

      // Resolve the promise
      request.resolve(value);

      // Emit success event
      this.emit('input-received', requestId, value);

      this.logDebug(`User input received: ${requestId} = "${value}"`);

      return {
        success: true,
        executionId: request.executionId
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      
      this.logDebug(`Invalid user input for ${requestId}: ${errorMessage}`);

      return {
        success: false,
        error: errorMessage,
        executionId: request.executionId
      };
    }
  }

  /**
   * Cancels a pending input request.
   * 
   * @param requestId - ID of the request to cancel
   * @param reason - Reason for cancellation
   * @returns True if request was cancelled successfully
   */
  public cancelInputRequest(requestId: string, reason: string = 'Cancelled by system'): boolean {
    const request = this.pendingRequests.get(requestId);
    
    if (!request) {
      return false;
    }

    // Clean up the request
    this.cleanupRequest(requestId);

    // Reject the promise
    request.reject(new Error(`Input request cancelled: ${reason}`));

    // Emit cancellation event
    this.emit('input-cancelled', requestId, reason);

    this.logDebug(`User input cancelled: ${requestId} - ${reason}`);

    return true;
  }

  /**
   * Cancels all pending input requests for a specific execution.
   * 
   * @param executionId - ID of the execution to cancel inputs for
   * @param reason - Reason for cancellation
   * @returns Number of requests cancelled
   */
  public cancelExecutionInputs(executionId: string, reason: string = 'Execution cancelled'): number {
    let cancelledCount = 0;

    for (const [requestId, request] of this.pendingRequests.entries()) {
      if (request.executionId === executionId) {
        if (this.cancelInputRequest(requestId, reason)) {
          cancelledCount++;
        }
      }
    }

    this.logDebug(`Cancelled ${cancelledCount} input requests for execution ${executionId}`);

    return cancelledCount;
  }

  /**
   * Gets information about all pending input requests.
   * 
   * @returns Array of pending request information
   */
  public getPendingRequests(): Array<Omit<PendingInputRequest, 'resolve' | 'reject' | 'timeoutHandle'>> {
    return Array.from(this.pendingRequests.values()).map(request => ({
      id: request.id,
      executionId: request.executionId,
      prompt: request.prompt,
      inputType: request.inputType,
      choices: request.choices,
      createdAt: request.createdAt,
      timeoutMs: request.timeoutMs
    }));
  }

  /**
   * Gets information about a specific pending request.
   * 
   * @param requestId - ID of the request
   * @returns Request information or undefined if not found
   */
  public getPendingRequest(requestId: string): Omit<PendingInputRequest, 'resolve' | 'reject' | 'timeoutHandle'> | undefined {
    const request = this.pendingRequests.get(requestId);
    if (!request) {
      return undefined;
    }

    return {
      id: request.id,
      executionId: request.executionId,
      prompt: request.prompt,
      inputType: request.inputType,
      choices: request.choices,
      createdAt: request.createdAt,
      timeoutMs: request.timeoutMs
    };
  }

  /**
   * Checks if there are any pending input requests for an execution.
   * 
   * @param executionId - ID of the execution to check
   * @returns True if there are pending requests
   */
  public hasPendingInputs(executionId: string): boolean {
    for (const request of this.pendingRequests.values()) {
      if (request.executionId === executionId) {
        return true;
      }
    }
    return false;
  }

  /**
   * Gets the number of pending input requests.
   * 
   * @returns Number of pending requests
   */
  public getPendingRequestCount(): number {
    return this.pendingRequests.size;
  }

  /**
   * Disposes of the handler and cleans up all resources.
   */
  public dispose(): void {
    // Cancel all pending requests
    const pendingIds = Array.from(this.pendingRequests.keys());
    for (const requestId of pendingIds) {
      this.cancelInputRequest(requestId, 'Handler disposed');
    }

    // Remove all listeners
    this.removeAllListeners();

    this.logDebug('UserInputHandler disposed');
  }

  /**
   * Validates an input request.
   */
  private validateInputRequest(
    executionId: string,
    prompt: string,
    inputType: string,
    options: { choices?: string[]; timeoutMs?: number }
  ): void {
    if (!executionId || typeof executionId !== 'string') {
      throw new ValidationError('Execution ID must be a non-empty string', {
        field: 'executionId',
        value: executionId,
        rule: 'required'
      });
    }

    if (!prompt || typeof prompt !== 'string') {
      throw new ValidationError('Prompt must be a non-empty string', {
        field: 'prompt',
        value: prompt,
        rule: 'required'
      });
    }

    const validInputTypes = ['text', 'choice', 'file', 'confirmation'];
    if (!validInputTypes.includes(inputType)) {
      throw new ValidationError(`Input type must be one of: ${validInputTypes.join(', ')}`, {
        field: 'inputType',
        value: inputType,
        rule: 'enum'
      });
    }

    if (inputType === 'choice' && (!options.choices || !Array.isArray(options.choices) || options.choices.length === 0)) {
      throw new ValidationError('Choices must be provided for choice input type', {
        field: 'choices',
        value: options.choices,
        rule: 'required'
      });
    }

    if (options.timeoutMs !== undefined && (typeof options.timeoutMs !== 'number' || options.timeoutMs <= 0)) {
      throw new ValidationError('Timeout must be a positive number', {
        field: 'timeoutMs',
        value: options.timeoutMs,
        rule: 'positive'
      });
    }
  }

  /**
   * Validates user input value against the request requirements.
   */
  private validateInputValue(request: PendingInputRequest, value: string): void {
    if (typeof value !== 'string') {
      throw new ValidationError('Input value must be a string', {
        field: 'value',
        value: value,
        rule: 'type'
      });
    }

    switch (request.inputType) {
      case 'text':
        if (value.trim() === '') {
          throw new ValidationError('Text input cannot be empty', {
            field: 'value',
            value: value,
            rule: 'required'
          });
        }
        break;

      case 'choice':
        if (!request.choices || !request.choices.includes(value)) {
          throw new ValidationError(
            `Input must be one of: ${request.choices?.join(', ') || 'none'}`,
            {
              field: 'value',
              value: value,
              rule: 'enum'
            }
          );
        }
        break;

      case 'confirmation':
        const validConfirmations = ['yes', 'no', 'y', 'n', 'true', 'false'];
        if (!validConfirmations.includes(value.toLowerCase())) {
          throw new ValidationError(
            `Confirmation must be one of: ${validConfirmations.join(', ')}`,
            {
              field: 'value',
              value: value,
              rule: 'enum'
            }
          );
        }
        break;

      case 'file':
        // Basic file path validation
        if (value.trim() === '' || value.includes('\0')) {
          throw new ValidationError('Invalid file path', {
            field: 'value',
            value: value,
            rule: 'format'
          });
        }
        break;
    }
  }

  /**
   * Handles input request timeout.
   */
  private handleInputTimeout(requestId: string): void {
    const request = this.pendingRequests.get(requestId);
    if (!request) {
      return;
    }

    // Clean up the request
    this.cleanupRequest(requestId);

    // Create timeout error
    const elapsedMs = Date.now() - request.createdAt.getTime();
    const timeoutError = new TimeoutError(
      'user-input',
      request.timeoutMs,
      elapsedMs,
      {
        requestId,
        executionId: request.executionId,
        prompt: request.prompt
      }
    );

    // Reject the promise
    request.reject(timeoutError);

    // Emit timeout event
    this.emit('input-timeout', requestId, request);

    this.logDebug(`User input timed out: ${requestId} after ${elapsedMs}ms`);
  }

  /**
   * Cleans up a request and its resources.
   */
  private cleanupRequest(requestId: string): void {
    const request = this.pendingRequests.get(requestId);
    if (request) {
      clearTimeout(request.timeoutHandle);
      this.pendingRequests.delete(requestId);
    }
  }

  /**
   * Generates a unique request ID.
   */
  private generateRequestId(): string {
    return `input-${Date.now()}-${++this.requestCounter}`;
  }

  /**
   * Logs debug messages if debug logging is enabled.
   */
  private logDebug(message: string, ...args: any[]): void {
    if (this.config.enableDebugLogging) {
      console.debug(`[UserInputHandler] ${message}`, ...args);
    }
  }
}