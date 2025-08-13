"use strict";
/**
 * Command registry scanner for discovering Kiro commands in VS Code.
 *
 * This module provides functionality to scan the VS Code command registry,
 * identify Kiro-related commands, and categorize them for further analysis.
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
exports.CommandRegistryScanner = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Scans the VS Code command registry to discover and categorize Kiro commands.
 *
 * The CommandRegistryScanner identifies all commands related to Kiro functionality,
 * categorizes them by type and purpose, and provides initial metadata for each command.
 */
class CommandRegistryScanner {
    /**
     * Discovers all Kiro-related commands from the VS Code command registry.
     *
     * This method scans all registered commands and filters for those that
     * belong to the Kiro ecosystem (kiroAgent and kiro prefixes).
     *
     * @returns Promise that resolves to array of discovered command metadata
     * @throws Error if command discovery fails
     */
    async discoverKiroCommands() {
        try {
            console.log('Starting Kiro command discovery...');
            // Get all registered commands from VS Code
            const allCommands = await vscode.commands.getCommands(true);
            console.log(`Found ${allCommands.length} total registered commands`);
            // Filter for Kiro-related commands
            const kiroCommands = this.filterKiroCommands(allCommands);
            console.log(`Found ${kiroCommands.length} Kiro-related commands`);
            // Convert to command metadata
            const commandMetadata = kiroCommands.map(commandId => this.createCommandMetadata(commandId));
            // Log discovery results
            this.logDiscoveryResults(commandMetadata);
            return commandMetadata;
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            throw new Error(`Failed to discover Kiro commands: ${errorMessage}`);
        }
    }
    /**
     * Filters the command list to include only Kiro-related commands.
     *
     * This method identifies commands that belong to the Kiro ecosystem
     * by checking for specific prefixes and patterns.
     *
     * @param allCommands Array of all registered command IDs
     * @returns Array of Kiro-related command IDs
     */
    filterKiroCommands(allCommands) {
        const kiroCommands = allCommands.filter(commandId => {
            // Check for kiroAgent commands (main AI functionality)
            if (commandId.startsWith('kiroAgent.')) {
                return true;
            }
            // Check for kiro commands (platform features)
            if (commandId.startsWith('kiro.')) {
                return true;
            }
            // Exclude our own research extension commands
            if (commandId.startsWith('kiroCommandResearch.')) {
                return false;
            }
            return false;
        });
        return kiroCommands.sort(); // Sort alphabetically for consistent ordering
    }
    /**
     * Creates initial command metadata for a discovered command.
     *
     * This method generates basic metadata structure for a command,
     * including categorization and initial signature information.
     *
     * @param commandId The command identifier
     * @returns CommandMetadata object with initial information
     */
    createCommandMetadata(commandId) {
        const category = commandId.startsWith('kiroAgent.') ? 'kiroAgent' : 'kiro';
        const subcategory = this.extractSubcategory(commandId);
        const displayName = this.generateDisplayName(commandId);
        const riskLevel = this.assessRiskLevel(commandId);
        const contextRequirements = this.inferContextRequirements(commandId);
        return {
            id: commandId,
            category,
            subcategory,
            displayName,
            description: `${category} command: ${displayName}`,
            riskLevel,
            contextRequirements,
            discoveredAt: new Date()
        };
    }
    /**
     * Extracts the subcategory from a command ID.
     *
     * This method analyzes the command structure to determine
     * the functional subcategory (e.g., 'agent', 'execution', 'spec').
     *
     * @param commandId The command identifier
     * @returns Subcategory string
     */
    extractSubcategory(commandId) {
        const parts = commandId.split('.');
        if (parts.length < 2) {
            return 'unknown';
        }
        // For kiroAgent commands, the second part is usually the subcategory
        if (commandId.startsWith('kiroAgent.')) {
            if (parts.length >= 3) {
                return parts[1]; // e.g., 'agent' from 'kiroAgent.agent.chatAgent'
            }
            return 'core';
        }
        // For kiro commands, the second part is the subcategory
        if (commandId.startsWith('kiro.')) {
            if (parts.length >= 3) {
                return parts[1]; // e.g., 'spec' from 'kiro.spec.createSpec'
            }
            return 'platform';
        }
        return 'unknown';
    }
    /**
     * Generates a human-readable display name from a command ID.
     *
     * This method converts camelCase command names into readable titles
     * by adding spaces and proper capitalization.
     *
     * @param commandId The command identifier
     * @returns Human-readable display name
     */
    generateDisplayName(commandId) {
        // Remove the prefix and get the command name
        const withoutPrefix = commandId.replace(/^(kiroAgent\.|kiro\.)/, '');
        // Split on dots and camelCase boundaries
        const parts = withoutPrefix
            .split('.')
            .flatMap(part => part.split(/(?=[A-Z])/))
            .filter(part => part.length > 0);
        // Capitalize each part and join with spaces
        const displayName = parts
            .map(part => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
            .join(' ');
        return displayName || 'Unknown Command';
    }
    /**
     * Assesses the risk level of a command based on its functionality.
     *
     * This method analyzes the command name and purpose to determine
     * the potential risk of executing the command during testing.
     *
     * @param commandId The command identifier
     * @returns Risk level assessment
     */
    assessRiskLevel(commandId) {
        const lowerCommandId = commandId.toLowerCase();
        // Destructive operations
        const destructivePatterns = [
            'delete', 'remove', 'purge', 'clear', 'reset', 'abort',
            'deleteaccount', 'purgeMetadata', 'restoreAllChanges'
        ];
        if (destructivePatterns.some(pattern => lowerCommandId.includes(pattern))) {
            return 'destructive';
        }
        // Moderate risk operations
        const moderatePatterns = [
            'create', 'execute', 'trigger', 'apply', 'modify', 'update',
            'install', 'enable', 'disable', 'set', 'write'
        ];
        if (moderatePatterns.some(pattern => lowerCommandId.includes(pattern))) {
            return 'moderate';
        }
        // Safe operations (read-only, UI, navigation)
        return 'safe';
    }
    /**
     * Infers context requirements for a command based on its functionality.
     *
     * This method analyzes the command to determine what workspace
     * or application context is needed for successful execution.
     *
     * @param commandId The command identifier
     * @returns Array of context requirement descriptions
     */
    inferContextRequirements(commandId) {
        const requirements = [];
        // File-related commands need active editor
        if (commandId.includes('file') || commandId.includes('File')) {
            requirements.push('Active file editor');
        }
        // Spec-related commands need workspace
        if (commandId.includes('spec') || commandId.includes('Spec')) {
            requirements.push('Open workspace');
        }
        // Agent execution commands need workspace
        if (commandId.includes('execution') || commandId.includes('agent')) {
            requirements.push('Open workspace');
        }
        // MCP commands need MCP configuration
        if (commandId.includes('mcp')) {
            requirements.push('MCP server configuration');
        }
        // Hook commands need hook configuration
        if (commandId.includes('hook')) {
            requirements.push('Agent hooks configuration');
        }
        return requirements;
    }
    /**
     * Creates discovery results from discovered commands.
     *
     * This method packages the discovered commands with statistics
     * and metadata for storage and export.
     *
     * @param commands Array of discovered command metadata
     * @returns Complete discovery results
     */
    createDiscoveryResults(commands) {
        const statistics = this.generateStatistics(commands);
        return {
            totalCommands: commands.length,
            kiroAgentCommands: commands.filter(cmd => cmd.category === 'kiroAgent').length,
            kiroCommands: commands.filter(cmd => cmd.category === 'kiro').length,
            commands,
            discoveryTimestamp: new Date(),
            statistics
        };
    }
    /**
     * Logs the results of command discovery for debugging and analysis.
     *
     * This method provides detailed logging of discovery results,
     * including categorization statistics and command breakdowns.
     *
     * @param commands Array of discovered command metadata
     */
    logDiscoveryResults(commands) {
        console.log('=== KIRO COMMAND DISCOVERY RESULTS ===');
        console.log(`Total commands discovered: ${commands.length}`);
        // Count by category
        const categoryStats = {};
        const subcategoryStats = {};
        const riskStats = {};
        for (const command of commands) {
            // Category stats
            categoryStats[command.category] = (categoryStats[command.category] || 0) + 1;
            // Subcategory stats
            const subcategoryKey = `${command.category}.${command.subcategory}`;
            subcategoryStats[subcategoryKey] = (subcategoryStats[subcategoryKey] || 0) + 1;
            // Risk stats
            riskStats[command.riskLevel] = (riskStats[command.riskLevel] || 0) + 1;
        }
        // Log category breakdown
        console.log('\nCommands by category:');
        for (const [category, count] of Object.entries(categoryStats)) {
            console.log(`  ${category}: ${count} commands`);
        }
        // Log subcategory breakdown
        console.log('\nCommands by subcategory:');
        for (const [subcategory, count] of Object.entries(subcategoryStats)) {
            console.log(`  ${subcategory}: ${count} commands`);
        }
        // Log risk assessment
        console.log('\nCommands by risk level:');
        for (const [risk, count] of Object.entries(riskStats)) {
            console.log(`  ${risk}: ${count} commands`);
        }
        // Log sample commands from each category
        console.log('\nSample commands:');
        const kiroAgentSamples = commands
            .filter(cmd => cmd.category === 'kiroAgent')
            .slice(0, 5);
        const kiroSamples = commands
            .filter(cmd => cmd.category === 'kiro')
            .slice(0, 5);
        console.log('  kiroAgent samples:');
        for (const cmd of kiroAgentSamples) {
            console.log(`    - ${cmd.id} (${cmd.subcategory}, ${cmd.riskLevel})`);
        }
        console.log('  kiro samples:');
        for (const cmd of kiroSamples) {
            console.log(`    - ${cmd.id} (${cmd.subcategory}, ${cmd.riskLevel})`);
        }
        console.log('=== END DISCOVERY RESULTS ===');
    }
    /**
     * Generates statistics about discovered commands.
     *
     * This method provides summary statistics about the discovered
     * commands for reporting and analysis purposes.
     *
     * @param commands Array of discovered command metadata
     * @returns Statistics object with counts and breakdowns
     */
    generateStatistics(commands) {
        const subcategories = [...new Set(commands.map(cmd => cmd.subcategory))].sort();
        const byCategory = {};
        const bySubcategory = {};
        for (const command of commands) {
            byCategory[command.category] = (byCategory[command.category] || 0) + 1;
            bySubcategory[command.subcategory] = (bySubcategory[command.subcategory] || 0) + 1;
        }
        return {
            safeCommands: commands.filter(cmd => cmd.riskLevel === 'safe').length,
            moderateCommands: commands.filter(cmd => cmd.riskLevel === 'moderate').length,
            destructiveCommands: commands.filter(cmd => cmd.riskLevel === 'destructive').length,
            subcategories,
            byCategory,
            bySubcategory
        };
    }
}
exports.CommandRegistryScanner = CommandRegistryScanner;
//# sourceMappingURL=command-registry-scanner.js.map