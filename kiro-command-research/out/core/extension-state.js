"use strict";
/**
 * Extension state management for the Kiro Command Research Tool.
 *
 * This module manages the global state of the extension and provides
 * access to shared resources and components.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExtensionState = void 0;
const file_storage_manager_1 = require("../storage/file-storage-manager");
const command_registry_scanner_1 = require("../discovery/command-registry-scanner");
const parameter_researcher_1 = require("../discovery/parameter-researcher");
const parameter_validator_1 = require("../testing/parameter-validator");
const command_executor_1 = require("../testing/command-executor");
const command_explorer_1 = require("../ui/command-explorer");
const testing_interface_1 = require("../ui/testing-interface");
const documentation_manager_1 = require("../ui/documentation-manager");
const documentation_exporter_1 = require("../export/documentation-exporter");
const documentation_viewer_1 = require("../documentation/documentation-viewer");
/**
 * Extension context and global state management.
 *
 * This class maintains the global state of the extension and provides
 * access to shared resources like the storage manager and UI components.
 */
class ExtensionState {
    constructor(context, storageManager, commandScanner, parameterResearcher, parameterValidator, commandExecutor, commandExplorer, testingInterface, documentationManager, documentationViewer) {
        this.context = context;
        this.storageManager = storageManager;
        this.commandScanner = commandScanner;
        this.parameterResearcher = parameterResearcher;
        this.parameterValidator = parameterValidator;
        this.commandExecutor = commandExecutor;
        this.commandExplorer = commandExplorer;
        this.testingInterface = testingInterface;
        this.documentationManager = documentationManager;
        this.documentationViewer = documentationViewer;
    }
    /**
     * Initializes the extension state singleton.
     *
     * @param context VS Code extension context
     * @returns Promise that resolves to the extension state instance
     */
    static async initialize(context) {
        if (ExtensionState.instance) {
            throw new Error('Extension state already initialized');
        }
        const storageManager = new file_storage_manager_1.FileStorageManager(context);
        await storageManager.initialize();
        const commandScanner = new command_registry_scanner_1.CommandRegistryScanner();
        const parameterResearcher = new parameter_researcher_1.ParameterResearcher();
        const parameterValidator = new parameter_validator_1.ParameterValidator();
        const commandExecutor = new command_executor_1.CommandExecutor(parameterValidator);
        // Initialize UI components
        const commandExplorer = new command_explorer_1.CommandExplorer(context, storageManager);
        const testingInterface = new testing_interface_1.TestingInterface(context, commandExecutor, parameterValidator, {
            defaultTimeout: 30000,
            defaultCreateSnapshot: false,
            requireConfirmation: true,
            showAdvancedOptions: true,
            maxRecentTests: 10
        });
        const documentationExporter = new documentation_exporter_1.DocumentationExporter();
        const documentationManager = new documentation_manager_1.DocumentationManager(context, documentationExporter, storageManager, {
            defaultFormats: ['markdown', 'json', 'typescript'],
            autoExport: false,
            exportDirectory: '',
            enableQualityAssessment: true,
            enableVersionTracking: true
        });
        const documentationViewer = new documentation_viewer_1.DocumentationViewer(context);
        ExtensionState.instance = new ExtensionState(context, storageManager, commandScanner, parameterResearcher, parameterValidator, commandExecutor, commandExplorer, testingInterface, documentationManager, documentationViewer);
        return ExtensionState.instance;
    }
    /**
     * Gets the current extension state instance.
     *
     * @returns The extension state instance
     * @throws Error if extension state is not initialized
     */
    static getInstance() {
        if (!ExtensionState.instance) {
            throw new Error('Extension state not initialized');
        }
        return ExtensionState.instance;
    }
    /**
     * Cleans up extension resources.
     *
     * @returns Promise that resolves when cleanup is complete
     */
    async dispose() {
        // Dispose UI components
        this.commandExplorer.dispose();
        this.testingInterface.dispose();
        this.documentationManager.dispose();
        this.documentationViewer.dispose();
        ExtensionState.instance = null;
    }
    /**
     * Gets the current extension state instance if it exists.
     *
     * @returns The extension state instance or null if not initialized
     */
    static getCurrentInstance() {
        return ExtensionState.instance;
    }
}
exports.ExtensionState = ExtensionState;
ExtensionState.instance = null;
//# sourceMappingURL=extension-state.js.map