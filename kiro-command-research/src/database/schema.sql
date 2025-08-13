-- Kiro Command Research Tool Database Schema
-- 
-- This schema stores command metadata, test results, and workflow information
-- discovered through the research process.

-- Commands table stores metadata for all discovered Kiro commands
CREATE TABLE IF NOT EXISTS commands (
    -- Primary key: Unique command identifier
    id TEXT PRIMARY KEY,
    
    -- Command categorization
    category TEXT NOT NULL CHECK (category IN ('kiroAgent', 'kiro')),
    subcategory TEXT,
    
    -- Display information
    display_name TEXT,
    description TEXT,
    
    -- Command signature as JSON
    signature JSON NOT NULL,
    
    -- Risk assessment for testing
    risk_level TEXT DEFAULT 'safe' CHECK (risk_level IN ('safe', 'moderate', 'destructive')),
    
    -- Timestamps
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_tested DATETIME
);

-- Test results table stores execution results for commands
CREATE TABLE IF NOT EXISTS test_results (
    -- Primary key
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Foreign key to commands table
    command_id TEXT NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
    
    -- Test execution data
    parameters JSON NOT NULL,
    success BOOLEAN NOT NULL,
    result JSON,
    error JSON,
    execution_time INTEGER NOT NULL, -- milliseconds
    side_effects JSON,
    
    -- Timestamp
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Command dependencies table tracks prerequisite relationships
CREATE TABLE IF NOT EXISTS command_dependencies (
    -- Composite primary key
    command_id TEXT NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
    depends_on TEXT NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
    
    -- Dependency type
    dependency_type TEXT NOT NULL CHECK (dependency_type IN ('prerequisite', 'sequence', 'context')),
    
    -- Optional dependency metadata
    metadata JSON,
    
    PRIMARY KEY (command_id, depends_on)
);

-- Command examples table stores usage examples
CREATE TABLE IF NOT EXISTS command_examples (
    -- Primary key
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Foreign key to commands table
    command_id TEXT NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
    
    -- Example information
    name TEXT NOT NULL,
    description TEXT,
    parameters JSON NOT NULL,
    expected_result JSON,
    prerequisites JSON, -- Array of prerequisite descriptions
    
    -- Timestamps
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Workflow templates table stores reusable command sequences
CREATE TABLE IF NOT EXISTS workflow_templates (
    -- Primary key
    id TEXT PRIMARY KEY,
    
    -- Template information
    name TEXT NOT NULL,
    description TEXT,
    parameters JSON, -- Array of workflow parameters
    tags JSON, -- Array of tags for categorization
    
    -- Timestamps
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Workflow steps table stores individual steps in workflows
CREATE TABLE IF NOT EXISTS workflow_steps (
    -- Primary key
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Foreign key to workflow templates
    workflow_id TEXT NOT NULL REFERENCES workflow_templates(id) ON DELETE CASCADE,
    
    -- Step information
    step_order INTEGER NOT NULL,
    command_id TEXT NOT NULL REFERENCES commands(id),
    parameters JSON NOT NULL,
    preconditions JSON, -- Array of precondition descriptions
    on_error TEXT DEFAULT 'stop' CHECK (on_error IN ('stop', 'continue', 'retry')),
    max_retries INTEGER DEFAULT 0,
    
    -- Ensure proper ordering
    UNIQUE (workflow_id, step_order)
);

-- Indexes for performance optimization

-- Index for command lookups by category
CREATE INDEX IF NOT EXISTS idx_commands_category ON commands(category, subcategory);

-- Index for test results by command and timestamp
CREATE INDEX IF NOT EXISTS idx_test_results_command_time ON test_results(command_id, timestamp DESC);

-- Index for successful test results
CREATE INDEX IF NOT EXISTS idx_test_results_success ON test_results(command_id, success, timestamp DESC);

-- Index for command dependencies
CREATE INDEX IF NOT EXISTS idx_dependencies_command ON command_dependencies(command_id);
CREATE INDEX IF NOT EXISTS idx_dependencies_depends_on ON command_dependencies(depends_on);

-- Index for workflow steps
CREATE INDEX IF NOT EXISTS idx_workflow_steps_workflow ON workflow_steps(workflow_id, step_order);

-- Triggers for automatic timestamp updates

-- Update commands.updated_at on modification
CREATE TRIGGER IF NOT EXISTS update_commands_timestamp 
    AFTER UPDATE ON commands
    FOR EACH ROW
    BEGIN
        UPDATE commands SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;

-- Update workflow_templates.updated_at on modification
CREATE TRIGGER IF NOT EXISTS update_workflow_templates_timestamp 
    AFTER UPDATE ON workflow_templates
    FOR EACH ROW
    BEGIN
        UPDATE workflow_templates SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;

-- Views for common queries

-- View for command summary with latest test results
CREATE VIEW IF NOT EXISTS command_summary AS
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
GROUP BY c.id, c.category, c.subcategory, c.display_name, c.description, c.risk_level, c.last_tested;

-- View for recent test results
CREATE VIEW IF NOT EXISTS recent_test_results AS
SELECT 
    tr.*,
    c.display_name as command_name,
    c.category,
    c.risk_level
FROM test_results tr
JOIN commands c ON tr.command_id = c.id
ORDER BY tr.timestamp DESC
LIMIT 100;