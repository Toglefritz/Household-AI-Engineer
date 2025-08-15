"use strict";
/**
 * Documentation export system for generating comprehensive command documentation.
 *
 * This module provides multi-format documentation export capabilities with
 * version tracking, change documentation, and example generation.
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
exports.DocumentationExporter = void 0;
const vscode = __importStar(require("vscode"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const schema_generator_1 = require("../documentation/schema-generator");
/**
 * Exports command documentation in multiple formats with version tracking.
 *
 * The DocumentationExporter provides comprehensive documentation generation
 * capabilities for integration documentation and API reference materials.
 */
class DocumentationExporter {
    constructor(config = {}) {
        const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath || '.';
        this.config = {
            outputDirectory: path.join(workspaceRoot, '.kiro', 'command-research', 'exports'),
            formats: ['markdown', 'json', 'typescript'],
            includeExamples: true,
            includeStatistics: true,
            includeChangeTracking: true,
            version: '1.0.0',
            ...config
        };
        this.schemaGenerator = new schema_generator_1.SchemaGenerator({
            includeExamples: this.config.includeExamples
        });
    }
    /**
     * Exports documentation in all configured formats.
     *
     * @param commands Array of command metadata
     * @param testResults Optional test results for examples
     * @param previousVersion Optional previous version for change tracking
     * @returns Promise that resolves to export result
     */
    async exportDocumentation(commands, testResults = [], previousVersion) {
        const startTime = Date.now();
        console.log(`DocumentationExporter: Starting export of ${commands.length} commands`);
        try {
            // Ensure output directory exists
            await this.ensureOutputDirectory();
            // Generate schemas
            const schemas = this.schemaGenerator.generateCompleteSchemaPackage(commands, testResults);
            // Create documentation metadata
            const metadata = await this.createDocumentationMetadata(commands, testResults, previousVersion);
            // Create template context
            const context = this.createTemplateContext(commands, testResults, metadata, schemas);
            // Export in each format
            const files = [];
            const warnings = [];
            for (const format of this.config.formats) {
                try {
                    const exportedFiles = await this.exportFormat(format, context);
                    files.push(...exportedFiles);
                }
                catch (error) {
                    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
                    warnings.push(`Failed to export ${format} format: ${errorMessage}`);
                }
            }
            const duration = Date.now() - startTime;
            console.log(`DocumentationExporter: Export completed in ${duration}ms, generated ${files.length} files`);
            return {
                success: true,
                files,
                metadata,
                duration,
                warnings
            };
        }
        catch (error) {
            const duration = Date.now() - startTime;
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error('DocumentationExporter: Export failed:', errorMessage);
            return {
                success: false,
                files: [],
                metadata: await this.createDocumentationMetadata(commands, testResults),
                duration,
                warnings: [],
                error: errorMessage
            };
        }
    }
    /**
     * Exports documentation in a specific format.
     *
     * @param format Documentation format
     * @param context Template context
     * @returns Promise that resolves to generated files
     */
    async exportFormat(format, context) {
        console.log(`DocumentationExporter: Exporting ${format} format`);
        switch (format) {
            case 'markdown':
                return await this.exportMarkdown(context);
            case 'html':
                return await this.exportHtml(context);
            case 'json':
                return await this.exportJson(context);
            case 'typescript':
                return await this.exportTypeScript(context);
            case 'openapi':
                return await this.exportOpenApi(context);
            case 'pdf':
                return await this.exportPdf(context);
            case 'confluence':
                return await this.exportConfluence(context);
            case 'gitbook':
                return await this.exportGitBook(context);
            default:
                throw new Error(`Unsupported documentation format: ${format}`);
        }
    }
    /**
     * Exports Markdown documentation.
     *
     * @param context Template context
     * @returns Promise that resolves to generated files
     */
    async exportMarkdown(context) {
        const files = [];
        // Generate main README
        const readmeContent = this.generateMarkdownReadme(context);
        const readmePath = path.join(this.config.outputDirectory, 'README.md');
        await fs.promises.writeFile(readmePath, readmeContent, 'utf8');
        files.push({
            path: readmePath,
            format: 'markdown',
            size: readmeContent.length
        });
        // Generate command reference
        const referenceContent = this.generateMarkdownReference(context);
        const referencePath = path.join(this.config.outputDirectory, 'COMMAND_REFERENCE.md');
        await fs.promises.writeFile(referencePath, referenceContent, 'utf8');
        files.push({
            path: referencePath,
            format: 'markdown',
            size: referenceContent.length
        });
        // Generate API documentation
        const apiContent = this.generateMarkdownApi(context);
        const apiPath = path.join(this.config.outputDirectory, 'API.md');
        await fs.promises.writeFile(apiPath, apiContent, 'utf8');
        files.push({
            path: apiPath,
            format: 'markdown',
            size: apiContent.length
        });
        // Generate examples if available
        if (context.testResults.length > 0) {
            const examplesContent = this.generateMarkdownExamples(context);
            const examplesPath = path.join(this.config.outputDirectory, 'EXAMPLES.md');
            await fs.promises.writeFile(examplesPath, examplesContent, 'utf8');
            files.push({
                path: examplesPath,
                format: 'markdown',
                size: examplesContent.length
            });
        }
        return files;
    }
    /**
     * Exports HTML documentation.
     *
     * @param context Template context
     * @returns Promise that resolves to generated files
     */
    async exportHtml(context) {
        const files = [];
        // Generate main HTML file
        const htmlContent = this.generateHtmlDocumentation(context);
        const htmlPath = path.join(this.config.outputDirectory, 'index.html');
        await fs.promises.writeFile(htmlPath, htmlContent, 'utf8');
        files.push({
            path: htmlPath,
            format: 'html',
            size: htmlContent.length
        });
        // Generate CSS file
        const cssContent = this.generateCssStyles();
        const cssPath = path.join(this.config.outputDirectory, 'styles.css');
        await fs.promises.writeFile(cssPath, cssContent, 'utf8');
        files.push({
            path: cssPath,
            format: 'html',
            size: cssContent.length
        });
        return files;
    }
    /**
     * Exports JSON documentation.
     *
     * @param context Template context
     * @returns Promise that resolves to generated files
     */
    async exportJson(context) {
        const files = [];
        // Export complete command data
        const commandsData = {
            metadata: context.metadata,
            commands: context.commands,
            statistics: context.statistics,
            testResults: this.config.includeExamples ? context.testResults : undefined
        };
        const commandsJson = JSON.stringify(commandsData, null, 2);
        const commandsPath = path.join(this.config.outputDirectory, 'commands.json');
        await fs.promises.writeFile(commandsPath, commandsJson, 'utf8');
        files.push({
            path: commandsPath,
            format: 'json',
            size: commandsJson.length
        });
        // Export JSON schema
        const schemaJson = JSON.stringify(context.schemas.jsonSchema, null, 2);
        const schemaPath = path.join(this.config.outputDirectory, 'schema.json');
        await fs.promises.writeFile(schemaPath, schemaJson, 'utf8');
        files.push({
            path: schemaPath,
            format: 'json',
            size: schemaJson.length
        });
        return files;
    }
    /**
     * Exports TypeScript definitions.
     *
     * @param context Template context
     * @returns Promise that resolves to generated files
     */
    async exportTypeScript(context) {
        const files = [];
        // Generate main types file
        const typesContent = this.generateTypeScriptDefinitions(context);
        const typesPath = path.join(this.config.outputDirectory, 'types.d.ts');
        await fs.promises.writeFile(typesPath, typesContent, 'utf8');
        files.push({
            path: typesPath,
            format: 'typescript',
            size: typesContent.length
        });
        // Generate command registry
        const registryContent = this.generateTypeScriptRegistry(context);
        const registryPath = path.join(this.config.outputDirectory, 'registry.ts');
        await fs.promises.writeFile(registryPath, registryContent, 'utf8');
        files.push({
            path: registryPath,
            format: 'typescript',
            size: registryContent.length
        });
        return files;
    }
    /**
     * Exports OpenAPI specification.
     *
     * @param context Template context
     * @returns Promise that resolves to generated files
     */
    async exportOpenApi(context) {
        const files = [];
        const openApiJson = JSON.stringify(context.schemas.openApiSpec, null, 2);
        const openApiPath = path.join(this.config.outputDirectory, 'openapi.json');
        await fs.promises.writeFile(openApiPath, openApiJson, 'utf8');
        files.push({
            path: openApiPath,
            format: 'openapi',
            size: openApiJson.length
        });
        return files;
    }
    /**
     * Exports PDF documentation (placeholder).
     *
     * @param context Template context
     * @returns Promise that resolves to generated files
     */
    async exportPdf(context) {
        // PDF generation would require additional dependencies like puppeteer
        // For now, return empty array
        console.warn('PDF export not implemented yet');
        return [];
    }
    /**
     * Exports Confluence documentation (placeholder).
     *
     * @param context Template context
     * @returns Promise that resolves to generated files
     */
    async exportConfluence(context) {
        // Confluence export would require API integration
        // For now, return empty array
        console.warn('Confluence export not implemented yet');
        return [];
    }
    /**
     * Exports GitBook documentation (placeholder).
     *
     * @param context Template context
     * @returns Promise that resolves to generated files
     */
    async exportGitBook(context) {
        // GitBook export would require specific formatting
        // For now, return empty array
        console.warn('GitBook export not implemented yet');
        return [];
    }
    /**
     * Generates Markdown README content.
     *
     * @param context Template context
     * @returns Markdown content
     */
    generateMarkdownReadme(context) {
        const { metadata, statistics } = context;
        return `# Kiro Command Documentation

Generated on ${metadata.generatedAt.toISOString()}  
Version: ${metadata.version}  
Commands: ${metadata.commandCount}  
${metadata.author ? `Author: ${metadata.author}` : ''}  
${metadata.organization ? `Organization: ${metadata.organization}` : ''}

## Overview

This documentation provides comprehensive information about Kiro IDE commands discovered and analyzed for remote orchestration purposes.

## Statistics

- **Total Commands**: ${statistics.totalCommands}
- **kiroAgent Commands**: ${statistics.byCategory['kiroAgent'] || 0}
- **kiro Commands**: ${statistics.byCategory['kiro'] || 0}

### By Risk Level
${Object.entries(statistics.byRiskLevel)
            .map(([risk, count]) => `- **${risk}**: ${count}`)
            .join('\n')}

### By Subcategory
${Object.entries(statistics.bySubcategory)
            .map(([sub, count]) => `- **${sub}**: ${count}`)
            .join('\n')}

## Documentation Files

- [Command Reference](./COMMAND_REFERENCE.md) - Detailed command documentation
- [API Documentation](./API.md) - WebSocket API reference
${context.testResults.length > 0 ? '- [Examples](./EXAMPLES.md) - Usage examples and test results' : ''}
- [JSON Schema](./schema.json) - Machine-readable schema
- [TypeScript Definitions](./types.d.ts) - Type definitions for development

## Integration

This documentation is designed for integration with the Household AI Engineer orchestration system. The generated schemas and API documentation enable remote command execution via WebSocket bridge.

## Change Tracking

${metadata.changeSummary ? this.formatChangeSummary(metadata.changeSummary) : 'No previous version available for comparison.'}

---

*Generated by Kiro Command Research Tool v${metadata.generatorVersion}*
`;
    }
    /**
     * Generates Markdown command reference content.
     *
     * @param context Template context
     * @returns Markdown content
     */
    generateMarkdownReference(context) {
        const { commands } = context;
        let content = `# Command Reference

This document provides detailed information about all discovered Kiro commands.

## Table of Contents

`;
        // Generate table of contents
        const categories = new Map();
        for (const command of commands) {
            if (!categories.has(command.category)) {
                categories.set(command.category, []);
            }
            categories.get(command.category).push(command);
        }
        for (const [category, categoryCommands] of categories) {
            content += `- [${category}](#${category.toLowerCase()})\n`;
            const subcategories = new Map();
            for (const command of categoryCommands) {
                if (!subcategories.has(command.subcategory)) {
                    subcategories.set(command.subcategory, []);
                }
                subcategories.get(command.subcategory).push(command);
            }
            for (const [subcategory] of subcategories) {
                content += `  - [${subcategory}](#${subcategory.toLowerCase().replace(/\s+/g, '-')})\n`;
            }
        }
        content += '\n';
        // Generate command documentation
        for (const [category, categoryCommands] of categories) {
            content += `## ${category}\n\n`;
            const subcategories = new Map();
            for (const command of categoryCommands) {
                if (!subcategories.has(command.subcategory)) {
                    subcategories.set(command.subcategory, []);
                }
                subcategories.get(command.subcategory).push(command);
            }
            for (const [subcategory, subcategoryCommands] of subcategories) {
                content += `### ${subcategory}\n\n`;
                for (const command of subcategoryCommands) {
                    content += this.generateCommandMarkdown(command);
                }
            }
        }
        return content;
    }
    /**
     * Generates Markdown for a single command.
     *
     * @param command Command metadata
     * @returns Markdown content
     */
    generateCommandMarkdown(command) {
        let content = `#### ${command.displayName}\n\n`;
        content += `**ID**: \`${command.id}\`  \n`;
        content += `**Risk Level**: ${command.riskLevel}  \n`;
        if (command.description) {
            content += `**Description**: ${command.description}  \n`;
        }
        if (command.contextRequirements.length > 0) {
            content += `**Context Requirements**: ${command.contextRequirements.join(', ')}  \n`;
        }
        if (command.signature) {
            content += '\n**Signature**:\n\n';
            if (command.signature.parameters.length > 0) {
                content += 'Parameters:\n';
                for (const param of command.signature.parameters) {
                    content += `- \`${param.name}\` (${param.type})${param.required ? ' *required*' : ' *optional*'}`;
                    if (param.description) {
                        content += ` - ${param.description}`;
                    }
                    content += '\n';
                }
                content += '\n';
            }
            if (command.signature.returnType) {
                content += `Returns: \`${command.signature.returnType}\`\n\n`;
            }
            content += `Async: ${command.signature.async ? 'Yes' : 'No'}  \n`;
            content += `Confidence: ${command.signature.confidence}  \n`;
        }
        content += '\n---\n\n';
        return content;
    }
    /**
     * Generates Markdown API documentation.
     *
     * @param context Template context
     * @returns Markdown content
     */
    generateMarkdownApi(context) {
        return `# WebSocket API Documentation

This document describes the WebSocket API for remote execution of Kiro commands.

## Connection

Connect to the WebSocket server at \`ws://localhost:8080/ws\`.

## Message Format

All messages follow this structure:

\`\`\`json
{
  "type": "execute" | "result" | "error" | "ping" | "pong",
  "id": "unique-message-id",
  "timestamp": "2025-01-10T14:30:00Z",
  "payload": { ... }
}
\`\`\`

## Command Execution

### Request

\`\`\`json
{
  "type": "execute",
  "id": "req-123",
  "timestamp": "2025-01-10T14:30:00Z",
  "payload": {
    "commandId": "kiroAgent.agent.chatAgent",
    "parameters": {
      "message": "Hello, Kiro!"
    },
    "timeoutMs": 30000,
    "createSnapshot": false,
    "requireConfirmation": false
  }
}
\`\`\`

### Response

\`\`\`json
{
  "type": "result",
  "id": "req-123",
  "timestamp": "2025-01-10T14:30:05Z",
  "payload": {
    "success": true,
    "commandId": "kiroAgent.agent.chatAgent",
    "duration": 1250,
    "result": { ... },
    "sideEffects": []
  }
}
\`\`\`

## Error Handling

Errors are returned with type "error":

\`\`\`json
{
  "type": "error",
  "id": "req-123",
  "timestamp": "2025-01-10T14:30:02Z",
  "payload": {
    "success": false,
    "commandId": "kiroAgent.agent.chatAgent",
    "duration": 500,
    "error": {
      "message": "Command not found",
      "type": "CommandNotFoundError",
      "stack": "..."
    }
  }
}
\`\`\`

## Available Commands

${context.commands.length} commands are available for execution. See [Command Reference](./COMMAND_REFERENCE.md) for details.

## Schema

The complete API schema is available in [OpenAPI format](./openapi.json).
`;
    }
    /**
     * Generates Markdown examples documentation.
     *
     * @param context Template context
     * @returns Markdown content
     */
    generateMarkdownExamples(context) {
        const { testResults } = context;
        let content = `# Usage Examples

This document provides real usage examples based on test results.

## Successful Executions

`;
        const successfulResults = testResults.filter(r => r.executionResult.success);
        for (const result of successfulResults.slice(0, 10)) { // Limit to 10 examples
            content += `### ${result.commandMetadata.displayName}\n\n`;
            content += `**Command**: \`${result.commandId}\`\n\n`;
            if (Object.keys(result.parameters).length > 0) {
                content += '**Parameters**:\n```json\n';
                content += JSON.stringify(result.parameters, null, 2);
                content += '\n```\n\n';
            }
            content += `**Duration**: ${result.executionResult.duration}ms\n\n`;
            if (result.executionResult.result) {
                content += '**Result**:\n```json\n';
                content += JSON.stringify(result.executionResult.result, null, 2);
                content += '\n```\n\n';
            }
            if (result.notes) {
                content += `**Notes**: ${result.notes}\n\n`;
            }
            content += '---\n\n';
        }
        return content;
    }
    /**
     * Generates HTML documentation.
     *
     * @param context Template context
     * @returns HTML content
     */
    generateHtmlDocumentation(context) {
        const { metadata, commands, statistics } = context;
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kiro Command Documentation</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>Kiro Command Documentation</h1>
        <p>Generated on ${metadata.generatedAt.toISOString()}</p>
        <p>Version: ${metadata.version} | Commands: ${metadata.commandCount}</p>
    </header>
    
    <nav>
        <ul>
            <li><a href="#overview">Overview</a></li>
            <li><a href="#statistics">Statistics</a></li>
            <li><a href="#commands">Commands</a></li>
        </ul>
    </nav>
    
    <main>
        <section id="overview">
            <h2>Overview</h2>
            <p>This documentation provides comprehensive information about Kiro IDE commands discovered and analyzed for remote orchestration purposes.</p>
        </section>
        
        <section id="statistics">
            <h2>Statistics</h2>
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Total Commands</h3>
                    <p class="stat-number">${statistics.totalCommands}</p>
                </div>
                <div class="stat-card">
                    <h3>kiroAgent Commands</h3>
                    <p class="stat-number">${statistics.byCategory['kiroAgent'] || 0}</p>
                </div>
                <div class="stat-card">
                    <h3>kiro Commands</h3>
                    <p class="stat-number">${statistics.byCategory['kiro'] || 0}</p>
                </div>
            </div>
        </section>
        
        <section id="commands">
            <h2>Commands</h2>
            ${this.generateHtmlCommandList(commands)}
        </section>
    </main>
    
    <footer>
        <p>Generated by Kiro Command Research Tool v${metadata.generatorVersion}</p>
    </footer>
</body>
</html>`;
    }
    /**
     * Generates HTML command list.
     *
     * @param commands Array of commands
     * @returns HTML content
     */
    generateHtmlCommandList(commands) {
        let html = '<div class="command-list">';
        for (const command of commands) {
            html += `
        <div class="command-card ${command.riskLevel}">
            <h3>${command.displayName}</h3>
            <p class="command-id">${command.id}</p>
            <p class="command-category">${command.category} > ${command.subcategory}</p>
            <p class="risk-level">Risk: ${command.riskLevel}</p>
            ${command.description ? `<p class="description">${command.description}</p>` : ''}
            ${command.contextRequirements.length > 0 ?
                `<p class="context">Context: ${command.contextRequirements.join(', ')}</p>` : ''}
        </div>
      `;
        }
        html += '</div>';
        return html;
    }
    /**
     * Generates CSS styles for HTML documentation.
     *
     * @returns CSS content
     */
    generateCssStyles() {
        return `
body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    margin: 0;
    padding: 0;
    background-color: #f5f5f5;
}

header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 2rem;
    text-align: center;
}

