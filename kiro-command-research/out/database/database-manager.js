"use strict";
/**
 * Database manager for the Kiro Command Research Tool.
 *
 * This class handles SQLite database initialization, connection management,
 * and provides a foundation for data access operations.
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
exports.DatabaseManager = void 0;
const sqlite3 = __importStar(require("sqlite3"));
const path = __importStar(require("path"));
const fs = __importStar(require("fs"));
/**
 * Manages SQLite database connections and initialization for command research data.
 *
 * The DatabaseManager handles database lifecycle, schema creation, and provides
 * a centralized connection point for all data access operations.
 */
class DatabaseManager {
    /**
     * Creates a new database manager instance.
     *
     * @param extensionContext VS Code extension context for storage path resolution
     */
    constructor(extensionContext) {
        this.extensionContext = extensionContext;
        this.database = null;
        // Store database in extension's global storage path
        const storagePath = extensionContext.globalStorageUri.fsPath;
        this.databasePath = path.join(storagePath, 'kiro-command-research.db');
    }
    /**
     * Initializes the database connection and creates schema if needed.
     *
     * This method must be called before any database operations.
     * It ensures the storage directory exists and creates the database
     * schema if this is the first run.
     *
     * @returns Promise that resolves when initialization is complete
     * @throws Error if database initialization fails
     */
    async initialize() {
        try {
            // Ensure storage directory exists
            const storageDir = path.dirname(this.databasePath);
            if (!fs.existsSync(storageDir)) {
                fs.mkdirSync(storageDir, { recursive: true });
            }
            // Create database connection
            this.database = new sqlite3.Database(this.databasePath);
            // Enable foreign key constraints
            await this.executeQuery('PRAGMA foreign_keys = ON');
            // Initialize schema
            await this.initializeSchema();
            console.log(`Database initialized at: ${this.databasePath}`);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            throw new Error(`Failed to initialize database: ${errorMessage}`);
        }
    }
    /**
     * Closes the database connection.
     *
     * This method should be called when the extension is deactivated
     * to ensure proper cleanup of database resources.
     *
     * @returns Promise that resolves when the connection is closed
     */
    async close() {
        if (this.database) {
            return new Promise((resolve, reject) => {
                this.database.close((error) => {
                    if (error) {
                        reject(new Error(`Failed to close database: ${error.message}`));
                    }
                    else {
                        this.database = null;
                        resolve();
                    }
                });
            });
        }
    }
    /**
     * Gets the active database connection.
     *
     * @returns The SQLite database instance
     * @throws Error if database is not initialized
     */
    getDatabase() {
        if (!this.database) {
            throw new Error('Database not initialized. Call initialize() first.');
        }
        return this.database;
    }
    /**
     * Executes a SQL query with optional parameters.
     *
     * This method provides a Promise-based interface for executing
     * SQL statements with proper error handling.
     *
     * @param sql SQL query string
     * @param params Optional parameters for the query
     * @returns Promise that resolves when query completes
     * @throws Error if query execution fails
     */
    async executeQuery(sql, params = []) {
        const database = this.getDatabase();
        return new Promise((resolve, reject) => {
            database.run(sql, params, function (error) {
                if (error) {
                    reject(new Error(`Query execution failed: ${error.message}`));
                }
                else {
                    resolve();
                }
            });
        });
    }
    /**
     * Executes a SQL query and returns a single row result.
     *
     * @param sql SQL query string
     * @param params Optional parameters for the query
     * @returns Promise that resolves to the first row or undefined
     * @throws Error if query execution fails
     */
    async queryOne(sql, params = []) {
        const database = this.getDatabase();
        return new Promise((resolve, reject) => {
            database.get(sql, params, (error, row) => {
                if (error) {
                    reject(new Error(`Query execution failed: ${error.message}`));
                }
                else {
                    resolve(row);
                }
            });
        });
    }
    /**
     * Executes a SQL query and returns all matching rows.
     *
     * @param sql SQL query string
     * @param params Optional parameters for the query
     * @returns Promise that resolves to array of result rows
     * @throws Error if query execution fails
     */
    async queryAll(sql, params = []) {
        const database = this.getDatabase();
        return new Promise((resolve, reject) => {
            database.all(sql, params, (error, rows) => {
                if (error) {
                    reject(new Error(`Query execution failed: ${error.message}`));
                }
                else {
                    resolve(rows || []);
                }
            });
        });
    }
    /**
     * Executes multiple SQL statements in a transaction.
     *
     * This method ensures all statements succeed or all are rolled back,
     * providing atomic execution for complex operations.
     *
     * @param statements Array of SQL statements with optional parameters
     * @returns Promise that resolves when all statements complete
     * @throws Error if any statement fails
     */
    async executeTransaction(statements) {
        const database = this.getDatabase();
        return new Promise((resolve, reject) => {
            database.serialize(() => {
                database.run('BEGIN TRANSACTION');
                let completed = 0;
                let hasError = false;
                const handleCompletion = (error) => {
                    if (error && !hasError) {
                        hasError = true;
                        database.run('ROLLBACK', () => {
                            reject(new Error(`Transaction failed: ${error.message}`));
                        });
                        return;
                    }
                    completed++;
                    if (completed === statements.length && !hasError) {
                        database.run('COMMIT', (commitError) => {
                            if (commitError) {
                                reject(new Error(`Transaction commit failed: ${commitError.message}`));
                            }
                            else {
                                resolve();
                            }
                        });
                    }
                };
                for (const statement of statements) {
                    database.run(statement.sql, statement.params || [], handleCompletion);
                }
            });
        });
    }
    /**
     * Initializes the database schema by executing embedded SQL statements.
     *
     * This method creates all necessary tables, indexes, triggers, and views
     * for the command research tool database.
     *
     * @returns Promise that resolves when schema is created
     * @throws Error if schema creation fails
     */
    async initializeSchema() {
        try {
            // Embedded schema SQL statements
            const schemaStatements = [
                // Commands table
                `CREATE TABLE IF NOT EXISTS commands (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL CHECK (category IN ('kiroAgent', 'kiro')),
          subcategory TEXT,
          display_name TEXT,
          description TEXT,
          signature JSON NOT NULL,
          risk_level TEXT DEFAULT 'safe' CHECK (risk_level IN ('safe', 'moderate', 'destructive')),
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          last_tested DATETIME
        )`,
                // Test results table
                `CREATE TABLE IF NOT EXISTS test_results (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          command_id TEXT NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
          parameters JSON NOT NULL,
          success BOOLEAN NOT NULL,
          result JSON,
          error JSON,
          execution_time INTEGER NOT NULL,
          side_effects JSON,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )`,
                // Command dependencies table
                `CREATE TABLE IF NOT EXISTS command_dependencies (
          command_id TEXT NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
          depends_on TEXT NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
          dependency_type TEXT NOT NULL CHECK (dependency_type IN ('prerequisite', 'sequence', 'context')),
          metadata JSON,
          PRIMARY KEY (command_id, depends_on)
        )`,
                // Command examples table
                `CREATE TABLE IF NOT EXISTS command_examples (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          command_id TEXT NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          description TEXT,
          parameters JSON NOT NULL,
          expected_result JSON,
          prerequisites JSON,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`,
                // Workflow templates table
                `CREATE TABLE IF NOT EXISTS workflow_templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          parameters JSON,
          tags JSON,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`,
                // Workflow steps table
                `CREATE TABLE IF NOT EXISTS workflow_steps (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workflow_id TEXT NOT NULL REFERENCES workflow_templates(id) ON DELETE CASCADE,
          step_order INTEGER NOT NULL,
          command_id TEXT NOT NULL REFERENCES commands(id),
          parameters JSON NOT NULL,
          preconditions JSON,
          on_error TEXT DEFAULT 'stop' CHECK (on_error IN ('stop', 'continue', 'retry')),
          max_retries INTEGER DEFAULT 0,
          UNIQUE (workflow_id, step_order)
        )`,
                // Indexes
                `CREATE INDEX IF NOT EXISTS idx_commands_category ON commands(category, subcategory)`,
                `CREATE INDEX IF NOT EXISTS idx_test_results_command_time ON test_results(command_id, timestamp DESC)`,
                `CREATE INDEX IF NOT EXISTS idx_test_results_success ON test_results(command_id, success, timestamp DESC)`,
                `CREATE INDEX IF NOT EXISTS idx_dependencies_command ON command_dependencies(command_id)`,
                `CREATE INDEX IF NOT EXISTS idx_dependencies_depends_on ON command_dependencies(depends_on)`,
                `CREATE INDEX IF NOT EXISTS idx_workflow_steps_workflow ON workflow_steps(workflow_id, step_order)`,
                // Triggers
                `CREATE TRIGGER IF NOT EXISTS update_commands_timestamp 
         AFTER UPDATE ON commands
         FOR EACH ROW
         BEGIN
           UPDATE commands SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
         END`,
                `CREATE TRIGGER IF NOT EXISTS update_workflow_templates_timestamp 
         AFTER UPDATE ON workflow_templates
         FOR EACH ROW
         BEGIN
           UPDATE workflow_templates SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
         END`,
                // Views
                `CREATE VIEW IF NOT EXISTS command_summary AS
         SELECT 
           c.id,
           c.category,
           c.subcategory,
           c.display_name,
           c.description,
           c.risk_level,
           c.last_tested,
           COUNT(tr.id) as total_tests,
           SUM(CASE WHEN tr.success = 1 THEN 1 ELSE 0 END) as successful_tests,
           AVG(tr.execution_time) as avg_execution_time
         FROM commands c
         LEFT JOIN test_results tr ON c.id = tr.command_id
         GROUP BY c.id, c.category, c.subcategory, c.display_name, c.description, c.risk_level, c.last_tested`,
                `CREATE VIEW IF NOT EXISTS recent_test_results AS
         SELECT 
           tr.*,
           c.display_name as command_name,
           c.category,
           c.risk_level
         FROM test_results tr
         JOIN commands c ON tr.command_id = c.id
         ORDER BY tr.timestamp DESC
         LIMIT 100`
            ];
            // Execute each statement
            for (const statement of schemaStatements) {
                await this.executeQuery(statement);
            }
            console.log('Database schema initialized successfully');
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            throw new Error(`Failed to initialize schema: ${errorMessage}`);
        }
    }
    /**
     * Checks if the database file exists and is accessible.
     *
     * @returns True if database file exists and is readable
     */
    isDatabaseInitialized() {
        try {
            return fs.existsSync(this.databasePath) && fs.statSync(this.databasePath).isFile();
        }
        catch {
            return false;
        }
    }
    /**
     * Gets the path to the database file.
     *
     * @returns Absolute path to the SQLite database file
     */
    getDatabasePath() {
        return this.databasePath;
    }
    /**
     * Performs database maintenance operations.
     *
     * This method runs VACUUM and ANALYZE to optimize database performance
     * and should be called periodically during extension lifecycle.
     *
     * @returns Promise that resolves when maintenance is complete
     */
    async performMaintenance() {
        try {
            await this.executeQuery('VACUUM');
            await this.executeQuery('ANALYZE');
            console.log('Database maintenance completed');
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.warn(`Database maintenance failed: ${errorMessage}`);
        }
    }
}
exports.DatabaseManager = DatabaseManager;
//# sourceMappingURL=database-manager.js.map