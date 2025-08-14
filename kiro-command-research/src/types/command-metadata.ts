/**
 * Simplified type definitions for Kiro command research data.
 * 
 * These interfaces define the structure for storing and manipulating
 * command information discovered through the research process.
 */

/**
 * Simplified metadata for a discovered Kiro command.
 * 
 * This interface captures essential information needed to understand
 * and document a command for remote orchestration purposes.
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
  
  /** Risk assessment for command execution */
  readonly riskLevel: 'safe' | 'moderate' | 'destructive';
  
  /** Workspace context requirements for execution */
  readonly contextRequirements: string[];
  
  /** When this command was discovered */
  readonly discoveredAt: Date;
  
  /** Command signature information (if researched) */
  readonly signature?: CommandSignature;
}

/**
 * Information about a command parameter.
 */
export interface ParameterInfo {
  /** Parameter name */
  readonly name: string;
  
  /** Parameter type (inferred) */
  readonly type: string;
  
  /** Whether parameter is required */
  readonly required: boolean;
  
  /** Parameter description if available */
  readonly description?: string;
  
  /** Default value if known */
  readonly defaultValue?: any;
  
  /** How this parameter info was discovered */
  readonly source: 'typescript' | 'documentation' | 'inference' | 'manual';
}

/**
 * Command signature information.
 */
export interface CommandSignature {
  /** Parameters for this command */
  readonly parameters: ParameterInfo[];
  
  /** Return type if known */
  readonly returnType?: string;
  
  /** Whether command is async */
  readonly async: boolean;
  
  /** Confidence level in this signature */
  readonly confidence: 'high' | 'medium' | 'low';
  
  /** Sources used to determine signature */
  readonly sources: string[];
  
  /** When signature was researched */
  readonly researchedAt: Date;
}

/**
 * Results of a command discovery session.
 * 
 * This interface captures the complete results of scanning
 * for and analyzing Kiro commands in the environment.
 */
export interface DiscoveryResults {
  /** Total number of commands discovered */
  readonly totalCommands: number;
  
  /** Number of kiroAgent commands */
  readonly kiroAgentCommands: number;
  
  /** Number of kiro platform commands */
  readonly kiroCommands: number;
  
  /** Array of all discovered commands */
  readonly commands: CommandMetadata[];
  
  /** When the discovery was performed */
  readonly discoveryTimestamp: Date;
  
  /** Statistical breakdown of discovered commands */
  readonly statistics: DiscoveryStatistics;
}

/**
 * Statistics about command discovery results.
 * 
 * This interface provides structured information about the
 * commands discovered during the scanning process.
 */
export interface DiscoveryStatistics {
  /** Number of safe commands */
  readonly safeCommands: number;
  
  /** Number of moderate risk commands */
  readonly moderateCommands: number;
  
  /** Number of destructive commands */
  readonly destructiveCommands: number;
  
  /** List of all subcategories found */
  readonly subcategories: string[];
  
  /** Commands grouped by category */
  readonly byCategory: Record<string, number>;
  
  /** Commands grouped by subcategory */
  readonly bySubcategory: Record<string, number>;
}