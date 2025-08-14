/**
 * Parameter researcher for discovering command signatures and parameters.
 * 
 * This module provides functionality to research command parameters through
 * various methods including TypeScript definitions, documentation, and
 * safe introspection techniques.
 */

import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Information about a command parameter.
 */
export interface ParameterInfo {
  /** Parameter name */
  name: string;
  
  /** Parameter type (inferred) */
  type: string;
  
  /** Whether parameter is required */
  required: boolean;
  
  /** Parameter description if available */
  description?: string;
  
  /** Default value if known */
  defaultValue?: any;
  
  /** How this parameter info was discovered */
  source: 'typescript' | 'documentation' | 'inference' | 'manual';
}

/**
 * Command signature information.
 */
export interface CommandSignature {
  /** Command ID */
  commandId: string;
  
  /** Parameters for this command */
  parameters: ParameterInfo[];
  
  /** Return type if known */
  returnType?: string;
  
  /** Whether command is async */
  async: boolean;
  
  /** Confidence level in this signature */
  confidence: 'high' | 'medium' | 'low';
  
  /** Sources used to determine signature */
  sources: string[];
  
  /** When signature was researched */
  researchedAt: Date;
}

/**
 * Researches command parameters and signatures using various techniques.
 * 
 * The ParameterResearcher attempts to discover command signatures through
 * multiple approaches, from safest to more intrusive.
 */
export class ParameterResearcher {
  
  /**
   * Researches parameters for a list of commands.
   * 
   * @param commandIds Array of command IDs to research
   * @returns Promise that resolves to array of command signatures
   */
  public async researchCommands(commandIds: string[]): Promise<CommandSignature[]> {
    const signatures: CommandSignature[] = [];
    
    console.log(`ParameterResearcher: Starting research for ${commandIds.length} commands...`);
    
    for (const commandId of commandIds) {
      try {
        const signature = await this.researchCommand(commandId);
        signatures.push(signature);
      } catch (error: unknown) {
        const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
        console.warn(`Failed to research command ${commandId}: ${errorMessage}`);
        
        // Create minimal signature for failed research
        signatures.push({
          commandId,
          parameters: [],
          async: true,
          confidence: 'low',
          sources: ['error'],
          researchedAt: new Date()
        });
      }
    }
    
    console.log(`ParameterResearcher: Completed research for ${signatures.length} commands`);
    return signatures;
  }
  
  /**
   * Researches parameters for a single command.
   * 
   * @param commandId Command ID to research
   * @returns Promise that resolves to command signature
   */
  public async researchCommand(commandId: string): Promise<CommandSignature> {
    const sources: string[] = [];
    const parameters: ParameterInfo[] = [];
    let confidence: 'high' | 'medium' | 'low' = 'low';
    let returnType: string | undefined;
    let isAsync = true; // Assume async by default for VS Code commands
    
    // Method 1: Try to find TypeScript definitions
    const tsDefinitions = await this.findTypeScriptDefinitions(commandId);
    if (tsDefinitions) {
      parameters.push(...tsDefinitions.parameters);
      returnType = tsDefinitions.returnType;
      confidence = 'high';
      sources.push('typescript-definitions');
    }
    
    // Method 2: Analyze command structure for common patterns
    const inferredParams = this.inferParametersFromStructure(commandId);
    if (inferredParams.length > 0) {
      // Merge with existing parameters, avoiding duplicates
      for (const param of inferredParams) {
        if (!parameters.find(p => p.name === param.name)) {
          parameters.push(param);
        }
      }
      sources.push('structure-inference');
      if (confidence === 'low') {
        confidence = 'medium';
      }
    }
    
    // Method 3: Check for known command patterns
    const knownPattern = this.checkKnownPatterns(commandId);
    if (knownPattern) {
      // Add known parameters
      for (const param of knownPattern.parameters) {
        if (!parameters.find(p => p.name === param.name)) {
          parameters.push(param);
        }
      }
      returnType = returnType || knownPattern.returnType;
      sources.push('known-patterns');
      if (confidence === 'low') {
        confidence = 'medium';
      }
    }
    
    return {
      commandId,
      parameters,
      returnType,
      async: isAsync,
      confidence,
      sources,
      researchedAt: new Date()
    };
  }
  
