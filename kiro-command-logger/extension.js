/**
 * Kiro Command Logger Extension
 * 
 * This simple extension discovers and logs all VS Code/Kiro IDE commands associated with
 * the Kiro AI agent. The extension obtains a list of all VS Code commands related to Kiro
 * and analyzes these commands by organizing them into categories. The resulting analysis
 * is provided in the "Output" panel.
 */

const vscode = require('vscode');

/**
 * Global sequence counter for tracking command execution order.
 * Incremented for each command to provide chronological ordering.
 */
let sequenceNumber = 0;

/**
 * Output channel for logging command information.
 * Created lazily when first needed and reused throughout extension lifecycle.
 */
let outputChannel = null;

/**
 * Activates the Kiro Command Logger extension.
 * 
 * This function is called when the extension is activated and sets up
 * the command monitoring infrastructure. It registers event listeners
 * and initializes the logging system.
 * 
 * @param {vscode.ExtensionContext} context - VS Code extension context
 */
function activate(context) {
    try {
        // Log extension activation
        logStatus('Kiro Command Logger extension activated');
        logStatus('Discovering Kiro commands and monitoring command execution...');
        
        // Discover and log all available commands, especially Kiro ones
        discoverKiroCommands();
        
        // Set up periodic command discovery to catch dynamically registered commands
        const commandDiscoveryInterval = setInterval(discoverKiroCommands, 30000); // Every 30 seconds
        
        // Register a test command to verify our extension is working
        const testCommandDisposable = vscode.commands.registerCommand('kiro-command-logger.test', () => {
            logStatus('Test command executed - extension is working correctly');
        });
        
        // Monitor workspace changes to detect when Kiro might be active
        const documentChangeDisposable = vscode.workspace.onDidChangeTextDocument(onDocumentChanged);
        const documentSaveDisposable = vscode.workspace.onDidSaveTextDocument(onDocumentSaved);
        
        // Add all disposables to subscriptions for cleanup
        context.subscriptions.push(
            testCommandDisposable,
            documentChangeDisposable,
            documentSaveDisposable,
            { dispose: () => clearInterval(commandDiscoveryInterval) }
        );
        
        // Log successful initialization
        logStatus('Command discovery and monitoring started');
        logStatus('Extension will periodically scan for new Kiro commands');
        
    } catch (error) {
        console.error('Failed to activate Kiro Command Logger:', error);
        
        logStatus(`Extension activation failed: ${error.message}`);
    }
}

/**
 * Discovers and logs all available VS Code commands, with special focus on Kiro commands.
 * 
 * This function queries the VS Code command registry to find all registered commands,
 * filters them to identify Kiro-specific commands, and logs detailed information
 * about what programmatic interfaces are available.
 */
async function discoverKiroCommands() {
    try {
        logStatus('Starting command discovery...');
        
        // Get all registered commands
        const allCommands = await vscode.commands.getCommands(true);
        logStatus(`Found ${allCommands.length} total registered commands`);
        
        // Filter specifically for kiroAgent commands
        const kiroAgentCommands = allCommands.filter(id => 
            id.startsWith('kiroAgent.')
        );
        
        // Also get any other kiro-prefixed commands for completeness
        const otherKiroCommands = allCommands.filter(id => 
            id.toLowerCase().startsWith('kiro.') && !id.startsWith('kiroAgent.')
        );
        
        // Log kiroAgent commands (primary focus)
        if (kiroAgentCommands.length > 0) {
            logStatus(`Found ${kiroAgentCommands.length} kiroAgent commands:`);
            kiroAgentCommands.forEach((command, index) => {
                logStatus(`  ${index + 1}. ${command}`);
            });
            
            // Log detailed analysis of kiroAgent commands
            logKiroAgentAnalysis(kiroAgentCommands);
        } else {
            logStatus('No kiroAgent commands found');
        }
        
        // Log other kiro commands if any exist
        if (otherKiroCommands.length > 0) {
            logStatus(`Found ${otherKiroCommands.length} other kiro commands:`);
            otherKiroCommands.forEach((command, index) => {
                logStatus(`  ${index + 1}. ${command}`);
            });
        }
        
        // Log summary statistics
        logStatus(`=== COMMAND DISCOVERY SUMMARY ===`);
        logStatus(`Total commands in VS Code: ${allCommands.length}`);
        logStatus(`kiroAgent commands: ${kiroAgentCommands.length}`);
        logStatus(`Other kiro commands: ${otherKiroCommands.length}`);
        logStatus(`=== END SUMMARY ===`);
        
    } catch (error) {
        console.error('Error discovering commands:', error);
        logStatus(`Command discovery failed: ${error.message}`);
    }
}

/**
 * Analyzes and logs detailed information about discovered kiroAgent commands.
 * 
 * @param {string[]} kiroAgentCommands - Array of kiroAgent command identifiers
 */
