/**
 * Schema generation engine for creating structured documentation schemas.
 * 
 * This module generates JSON schemas, TypeScript definitions, and OpenAPI
 * specifications from command metadata and test results for integration use.
 */

import * as vscode from 'vscode';
import { CommandMetadata, ParameterInfo, CommandSignature } from '../types/command-metadata';
import { TestResult } from '../testing/result-capture';

/**
 * JSON Schema definition for command metadata.
 */
export interface JsonSchema {
  /** Schema version */
  readonly $schema: string;
  
  /** Schema title */
  readonly title: string;
  
  /** Schema description */
  readonly description: string;
  
  /** Schema type */
  readonly type: string;
  
  /** Object properties */
  readonly properties?: Record<string, JsonSchemaProperty>;
  
  /** Required properties */
  readonly required?: string[];
  
  /** Additional properties allowed */
  readonly additionalProperties?: boolean;
  
  /** Schema definitions */
  readonly definitions?: Record<string, JsonSchema>;
}

/**
 * JSON Schema property definition.
 */
export interface JsonSchemaProperty {
  /** Property type */
  readonly type: string;
  
  /** Property description */
  readonly description?: string;
  
  /** Property format */
  readonly format?: string;
  
  /** Enum values */
  readonly enum?: any[];
  
  /** Array items schema */
  readonly items?: JsonSchemaProperty;
  
  /** Object properties */
  readonly properties?: Record<string, JsonSchemaProperty>;
  
  /** Required properties for objects */
  readonly required?: string[];
  
  /** Default value */
  readonly default?: any;
  
  /** Examples */
  readonly examples?: any[];
}

/**
 * TypeScript definition structure.
 */
export interface TypeScriptDefinition {
  /** Interface or type name */
  readonly name: string;
  
  /** Definition type */
  readonly type: 'interface' | 'type' | 'enum';
  
  /** TypeScript code */
  readonly code: string;
  
  /** JSDoc comment */
  readonly documentation?: string;
  
  /** Dependencies on other types */
  readonly dependencies: string[];
}

/**
 * OpenAPI specification structure.
 */
export interface OpenApiSpec {
  /** OpenAPI version */
  readonly openapi: string;
  
  /** API information */
  readonly info: {
    title: string;
    version: string;
    description: string;
  };
  
  /** Server information */
  readonly servers: Array<{
    url: string;
    description: string;
  }>;
  
  /** API paths */
  readonly paths: Record<string, OpenApiPath>;
  
  /** Component schemas */
  readonly components: {
    schemas: Record<string, JsonSchema>;
  };
}

/**
 * OpenAPI path definition.
 */
export interface OpenApiPath {
  /** HTTP methods */
  readonly post?: OpenApiOperation;
  readonly get?: OpenApiOperation;
}

/**
 * OpenAPI operation definition.
 */
export interface OpenApiOperation {
  /** Operation summary */
  readonly summary: string;
  
  /** Operation description */
  readonly description: string;
  
  /** Operation tags */
  readonly tags: string[];
  
  /** Request body */
  readonly requestBody?: {
    required: boolean;
    content: Record<string, {
      schema: JsonSchema;
    }>;
  };
  
  /** Responses */
  readonly responses: Record<string, {
    description: string;
    content?: Record<string, {
      schema: JsonSchema;
    }>;
  }>;
}

/**
 * Schema generation configuration.
 */
export interface SchemaConfig {
  /** Include test result examples */
  readonly includeExamples: boolean;
  
  /** Include deprecated commands */
  readonly includeDeprecated: boolean;
  
  /** Schema version to generate */
  readonly schemaVersion: string;
  
  /** TypeScript target version */
  readonly typescriptTarget: 'ES2015' | 'ES2018' | 'ES2020' | 'ES2022';
  
  /** OpenAPI version */
  readonly openApiVersion: string;
  
  /** Include internal commands */
  readonly includeInternal: boolean;
}

/**
 * Generates structured schemas and definitions from command metadata.
 * 
 * The SchemaGenerator creates JSON schemas, TypeScript definitions, and
 * OpenAPI specifications for integration with external systems.
 */