  /**
   * Attempts to find TypeScript definitions for a command.
   * 
   * This method looks for TypeScript definition files that might
   * contain command signatures.
   * 
   * @param commandId Command ID to search for
   * @returns Promise that resolves to signature info or null
   */
  private async findTypeScriptDefinitions(commandId: string): Promise<{ parameters: ParameterInfo[]; returnType?: string } | null> {
    try {
      // This is a placeholder for TypeScript definition discovery
      // In a real implementation, this would:
      // 1. Search for .d.ts files in the workspace
      // 2. Parse TypeScript AST to find command definitions
      // 3. Extract parameter information from function signatures
      
      // For now, return null to indicate no TypeScript definitions found
      return null;
    } catch (error: unknown) {
      console.warn(`Failed to find TypeScript definitions for ${commandId}:`, error);
      return null;
    }
  }
  
  /**
   * Infers parameters from command structure and naming patterns.
   * 
   * @param commandId Command ID to analyze
   * @returns Array of inferred parameters
   */
  private inferParametersFromStructure(commandId: string): ParameterInfo[] {
    const parameters: ParameterInfo[] = [];
    
    // Common patterns based on command structure
    if (commandId.includes('.file') || commandId.includes('File')) {
      parameters.push({
        name: 'uri',
        type: 'vscode.Uri',
        required: false,
        description: 'File URI to operate on',
        source: 'inference'
      });
    }
    
    if (commandId.includes('.create') || commandId.includes('Create')) {
      parameters.push({
        name: 'name',
        type: 'string',
        required: true,
        description: 'Name for the item to create',
        source: 'inference'
      });
    }
    
    if (commandId.includes('.execute') || commandId.includes('Execute')) {
      parameters.push({
        name: 'options',
        type: 'object',
        required: false,
        description: 'Execution options',
        source: 'inference'
      });
    }
    
    if (commandId.includes('.open') || commandId.includes('Open')) {
      parameters.push({
        name: 'resource',
        type: 'string | vscode.Uri',
        required: false,
        description: 'Resource to open',
        source: 'inference'
      });
    }
    
    return parameters;
  }
  
