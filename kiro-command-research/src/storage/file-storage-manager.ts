/**
 * Simple file-based storage manager for command research data.
 * 
 * This module provides JSON file storage capabilities without the complexity
 * of database dependencies, making the extension more reliable and portable.
 */

import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

/**
 * Manages file-based storage for command research data.
 * 
 * The FileStorageManager provides simple JSON file operations for storing
 * and retrieving command discovery results and generated documentation.
 */
export class FileStorageManager {
  private readonly storageDir: string;

  /**
   * Creates a new file storage manager instance.
   * 
   * @param extensionContext VS Code extension context for storage path resolution
   */
  constructor(private readonly extensionContext: vscode.ExtensionContext) {
    // Use workspace storage if available, otherwise use global storage
    const workspaceStorage = extensionContext.storageUri?.fsPath;
    const globalStorage = extensionContext.globalStorageUri.fsPath;
    
    this.storageDir = workspaceStorage 
      ? path.join(workspaceStorage, '.kiro', 'command-research')
      : path.join(globalStorage, 'command-research');
  }

  /**
   * Initializes the storage directory structure.
   * 
   * Creates necessary directories for storing command research data
   * if they don't already exist.
   * 
   * @returns Promise that resolves when initialization is complete
   */
  public async initialize(): Promise<void> {
    try {
      console.log('FileStorageManager: Initializing storage directories...');
      
      // Create main storage directory
      if (!fs.existsSync(this.storageDir)) {
        fs.mkdirSync(this.storageDir, { recursive: true });
      }

      // Create subdirectories
      const subdirs = ['exports', 'logs'];
      for (const subdir of subdirs) {
        const subdirPath = path.join(this.storageDir, subdir);
        if (!fs.existsSync(subdirPath)) {
          fs.mkdirSync(subdirPath, { recursive: true });
        }
      }

      console.log(`Storage initialized at: ${this.storageDir}`);
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Failed to initialize storage: ${errorMessage}`);
    }
  }

  /**
   * Saves discovery results to a JSON file.
   * 
   * @param results Discovery results to save
   * @returns Promise that resolves when save is complete
   */
  public async saveDiscoveryResults(results: any): Promise<void> {
    try {
      const filePath = path.join(this.storageDir, 'discovery-results.json');
      const jsonData = JSON.stringify(results, null, 2);
      
      fs.writeFileSync(filePath, jsonData, 'utf8');
      console.log(`Discovery results saved to: ${filePath}`);
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Failed to save discovery results: ${errorMessage}`);
    }
  }

  /**
   * Loads discovery results from the JSON file.
   * 
   * @returns Promise that resolves to discovery results or null if not found
   */
  public async loadDiscoveryResults(): Promise<any | null> {
    try {
      const filePath = path.join(this.storageDir, 'discovery-results.json');
      
      if (!fs.existsSync(filePath)) {
        return null;
      }

      const jsonData = fs.readFileSync(filePath, 'utf8');
      return JSON.parse(jsonData);
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      console.warn(`Failed to load discovery results: ${errorMessage}`);
      return null;
    }
  }

  /**
   * Exports data to a file in the exports directory.
   * 
   * @param filename Name of the file to create
   * @param content Content to write to the file
   * @param format File format ('json', 'md', 'ts', etc.)
   * @returns Promise that resolves to the file path when export is complete
   */
  public async exportToFile(filename: string, content: string, format: string): Promise<string> {
    try {
      const exportsDir = path.join(this.storageDir, 'exports');
      const filePath = path.join(exportsDir, filename);
      
      fs.writeFileSync(filePath, content, 'utf8');
      console.log(`Exported ${format.toUpperCase()} to: ${filePath}`);
      
      return filePath;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Failed to export ${format} file: ${errorMessage}`);
    }
  }

  /**
   * Logs discovery activity to a dated log file.
   * 
   * @param message Log message to write
   * @returns Promise that resolves when log is written
   */
  public async logActivity(message: string): Promise<void> {
    try {
      const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
      const logFile = path.join(this.storageDir, 'logs', `discovery-${today}.log`);
      const timestamp = new Date().toISOString();
      const logEntry = `${timestamp}: ${message}\n`;
      
      fs.appendFileSync(logFile, logEntry, 'utf8');
    } catch (error: unknown) {
      // Don't throw on logging errors, just warn
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      console.warn(`Failed to write log: ${errorMessage}`);
    }
  }

  /**
   * Gets the storage directory path.
   * 
   * @returns Absolute path to the storage directory
   */
  public getStorageDir(): string {
    return this.storageDir;
  }

  /**
   * Gets the exports directory path.
   * 
   * @returns Absolute path to the exports directory
   */
  public getExportsDir(): string {
    return path.join(this.storageDir, 'exports');
  }

  /**
   * Checks if discovery results exist.
   * 
   * @returns True if discovery results file exists
   */
  public hasDiscoveryResults(): boolean {
    const filePath = path.join(this.storageDir, 'discovery-results.json');
    return fs.existsSync(filePath);
  }

  /**
   * Gets information about stored files.
   * 
   * @returns Object with file information and statistics
   */
  public getStorageInfo(): StorageInfo {
    const info: StorageInfo = {
      storageDir: this.storageDir,
      hasResults: this.hasDiscoveryResults(),
      exportedFiles: [],
      logFiles: []
    };

    try {
      // Check for exported files
      const exportsDir = path.join(this.storageDir, 'exports');
      if (fs.existsSync(exportsDir)) {
        info.exportedFiles = fs.readdirSync(exportsDir)
          .filter(file => fs.statSync(path.join(exportsDir, file)).isFile());
      }

      // Check for log files
      const logsDir = path.join(this.storageDir, 'logs');
      if (fs.existsSync(logsDir)) {
        info.logFiles = fs.readdirSync(logsDir)
          .filter(file => file.endsWith('.log'));
      }
    } catch (error: unknown) {
      console.warn('Failed to get storage info:', error);
    }

    return info;
  }
}

/**
 * Information about the current storage state.
 */
export interface StorageInfo {
  /** Path to the storage directory */
  storageDir: string;
  
  /** Whether discovery results exist */
  hasResults: boolean;
  
  /** List of exported files */
  exportedFiles: string[];
  
  /** List of log files */
  logFiles: string[];
}