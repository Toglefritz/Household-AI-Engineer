/**
 * Result capture system for recording command execution results.
 * 
 * This module provides comprehensive result capture capabilities for
 * command testing, including return values, side effects, and metadata.
 */

import * as vscode from 'vscode';
import { ExecutionResult, ExecutionError, SideEffect } from './command-executor';
import { CommandMetadata } from '../types/command-metadata';

/**
 * Detailed test result with comprehensive execution information.
 */
export interface TestResult {
  /** Unique identifier for this test result */
  readonly id: string;
  
  /** Command that was tested */
  readonly commandId: string;
  
  /** Command metadata at time of testing */
  readonly commandMetadata: CommandMetadata;
  
  /** Parameters used in the test */
  readonly parameters: Record<string, any>;
  
  /** Execution result */
  readonly executionResult: ExecutionResult;
  
  /** Test session information */
  readonly session: TestSession;
  
  /** Analysis of the result */
  readonly analysis: ResultAnalysis;
  
  /** When this test was performed */
  readonly timestamp: Date;
  
  /** Tags for categorizing this test */
  readonly tags: string[];
  
  /** User notes about this test */
  readonly notes?: string;
}

/**
 * Information about the test session.
 */
export interface TestSession {
  /** Session identifier */
  readonly sessionId: string;
  
  /** VS Code version */
  readonly vscodeVersion: string;
  
  /** Kiro extension version (if available) */
  readonly kiroVersion?: string;
  
  /** Workspace information */
  readonly workspace: WorkspaceInfo;
  
  /** Environment variables relevant to testing */
  readonly environment: Record<string, string>;
  
  /** Test configuration used */
  readonly configuration: TestConfiguration;
}

/**
 * Workspace information at time of testing.
 */
export interface WorkspaceInfo {
  /** Workspace name */
  readonly name?: string;
  
  /** Workspace root path */
  readonly rootPath?: string;
  
  /** Number of folders in workspace */
  readonly folderCount: number;
  
  /** Number of open files */
  readonly openFileCount: number;
  
  /** Active file information */
  readonly activeFile?: {
    path: string;
    language: string;
    lineCount: number;
  };
  
  /** Workspace settings relevant to command execution */
  readonly relevantSettings: Record<string, any>;
}

/**
 * Test configuration used for execution.
 */
export interface TestConfiguration {
  /** Timeout used for execution */
  readonly timeoutMs: number;
  
  /** Whether snapshot was created */
  readonly snapshotEnabled: boolean;
  
  /** Whether confirmation was required */
  readonly confirmationRequired: boolean;
  
  /** Side effect monitoring level */
  readonly monitoringLevel: 'none' | 'basic' | 'comprehensive';
  
  /** Additional test options */
  readonly options: Record<string, any>;
}

/**
 * Analysis of command execution result.
 */
export interface ResultAnalysis {
  /** Whether the result matches expected behavior */
  readonly behaviorMatch: 'expected' | 'unexpected' | 'unknown';
  
  /** Performance characteristics */
  readonly performance: PerformanceAnalysis;
  
  /** Side effect analysis */
  readonly sideEffectAnalysis: SideEffectAnalysis;
  
  /** Return value analysis */
  readonly returnValueAnalysis: ReturnValueAnalysis;
  
  /** Risk assessment based on execution */
  readonly riskAssessment: RiskAssessment;
  
  /** Recommendations for future testing */
  readonly recommendations: string[];
}

/**
 * Performance analysis of command execution.
 */
export interface PerformanceAnalysis {
  /** Execution duration category */
  readonly durationCategory: 'fast' | 'moderate' | 'slow' | 'very_slow';
  
  /** Performance compared to similar commands */
  readonly relativePerformance: 'faster' | 'similar' | 'slower' | 'unknown';
  
  /** Whether performance is consistent across runs */
  readonly consistency: 'consistent' | 'variable' | 'unknown';
  
  /** Performance metrics */
  readonly metrics: {
    executionTimeMs: number;
    memoryImpact?: 'low' | 'medium' | 'high';
    cpuImpact?: 'low' | 'medium' | 'high';
  };
}

/**
 * Analysis of side effects detected during execution.
 */
export interface SideEffectAnalysis {
  /** Total number of side effects detected */
  readonly totalEffects: number;
  