nav {
    background: #333;
    padding: 1rem;
}

nav ul {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    gap: 2rem;
}

nav a {
    color: white;
    text-decoration: none;
    padding: 0.5rem 1rem;
    border-radius: 4px;
    transition: background-color 0.3s;
}

nav a:hover {
    background-color: #555;
}

main {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin: 2rem 0;
}

.stat-card {
    background: white;
    padding: 1.5rem;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    text-align: center;
}

.stat-number {
    font-size: 2rem;
    font-weight: bold;
    color: #667eea;
    margin: 0;
}

.command-list {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1rem;
}

.command-card {
    background: white;
    padding: 1.5rem;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    border-left: 4px solid #ddd;
}

.command-card.safe {
    border-left-color: #4CAF50;
}

.command-card.moderate {
    border-left-color: #FF9800;
}

.command-card.destructive {
    border-left-color: #f44336;
}

.command-id {
    font-family: monospace;
    background: #f0f0f0;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    font-size: 0.9rem;
}

.command-category {
    color: #666;
    font-size: 0.9rem;
}

.risk-level {
    font-weight: bold;
    font-size: 0.9rem;
}

.description {
    color: #555;
    font-style: italic;
}

.context {
    font-size: 0.8rem;
    color: #777;
}

footer {
    background: #333;
    color: white;
    text-align: center;
    padding: 1rem;
    margin-top: 2rem;
}
`;
    }
    /**
     * Generates TypeScript definitions content.
     *
     * @param context Template context
     * @returns TypeScript content
     */
    generateTypeScriptDefinitions(context) {
        const { schemas } = context;
        let content = `/**
 * Kiro Command Type Definitions
 * 
 * Generated on ${context.metadata.generatedAt.toISOString()}
 * Version: ${context.metadata.version}
 * Commands: ${context.metadata.commandCount}
 */