export class SchemaGenerator {
  private readonly config: SchemaConfig;
  
  constructor(config: Partial<SchemaConfig> = {}) {
    this.config = {
      includeExamples: true,
      includeDeprecated: false,
      schemaVersion: 'http://json-schema.org/draft-07/schema#',
      typescriptTarget: 'ES2020',
      openApiVersion: '3.0.3',
      includeInternal: false,
      ...config
    };
  }
  
  /**
   * Generates a JSON schema for command metadata structure.
   * 
   * @param commands Array of command metadata
   * @param testResults Optional test results for examples
   * @returns JSON schema definition
   */
  public generateCommandMetadataSchema(
    commands: CommandMetadata[],
    testResults?: TestResult[]
  ): JsonSchema {
    console.log(`SchemaGenerator: Generating JSON schema for ${commands.length} commands`);
    
    const schema: JsonSchema = {
      $schema: this.config.schemaVersion,
      title: 'Kiro Command Metadata Schema',
      description: 'Schema for Kiro IDE command metadata and signatures',
      type: 'object',
      properties: {
        version: {
          type: 'string',
          description: 'Schema version',
          examples: ['1.0.0']
        },
        timestamp: {
          type: 'string',
          format: 'date-time',
          description: 'When this schema was generated'
        },
        commands: {
          type: 'array',
          description: 'Array of discovered Kiro commands',
          items: this.generateCommandSchema(commands, testResults)
        },
        statistics: {
          type: 'object',
          description: 'Statistics about discovered commands',
          properties: {
            totalCommands: { type: 'number' },
            kiroAgentCommands: { type: 'number' },
            kiroCommands: { type: 'number' },
            safeCommands: { type: 'number' },
            moderateCommands: { type: 'number' },
            destructiveCommands: { type: 'number' },
            subcategories: {
              type: 'array',
              items: { type: 'string' }
            }
          },
          required: ['totalCommands', 'kiroAgentCommands', 'kiroCommands']
        }
      },
      required: ['version', 'timestamp', 'commands'],
      additionalProperties: false,
      definitions: {
        CommandMetadata: this.generateCommandSchema(commands, testResults) as any,
        ParameterInfo: this.generateParameterSchema() as any,
        CommandSignature: this.generateSignatureSchema() as any
      }
    };
    
    return schema;
  }
  
  /**
   * Generates TypeScript definitions for command interfaces.
   * 
   * @param commands Array of command metadata
   * @param testResults Optional test results for examples
   * @returns Array of TypeScript definitions
   */
  public generateTypeScriptDefinitions(
    commands: CommandMetadata[],
    testResults?: TestResult[]
  ): TypeScriptDefinition[] {
    console.log(`SchemaGenerator: Generating TypeScript definitions for ${commands.length} commands`);
    
    const definitions: TypeScriptDefinition[] = [];
    
    // Generate base interfaces
    definitions.push(this.generateCommandMetadataInterface());
    definitions.push(this.generateParameterInfoInterface());
    definitions.push(this.generateCommandSignatureInterface());
    definitions.push(this.generateDiscoveryResultsInterface());
    
    // Generate command-specific types
    definitions.push(this.generateCommandCategoryEnum(commands));
    definitions.push(this.generateRiskLevelEnum());
    definitions.push(this.generateSubcategoryEnum(commands));
    
    // Generate command registry interface
    definitions.push(this.generateCommandRegistryInterface(commands));
    
    // Generate WebSocket bridge interfaces if test results available
    if (testResults && testResults.length > 0) {
      definitions.push(this.generateWebSocketMessageInterface());
      definitions.push(this.generateExecutionRequestInterface());
      definitions.push(this.generateExecutionResponseInterface());
    }
    
    return definitions;
  }
  