  /** Side effects grouped by type */
  readonly effectsByType: Record<string, number>;
  
  /** Whether side effects were expected */
  readonly expectedEffects: boolean;
  
  /** Risk level of detected side effects */
  readonly riskLevel: 'none' | 'low' | 'medium' | 'high';
  
  /** Most significant side effects */
  readonly significantEffects: SideEffect[];
  
  /** Analysis of workspace state changes */
  readonly workspaceChanges: {
    filesCreated: number;
    filesModified: number;
    filesDeleted: number;
    settingsChanged: number;
    viewsOpened: number;
    viewsClosed: number;
  };
}

/**
 * Analysis of command return value.
 */
export interface ReturnValueAnalysis {
  /** Type of return value */
  readonly returnType: string;
  
  /** Whether return value is useful */
  readonly usefulness: 'very_useful' | 'somewhat_useful' | 'not_useful' | 'unknown';
  
  /** Structure analysis for complex return values */
  readonly structure?: {
    isObject: boolean;
    isArray: boolean;
    keyCount?: number;
    arrayLength?: number;
    nestedLevels: number;
  };
  
  /** Whether return value contains sensitive information */
  readonly containsSensitiveData: boolean;
  
  /** Serialization characteristics */
  readonly serialization: {
    isSerializable: boolean;
    jsonSize?: number;
    complexity: 'simple' | 'moderate' | 'complex';
  };
}

/**
 * Risk assessment based on command execution.
 */
export interface RiskAssessment {
  /** Overall risk level */
  readonly overallRisk: 'very_low' | 'low' | 'medium' | 'high' | 'very_high';
  
  /** Specific risk factors identified */
  readonly riskFactors: string[];
  
  /** Whether command should be used in automation */
  readonly automationSuitability: 'excellent' | 'good' | 'fair' | 'poor' | 'unsuitable';
  
  /** Recommended precautions */
  readonly precautions: string[];
  
  /** Whether command requires special handling */
  readonly requiresSpecialHandling: boolean;
}

/**
 * Captures and analyzes command execution results for testing purposes.
 * 
 * The ResultCapture class provides comprehensive result recording and analysis
 * capabilities for understanding command behavior and building reliable automation.
 */
export class ResultCapture {
  private readonly results: Map<string, TestResult> = new Map();
  private sessionCounter = 0;
  
  /**
   * Captures a command execution result with comprehensive analysis.
   * 
   * @param commandMetadata Metadata for the executed command
   * @param parameters Parameters used in execution
   * @param executionResult Result from command execution
   * @param configuration Test configuration used
   * @param notes Optional user notes about the test
   * @returns Promise that resolves to captured test result
   */
  public async captureResult(
    commandMetadata: CommandMetadata,
    parameters: Record<string, any>,
    executionResult: ExecutionResult,
    configuration: TestConfiguration,
    notes?: string
  ): Promise<TestResult> {
    const resultId = this.generateResultId();
    const timestamp = new Date();
    
    console.log(`ResultCapture: Capturing result for ${commandMetadata.id}`);
    
    // Gather session information
    const session = await this.gatherSessionInfo(configuration);
    
    // Analyze the execution result
    const analysis = await this.analyzeResult(
      commandMetadata,
      parameters,
      executionResult,
      session
    );
    
    // Generate tags based on result characteristics
    const tags = this.generateTags(commandMetadata, executionResult, analysis);
    
    const testResult: TestResult = {
      id: resultId,
      commandId: commandMetadata.id,
      commandMetadata,
      parameters,
      executionResult,
      session,
      analysis,
      timestamp,
      tags,
      notes
    };
    
    this.results.set(resultId, testResult);
    
    console.log(`ResultCapture: Captured result ${resultId} with ${analysis.sideEffectAnalysis.totalEffects} side effects`);
    
    return testResult;
  }
  
  /**
   * Retrieves a test result by ID.
   * 
   * @param resultId Result identifier
   * @returns Test result or undefined if not found
   */
  public getResult(resultId: string): TestResult | undefined {
    return this.results.get(resultId);
  }
  
  /**
   * Retrieves all test results for a specific command.
   * 
   * @param commandId Command identifier
   * @returns Array of test results for the command
   */
  public getResultsForCommand(commandId: string): TestResult[] {
    return Array.from(this.results.values())
      .filter(result => result.commandId === commandId)
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  }
  