  /**
   * Checks for known command patterns and their typical signatures.
   * 
   * @param commandId Command ID to check
   * @returns Known pattern info or null
   */
  private checkKnownPatterns(commandId: string): { parameters: ParameterInfo[]; returnType?: string } | null {
    // Known patterns for common Kiro commands
    const knownPatterns: Record<string, { parameters: ParameterInfo[]; returnType?: string }> = {
      // Agent commands
      'kiroAgent.agent.chatAgent': {
        parameters: [
          {
            name: 'message',
            type: 'string',
            required: false,
            description: 'Message to send to the agent',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      'kiroAgent.agent.promptAgent': {
        parameters: [
          {
            name: 'prompt',
            type: 'string',
            required: true,
            description: 'Prompt to send to the agent',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      'kiroAgent.agent.askAgent': {
        parameters: [
          {
            name: 'question',
            type: 'string',
            required: true,
            description: 'Question to ask the agent',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      // Spec creation and management
      'kiroAgent.initiateSpecCreation': {
        parameters: [
          {
            name: 'featureDescription',
            type: 'string',
            required: false,
            description: 'Description of the feature to create a spec for',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      // Execution commands
      'kiroAgent.executions.triggerAgent': {
        parameters: [
          {
            name: 'executionOptions',
            type: 'object',
            required: false,
            description: 'Options for agent execution including context and parameters',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      'kiroAgent.executions.addToExecution': {
        parameters: [
          {
            name: 'content',
            type: 'string',
            required: true,
            description: 'Content to add to the current execution',
            source: 'manual'
          },
          {
            name: 'executionId',
            type: 'string',
            required: false,
            description: 'ID of the execution to add to (optional, uses current if not specified)',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      // File operations
      'kiroAgent.revealFile': {
        parameters: [
          {
            name: 'uri',
            type: 'vscode.Uri',
            required: true,
            description: 'URI of file to reveal',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      // Spec operations
      'kiro.spec.navigateToRequirements': {
        parameters: [],
        returnType: 'Promise<void>'
      },
      
      'kiro.spec.navigateToDesign': {
        parameters: [],
        returnType: 'Promise<void>'
      },
      
      'kiro.spec.navigateToTasks': {
        parameters: [],
        returnType: 'Promise<void>'
      },
      
      'kiro.spec.explorerCreateSpec': {
        parameters: [
          {
            name: 'specName',
            type: 'string',
            required: false,
            description: 'Name for the new spec',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      'kiro.spec.explorerDeleteSpec': {
        parameters: [
          {
            name: 'specPath',
            type: 'string',
            required: true,
            description: 'Path to the spec to delete',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      // File and context operations
      'kiroAgent.selectFilesAsContext': {
        parameters: [
          {
            name: 'files',
            type: 'vscode.Uri[]',
            required: false,
            description: 'Array of file URIs to add as context',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      'kiroAgent.focusContinueInput': {
        parameters: [],
        returnType: 'Promise<void>'
      },
      
      'kiroAgent.sendMainUserInput': {
        parameters: [
          {
            name: 'input',
            type: 'string',
            required: true,
            description: 'User input to send to the agent',
            source: 'manual'
          }
        ],
        returnType: 'Promise<void>'
      },
      
      // Codebase operations
      'kiroAgent.rebuildCodebaseIndex': {
        parameters: [],
        returnType: 'Promise<void>'
      },
      
      'kiroAgent.codebaseForceReIndex': {
        parameters: [],
        returnType: 'Promise<void>'
      }
    };
    
    return knownPatterns[commandId] || null;
  }
  
  /**
   * Gets statistics about parameter research results.
   * 
   * @param signatures Array of researched command signatures
   * @returns Statistics about the research
   */
  public getResearchStatistics(signatures: CommandSignature[]): ParameterResearchStatistics {
    const stats: ParameterResearchStatistics = {
      totalCommands: signatures.length,
      highConfidence: signatures.filter(s => s.confidence === 'high').length,
      mediumConfidence: signatures.filter(s => s.confidence === 'medium').length,
      lowConfidence: signatures.filter(s => s.confidence === 'low').length,
      withParameters: signatures.filter(s => s.parameters.length > 0).length,
      withoutParameters: signatures.filter(s => s.parameters.length === 0).length,
      sources: this.countSources(signatures),
      researchTimestamp: new Date()
    };
    
    return stats;
  }
  
  /**
   * Counts the sources used across all signatures.
   * 
   * @param signatures Array of command signatures
   * @returns Record of source counts
   */
  private countSources(signatures: CommandSignature[]): Record<string, number> {
    const sourceCounts: Record<string, number> = {};
    
    for (const signature of signatures) {
      for (const source of signature.sources) {
        sourceCounts[source] = (sourceCounts[source] || 0) + 1;
      }
    }
    
    return sourceCounts;
  }
}

/**
 * Statistics about parameter research results.
 */
export interface ParameterResearchStatistics {
  /** Total number of commands researched */
  totalCommands: number;
  
  /** Number of high confidence signatures */
  highConfidence: number;
  
  /** Number of medium confidence signatures */
  mediumConfidence: number;
  
  /** Number of low confidence signatures */
  lowConfidence: number;
  
  /** Number of commands with parameters discovered */
  withParameters: number;
  
  /** Number of commands with no parameters */
  withoutParameters: number;
  
  /** Count of research sources used */
  sources: Record<string, number>;
  
  /** When research was performed */
  researchTimestamp: Date;
}