function logKiroAgentAnalysis(kiroAgentCommands) {
    const analysis = {
        total: kiroAgentCommands.length,
        categories: {
            chat: [],
            conversation: [],
            file: [],
            editor: [],
            workspace: [],
            ui: [],
            settings: [],
            other: []
        }
    };
    
    // Analyze kiroAgent command patterns
    kiroAgentCommands.forEach(command => {
        const lowerCommand = command.toLowerCase();
        const commandPart = command.replace('kiroAgent.', '').toLowerCase();
        
        // Categorize by functionality
        if (lowerCommand.includes('chat') || lowerCommand.includes('message')) {
            analysis.categories.chat.push(command);
        } else if (lowerCommand.includes('conversation') || lowerCommand.includes('dialog')) {
            analysis.categories.conversation.push(command);
        } else if (lowerCommand.includes('file') || lowerCommand.includes('document')) {
            analysis.categories.file.push(command);
        } else if (lowerCommand.includes('editor') || lowerCommand.includes('text')) {
            analysis.categories.editor.push(command);
        } else if (lowerCommand.includes('workspace') || lowerCommand.includes('project')) {
            analysis.categories.workspace.push(command);
        } else if (lowerCommand.includes('ui') || lowerCommand.includes('view') || lowerCommand.includes('panel')) {
            analysis.categories.ui.push(command);
        } else if (lowerCommand.includes('setting') || lowerCommand.includes('config')) {
            analysis.categories.settings.push(command);
        } else {
            analysis.categories.other.push(command);
        }
    });
    
    // Log analysis results
    logStatus('=== KIRO AGENT COMMAND ANALYSIS ===');
    logStatus(`Total kiroAgent commands: ${analysis.total}`);
    
    logStatus('Commands by functionality:');
    Object.entries(analysis.categories).forEach(([category, commands]) => {
        if (commands.length > 0) {
            logStatus(`  ${category.toUpperCase()}: ${commands.length} commands`);
            commands.forEach(cmd => {
                const shortName = cmd.replace('kiroAgent.', '');
                logStatus(`    - ${shortName} (${cmd})`);
            });
        }
    });
    
    logStatus('=== END KIRO AGENT ANALYSIS ===');
}

/**
 * Handles document change events from VS Code.
 * 
 * This function is called when text is modified in any document,
 * which often indicates editor commands or user actions.
 * 
 * @param {vscode.TextDocumentChangeEvent} event - Document change event
 */
function onDocumentChanged(event) {
    try {
        const fileName = event.document.fileName;
        
        // Prevent feedback loop: ignore changes to our own output channel
        if (fileName && fileName.includes('kiro-command-logger')) {
            return;
        }
        
        // Ignore other output channels and log files to reduce noise
        if (fileName && (
            fileName.includes('extension-output-') ||
            fileName.includes('Output - ') ||
            event.document.languageId === 'log'
        )) {
            return;
        }
        
        const changeCount = event.contentChanges.length;
        processAndLogEvent('document.textChanged', {
            fileName: fileName,
            changeCount: changeCount,
            language: event.document.languageId
        });
    } catch (error) {
        console.error('Error processing document change:', error);
        logStatus(`Document change processing error: ${error.message}`);
    }
}

/**
 * Handles document save events from VS Code.
 * 
 * @param {vscode.TextDocument} document - The saved document
 */
function onDocumentSaved(document) {
    try {
        const fileName = document.fileName;
        
        // Filter out output channels and log files
        if (fileName && (
            fileName.includes('kiro-command-logger') ||
            fileName.includes('extension-output-') ||
            fileName.includes('Output - ') ||
            document.languageId === 'log'
        )) {
            return;
        }
        
        processAndLogEvent('document.saved', {
            fileName: fileName,
            language: document.languageId,
            lineCount: document.lineCount
        });
    } catch (error) {
        console.error('Error processing document save:', error);
    }
}

/**
 * Processes and logs a captured event with enriched metadata.
 * 
 * This function adds timestamps, sequence numbers, categorization,
 * and formatting to captured events before logging them.
 * 
 * @param {string} eventType - The type of event that occurred
 * @param {Object} eventData - Data associated with the event
 */
function processAndLogEvent(eventType, eventData) {
    const timestamp = new Date().toISOString();
    const sequence = ++sequenceNumber;
    const formattedData = formatArguments(eventData);
    const isKiroRelated = isKiroEvent(eventType, eventData);
    const category = categorizeEvent(eventType);
    
    const logEntry = {
        timestamp,
        sequence,
        eventType,
        eventData,
        formattedData,
        isKiroRelated,
        category
    };
    
    logEvent(logEntry);
}

/**
 * Formats command arguments for readable output.
 * 
 * Handles complex objects and circular references safely by attempting
 * JSON serialization with fallback to error messages for problematic data.
 * 
 * @param {Array} args - Command arguments to format
 * @returns {string} Formatted argument string
 */