  /**
   * Retrieves test results matching specific criteria.
   * 
   * @param criteria Search criteria
   * @returns Array of matching test results
   */
  public searchResults(criteria: {
    commandId?: string;
    success?: boolean;
    riskLevel?: string;
    tags?: string[];
    dateRange?: { start: Date; end: Date };
    hasNotes?: boolean;
  }): TestResult[] {
    return Array.from(this.results.values()).filter(result => {
      if (criteria.commandId && result.commandId !== criteria.commandId) {
        return false;
      }
      
      if (criteria.success !== undefined && result.executionResult.success !== criteria.success) {
        return false;
      }
      
      if (criteria.riskLevel && result.analysis.riskAssessment.overallRisk !== criteria.riskLevel) {
        return false;
      }
      
      if (criteria.tags && !criteria.tags.every(tag => result.tags.includes(tag))) {
        return false;
      }
      
      if (criteria.dateRange) {
        const timestamp = result.timestamp.getTime();
        if (timestamp < criteria.dateRange.start.getTime() || 
            timestamp > criteria.dateRange.end.getTime()) {
          return false;
        }
      }
      
      if (criteria.hasNotes !== undefined) {
        const hasNotes = !!result.notes;
        if (hasNotes !== criteria.hasNotes) {
          return false;
        }
      }
      
      return true;
    }).sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  }
  
  /**
   * Gets statistics about captured results.
   * 
   * @returns Result statistics
   */
  public getStatistics(): {
    totalResults: number;
    successfulResults: number;
    failedResults: number;
    commandsCovered: number;
    averageExecutionTime: number;
    riskDistribution: Record<string, number>;
    tagDistribution: Record<string, number>;
  } {
    const results = Array.from(this.results.values());
    
    const successfulResults = results.filter(r => r.executionResult.success).length;
    const failedResults = results.length - successfulResults;
    
    const commandsCovered = new Set(results.map(r => r.commandId)).size;
    
    const totalExecutionTime = results.reduce((sum, r) => sum + r.executionResult.duration, 0);
    const averageExecutionTime = results.length > 0 ? totalExecutionTime / results.length : 0;
    
    const riskDistribution: Record<string, number> = {};
    const tagDistribution: Record<string, number> = {};
    
    for (const result of results) {
      const risk = result.analysis.riskAssessment.overallRisk;
      riskDistribution[risk] = (riskDistribution[risk] || 0) + 1;
      
      for (const tag of result.tags) {
        tagDistribution[tag] = (tagDistribution[tag] || 0) + 1;
      }
    }
    
    return {
      totalResults: results.length,
      successfulResults,
      failedResults,
      commandsCovered,
      averageExecutionTime,
      riskDistribution,
      tagDistribution
    };
  }
  
  /**
   * Exports test results in various formats.
   * 
   * @param format Export format
   * @param criteria Optional filtering criteria
   * @returns Exported data as string
   */
  public exportResults(
    format: 'json' | 'csv' | 'markdown',
    criteria?: Parameters<typeof this.searchResults>[0]
  ): string {
    const results = criteria ? this.searchResults(criteria) : Array.from(this.results.values());
    
    switch (format) {
      case 'json':
        return JSON.stringify(results, null, 2);
        
      case 'csv':
        return this.exportToCsv(results);
        
      case 'markdown':
        return this.exportToMarkdown(results);
        
      default:
        throw new Error(`Unsupported export format: ${format}`);
    }
  }
  
  /**
   * Clears all captured results.
   */
  public clearResults(): void {
    this.results.clear();
    console.log('ResultCapture: Cleared all results');
  }
  
