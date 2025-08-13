/**
 * Core type definitions for Kiro command metadata and research data.
 * 
 * These interfaces define the structure for storing and manipulating
 * command information discovered through the research process.
 */

/**
 * Represents the complete metadata for a discovered Kiro command.
 * 
 * This interface captures all information needed to understand,
 * test, and document a command for remote orchestration purposes.
 */
export interface CommandMetadata {
  /** Unique command identifier (e.g., 'kiroAgent.agent.chatAgent') */
  readonly id: string;
  
  /** Primary command category ('kiroAgent' or 'kiro') */
  readonly category: 'kiroAgent' | 'kiro';
  
  /** Functional subcategory (e.g., 'agent', 'execution', 'spec') */
  readonly subcategory: string;
  
  /** Human-readable display name for the command */
  readonly displayName: string;
  
  /** Detailed description of command functionality */
  readonly description?: string;
  
  /** Command signature including parameters and return type */
  readonly signature: CommandSignature;
  
  /** Example usage patterns and test cases */
  readonly examples: CommandExample[];
  
  /** Commands that must be executed before this command */
  readonly dependencies: string[];
  
  /** Risk assessment for safe testing */
  readonly riskLevel: 'safe' | 'moderate' | 'destructive';
  
  /** Timestamp of last successful test execution */
  readonly lastTested?: Date;
  
  /** Historical test execution results */
  readonly testResults: TestResult[];
}

/**
 * Defines the signature of a command including parameters and return type.
 * 
 * This interface captures the technical contract for command execution,
 * enabling parameter validation and result type checking.
 */
export interface CommandSignature {
  /** Array of command parameters with type information */
  readonly parameters: Parameter[];
  
  /** Expected return type from command execution */
  readonly returnType: TypeDefinition;
  
  /** Whether the command executes asynchronously */
  readonly async: boolean;
  
  /** Workspace context requirements for execution */
  readonly contextRequirements: string[];
}

/**
 * Represents a single command parameter with validation rules.
 * 
 * Parameters define the input contract for command execution,
 * including type constraints and validation requirements.
 */
export interface Parameter {
  /** Parameter name as expected by the command */
  readonly name: string;
  
  /** Type definition for parameter validation */
  readonly type: TypeDefinition;
  
  /** Whether this parameter is required for execution */
  readonly required: boolean;
  
  /** Human-readable description of parameter purpose */
  readonly description?: string;
  
  /** Default value when parameter is optional */
  readonly defaultValue?: any;
  
  /** Validation rules for parameter values */
  readonly validation?: ValidationRule[];
}

/**
 * Defines type information for parameters and return values.
 * 
 * This interface provides a flexible type system for documenting
 * command contracts and enabling runtime validation.
 */
export interface TypeDefinition {
  /** Base type name (e.g., 'string', 'number', 'object') */
  readonly name: string;
  
  /** Whether the type allows null values */
  readonly nullable: boolean;
  
  /** For array types, the element type definition */
  readonly elementType?: TypeDefinition;
  
  /** For object types, property definitions */
  readonly properties?: Record<string, TypeDefinition>;
  
  /** For union types, possible type alternatives */
  readonly unionTypes?: TypeDefinition[];
}

/**
 * Validation rule for parameter values.
 * 
 * Rules enable runtime validation of command parameters
 * before execution to prevent errors and ensure safety.
 */
export interface ValidationRule {
  /** Type of validation to perform */
  readonly type: 'range' | 'pattern' | 'enum' | 'custom';
  
  /** Rule-specific configuration */
  readonly config: Record<string, any>;
  
  /** Error message when validation fails */
  readonly errorMessage: string;
}

/**
 * Example usage pattern for a command.
 * 
 * Examples provide concrete usage patterns that can be used
 * for testing, documentation, and workflow generation.
 */
export interface CommandExample {
  /** Descriptive name for this example */
  readonly name: string;
  
  /** Description of what this example demonstrates */
  readonly description: string;
  
  /** Parameter values for this example */
  readonly parameters: Record<string, any>;
  
  /** Expected result from execution */
  readonly expectedResult?: any;
  
  /** Prerequisites for running this example */
  readonly prerequisites?: string[];
}

/**
 * Result of a command execution test.
 * 
 * Test results capture the outcome of command execution
 * for analysis, debugging, and performance monitoring.
 */
export interface TestResult {
  /** Timestamp when test was executed */
  readonly timestamp: Date;
  
  /** Parameter values used in the test */
  readonly parameters: Record<string, any>;
  
  /** Whether the command executed successfully */
  readonly success: boolean;
  
  /** Return value from successful execution */
  readonly result?: any;
  
  /** Error information from failed execution */
  readonly error?: ErrorInfo;
  
  /** Execution time in milliseconds */
  readonly executionTime: number;
  
  /** Side effects detected during execution */
  readonly sideEffects: SideEffect[];
}

/**
 * Information about command execution errors.
 * 
 * Error details help with debugging and understanding
 * command failure modes for better error handling.
 */
export interface ErrorInfo {
  /** Error message from the command execution */
  readonly message: string;
  
  /** Error type or category */
  readonly type: string;
  
  /** Stack trace if available */
  readonly stack?: string;
  
  /** Additional error context */
  readonly context?: Record<string, any>;
}

/**
 * Side effect detected during command execution.
 * 
 * Side effects help understand the full impact of command
 * execution beyond the return value.
 */
export interface SideEffect {
  /** Type of side effect that occurred */
  readonly type: 'file_created' | 'file_modified' | 'file_deleted' | 'view_opened' | 'view_closed' | 'state_changed' | 'setting_changed';
  
  /** Human-readable description of the side effect */
  readonly description: string;
  
  /** Detailed information about the side effect */
  readonly details: Record<string, any>;
}

/**
 * Workflow template representing a sequence of commands.
 * 
 * Templates capture common command patterns that can be
 * reused for automation and orchestration purposes.
 */
export interface WorkflowTemplate {
  /** Unique identifier for the workflow */
  readonly id: string;
  
  /** Human-readable name for the workflow */
  readonly name: string;
  
  /** Description of what the workflow accomplishes */
  readonly description: string;
  
  /** Sequence of commands in execution order */
  readonly steps: WorkflowStep[];
  
  /** Input parameters for the workflow */
  readonly parameters: Parameter[];
  
  /** Tags for categorizing and searching workflows */
  readonly tags: string[];
}

/**
 * Single step in a workflow template.
 * 
 * Steps define individual command executions within
 * a larger workflow sequence.
 */
export interface WorkflowStep {
  /** Command to execute in this step */
  readonly commandId: string;
  
  /** Parameters to pass to the command */
  readonly parameters: Record<string, any>;
  
  /** Conditions that must be met before execution */
  readonly preconditions?: string[];
  
  /** Actions to take if this step fails */
  readonly onError?: 'stop' | 'continue' | 'retry';
  
  /** Maximum number of retry attempts */
  readonly maxRetries?: number;
}