  /**
   * Generates OpenAPI specification for WebSocket bridge.
   * 
   * @param commands Array of command metadata
   * @param testResults Optional test results for examples
   * @returns OpenAPI specification
   */
  public generateOpenApiSpec(
    commands: CommandMetadata[],
    testResults?: TestResult[]
  ): OpenApiSpec {
    console.log(`SchemaGenerator: Generating OpenAPI spec for ${commands.length} commands`);
    
    const spec: OpenApiSpec = {
      openapi: this.config.openApiVersion,
      info: {
        title: 'Kiro Command WebSocket Bridge API',
        version: '1.0.0',
        description: 'WebSocket API for remote execution of Kiro IDE commands'
      },
      servers: [
        {
          url: 'ws://localhost:8080',
          description: 'Local WebSocket server'
        }
      ],
      paths: this.generateApiPaths(commands, testResults),
      components: {
        schemas: this.generateApiSchemas(commands, testResults)
      }
    };
    
    return spec;
  }
  
  /**
   * Generates a complete schema package with all formats.
   * 
   * @param commands Array of command metadata
   * @param testResults Optional test results for examples
   * @returns Complete schema package
   */
  public generateCompleteSchemaPackage(
    commands: CommandMetadata[],
    testResults?: TestResult[]
  ): {
    jsonSchema: JsonSchema;
    typeScriptDefinitions: TypeScriptDefinition[];
    openApiSpec: OpenApiSpec;
    metadata: {
      generatedAt: Date;
      commandCount: number;
      testResultCount: number;
      schemaVersion: string;
    };
  } {
    console.log('SchemaGenerator: Generating complete schema package');
    
    const jsonSchema = this.generateCommandMetadataSchema(commands, testResults);
    const typeScriptDefinitions = this.generateTypeScriptDefinitions(commands, testResults);
    const openApiSpec = this.generateOpenApiSpec(commands, testResults);
    
    return {
      jsonSchema,
      typeScriptDefinitions,
      openApiSpec,
      metadata: {
        generatedAt: new Date(),
        commandCount: commands.length,
        testResultCount: testResults?.length || 0,
        schemaVersion: this.config.schemaVersion
      }
    };
  }
  
  /**
   * Generates JSON schema for individual command.
   * 
   * @param commands Array of commands for examples
   * @param testResults Optional test results
   * @returns JSON schema property
   */
  private generateCommandSchema(
    commands: CommandMetadata[],
    testResults?: TestResult[]
  ): JsonSchemaProperty {
    const examples: any[] = [];
    
    if (this.config.includeExamples && commands.length > 0) {
      examples.push({
        id: 'kiroAgent.agent.chatAgent',
        category: 'kiroAgent',
        subcategory: 'agent',
        displayName: 'Chat Agent',
        description: 'Initiates a chat session with the Kiro agent',
        riskLevel: 'safe',
        contextRequirements: ['Open workspace'],
        discoveredAt: '2025-01-10T14:30:00Z'
      });
    }
    
    return {
      type: 'object',
      description: 'Metadata for a discovered Kiro command',
      properties: {
        id: {
          type: 'string',
          description: 'Unique command identifier'
        },
        category: {
          type: 'string',
          enum: ['kiroAgent', 'kiro'],
          description: 'Primary command category'
        },
        subcategory: {
          type: 'string',
          description: 'Functional subcategory'
        },
        displayName: {
          type: 'string',
          description: 'Human-readable display name'
        },
        description: {
          type: 'string',
          description: 'Detailed description of command functionality'
        },
        riskLevel: {
          type: 'string',
          enum: ['safe', 'moderate', 'destructive'],
          description: 'Risk assessment for command execution'
        },
        contextRequirements: {
          type: 'array',
          items: { type: 'string' },
          description: 'Workspace context requirements'
        },
        discoveredAt: {
          type: 'string',
          format: 'date-time',
          description: 'When this command was discovered'
        },
        signature: {
          type: 'object',
          description: 'Command signature information',
          properties: {
            parameters: {
              type: 'array',
              items: { type: 'object' }
            },
            returnType: { type: 'string' },
            async: { type: 'boolean' },
            confidence: {
              type: 'string',
              enum: ['high', 'medium', 'low']
            }
          }
        }
      },
      required: ['id', 'category', 'subcategory', 'displayName', 'riskLevel', 'contextRequirements', 'discoveredAt'],
      examples: examples.length > 0 ? examples : undefined
    };
  }
  