function formatArguments(args) {
    if (!args || args.length === 0) {
        return 'none';
    }
    
    try {
        return JSON.stringify(args, null, 2);
    } catch (error) {
        // Handle circular references or other serialization issues
        return `[Unable to serialize: ${error.message}]`;
    }
}

/**
 * Creates or gets the output channel for logging.
 * 
 * Lazily creates the output channel on first use and reuses it
 * throughout the extension lifecycle for consistent logging.
 * 
 * @returns {vscode.OutputChannel} The output channel for logging
 */
function getOutputChannel() {
    if (!outputChannel) {
        outputChannel = vscode.window.createOutputChannel('Kiro Command Logger');
    }
    return outputChannel;
}

/**
 * Logs an event entry to the output channel.
 * 
 * Formats the entry with consistent styling and structure for
 * easy reading and analysis of event patterns.
 * 
 * @param {Object} entry - Event log entry with metadata
 */
function logEvent(entry) {
    const channel = getOutputChannel();
    const formattedEntry = formatLogEntry(entry);
    
    channel.appendLine(formattedEntry);
    
    // Also log to console for immediate visibility during development
    console.log('Kiro Event:', entry.eventType, 'Data:', entry.eventData);
}

/**
 * Formats an event entry for display.
 * 
 * Creates readable, structured output with proper indentation
 * and clear separation between different data elements.
 * 
 * @param {Object} entry - Event log entry to format
 * @returns {string} Formatted log entry string
 */
function formatLogEntry(entry) {
    const kiroIndicator = entry.isKiroRelated ? '[KIRO]' : '[VS Code]';
    const header = `${entry.timestamp} ${kiroIndicator} #${entry.sequence}`;
    
    return `
${header}
Event: ${entry.eventType}
Category: ${entry.category}
Data: ${entry.formattedData}
${'='.repeat(80)}`;
}

/**
 * Logs extension status messages.
 * 
 * Provides a consistent way to log extension lifecycle events
 * and status information for debugging and monitoring.
 * 
 * @param {string} message - Status message to log
 */
function logStatus(message) {
    const channel = getOutputChannel();
    const timestamp = new Date().toISOString();
    channel.appendLine(`${timestamp} [STATUS] ${message}`);
}

/**
 * Simple patterns for identifying Kiro-related file operations.
 * These patterns help identify events that are likely related
 * to Kiro AI agent operations versus general VS Code usage.
 */
const kiroFilePatterns = [
    'kiro',
    'ai-generated',
    'agent-created',
    'chat-response',
    'conversation',
    'generated-code'
];

/**
 * Event category mappings for classification.
 * Maps event types to logical categories for better
 * organization and analysis of event patterns.
 */
const eventCategories = {
    'document.': 'document',
    'editor.': 'editor',
    'window.': 'window',
    'workspace.': 'workspace',
    'debug.': 'debug',
    'extension.': 'extension',
    'git.': 'git',
    'terminal.': 'terminal'
};

/**
 * Determines if an event is likely Kiro-related.
 * 
 * Uses file path analysis and event data to identify events that
 * are probably related to Kiro AI agent operations.
 * 
 * @param {string} eventType - Event type identifier
 * @param {Object} eventData - Event data to analyze
 * @returns {boolean} True if event appears to be Kiro-related
 */
function isKiroEvent(eventType, eventData) {
    // Check if filename contains Kiro-related patterns
    if (eventData.fileName) {
        const fileName = eventData.fileName.toLowerCase();
        if (kiroFilePatterns.some(pattern => fileName.includes(pattern))) {
            return true;
        }
    }
    
    // Check if event type suggests Kiro activity
    const eventTypeLower = eventType.toLowerCase();
    if (kiroFilePatterns.some(pattern => eventTypeLower.includes(pattern))) {
        return true;
    }
    
    return false;
}

/**
 * Categorizes an event based on its type.
 * 
 * Provides context for understanding event purpose by
 * mapping event types to logical categories.
 * 
 * @param {string} eventType - Event type to categorize
 * @returns {string} Category name for the event
 */
function categorizeEvent(eventType) {
    for (const [prefix, category] of Object.entries(eventCategories)) {
        if (eventType.startsWith(prefix)) {
            return category;
        }
    }
    
    return 'other';
}

/**
 * Deactivates the extension and cleans up resources.
 * 
 * Called when the extension is deactivated. Cleanup is handled
 * automatically by VS Code through the context.subscriptions array.
 */
function deactivate() {
    logStatus('Kiro Command Logger extension deactivated');
    
    // Cleanup is handled automatically by context.subscriptions
    // Output channel will be disposed by VS Code
}

// Export the activation and deactivation functions
module.exports = {
    activate,
    deactivate
};