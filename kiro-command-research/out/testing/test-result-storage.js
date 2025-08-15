"use strict";
/**
 * Test result storage and retrieval system for persisting command test data.
 *
 * This module provides comprehensive storage capabilities for test results,
 * including file-based persistence, search functionality, and data management.
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
exports.TestResultStorage = void 0;
const vscode = __importStar(require("vscode"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
/**
 * Manages persistent storage and retrieval of command test results.
 *
 * The TestResultStorage class provides comprehensive data management for
 * test results, including efficient storage, search, and export capabilities.
 */
class TestResultStorage {
    constructor(config = {}) {
        this.resultCache = new Map();
        this.indexCache = new Map(); // commandId -> resultIds
        this.config = {
            baseDirectory: path.join(vscode.workspace.workspaceFolders?.[0]?.uri.fsPath || '.', '.kiro', 'command-research', 'test-results'),
            maxResultsPerCommand: 100,
            maxResultAge: 30,
            compressOldResults: true,
            createBackups: true,
            format: 'json',
            ...config
        };
        this.ensureDirectoryExists();
    }
    /**
     * Stores a test result persistently.
     *
     * @param result Test result to store
     * @returns Promise that resolves when result is stored
     */
    async storeResult(result) {
        console.log(`TestResultStorage: Storing result ${result.id} for command ${result.commandId}`);
        try {
            // Add to cache
            this.resultCache.set(result.id, result);
            // Update command index
            const commandResults = this.indexCache.get(result.commandId) || [];
            if (!commandResults.includes(result.id)) {
                commandResults.push(result.id);
                commandResults.sort((a, b) => {
                    const resultA = this.resultCache.get(a);
                    const resultB = this.resultCache.get(b);
                    if (!resultA || !resultB)
                        return 0;
                    return resultB.timestamp.getTime() - resultA.timestamp.getTime();
                });
                this.indexCache.set(result.commandId, commandResults);
            }
            // Write to file system
            await this.writeResultToFile(result);
            // Update command index file
            await this.updateCommandIndex(result.commandId);
            // Cleanup old results if needed
            await this.cleanupOldResults(result.commandId);
            console.log(`TestResultStorage: Successfully stored result ${result.id}`);
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error(`TestResultStorage: Failed to store result ${result.id}:`, errorMessage);
            throw new Error(`Failed to store test result: ${errorMessage}`);
        }
    }
    /**
     * Retrieves a test result by ID.
     *
     * @param resultId Result identifier
     * @returns Promise that resolves to test result or undefined
     */
    async getResult(resultId) {
        // Check cache first
        if (this.resultCache.has(resultId)) {
            return this.resultCache.get(resultId);
        }
        // Try to load from file system
        try {
            const result = await this.loadResultFromFile(resultId);
            if (result) {
                this.resultCache.set(resultId, result);
            }
            return result;
        }
        catch (error) {
            console.warn(`Failed to load result ${resultId}:`, error);
            return undefined;
        }
    }
    /**
     * Retrieves all test results for a specific command.
     *
     * @param commandId Command identifier
     * @param limit Maximum number of results to return
     * @returns Promise that resolves to array of test results
     */
    async getResultsForCommand(commandId, limit) {
        console.log(`TestResultStorage: Loading results for command ${commandId}`);
        try {
            // Load command index if not cached
            if (!this.indexCache.has(commandId)) {
                await this.loadCommandIndex(commandId);
            }
            const resultIds = this.indexCache.get(commandId) || [];
            const limitedIds = limit ? resultIds.slice(0, limit) : resultIds;
            const results = [];
            for (const resultId of limitedIds) {
                const result = await this.getResult(resultId);
                if (result) {
                    results.push(result);
                }
            }
            return results;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error(`TestResultStorage: Failed to load results for command ${commandId}:`, errorMessage);
            return [];
        }
    }
    /**
     * Searches for test results matching specific criteria.
     *
     * @param criteria Search criteria
     * @returns Promise that resolves to matching test results
     */
    async searchResults(criteria) {
        console.log('TestResultStorage: Searching results with criteria:', criteria);
        try {
            let results = [];
            if (criteria.commandId) {
                // Search within specific command
                results = await this.getResultsForCommand(criteria.commandId);
            }
            else {
                // Search across all commands
                results = await this.getAllResults();
            }
            // Apply filters
            results = this.applyFilters(results, criteria);
            // Apply sorting
            results = this.applySorting(results, criteria);
            // Apply limit
            if (criteria.limit && criteria.limit > 0) {
                results = results.slice(0, criteria.limit);
            }
            console.log(`TestResultStorage: Found ${results.length} matching results`);
            return results;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('TestResultStorage: Search failed:', errorMessage);
            return [];
        }
    }
    /**
     * Gets storage statistics and health information.
     *
     * @returns Promise that resolves to storage statistics
     */
    async getStatistics() {
        console.log('TestResultStorage: Calculating storage statistics');
        try {
            const allResults = await this.getAllResults();
            let totalSizeBytes = 0;
            let oldestResult;
            let newestResult;
            const resultsByCommand = {};
            const healthIssues = [];
            for (const result of allResults) {
                // Update command counts
                resultsByCommand[result.commandId] = (resultsByCommand[result.commandId] || 0) + 1;
                // Update date range
                if (!oldestResult || result.timestamp < oldestResult) {
                    oldestResult = result.timestamp;
                }
                if (!newestResult || result.timestamp > newestResult) {
                    newestResult = result.timestamp;
                }
                // Estimate size (rough calculation)
                totalSizeBytes += JSON.stringify(result).length;
            }
            // Check for health issues
            if (totalSizeBytes > 100 * 1024 * 1024) { // 100MB
                healthIssues.push('Storage size is large (>100MB)');
            }
            const maxAge = Date.now() - (this.config.maxResultAge * 24 * 60 * 60 * 1000);
            const oldResults = allResults.filter(r => r.timestamp.getTime() < maxAge);
            if (oldResults.length > 0) {
                healthIssues.push(`${oldResults.length} results are older than ${this.config.maxResultAge} days`);
            }
            // Check for commands with too many results
            for (const [commandId, count] of Object.entries(resultsByCommand)) {
                if (count > this.config.maxResultsPerCommand) {
                    healthIssues.push(`Command ${commandId} has ${count} results (max: ${this.config.maxResultsPerCommand})`);
                }
            }
            const health = healthIssues.length === 0 ? 'healthy' :
                healthIssues.length <= 2 ? 'warning' : 'error';
            return {
                totalResults: allResults.length,
                commandsWithResults: Object.keys(resultsByCommand).length,
                totalSizeBytes,
                oldestResult,
                newestResult,
                resultsByCommand,
                health,
                healthIssues
            };
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('TestResultStorage: Failed to calculate statistics:', errorMessage);
            return {
                totalResults: 0,
                commandsWithResults: 0,
                totalSizeBytes: 0,
                resultsByCommand: {},
                health: 'error',
                healthIssues: [`Failed to calculate statistics: ${errorMessage}`]
            };
        }
    }
    /**
     * Exports test results in various formats.
     *
     * @param criteria Search criteria for results to export
     * @param options Export options
     * @returns Promise that resolves to exported data
     */
    async exportResults(criteria, options) {
        console.log('TestResultStorage: Exporting results');
        const results = await this.searchResults(criteria);
        switch (options.format) {
            case 'json':
                return this.exportToJson(results, options);
            case 'csv':
                return this.exportToCsv(results, options);
            case 'markdown':
                return this.exportToMarkdown(results, options);
            case 'html':
                return this.exportToHtml(results, options);
            default:
                throw new Error(`Unsupported export format: ${options.format}`);
        }
    }
    /**
     * Deletes a test result.
     *
     * @param resultId Result identifier
     * @returns Promise that resolves to true if result was deleted
     */
    async deleteResult(resultId) {
        console.log(`TestResultStorage: Deleting result ${resultId}`);
        try {
            // Get result to find command ID
            const result = await this.getResult(resultId);
            if (!result) {
                return false;
            }
            // Remove from cache
            this.resultCache.delete(resultId);
            // Update command index
            const commandResults = this.indexCache.get(result.commandId) || [];
            const updatedResults = commandResults.filter(id => id !== resultId);
            this.indexCache.set(result.commandId, updatedResults);
            // Delete file
            await this.deleteResultFile(resultId);
            // Update command index file
            await this.updateCommandIndex(result.commandId);
            console.log(`TestResultStorage: Successfully deleted result ${resultId}`);
            return true;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error(`TestResultStorage: Failed to delete result ${resultId}:`, errorMessage);
            return false;
        }
    }
    /**
     * Cleans up old test results based on configuration.
     *
     * @returns Promise that resolves to number of results cleaned up
     */
    async cleanup() {
        console.log('TestResultStorage: Starting cleanup');
        let cleanedCount = 0;
        try {
            const allResults = await this.getAllResults();
            const maxAge = Date.now() - (this.config.maxResultAge * 24 * 60 * 60 * 1000);
            // Group results by command
            const resultsByCommand = {};
            for (const result of allResults) {
                if (!resultsByCommand[result.commandId]) {
                    resultsByCommand[result.commandId] = [];
                }
                resultsByCommand[result.commandId].push(result);
            }
            // Cleanup each command's results
            for (const [commandId, results] of Object.entries(resultsByCommand)) {
                // Sort by timestamp (newest first)
                results.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
                // Remove old results
                const oldResults = results.filter(r => r.timestamp.getTime() < maxAge);
                for (const result of oldResults) {
                    await this.deleteResult(result.id);
                    cleanedCount++;
                }
                // Remove excess results (keep only maxResultsPerCommand)
                const excessResults = results.slice(this.config.maxResultsPerCommand);
                for (const result of excessResults) {
                    await this.deleteResult(result.id);
                    cleanedCount++;
                }
            }
            console.log(`TestResultStorage: Cleanup completed, removed ${cleanedCount} results`);
            return cleanedCount;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('TestResultStorage: Cleanup failed:', errorMessage);
            return cleanedCount;
        }
    }
    /**
     * Creates a backup of all test results.
     *
     * @param backupPath Optional backup file path
     * @returns Promise that resolves to backup file path
     */
    async createBackup(backupPath) {
        console.log('TestResultStorage: Creating backup');
        if (!backupPath) {
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            backupPath = path.join(this.config.baseDirectory, `backup-${timestamp}.json`);
        }
        try {
            const allResults = await this.getAllResults();
            const backupData = {
                timestamp: new Date().toISOString(),
                version: '1.0',
                resultCount: allResults.length,
                results: allResults
            };
            await fs.promises.writeFile(backupPath, JSON.stringify(backupData, null, 2), 'utf8');
            console.log(`TestResultStorage: Backup created at ${backupPath}`);
            return backupPath;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('TestResultStorage: Backup failed:', errorMessage);
            throw new Error(`Failed to create backup: ${errorMessage}`);
        }
    }
    /**
     * Restores test results from a backup file.
     *
     * @param backupPath Backup file path
     * @param overwrite Whether to overwrite existing results
     * @returns Promise that resolves to number of results restored
     */
    async restoreFromBackup(backupPath, overwrite = false) {
        console.log(`TestResultStorage: Restoring from backup ${backupPath}`);
        try {
            const backupContent = await fs.promises.readFile(backupPath, 'utf8');
            const backupData = JSON.parse(backupContent);
            if (!backupData.results || !Array.isArray(backupData.results)) {
                throw new Error('Invalid backup file format');
            }
            let restoredCount = 0;
            for (const resultData of backupData.results) {
                try {
                    // Convert timestamp strings back to Date objects
                    const result = {
                        ...resultData,
                        timestamp: new Date(resultData.timestamp),
                        executionResult: {
                            ...resultData.executionResult,
                            startTime: new Date(resultData.executionResult.startTime),
                            endTime: new Date(resultData.executionResult.endTime)
                        },
                        session: {
                            ...resultData.session,
                            workspace: resultData.session.workspace
                        }
                    };
                    // Check if result already exists
                    const existing = await this.getResult(result.id);
                    if (existing && !overwrite) {
                        continue;
                    }
                    await this.storeResult(result);
                    restoredCount++;
                }
                catch (error) {
                    console.warn(`Failed to restore result ${resultData.id}:`, error);
                }
            }
            console.log(`TestResultStorage: Restored ${restoredCount} results from backup`);
            return restoredCount;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('TestResultStorage: Restore failed:', errorMessage);
            throw new Error(`Failed to restore from backup: ${errorMessage}`);
        }
    }
    /**
     * Ensures the storage directory exists.
     */
    ensureDirectoryExists() {
        try {
            if (!fs.existsSync(this.config.baseDirectory)) {
                fs.mkdirSync(this.config.baseDirectory, { recursive: true });
            }
        }
        catch (error) {
            console.error('Failed to create storage directory:', error);
        }
    }
    /**
     * Writes a test result to file.
     *
     * @param result Test result to write
     * @returns Promise that resolves when file is written
     */
    async writeResultToFile(result) {
        const filePath = this.getResultFilePath(result.id);
        const data = JSON.stringify(result, null, 2);
        await fs.promises.writeFile(filePath, data, 'utf8');
    }
    /**
     * Loads a test result from file.
     *
     * @param resultId Result identifier
     * @returns Promise that resolves to test result or undefined
     */
    async loadResultFromFile(resultId) {
        const filePath = this.getResultFilePath(resultId);
        try {
            const data = await fs.promises.readFile(filePath, 'utf8');
            const resultData = JSON.parse(data);
            // Convert timestamp strings back to Date objects
            return {
                ...resultData,
                timestamp: new Date(resultData.timestamp),
                executionResult: {
                    ...resultData.executionResult,
                    startTime: new Date(resultData.executionResult.startTime),
                    endTime: new Date(resultData.executionResult.endTime)
                }
            };
        }
        catch (error) {
            if (error.code !== 'ENOENT') {
                console.warn(`Failed to load result file ${filePath}:`, error);
            }
            return undefined;
        }
    }
    /**
     * Deletes a result file.
     *
     * @param resultId Result identifier
     * @returns Promise that resolves when file is deleted
     */
    async deleteResultFile(resultId) {
        const filePath = this.getResultFilePath(resultId);
        try {
            await fs.promises.unlink(filePath);
        }
        catch (error) {
            if (error.code !== 'ENOENT') {
                throw error;
            }
        }
    }
    /**
     * Gets the file path for a result.
     *
     * @param resultId Result identifier
     * @returns File path
     */
    getResultFilePath(resultId) {
        return path.join(this.config.baseDirectory, 'results', `${resultId}.json`);
    }
    /**
     * Gets the file path for a command index.
     *
     * @param commandId Command identifier
     * @returns File path
     */
    getCommandIndexPath(commandId) {
        const safeCommandId = commandId.replace(/[^a-zA-Z0-9.-]/g, '_');
        return path.join(this.config.baseDirectory, 'indexes', `${safeCommandId}.json`);
    }
    /**
     * Updates the command index file.
     *
     * @param commandId Command identifier
     * @returns Promise that resolves when index is updated
     */
    async updateCommandIndex(commandId) {
        const indexPath = this.getCommandIndexPath(commandId);
        const resultIds = this.indexCache.get(commandId) || [];
        const indexData = {
            commandId,
            resultIds,
            lastUpdated: new Date().toISOString()
        };
        // Ensure indexes directory exists
        const indexDir = path.dirname(indexPath);
        if (!fs.existsSync(indexDir)) {
            fs.mkdirSync(indexDir, { recursive: true });
        }
        await fs.promises.writeFile(indexPath, JSON.stringify(indexData, null, 2), 'utf8');
    }
    /**
     * Loads a command index from file.
     *
     * @param commandId Command identifier
     * @returns Promise that resolves when index is loaded
     */
    async loadCommandIndex(commandId) {
        const indexPath = this.getCommandIndexPath(commandId);
        try {
            const data = await fs.promises.readFile(indexPath, 'utf8');
            const indexData = JSON.parse(data);
            this.indexCache.set(commandId, indexData.resultIds || []);
        }
        catch (error) {
            if (error.code !== 'ENOENT') {
                console.warn(`Failed to load command index ${indexPath}:`, error);
            }
            this.indexCache.set(commandId, []);
        }
    }
    /**
     * Gets all test results from storage.
     *
     * @returns Promise that resolves to all test results
     */
    async getAllResults() {
        const results = [];
        try {
            const resultsDir = path.join(this.config.baseDirectory, 'results');
            if (!fs.existsSync(resultsDir)) {
                return results;
            }
            const files = await fs.promises.readdir(resultsDir);
            for (const file of files) {
                if (file.endsWith('.json')) {
                    const resultId = file.replace('.json', '');
                    const result = await this.getResult(resultId);
                    if (result) {
                        results.push(result);
                    }
                }
            }
        }
        catch (error) {
            console.warn('Failed to load all results:', error);
        }
        return results;
    }
    /**
     * Applies filters to search results.
     *
     * @param results Results to filter
     * @param criteria Search criteria
     * @returns Filtered results
     */
    applyFilters(results, criteria) {
        return results.filter(result => {
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
            if (criteria.minDuration !== undefined && result.executionResult.duration < criteria.minDuration) {
                return false;
            }
            if (criteria.maxDuration !== undefined && result.executionResult.duration > criteria.maxDuration) {
                return false;
            }
            if (criteria.hasNotes !== undefined) {
                const hasNotes = !!result.notes;
                if (hasNotes !== criteria.hasNotes) {
                    return false;
                }
            }
            if (criteria.sideEffectRange) {
                const sideEffectCount = result.analysis.sideEffectAnalysis.totalEffects;
                if (sideEffectCount < criteria.sideEffectRange.min ||
                    sideEffectCount > criteria.sideEffectRange.max) {
                    return false;
                }
            }
            if (criteria.textSearch) {
                const searchText = criteria.textSearch.toLowerCase();
                const searchableText = [
                    result.commandMetadata.description || '',
                    result.notes || '',
                    result.executionResult.error?.message || ''
                ].join(' ').toLowerCase();
                if (!searchableText.includes(searchText)) {
                    return false;
                }
            }
            return true;
        });
    }
    /**
     * Applies sorting to search results.
     *
     * @param results Results to sort
     * @param criteria Search criteria
     * @returns Sorted results
     */
    applySorting(results, criteria) {
        const sortBy = criteria.sortBy || 'timestamp';
        const sortOrder = criteria.sortOrder || 'desc';
        return results.sort((a, b) => {
            let comparison = 0;
            switch (sortBy) {
                case 'timestamp':
                    comparison = a.timestamp.getTime() - b.timestamp.getTime();
                    break;
                case 'duration':
                    comparison = a.executionResult.duration - b.executionResult.duration;
                    break;
                case 'commandId':
                    comparison = a.commandId.localeCompare(b.commandId);
                    break;
                case 'riskLevel':
                    const riskOrder = ['very_low', 'low', 'medium', 'high', 'very_high'];
                    const aRisk = riskOrder.indexOf(a.analysis.riskAssessment.overallRisk);
                    const bRisk = riskOrder.indexOf(b.analysis.riskAssessment.overallRisk);
                    comparison = aRisk - bRisk;
                    break;
            }
            return sortOrder === 'asc' ? comparison : -comparison;
        });
    }
    /**
     * Cleans up old results for a specific command.
     *
     * @param commandId Command identifier
     * @returns Promise that resolves when cleanup is complete
     */
    async cleanupOldResults(commandId) {
        const results = await this.getResultsForCommand(commandId);
        if (results.length <= this.config.maxResultsPerCommand) {
            return;
        }
        // Sort by timestamp (newest first)
        results.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
        // Remove excess results
        const excessResults = results.slice(this.config.maxResultsPerCommand);
        for (const result of excessResults) {
            await this.deleteResult(result.id);
        }
    }
    /**
     * Exports results to JSON format.
     *
     * @param results Results to export
     * @param options Export options
     * @returns JSON string
     */
    exportToJson(results, options) {
        const exportData = results.map(result => {
            const exported = {
                id: result.id,
                commandId: result.commandId,
                timestamp: result.timestamp.toISOString(),
                success: result.executionResult.success,
                duration: result.executionResult.duration,
                tags: result.tags
            };
            if (options.includeExecutionDetails) {
                exported.executionResult = result.executionResult;
            }
            if (options.includeAnalysis) {
                exported.analysis = result.analysis;
            }
            if (options.includeSideEffects) {
                exported.sideEffects = result.executionResult.sideEffects;
            }
            if (result.notes) {
                exported.notes = result.notes;
            }
            return exported;
        });
        return JSON.stringify(exportData, null, 2);
    }
    /**
     * Exports results to CSV format.
     *
     * @param results Results to export
     * @param options Export options
     * @returns CSV string
     */
    exportToCsv(results, options) {
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
     * @param options Export options
     * @returns Markdown string
     */
    exportToMarkdown(results, options) {
        let markdown = '# Command Test Results Export\n\n';
        markdown += `Generated: ${new Date().toISOString()}\n`;
        markdown += `Total Results: ${results.length}\n\n`;
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
            if (options.includeAnalysis) {
                markdown += '\n### Analysis\n\n';
                markdown += `- **Performance**: ${result.analysis.performance.durationCategory}\n`;
                markdown += `- **Automation Suitability**: ${result.analysis.riskAssessment.automationSuitability}\n`;
                if (result.analysis.recommendations.length > 0) {
                    markdown += '\n**Recommendations**:\n';
                    for (const rec of result.analysis.recommendations) {
                        markdown += `- ${rec}\n`;
                    }
                }
            }
            markdown += '\n---\n\n';
        }
        return markdown;
    }
    /**
     * Exports results to HTML format.
     *
     * @param results Results to export
     * @param options Export options
     * @returns HTML string
     */
    exportToHtml(results, options) {
        let html = `
<!DOCTYPE html>
<html>
<head>
    <title>Command Test Results Export</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .result { border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; }
        .success { border-left: 5px solid #4CAF50; }
        .failure { border-left: 5px solid #f44336; }
        .metadata { color: #666; font-size: 0.9em; }
        .tags { margin: 10px 0; }
        .tag { background: #e1e1e1; padding: 2px 6px; border-radius: 3px; margin-right: 5px; font-size: 0.8em; }
    </style>
</head>
<body>
    <h1>Command Test Results Export</h1>
    <p>Generated: ${new Date().toISOString()}</p>
    <p>Total Results: ${results.length}</p>
`;
        for (const result of results) {
            const successClass = result.executionResult.success ? 'success' : 'failure';
            const successIcon = result.executionResult.success ? '✅' : '❌';
            html += `
    <div class="result ${successClass}">
        <h3>${result.commandId} ${successIcon}</h3>
        <div class="metadata">
            <strong>ID:</strong> ${result.id}<br>
            <strong>Duration:</strong> ${result.executionResult.duration}ms<br>
            <strong>Risk Level:</strong> ${result.analysis.riskAssessment.overallRisk}<br>
            <strong>Side Effects:</strong> ${result.analysis.sideEffectAnalysis.totalEffects}<br>
            <strong>Timestamp:</strong> ${result.timestamp.toISOString()}
        </div>
`;
            if (result.tags.length > 0) {
                html += '        <div class="tags">';
                for (const tag of result.tags) {
                    html += `<span class="tag">${tag}</span>`;
                }
                html += '</div>';
            }
            if (result.notes) {
                html += `        <p><strong>Notes:</strong> ${result.notes}</p>`;
            }
            html += '    </div>';
        }
        html += `
</body>
</html>`;
        return html;
    }
}
exports.TestResultStorage = TestResultStorage;
//# sourceMappingURL=test-result-storage.js.map