  /**
   * Generates JSON schema for parameter information.
   * 
   * @returns JSON schema property
   */
  private generateParameterSchema(): JsonSchemaProperty {
    return {
      type: 'object',
      description: 'Information about a command parameter',
      properties: {
        name: { type: 'string', description: 'Parameter name' },
        type: { type: 'string', description: 'Parameter type' },
        required: { type: 'boolean', description: 'Whether parameter is required' },
        description: { type: 'string', description: 'Parameter description' },
        defaultValue: { type: 'any', description: 'Default value if known' },
        source: {
          type: 'string',
          enum: ['typescript', 'documentation', 'inference', 'manual'],
          description: 'How parameter info was discovered'
        }
      },
      required: ['name', 'type', 'required', 'source']
    };
  }
  
  /**
   * Generates JSON schema for command signature.
   * 
   * @returns JSON schema property
   */
  private generateSignatureSchema(): JsonSchemaProperty {
    return {
      type: 'object',
      description: 'Command signature information',
      properties: {
        parameters: {
          type: 'array',
          items: { type: 'object' },
          description: 'Parameters for this command'
        },
        returnType: { type: 'string', description: 'Return type if known' },
        async: { type: 'boolean', description: 'Whether command is async' },
        confidence: {
          type: 'string',
          enum: ['high', 'medium', 'low'],
          description: 'Confidence level in signature'
        },
        sources: {
          type: 'array',
          items: { type: 'string' },
          description: 'Sources used to determine signature'
        },
        researchedAt: {
          type: 'string',
          format: 'date-time',
          description: 'When signature was researched'
        }
      },
      required: ['parameters', 'async', 'confidence', 'sources', 'researchedAt']
    };
  }
  
  /**
   * Generates TypeScript interface for CommandMetadata.
   * 
   * @returns TypeScript definition
   */
  private generateCommandMetadataInterface(): TypeScriptDefinition {
    return {
      name: 'CommandMetadata',
      type: 'interface',
      documentation: 'Metadata for a discovered Kiro command',
      dependencies: ['ParameterInfo', 'CommandSignature'],
      code: `/**
 * Metadata for a discovered Kiro command.
 */
export interface CommandMetadata {
  /** Unique command identifier */
  readonly id: string;
  
  /** Primary command category */
  readonly category: 'kiroAgent' | 'kiro';
  
  /** Functional subcategory */
  readonly subcategory: string;
  
  /** Human-readable display name */
  readonly displayName: string;
  
  /** Detailed description of command functionality */
  readonly description?: string;
  
  /** Risk assessment for command execution */
  readonly riskLevel: 'safe' | 'moderate' | 'destructive';
  
  /** Workspace context requirements */
  readonly contextRequirements: string[];
  
  /** When this command was discovered */
  readonly discoveredAt: Date;
  
  /** Command signature information */
  readonly signature?: CommandSignature;
}`
    };
  }
  
  /**
   * Generates TypeScript interface for ParameterInfo.
   * 
   * @returns TypeScript definition
   */
  private generateParameterInfoInterface(): TypeScriptDefinition {
    return {
      name: 'ParameterInfo',
      type: 'interface',
      documentation: 'Information about a command parameter',
      dependencies: [],
      code: `/**
 * Information about a command parameter.
 */
export interface ParameterInfo {
  /** Parameter name */
  readonly name: string;
  
  /** Parameter type */
  readonly type: string;
  
  /** Whether parameter is required */
  readonly required: boolean;
  
  /** Parameter description */
  readonly description?: string;
  
  /** Default value if known */
  readonly defaultValue?: any;
  
  /** How parameter info was discovered */
  readonly source: 'typescript' | 'documentation' | 'inference' | 'manual';
}`
    };
  }
  
