"use strict";
/**
 * Simple file-based storage manager for command research data.
 *
 * This module provides JSON file storage capabilities without the complexity
 * of database dependencies, making the extension more reliable and portable.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FileStorageManager = void 0;
const path = __importStar(require("path"));
const fs = __importStar(require("fs"));
/**
 * Manages file-based storage for command research data.
 *
 * The FileStorageManager provides simple JSON file operations for storing
 * and retrieving command discovery results and generated documentation.
 */
class FileStorageManager {
    /**
     * Creates a new file storage manager instance.
     *
     * @param extensionContext VS Code extension context for storage path resolution
     */
    constructor(extensionContext) {
        this.extensionContext = extensionContext;
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
    async initialize() {
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
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            throw new Error(`Failed to initialize storage: ${errorMessage}`);
        }
    }
    /**
     * Saves discovery results to a JSON file.
     *
     * @param results Discovery results to save
     * @returns Promise that resolves when save is complete
     */
    async saveDiscoveryResults(results) {
        try {
            const filePath = path.join(this.storageDir, 'discovery-results.json');
            const jsonData = JSON.stringify(results, null, 2);
            fs.writeFileSync(filePath, jsonData, 'utf8');
            console.log(`Discovery results saved to: ${filePath}`);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            throw new Error(`Failed to save discovery results: ${errorMessage}`);
        }
    }
    /**
     * Loads discovery results from the JSON file.
     *
     * @returns Promise that resolves to discovery results or null if not found
     */
    async loadDiscoveryResults() {
        try {
            const filePath = path.join(this.storageDir, 'discovery-results.json');
            if (!fs.existsSync(filePath)) {
                return null;
            }
            const jsonData = fs.readFileSync(filePath, 'utf8');
            return JSON.parse(jsonData);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
    async exportToFile(filename, content, format) {
        try {
            const exportsDir = path.join(this.storageDir, 'exports');
            const filePath = path.join(exportsDir, filename);
            fs.writeFileSync(filePath, content, 'utf8');
            console.log(`Exported ${format.toUpperCase()} to: ${filePath}`);
            return filePath;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            throw new Error(`Failed to export ${format} file: ${errorMessage}`);
        }
    }
    /**
     * Logs discovery activity to a dated log file.
     *
     * @param message Log message to write
     * @returns Promise that resolves when log is written
     */
    async logActivity(message) {
        try {
            const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
            const logFile = path.join(this.storageDir, 'logs', `discovery-${today}.log`);
            const timestamp = new Date().toISOString();
            const logEntry = `${timestamp}: ${message}\n`;
            fs.appendFileSync(logFile, logEntry, 'utf8');
        }
        catch (error) {
            // Don't throw on logging errors, just warn
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.warn(`Failed to write log: ${errorMessage}`);
        }
    }
    /**
     * Gets the storage directory path.
     *
     * @returns Absolute path to the storage directory
     */
    getStorageDir() {
        return this.storageDir;
    }
    /**
     * Gets the exports directory path.
     *
     * @returns Absolute path to the exports directory
     */
    getExportsDir() {
        return path.join(this.storageDir, 'exports');
    }
    /**
     * Checks if discovery results exist.
     *
     * @returns True if discovery results file exists
     */
    hasDiscoveryResults() {
        const filePath = path.join(this.storageDir, 'discovery-results.json');
        return fs.existsSync(filePath);
    }
    /**
     * Saves arbitrary data to a JSON file.
     *
     * @param filename Name of the file to save to
     * @param data Data to save (will be JSON stringified)
     * @returns Promise that resolves when save is complete
     */
    async saveData(filename, data) {
        try {
            const filePath = path.join(this.storageDir, filename);
            fs.writeFileSync(filePath, data, 'utf8');
            console.log(`FileStorageManager: Saved data to ${filename}`);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error(`FileStorageManager: Failed to save data to ${filename}:`, errorMessage);
            throw error;
        }
    }
    /**
     * Loads arbitrary data from a JSON file.
     *
     * @param filename Name of the file to load from
     * @returns Promise that resolves to file content or null if not found
     */
    async loadData(filename) {
        try {
            const filePath = path.join(this.storageDir, filename);
            if (!fs.existsSync(filePath)) {
                return null;
            }
            const content = fs.readFileSync(filePath, 'utf8');
            console.log(`FileStorageManager: Loaded data from ${filename}`);
            return content;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error(`FileStorageManager: Failed to load data from ${filename}:`, errorMessage);
            return null;
        }
    }
    /**
     * Gets information about stored files.
     *
     * @returns Object with file information and statistics
     */
    getStorageInfo() {
        const info = {
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
        }
        catch (error) {
            console.warn('Failed to get storage info:', error);
        }
        return info;
    }
}
exports.FileStorageManager = FileStorageManager;
//# sourceMappingURL=file-storage-manager.js.map