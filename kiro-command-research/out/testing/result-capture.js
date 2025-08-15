"use strict";
/**
 * Result capture system for recording command execution results.
 *
 * This module provides comprehensive result capture capabilities for
 * command testing, including return values, side effects, and metadata.
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
exports.ResultCapture = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Captures and analyzes command execution results for testing purposes.
 *
 * The ResultCapture class provides comprehensive result recording and analysis
 * capabilities for understanding command behavior and building reliable automation.
 */
class ResultCapture {
    constructor() {
        this.results = new Map();
        this.sessionCounter = 0;
    }
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
    async captureResult(commandMetadata, parameters, executionResult, configuration, notes) {
        const resultId = this.generateResultId();
        const timestamp = new Date();
        console.log(`ResultCapture: Capturing result for ${commandMetadata.id}`);
        // Gather session information
        const session = await this.gatherSessionInfo(configuration);
        // Analyze the execution result
        const analysis = await this.analyzeResult(commandMetadata, parameters, executionResult, session);
        // Generate tags based on result characteristics
        const tags = this.generateTags(commandMetadata, executionResult, analysis);
        const testResult = {
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
    getResult(resultId) {
        return this.results.get(resultId);
    }
    /**
     * Retrieves all test results for a specific command.
     *
     * @param commandId Command identifier
     * @returns Array of test results for the command
     */
    getResultsForCommand(commandId) {
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
    searchResults(criteria) {
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
    getStatistics() {
        const results = Array.from(this.results.values());
        const successfulResults = results.filter(r => r.executionResult.success).length;
        const failedResults = results.length - successfulResults;
        const commandsCovered = new Set(results.map(r => r.commandId)).size;
        const totalExecutionTime = results.reduce((sum, r) => sum + r.executionResult.duration, 0);
        const averageExecutionTime = results.length > 0 ? totalExecutionTime / results.length : 0;
        const riskDistribution = {};
        const tagDistribution = {};
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
    exportResults(format, criteria) {
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
    clearResults() {
        this.results.clear();
        console.log('ResultCapture: Cleared all results');
    }
    /**
     * Generates a unique result identifier.
     *
     * @returns Unique result ID
     */
    generateResultId() {
        return `result_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    /**
     * Gathers information about the current test session.
     *
     * @param configuration Test configuration
     * @returns Promise that resolves to session information
     */
    async gatherSessionInfo(configuration) {
        const sessionId = `session_${++this.sessionCounter}_${Date.now()}`;
        // Get VS Code version
        const vscodeVersion = vscode.version;
        // Try to get Kiro version (if available)
        let kiroVersion;
        try {
            const kiroExtension = vscode.extensions.getExtension('kiro.kiro');
            kiroVersion = kiroExtension?.packageJSON?.version;
        }
        catch (error) {
            // Kiro extension not available or accessible
        }
        // Gather workspace information
        const workspace = await this.gatherWorkspaceInfo();
        // Gather relevant environment variables
        const environment = {};
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
    async gatherWorkspaceInfo() {
        const workspaceFolders = vscode.workspace.workspaceFolders;
        const folderCount = workspaceFolders?.length || 0;
        let name;
        let rootPath;
        if (workspaceFolders && workspaceFolders.length > 0) {
            name = workspaceFolders[0].name;
            rootPath = workspaceFolders[0].uri.fsPath;
        }
        const openFileCount = vscode.workspace.textDocuments.length;
        let activeFile;
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
        const relevantSettings = {};
        const settingsToCapture = [
            'editor.fontSize',
            'editor.tabSize',
            'files.autoSave',
            'workbench.colorTheme'
        ];
        for (const setting of settingsToCapture) {
            try {
                relevantSettings[setting] = config.get(setting);
            }
            catch (error) {
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
    async analyzeResult(commandMetadata, parameters, executionResult, session) {
        // Analyze performance
        const performance = this.analyzePerformance(executionResult);
        // Analyze side effects
        const sideEffectAnalysis = this.analyzeSideEffects(executionResult.sideEffects);
        // Analyze return value
        const returnValueAnalysis = this.analyzeReturnValue(executionResult.result);
        // Assess risk
        const riskAssessment = this.assessRisk(commandMetadata, executionResult, sideEffectAnalysis, returnValueAnalysis);
        // Generate recommendations
        const recommendations = this.generateRecommendations(commandMetadata, executionResult, performance, sideEffectAnalysis, riskAssessment);
        return {
            behaviorMatch: 'unknown',
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
    analyzePerformance(executionResult) {
        const duration = executionResult.duration;
        let durationCategory;
        if (duration < 100) {
            durationCategory = 'fast';
        }
        else if (duration < 1000) {
            durationCategory = 'moderate';
        }
        else if (duration < 5000) {
            durationCategory = 'slow';
        }
        else {
            durationCategory = 'very_slow';
        }
        return {
            durationCategory,
            relativePerformance: 'unknown',
            consistency: 'unknown',
            metrics: {
                executionTimeMs: duration,
                memoryImpact: 'low',
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
    analyzeSideEffects(sideEffects) {
        const totalEffects = sideEffects.length;
        const effectsByType = {};
        for (const effect of sideEffects) {
            effectsByType[effect.type] = (effectsByType[effect.type] || 0) + 1;
        }
        // Determine risk level based on side effects
        let riskLevel = 'none';
        if (totalEffects > 0) {
            const hasDestructiveEffects = sideEffects.some(e => e.type === 'file_deleted' || e.type === 'workspace_changed');
            const hasModificationEffects = sideEffects.some(e => e.type === 'file_modified' || e.type === 'setting_changed');
            if (hasDestructiveEffects) {
                riskLevel = 'high';
            }
            else if (hasModificationEffects) {
                riskLevel = 'medium';
            }
            else {
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
            expectedEffects: false,
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
    analyzeReturnValue(returnValue) {
        const returnType = typeof returnValue;
        let structure;
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
        let jsonSize;
        let complexity = 'simple';
        try {
            const jsonString = JSON.stringify(returnValue);
            jsonSize = jsonString.length;
            if (jsonSize > 10000) {
                complexity = 'complex';
            }
            else if (jsonSize > 1000) {
                complexity = 'moderate';
            }
        }
        catch (error) {
            isSerializable = false;
            complexity = 'complex';
        }
        return {
            returnType,
            usefulness: 'unknown',
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
    assessRisk(commandMetadata, executionResult, sideEffectAnalysis, returnValueAnalysis) {
        const riskFactors = [];
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
        let overallRisk;
        if (riskScore >= 6) {
            overallRisk = 'very_high';
        }
        else if (riskScore >= 4) {
            overallRisk = 'high';
        }
        else if (riskScore >= 2) {
            overallRisk = 'medium';
        }
        else if (riskScore >= 1) {
            overallRisk = 'low';
        }
        else {
            overallRisk = 'very_low';
        }
        // Determine automation suitability
        let automationSuitability;
        if (overallRisk === 'very_low' && executionResult.success) {
            automationSuitability = 'excellent';
        }
        else if (overallRisk === 'low' && executionResult.success) {
            automationSuitability = 'good';
        }
        else if (overallRisk === 'medium') {
            automationSuitability = 'fair';
        }
        else if (overallRisk === 'high') {
            automationSuitability = 'poor';
        }
        else {
            automationSuitability = 'unsuitable';
        }
        // Generate precautions
        const precautions = [];
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
    generateRecommendations(commandMetadata, executionResult, performance, sideEffectAnalysis, riskAssessment) {
        const recommendations = [];
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
    generateTags(commandMetadata, executionResult, analysis) {
        const tags = [];
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
    calculateNestingLevel(obj) {
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
    checkForSensitiveData(value) {
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
    exportToCsv(results) {
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
    exportToMarkdown(results) {
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
exports.ResultCapture = ResultCapture;
//# sourceMappingURL=result-capture.js.map