  /**
   * Generates TypeScript interface for CommandSignature.
   * 
   * @returns TypeScript definition
   */
  private generateCommandSignatureInterface(): TypeScriptDefinition {
    return {
      name: 'CommandSignature',
      type: 'interface',
      documentation: 'Command signature information',
      dependencies: ['ParameterInfo'],
      code: `/**
 * Command signature information.
 */
export interface CommandSignature {
  /** Parameters for this command */
  readonly parameters: ParameterInfo[];
  
  /** Return type if known */
  readonly returnType?: string;
  
  /** Whether command is async */
  readonly async: boolean;
  
  /** Confidence level in signature */
  readonly confidence: 'high' | 'medium' | 'low';
  
  /** Sources used to determine signature */
  readonly sources: string[];
  
  /** When signature was researched */
  readonly researchedAt: Date;
}`
    };
  }
  
  /**
   * Generates TypeScript interface for DiscoveryResults.
   * 
   * @returns TypeScript definition
   */
  private generateDiscoveryResultsInterface(): TypeScriptDefinition {
    return {
      name: 'DiscoveryResults',
      type: 'interface',
      documentation: 'Results of command discovery session',
      dependencies: ['CommandMetadata'],
      code: `/**
 * Results of command discovery session.
 */
export interface DiscoveryResults {
  /** Total number of commands discovered */
  readonly totalCommands: number;
  
  /** Number of kiroAgent commands */
  readonly kiroAgentCommands: number;
  
  /** Number of kiro platform commands */
  readonly kiroCommands: number;
  
  /** Array of discovered commands */
  readonly commands: CommandMetadata[];
  
  /** When discovery was performed */
  readonly discoveryTimestamp: Date;
  
  /** Statistical breakdown */
  readonly statistics: {
    safeCommands: number;
    moderateCommands: number;
    destructiveCommands: number;
    subcategories: string[];
    byCategory: Record<string, number>;
    bySubcategory: Record<string, number>;
  };
}`
    };
  }
  
  /**
   * Generates TypeScript enum for command categories.
   * 
   * @param commands Array of commands to analyze
   * @returns TypeScript definition
   */
  private generateCommandCategoryEnum(commands: CommandMetadata[]): TypeScriptDefinition {
    const categories = new Set(commands.map(c => c.category));
    const enumValues = Array.from(categories).map(cat => `  ${cat} = '${cat}'`).join(',\n');
    
    return {
      name: 'CommandCategory',
      type: 'enum',
      documentation: 'Available command categories',
      dependencies: [],
      code: `/**
 * Available command categories.
 */
export enum CommandCategory {
${enumValues}
}`
    };
  }
  
  /**
   * Generates TypeScript enum for risk levels.
   * 
   * @returns TypeScript definition
   */
  private generateRiskLevelEnum(): TypeScriptDefinition {
    return {
      name: 'RiskLevel',
      type: 'enum',
      documentation: 'Command risk levels',
      dependencies: [],
      code: `/**
 * Command risk levels.
 */
export enum RiskLevel {
  Safe = 'safe',
  Moderate = 'moderate',
  Destructive = 'destructive'
}`
    };
  }
  
  /**
   * Generates TypeScript enum for subcategories.
   * 
   * @param commands Array of commands to analyze
   * @returns TypeScript definition
   */
  private generateSubcategoryEnum(commands: CommandMetadata[]): TypeScriptDefinition {
    const subcategories = new Set(commands.map(c => c.subcategory));
    const enumValues = Array.from(subcategories)
      .map(sub => `  ${this.toPascalCase(sub)} = '${sub}'`)
      .join(',\n');
    
    return {
      name: 'CommandSubcategory',
      type: 'enum',
      documentation: 'Available command subcategories',
      dependencies: [],
      code: `/**
 * Available command subcategories.
 */
export enum CommandSubcategory {
${enumValues}
}`
    };
  }
  
