/**
 * Extension state management for the Kiro Command Research Tool.
 * 
 * This module manages the global state of the extension and provides
 * access to shared resources and components.
 */

import * as vscode from 'vscode';
import { FileStorageManager } from '../storage/file-storage-manager';
import { CommandRegistryScanner } from '../discovery/command-registry-scanner';
import { ParameterResearcher } from '../discovery/parameter-researcher';
import { ParameterValidator } from '../testing/parameter-validator';
import { CommandExecutor } from '../testing/command-executor';
import { CommandExplorer } from '../ui/command-explorer';
import { TestingInterface } from '../ui/testing-interface';
import { DocumentationManager } from '../ui/documentation-manager';
import { DocumentationExporter } from '../export/documentation-exporter';
import { DocumentationViewer } from '../documentation/documentation-viewer';

/**
 * Extension context and global state management.
 * 
 * This class maintains the global state of the extension and provides
 * access to shared resources like the storage manager and UI components.
 */
export class ExtensionState {
  private static instance: ExtensionState | null = null;

  private constructor(
    public readonly context: vscode.ExtensionContext,
    public readonly storageManager: FileStorageManager,
    public readonly commandScanner: CommandRegistryScanner,
    public readonly parameterResearcher: ParameterResearcher,
    public readonly parameterValidator: ParameterValidator,
    public readonly commandExecutor: CommandExecutor,
    public readonly commandExplorer: CommandExplorer,
    public readonly testingInterface: TestingInterface,
    public readonly documentationManager: DocumentationManager,
    public readonly documentationViewer: DocumentationViewer
  ) { }

  /**
   * Initializes the extension state singleton.
   * 
   * @param context VS Code extension context
   * @returns Promise that resolves to the extension state instance
   */
  public static async initialize(context: vscode.ExtensionContext): Promise<ExtensionState> {
    if (ExtensionState.instance) {
      throw new Error('Extension state already initialized');
    }

    const storageManager: FileStorageManager = new FileStorageManager(context);
    await storageManager.initialize();

    const commandScanner: CommandRegistryScanner = new CommandRegistryScanner();
    const parameterResearcher: ParameterResearcher = new ParameterResearcher();
    const parameterValidator: ParameterValidator = new ParameterValidator();
    const commandExecutor: CommandExecutor = new CommandExecutor(parameterValidator);
    
    // Initialize UI components
    const commandExplorer: CommandExplorer = new CommandExplorer(context, storageManager);
    const testingInterface: TestingInterface = new TestingInterface(
      context,
      commandExecutor,
      parameterValidator,
      {
        defaultTimeout: 30000,
        defaultCreateSnapshot: false,
        requireConfirmation: true,
        showAdvancedOptions: true,
        maxRecentTests: 10
      }
    );
    
    const documentationExporter: DocumentationExporter = new DocumentationExporter();
    const documentationManager: DocumentationManager = new DocumentationManager(
      context,
      documentationExporter,
      storageManager,
      {
        defaultFormats: ['markdown', 'json', 'typescript'],
        autoExport: false,
        exportDirectory: '',
        enableQualityAssessment: true,
        enableVersionTracking: true
      }
    );
    
    const documentationViewer: DocumentationViewer = new DocumentationViewer(context);

    ExtensionState.instance = new ExtensionState(
      context, 
      storageManager, 
      commandScanner, 
      parameterResearcher, 
      parameterValidator, 
      commandExecutor,
      commandExplorer,
      testingInterface,
      documentationManager,
      documentationViewer
    );
    return ExtensionState.instance;
  }

  /**
   * Gets the current extension state instance.
   * 
   * @returns The extension state instance
   * @throws Error if extension state is not initialized
   */
  public static getInstance(): ExtensionState {
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
  public async dispose(): Promise<void> {
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
  public static getCurrentInstance(): ExtensionState | null {
    return ExtensionState.instance;
  }
}