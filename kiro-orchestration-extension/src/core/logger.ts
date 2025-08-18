/**
 * Logging utility for the Kiro Orchestration Extension.
 * 
 * This module provides structured logging capabilities with configurable
 * log levels and consistent formatting across all extension components.
 */

import * as vscode from 'vscode';

/**
 * Log levels supported by the logger.
 */
export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

/**
 * Logger class for structured logging throughout the extension.
 * 
 * This class provides consistent logging with timestamps, component names,
 * and configurable log levels. All log output is sent to the VS Code
 * output channel for easy debugging and monitoring.
 */
export class Logger {
  private static outputChannel: vscode.OutputChannel | null = null;
  private static currentLogLevel: LogLevel = 'info';
  
  private readonly componentName: string;

  /**
   * Creates a new logger instance for a specific component.
   * 
   * @param componentName - Name of the component using this logger
   */
  constructor(componentName: string) {
    this.componentName = componentName;
    
    // Initialize the output channel if it doesn't exist
    if (!Logger.outputChannel) {
      Logger.outputChannel = vscode.window.createOutputChannel('Kiro Orchestration');
    }
  }

  /**
   * Sets the global log level for all logger instances.
   * 
   * @param level - The minimum log level to output
   */
  public static setLogLevel(level: LogLevel): void {
    Logger.currentLogLevel = level;
  }

  /**
   * Gets the current global log level.
   * 
   * @returns The current log level
   */
  public static getLogLevel(): LogLevel {
    return Logger.currentLogLevel;
  }

  /**
   * Logs a debug message.
   * 
   * Debug messages are used for detailed diagnostic information
   * that is typically only of interest during development.
   * 
   * @param message - The message to log
   * @param data - Optional additional data to include
   */
  public debug(message: string, data?: unknown): void {
    this.log('debug', message, data);
  }

  /**
   * Logs an info message.
   * 
   * Info messages are used for general information about
   * the normal operation of the extension.
   * 
   * @param message - The message to log
   * @param data - Optional additional data to include
   */
  public info(message: string, data?: unknown): void {
    this.log('info', message, data);
  }

  /**
   * Logs a warning message.
   * 
   * Warning messages indicate potentially problematic situations
   * that don't prevent the extension from functioning.
   * 
   * @param message - The message to log
   * @param data - Optional additional data to include
   */
  public warn(message: string, data?: unknown): void {
    this.log('warn', message, data);
  }

  /**
   * Logs an error message.
   * 
   * Error messages indicate serious problems that may prevent
   * the extension from functioning correctly.
   * 
   * @param message - The message to log
   * @param data - Optional additional data to include
   */
  public error(message: string, data?: unknown): void {
    this.log('error', message, data);
  }

  /**
   * Internal logging method that handles message formatting and output.
   * 
   * @param level - The log level for this message
   * @param message - The message to log
   * @param data - Optional additional data to include
   */
  private log(level: LogLevel, message: string, data?: unknown): void {
    // Check if this message should be logged based on current log level
    if (!this.shouldLog(level)) {
      return;
    }

    // Format the log message with timestamp and component name
    const timestamp: string = new Date().toISOString();
    const levelUpper: string = level.toUpperCase().padEnd(5);
    const formattedMessage: string = `[${timestamp}] ${levelUpper} [${this.componentName}] ${message}`;

    // Add data if provided
    let fullMessage: string = formattedMessage;
    if (data !== undefined) {
      const dataString: string = typeof data === 'string' ? data : JSON.stringify(data, null, 2);
      fullMessage += `\n${dataString}`;
    }

    // Output to VS Code output channel
    if (Logger.outputChannel) {
      Logger.outputChannel.appendLine(fullMessage);
    }

    // Also log to console for development
    switch (level) {
      case 'debug':
        console.debug(fullMessage);
        break;
      case 'info':
        console.info(fullMessage);
        break;
      case 'warn':
        console.warn(fullMessage);
        break;
      case 'error':
        console.error(fullMessage);
        break;
    }
  }

  /**
   * Determines if a message at the given level should be logged.
   * 
   * @param level - The log level to check
   * @returns True if the message should be logged, false otherwise
   */
  private shouldLog(level: LogLevel): boolean {
    const levels: LogLevel[] = ['debug', 'info', 'warn', 'error'];
    const currentLevelIndex: number = levels.indexOf(Logger.currentLogLevel);
    const messageLevelIndex: number = levels.indexOf(level);
    
    return messageLevelIndex >= currentLevelIndex;
  }

  /**
   * Shows the output channel in VS Code.
   * 
   * This method brings the extension's output channel into focus,
   * which is useful for debugging and monitoring.
   */
  public static showOutputChannel(): void {
    if (Logger.outputChannel) {
      Logger.outputChannel.show();
    }
  }

  /**
   * Disposes of the logger resources.
   * 
   * This method should be called during extension deactivation
   * to clean up the output channel.
   */
  public static dispose(): void {
    if (Logger.outputChannel) {
      Logger.outputChannel.dispose();
      Logger.outputChannel = null;
    }
  }
}