  /**
   * Generates TypeScript interface for command registry.
   * 
   * @param commands Array of commands
   * @returns TypeScript definition
   */
  private generateCommandRegistryInterface(commands: CommandMetadata[]): TypeScriptDefinition {
    return {
      name: 'CommandRegistry',
      type: 'interface',
      documentation: 'Registry of all discovered commands',
      dependencies: ['CommandMetadata'],
      code: `/**
 * Registry of all discovered commands.
 */
export interface CommandRegistry {
  /** Commands indexed by ID */
  readonly byId: Record<string, CommandMetadata>;
  
  /** Commands grouped by category */
  readonly byCategory: Record<string, CommandMetadata[]>;
  
  /** Commands grouped by subcategory */
  readonly bySubcategory: Record<string, CommandMetadata[]>;
  
  /** Commands grouped by risk level */
  readonly byRiskLevel: Record<string, CommandMetadata[]>;
  
  /** Get command by ID */
  getCommand(id: string): CommandMetadata | undefined;
  
  /** Get commands by category */
  getCommandsByCategory(category: string): CommandMetadata[];
  
  /** Get commands by subcategory */
  getCommandsBySubcategory(subcategory: string): CommandMetadata[];
  
  /** Search commands by text */
  searchCommands(query: string): CommandMetadata[];
}`
    };
  }
  
  /**
   * Generates WebSocket message interface.
   * 
   * @returns TypeScript definition
   */
  private generateWebSocketMessageInterface(): TypeScriptDefinition {
    return {
      name: 'WebSocketMessage',
      type: 'interface',
      documentation: 'WebSocket message structure',
      dependencies: [],
      code: `/**
 * WebSocket message structure for command execution.
 */
export interface WebSocketMessage {
  /** Message type */
  readonly type: 'execute' | 'result' | 'error' | 'ping' | 'pong';
  
  /** Message ID for correlation */
  readonly id: string;
  
  /** Message timestamp */
  readonly timestamp: Date;
  
  /** Message payload */
  readonly payload: any;
}`
    };
  }
  
  /**
   * Generates execution request interface.
   * 
   * @returns TypeScript definition
   */
  private generateExecutionRequestInterface(): TypeScriptDefinition {
    return {
      name: 'ExecutionRequest',
      type: 'interface',
      documentation: 'Command execution request',
      dependencies: [],
      code: `/**
 * Command execution request via WebSocket.
 */
export interface ExecutionRequest {
  /** Command ID to execute */
  readonly commandId: string;
  
  /** Command parameters */
  readonly parameters: Record<string, any>;
  
  /** Execution timeout in milliseconds */
  readonly timeoutMs?: number;
  
  /** Whether to create workspace snapshot */
  readonly createSnapshot?: boolean;
  
  /** Whether to require confirmation for destructive commands */
  readonly requireConfirmation?: boolean;
}`
    };
  }
  
  /**
   * Generates execution response interface.
   * 
   * @returns TypeScript definition
   */
  private generateExecutionResponseInterface(): TypeScriptDefinition {
    return {
      name: 'ExecutionResponse',
      type: 'interface',
      documentation: 'Command execution response',
      dependencies: [],
      code: `/**
 * Command execution response via WebSocket.
 */
export interface ExecutionResponse {
  /** Whether execution was successful */
  readonly success: boolean;
  
  /** Command that was executed */
  readonly commandId: string;
  
  /** Execution duration in milliseconds */
  readonly duration: number;
  
  /** Command result if successful */
  readonly result?: any;
  
  /** Error information if failed */
  readonly error?: {
    message: string;
    type: string;
    stack?: string;
  };
  
  /** Detected side effects */
  readonly sideEffects: Array<{
    type: string;
    description: string;
    resource?: string;
    timestamp: Date;
  }>;
}`
    };
  }
  