  /**
   * Generates a unique result identifier.
   * 
   * @returns Unique result ID
   */
  private generateResultId(): string {
    return `result_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /**
   * Gathers information about the current test session.
   * 
   * @param configuration Test configuration
   * @returns Promise that resolves to session information
   */
  private async gatherSessionInfo(configuration: TestConfiguration): Promise<TestSession> {
    const sessionId = `session_${++this.sessionCounter}_${Date.now()}`;
    
    // Get VS Code version
    const vscodeVersion = vscode.version;
    
    // Try to get Kiro version (if available)
    let kiroVersion: string | undefined;
    try {
      const kiroExtension = vscode.extensions.getExtension('kiro.kiro');
      kiroVersion = kiroExtension?.packageJSON?.version;
    } catch (error) {
      // Kiro extension not available or accessible
    }
    
    // Gather workspace information
    const workspace = await this.gatherWorkspaceInfo();
    
    // Gather relevant environment variables
    const environment: Record<string, string> = {};
    const envVars = ['NODE_ENV', 'VSCODE_PID', 'TERM'];
    for (const envVar of envVars) {
      const value = process.env[envVar];
      if (value) {
        environment[envVar] = value;
      }
    }
    
    return {
      sessionId,
      vscodeVersion,
      kiroVersion,
      workspace,
      environment,
      configuration
    };
  }
  
  /**
   * Gathers information about the current workspace.
   * 
   * @returns Promise that resolves to workspace information
   */
  private async gatherWorkspaceInfo(): Promise<WorkspaceInfo> {
    const workspaceFolders = vscode.workspace.workspaceFolders;
    const folderCount = workspaceFolders?.length || 0;
    
    let name: string | undefined;
    let rootPath: string | undefined;
    
    if (workspaceFolders && workspaceFolders.length > 0) {
      name = workspaceFolders[0].name;
      rootPath = workspaceFolders[0].uri.fsPath;
    }
    
    const openFileCount = vscode.workspace.textDocuments.length;
    
    let activeFile: WorkspaceInfo['activeFile'];
    if (vscode.window.activeTextEditor) {
      const editor = vscode.window.activeTextEditor;
      activeFile = {
        path: editor.document.uri.fsPath,
        language: editor.document.languageId,
        lineCount: editor.document.lineCount
      };
    }
    
    // Gather relevant workspace settings
    const config = vscode.workspace.getConfiguration();
    const relevantSettings: Record<string, any> = {};
    
    const settingsToCapture = [
      'editor.fontSize',
      'editor.tabSize',
      'files.autoSave',
      'workbench.colorTheme'
    ];
    
    for (const setting of settingsToCapture) {
      try {
        relevantSettings[setting] = config.get(setting);
      } catch (error) {
        // Ignore settings we can't access
      }
    }
    
    return {
      name,
      rootPath,
      folderCount,
      openFileCount,
      activeFile,
      relevantSettings
    };
  }
  
  /**
   * Analyzes a command execution result.
   * 
   * @param commandMetadata Command metadata
   * @param parameters Execution parameters
   * @param executionResult Execution result
   * @param session Session information
   * @returns Promise that resolves to result analysis
   */
  private async analyzeResult(
    commandMetadata: CommandMetadata,
    parameters: Record<string, any>,
    executionResult: ExecutionResult,
    session: TestSession
  ): Promise<ResultAnalysis> {
    // Analyze performance
    const performance = this.analyzePerformance(executionResult);
    
    // Analyze side effects
    const sideEffectAnalysis = this.analyzeSideEffects(executionResult.sideEffects);
    
    // Analyze return value
    const returnValueAnalysis = this.analyzeReturnValue(executionResult.result);
    
    // Assess risk
    const riskAssessment = this.assessRisk(
      commandMetadata,
      executionResult,
      sideEffectAnalysis,
      returnValueAnalysis
    );
    
    // Generate recommendations
    const recommendations = this.generateRecommendations(
      commandMetadata,
      executionResult,
      performance,
      sideEffectAnalysis,
      riskAssessment
    );
    
    return {
      behaviorMatch: 'unknown', // Would need historical data to determine
      performance,
      sideEffectAnalysis,
      returnValueAnalysis,
      riskAssessment,
      recommendations
    };
  }
  
  /**
   * Analyzes performance characteristics of command execution.
   * 
   * @param executionResult Execution result
   * @returns Performance analysis
   */
  private analyzePerformance(executionResult: ExecutionResult): PerformanceAnalysis {
    const duration = executionResult.duration;
    
    let durationCategory: PerformanceAnalysis['durationCategory'];
    if (duration < 100) {
      durationCategory = 'fast';
    } else if (duration < 1000) {
      durationCategory = 'moderate';
    } else if (duration < 5000) {
      durationCategory = 'slow';
    } else {
      durationCategory = 'very_slow';
    }
    
    return {
      durationCategory,
      relativePerformance: 'unknown', // Would need comparison data
      consistency: 'unknown', // Would need multiple runs
      metrics: {
        executionTimeMs: duration,
        memoryImpact: 'low', // Default assumption
        cpuImpact: 'low' // Default assumption
      }
    };
  }
  
  /**
   * Analyzes side effects detected during execution.
   * 
   * @param sideEffects Detected side effects
   * @returns Side effect analysis
   */
  private analyzeSideEffects(sideEffects: SideEffect[]): SideEffectAnalysis {
    const totalEffects = sideEffects.length;
    
    const effectsByType: Record<string, number> = {};
    for (const effect of sideEffects) {
      effectsByType[effect.type] = (effectsByType[effect.type] || 0) + 1;
    }
    
    // Determine risk level based on side effects
    let riskLevel: SideEffectAnalysis['riskLevel'] = 'none';
    if (totalEffects > 0) {
      const hasDestructiveEffects = sideEffects.some(e => 
        e.type === 'file_deleted' || e.type === 'workspace_changed'
      );
      const hasModificationEffects = sideEffects.some(e => 
        e.type === 'file_modified' || e.type === 'setting_changed'
      );
      
      if (hasDestructiveEffects) {
        riskLevel = 'high';
      } else if (hasModificationEffects) {
        riskLevel = 'medium';
      } else {
        riskLevel = 'low';
      }
    }
    
    // Identify most significant effects
    const significantEffects = sideEffects
      .filter(e => e.type === 'file_deleted' || e.type === 'workspace_changed' || e.type === 'setting_changed')
      .slice(0, 5); // Top 5 most significant
    
    // Analyze workspace changes
    const workspaceChanges = {
      filesCreated: effectsByType['file_created'] || 0,
      filesModified: effectsByType['file_modified'] || 0,
      filesDeleted: effectsByType['file_deleted'] || 0,
      settingsChanged: effectsByType['setting_changed'] || 0,
      viewsOpened: effectsByType['view_opened'] || 0,
      viewsClosed: effectsByType['view_closed'] || 0
    };
    
    return {
      totalEffects,
      effectsByType,
      expectedEffects: false, // Default assumption
      riskLevel,
      significantEffects,
      workspaceChanges
    };
  }
  
  /**
   * Analyzes command return value.
   * 
   * @param returnValue Command return value
   * @returns Return value analysis
   */
  private analyzeReturnValue(returnValue: any): ReturnValueAnalysis {
    const returnType = typeof returnValue;
    
    let structure: ReturnValueAnalysis['structure'];
    if (returnValue && typeof returnValue === 'object') {
      const isArray = Array.isArray(returnValue);
      structure = {
        isObject: !isArray,
        isArray,
        keyCount: isArray ? undefined : Object.keys(returnValue).length,
        arrayLength: isArray ? returnValue.length : undefined,
        nestedLevels: this.calculateNestingLevel(returnValue)
      };
    }
    
    // Check for sensitive data patterns
    const containsSensitiveData = this.checkForSensitiveData(returnValue);
    
    // Analyze serialization characteristics
    let isSerializable = true;
    let jsonSize: number | undefined;
    let complexity: ReturnValueAnalysis['serialization']['complexity'] = 'simple';
    
    try {
      const jsonString = JSON.stringify(returnValue);
      jsonSize = jsonString.length;
      
      if (jsonSize > 10000) {
        complexity = 'complex';
      } else if (jsonSize > 1000) {
        complexity = 'moderate';
      }
    } catch (error) {
      isSerializable = false;
      complexity = 'complex';
    }
    
    return {
      returnType,
      usefulness: 'unknown', // Would need domain knowledge to determine
      structure,
      containsSensitiveData,
      serialization: {
        isSerializable,
        jsonSize,
        complexity
      }
    };
  }
  
  /**
   * Assesses risk based on command execution characteristics.
   * 
   * @param commandMetadata Command metadata
   * @param executionResult Execution result
   * @param sideEffectAnalysis Side effect analysis
   * @param returnValueAnalysis Return value analysis
   * @returns Risk assessment
   */
  private assessRisk(
    commandMetadata: CommandMetadata,
    executionResult: ExecutionResult,
    sideEffectAnalysis: SideEffectAnalysis,
    returnValueAnalysis: ReturnValueAnalysis
  ): RiskAssessment {
    const riskFactors: string[] = [];
    let riskScore = 0;
    
    // Base risk from command metadata
    switch (commandMetadata.riskLevel) {
      case 'destructive':
        riskScore += 3;
        riskFactors.push('Command marked as destructive');
        break;
      case 'moderate':
        riskScore += 2;
        riskFactors.push('Command marked as moderate risk');
        break;
      case 'safe':
        riskScore += 0;
        break;
    }
    
    // Risk from side effects
    switch (sideEffectAnalysis.riskLevel) {
      case 'high':
        riskScore += 3;
        riskFactors.push('High-risk side effects detected');
        break;
      case 'medium':
        riskScore += 2;
        riskFactors.push('Medium-risk side effects detected');
        break;
      case 'low':
        riskScore += 1;
        riskFactors.push('Low-risk side effects detected');
        break;
    }
    
    // Risk from execution failure
    if (!executionResult.success) {
      riskScore += 1;
      riskFactors.push('Command execution failed');
    }
    
    // Risk from sensitive data
    if (returnValueAnalysis.containsSensitiveData) {
      riskScore += 2;
      riskFactors.push('Return value contains sensitive data');
    }
    
    // Determine overall risk level
    let overallRisk: RiskAssessment['overallRisk'];
    if (riskScore >= 6) {
      overallRisk = 'very_high';
    } else if (riskScore >= 4) {
      overallRisk = 'high';
    } else if (riskScore >= 2) {
      overallRisk = 'medium';
    } else if (riskScore >= 1) {
      overallRisk = 'low';
    } else {
      overallRisk = 'very_low';
    }
    
    // Determine automation suitability
    let automationSuitability: RiskAssessment['automationSuitability'];
    if (overallRisk === 'very_low' && executionResult.success) {
      automationSuitability = 'excellent';
    } else if (overallRisk === 'low' && executionResult.success) {
      automationSuitability = 'good';
    } else if (overallRisk === 'medium') {
      automationSuitability = 'fair';
    } else if (overallRisk === 'high') {
      automationSuitability = 'poor';
    } else {
      automationSuitability = 'unsuitable';
    }
    
    // Generate precautions
    const precautions: string[] = [];
    if (sideEffectAnalysis.riskLevel !== 'none') {
      precautions.push('Monitor workspace state changes');
    }
    if (commandMetadata.riskLevel === 'destructive') {
      precautions.push('Create workspace backup before execution');
    }
    if (returnValueAnalysis.containsSensitiveData) {
      precautions.push('Sanitize return values before logging');
    }
    
    const requiresSpecialHandling = overallRisk === 'high' || overallRisk === 'very_high';
    
    return {
      overallRisk,
      riskFactors,
      automationSuitability,
      precautions,
      requiresSpecialHandling
    };
  }
  
  /**
   * Generates recommendations for future testing and usage.
   * 
   * @param commandMetadata Command metadata
   * @param executionResult Execution result
   * @param performance Performance analysis
   * @param sideEffectAnalysis Side effect analysis
   * @param riskAssessment Risk assessment
   * @returns Array of recommendations
   */
  private generateRecommendations(
    commandMetadata: CommandMetadata,
    executionResult: ExecutionResult,
    performance: PerformanceAnalysis,
    sideEffectAnalysis: SideEffectAnalysis,
    riskAssessment: RiskAssessment
  ): string[] {
    const recommendations: string[] = [];
    
    if (!executionResult.success) {
      recommendations.push('Investigate execution failure and retry with different parameters');
    }
    
    if (performance.durationCategory === 'very_slow') {
      recommendations.push('Consider timeout handling for automation use');
    }
    
    if (sideEffectAnalysis.totalEffects > 5) {
      recommendations.push('Test with workspace snapshot to understand all side effects');
    }
    
    if (riskAssessment.overallRisk === 'high' || riskAssessment.overallRisk === 'very_high') {
      recommendations.push('Avoid using in automated workflows without manual oversight');
    }
    
    if (commandMetadata.signature?.confidence === 'low') {
      recommendations.push('Research command signature more thoroughly');
    }
    
    return recommendations;
  }
  
  /**
   * Generates tags for categorizing test results.
   * 
   * @param commandMetadata Command metadata
   * @param executionResult Execution result
   * @param analysis Result analysis
   * @returns Array of tags
   */
  private generateTags(
    commandMetadata: CommandMetadata,
    executionResult: ExecutionResult,
    analysis: ResultAnalysis
  ): string[] {
    const tags: string[] = [];
    
    // Basic tags
    tags.push(commandMetadata.category);
    tags.push(commandMetadata.subcategory);
    tags.push(commandMetadata.riskLevel);
    
    // Result tags
    tags.push(executionResult.success ? 'success' : 'failure');
    tags.push(analysis.performance.durationCategory);
    tags.push(analysis.riskAssessment.overallRisk);
    
    // Side effect tags
    if (analysis.sideEffectAnalysis.totalEffects > 0) {
      tags.push('has_side_effects');
    }
    
    // Special tags
    if (analysis.returnValueAnalysis.containsSensitiveData) {
      tags.push('sensitive_data');
    }
    
    if (analysis.riskAssessment.requiresSpecialHandling) {
      tags.push('special_handling');
    }
    
    return tags;
  }
  
  /**
   * Calculates nesting level of an object.
   * 
   * @param obj Object to analyze
   * @returns Maximum nesting level
   */
  private calculateNestingLevel(obj: any): number {
    if (typeof obj !== 'object' || obj === null) {
      return 0;
    }
    
    let maxLevel = 0;
    for (const value of Object.values(obj)) {
      if (typeof value === 'object' && value !== null) {
        maxLevel = Math.max(maxLevel, 1 + this.calculateNestingLevel(value));
      }
    }
    
    return maxLevel;
  }
  
  /**
   * Checks if a value contains sensitive data patterns.
   * 
   * @param value Value to check
   * @returns True if sensitive data is detected
   */
  private checkForSensitiveData(value: any): boolean {
    if (typeof value === 'string') {
      const sensitivePatterns = [
        /password/i,
        /token/i,
        /key/i,
        /secret/i,
        /credential/i,
        /auth/i
      ];
      
      return sensitivePatterns.some(pattern => pattern.test(value));
    }
    
    if (typeof value === 'object' && value !== null) {
      const jsonString = JSON.stringify(value).toLowerCase();
      return jsonString.includes('password') || 
             jsonString.includes('token') || 
             jsonString.includes('secret') ||
             jsonString.includes('credential');
    }
    
    return false;
  }
  
  /**
   * Exports results to CSV format.
   * 
   * @param results Results to export
   * @returns CSV string
   */
  private exportToCsv(results: TestResult[]): string {
    const headers = [
      'ID',
      'Command ID',
      'Success',
      'Duration (ms)',
      'Risk Level',
      'Side Effects',
      'Timestamp',
      'Notes'
    ];
    
    const rows = results.map(result => [
      result.id,
      result.commandId,
      result.executionResult.success.toString(),
      result.executionResult.duration.toString(),
      result.analysis.riskAssessment.overallRisk,
      result.analysis.sideEffectAnalysis.totalEffects.toString(),
      result.timestamp.toISOString(),
      result.notes || ''
    ]);
    
    return [headers, ...rows].map(row => row.join(',')).join('\n');
  }
  
  /**
   * Exports results to Markdown format.
   * 
   * @param results Results to export
   * @returns Markdown string
   */
  private exportToMarkdown(results: TestResult[]): string {
    let markdown = '# Command Test Results\n\n';
    
    for (const result of results) {
      markdown += `## ${result.commandId}\n\n`;
      markdown += `- **Result ID**: ${result.id}\n`;
      markdown += `- **Success**: ${result.executionResult.success ? '✅' : '❌'}\n`;
      markdown += `- **Duration**: ${result.executionResult.duration}ms\n`;
      markdown += `- **Risk Level**: ${result.analysis.riskAssessment.overallRisk}\n`;
      markdown += `- **Side Effects**: ${result.analysis.sideEffectAnalysis.totalEffects}\n`;
      markdown += `- **Timestamp**: ${result.timestamp.toISOString()}\n`;
      
      if (result.notes) {
        markdown += `- **Notes**: ${result.notes}\n`;
      }
      
      markdown += '\n';
    }
    
    return markdown;
  }
}