`;
        // Add all TypeScript definitions
        for (const definition of schemas.typeScriptDefinitions) {
            content += definition.code + '\n\n';
        }
        return content;
    }
    /**
     * Generates TypeScript command registry.
     *
     * @param context Template context
     * @returns TypeScript content
     */
    generateTypeScriptRegistry(context) {
        const { commands } = context;
        let content = `/**
 * Kiro Command Registry
 * 
 * Generated command registry with all discovered commands.
 */

import { CommandMetadata, CommandRegistry } from './types';

`;
        // Generate command data
        content += 'const COMMANDS: CommandMetadata[] = [\n';
        for (const command of commands) {
            content += '  {\n';
            content += `    id: '${command.id}',\n`;
            content += `    category: '${command.category}',\n`;
            content += `    subcategory: '${command.subcategory}',\n`;
            content += `    displayName: '${command.displayName}',\n`;
            if (command.description) {
                content += `    description: '${command.description.replace(/'/g, "\\'")}',\n`;
            }
            content += `    riskLevel: '${command.riskLevel}',\n`;
            content += `    contextRequirements: [${command.contextRequirements.map(req => `'${req}'`).join(', ')}],\n`;
            content += `    discoveredAt: new Date('${command.discoveredAt.toISOString()}'),\n`;
            content += '  },\n';
        }
        content += '];\n\n';
        // Generate registry implementation
        content += `export const commandRegistry: CommandRegistry = {
  byId: COMMANDS.reduce((acc, cmd) => {
    acc[cmd.id] = cmd;
    return acc;
  }, {} as Record<string, CommandMetadata>),
  
  byCategory: COMMANDS.reduce((acc, cmd) => {
    if (!acc[cmd.category]) acc[cmd.category] = [];
    acc[cmd.category].push(cmd);
    return acc;
  }, {} as Record<string, CommandMetadata[]>),
  
  bySubcategory: COMMANDS.reduce((acc, cmd) => {
    if (!acc[cmd.subcategory]) acc[cmd.subcategory] = [];
    acc[cmd.subcategory].push(cmd);
    return acc;
  }, {} as Record<string, CommandMetadata[]>),
  
  byRiskLevel: COMMANDS.reduce((acc, cmd) => {
    if (!acc[cmd.riskLevel]) acc[cmd.riskLevel] = [];
    acc[cmd.riskLevel].push(cmd);
    return acc;
  }, {} as Record<string, CommandMetadata[]>),
  
  getCommand(id: string): CommandMetadata | undefined {
    return this.byId[id];
  },
  
  getCommandsByCategory(category: string): CommandMetadata[] {
    return this.byCategory[category] || [];
  },
  
  getCommandsBySubcategory(subcategory: string): CommandMetadata[] {
    return this.bySubcategory[subcategory] || [];
  },
  
  searchCommands(query: string): CommandMetadata[] {
    const lowerQuery = query.toLowerCase();
    return COMMANDS.filter(cmd => 
      cmd.id.toLowerCase().includes(lowerQuery) ||
      cmd.displayName.toLowerCase().includes(lowerQuery) ||
      (cmd.description && cmd.description.toLowerCase().includes(lowerQuery))
    );
  }
};
`;
        return content;
    }
    /**
     * Creates documentation metadata.
     *
     * @param commands Array of commands
     * @param testResults Array of test results
     * @param previousVersion Optional previous version
     * @returns Promise that resolves to documentation metadata
     */
    async createDocumentationMetadata(commands, testResults, previousVersion) {
        let changeSummary;
        if (previousVersion && this.config.includeChangeTracking) {
            // This would require loading previous command data
            // For now, create empty change summary
            changeSummary = {
                commandsAdded: [],
                commandsRemoved: [],
                commandsModified: [],
                signatureChanges: []
            };
        }
        return {
            version: this.config.version,
            generatedAt: new Date(),
            commandCount: commands.length,
            testResultCount: testResults.length,
            generatorVersion: '1.0.0',
            author: this.config.author,
            organization: this.config.organization,
            changeSummary
        };
    }
    /**
     * Creates template context for documentation generation.
     *
     * @param commands Array of commands
     * @param testResults Array of test results
     * @param metadata Documentation metadata
     * @param schemas Generated schemas
     * @returns Template context
     */
    createTemplateContext(commands, testResults, metadata, schemas) {
        // Calculate statistics
        const statistics = {
            totalCommands: commands.length,
            byCategory: commands.reduce((acc, cmd) => {
                acc[cmd.category] = (acc[cmd.category] || 0) + 1;
                return acc;
            }, {}),
            bySubcategory: commands.reduce((acc, cmd) => {
                acc[cmd.subcategory] = (acc[cmd.subcategory] || 0) + 1;
                return acc;
            }, {}),
            byRiskLevel: commands.reduce((acc, cmd) => {
                acc[cmd.riskLevel] = (acc[cmd.riskLevel] || 0) + 1;
                return acc;
            }, {})
        };
        return {
            commands,
            testResults,
            metadata,
            statistics,
            schemas
        };
    }
    /**
     * Formats change summary for display.
     *
     * @param changeSummary Change summary
     * @returns Formatted string
     */
    formatChangeSummary(changeSummary) {
        let summary = '';
        if (changeSummary.commandsAdded.length > 0) {
            summary += `**Added Commands**: ${changeSummary.commandsAdded.length}\n`;
            summary += changeSummary.commandsAdded.map(id => `- ${id}`).join('\n') + '\n\n';
        }
        if (changeSummary.commandsRemoved.length > 0) {
            summary += `**Removed Commands**: ${changeSummary.commandsRemoved.length}\n`;
            summary += changeSummary.commandsRemoved.map(id => `- ${id}`).join('\n') + '\n\n';
        }
        if (changeSummary.commandsModified.length > 0) {
            summary += `**Modified Commands**: ${changeSummary.commandsModified.length}\n`;
            for (const mod of changeSummary.commandsModified) {
                summary += `- ${mod.commandId}: ${mod.changes.join(', ')}\n`;
            }
            summary += '\n';
        }
        return summary || 'No changes detected.';
    }
    /**
     * Ensures output directory exists.
     *
     * @returns Promise that resolves when directory exists
     */
    async ensureOutputDirectory() {
        try {
            await fs.promises.mkdir(this.config.outputDirectory, { recursive: true });
        }
        catch (error) {
            console.warn('Failed to create output directory:', error);
        }
    }
}
exports.DocumentationExporter = DocumentationExporter;
//# sourceMappingURL=documentation-exporter.js.map