  /**
   * Generates API paths for OpenAPI spec.
   * 
   * @param commands Array of commands
   * @param testResults Optional test results
   * @returns API paths
   */
  private generateApiPaths(
    commands: CommandMetadata[],
    testResults?: TestResult[]
  ): Record<string, OpenApiPath> {
    const paths: Record<string, OpenApiPath> = {};
    
    // WebSocket connection endpoint
    paths['/ws'] = {
      get: {
        summary: 'WebSocket Connection',
        description: 'Establish WebSocket connection for command execution',
        tags: ['WebSocket'],
        responses: {
          '101': {
            description: 'WebSocket connection established'
          },
          '400': {
            description: 'Bad request'
          }
        }
      }
    };
    
    // Command discovery endpoint
    paths['/commands'] = {
      get: {
        summary: 'Get Discovered Commands',
        description: 'Retrieve all discovered Kiro commands',
        tags: ['Commands'],
        responses: {
          '200': {
            description: 'List of discovered commands',
            content: {
              'application/json': {
                schema: {
                  $schema: this.config.schemaVersion,
                  title: 'Commands Array',
                  description: 'Array of command metadata',
                  type: 'array',
                  items: { $ref: '#/components/schemas/CommandMetadata' }
                } as JsonSchema
              }
            }
          }
        }
      }
    };
    
    // Command execution endpoint
    paths['/execute'] = {
      post: {
        summary: 'Execute Command',
        description: 'Execute a Kiro command with parameters',
        tags: ['Execution'],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { 
                $schema: this.config.schemaVersion,
                title: 'Execution Request',
                description: 'Command execution request',
                type: 'object',
                $ref: '#/components/schemas/ExecutionRequest' 
              } as JsonSchema
            }
          }
        },
        responses: {
          '200': {
            description: 'Command executed successfully',
            content: {
              'application/json': {
                schema: { 
                  $schema: this.config.schemaVersion,
                  title: 'Execution Response',
                  description: 'Command execution response',
                  type: 'object',
                  $ref: '#/components/schemas/ExecutionResponse' 
                } as JsonSchema
              }
            }
          },
          '400': {
            description: 'Invalid request'
          },
          '500': {
            description: 'Execution failed'
          }
        }
      }
    };
    
    return paths;
  }
  
  /**
   * Generates API schemas for OpenAPI spec.
   * 
   * @param commands Array of commands
   * @param testResults Optional test results
   * @returns API schemas
   */
  private generateApiSchemas(
    commands: CommandMetadata[],
    testResults?: TestResult[]
  ): Record<string, JsonSchema> {
    const schemas: Record<string, JsonSchema> = {};
    
    schemas.CommandMetadata = this.generateCommandSchema(commands, testResults) as JsonSchema;
    schemas.ParameterInfo = this.generateParameterSchema() as JsonSchema;
    schemas.CommandSignature = this.generateSignatureSchema() as JsonSchema;
    
    schemas.ExecutionRequest = {
      $schema: this.config.schemaVersion,
      title: 'Execution Request',
      description: 'Command execution request schema',
      type: 'object',
      properties: {
        commandId: { type: 'string', description: 'Command ID to execute' },
        parameters: { type: 'object', description: 'Command parameters' },
        timeoutMs: { type: 'number', description: 'Execution timeout' },
        createSnapshot: { type: 'boolean', description: 'Create workspace snapshot' },
        requireConfirmation: { type: 'boolean', description: 'Require confirmation' }
      },
      required: ['commandId', 'parameters']
    } as JsonSchema;
    
    schemas.ExecutionResponse = {
      $schema: this.config.schemaVersion,
      title: 'Execution Response',
      description: 'Command execution response schema',
      type: 'object',
      properties: {
        success: { type: 'boolean', description: 'Execution success' },
        commandId: { type: 'string', description: 'Executed command ID' },
        duration: { type: 'number', description: 'Execution duration' },
        result: { type: 'any', description: 'Command result' },
        error: {
          type: 'object',
          properties: {
            message: { type: 'string' },
            type: { type: 'string' },
            stack: { type: 'string' }
          }
        },
        sideEffects: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              type: { type: 'string' },
              description: { type: 'string' },
              resource: { type: 'string' },
              timestamp: { type: 'string', format: 'date-time' }
            }
          }
        }
      },
      required: ['success', 'commandId', 'duration']
    } as JsonSchema;
    
    return schemas;
  }
  
  /**
   * Converts string to PascalCase.
   * 
   * @param str String to convert
   * @returns PascalCase string
   */
  private toPascalCase(str: string): string {
    return str
      .split(/[-_\s]+/)
      .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join('');
  }
}