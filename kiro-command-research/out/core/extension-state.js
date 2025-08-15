"use strict";
/**
 * Extension state management for the Kiro Command Research Tool.
 *
 * This module manages the global state of the extension and provides
 * access to shared resources and components.
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
exports.ExtensionState = void 0;
const vscode = __importStar(require("vscode"));
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
const dashboard_1 = require("../ui/dashboard");
const dashboard_provider_1 = require("../ui/dashboard-provider");
const manual_parameter_editor_1 = require("../ui/manual-parameter-editor");
/**
 * Extension context and global state management.
 *
 * This class maintains the global state of the extension and provides
 * access to shared resources like the storage manager and UI components.
 */
class ExtensionState {
    constructor(context, storageManager, commandScanner, parameterResearcher, parameterValidator, commandExecutor, commandExplorer, testingInterface, documentationManager, documentationViewer, dashboard, dashboardProvider, manualParameterEditor) {
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
        this.dashboard = dashboard;
        this.dashboardProvider = dashboardProvider;
        this.manualParameterEditor = manualParameterEditor;
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
        const dashboard = new dashboard_1.Dashboard(context, storageManager, {
            showGuidance: true,
            autoRefresh: true,
            refreshInterval: 30000,
            showDetailedStats: true
        });
        const dashboardProvider = new dashboard_provider_1.DashboardProvider();
        // Register the dashboard tree data provider
        vscode.window.registerTreeDataProvider('kiroDashboard', dashboardProvider);
        const manualParameterEditor = new manual_parameter_editor_1.ManualParameterEditor(context, storageManager, {
            showAdvancedOptions: true,
            validateTypes: true,
            showExamples: true,
            maxParameters: 20
        });
        ExtensionState.instance = new ExtensionState(context, storageManager, commandScanner, parameterResearcher, parameterValidator, commandExecutor, commandExplorer, testingInterface, documentationManager, documentationViewer, dashboard, dashboardProvider, manualParameterEditor);
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
        this.dashboard.dispose();
        this.manualParameterEditor.dispose();
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