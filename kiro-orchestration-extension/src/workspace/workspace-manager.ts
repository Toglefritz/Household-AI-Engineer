/**
 * Workspace management for the Kiro Orchestration Extension.
 * 
 * This module handles creation, management, and cleanup of application
 * workspaces where Kiro develops user-requested applications.
 */

import * as fs from 'fs-extra';
import * as path from 'path';
import * as vscode from 'vscode';
import { Logger } from '../core/logger';
import { ExtensionConfiguration } from '../core/configuration-manager';
import { 
  ApplicationMetadata, 
  serializeApplicationMetadata, 
  deserializeApplicationMetadata,
  createWorkspaceError,
  createSystemError,
  OrchestrationError
} from '../types';

/**
 * Workspace creation parameters.
 */
export interface CreateWorkspaceParams {
  /** Application ID for the workspace */
  applicationId: string;
  
  /** Application metadata to store */
  metadata: ApplicationMetadata;
  
  /** Whether to initialize Git repository */
  initializeGit?: boolean;
  
  /** Custom spec template path (optional) */
  customTemplatePath?: string;
}

/**
 * Workspace validation result.
 */
export interface WorkspaceValidationResult {
  /** Whether the workspace is valid */
  isValid: boolean;
  
  /** List of validation issues found */
  issues: string[];
  
  /** Whether the issues are recoverable */
  recoverable: boolean;
}

/**
 * Workspace information structure.
 */
export interface WorkspaceInfo {
  /** Application ID */
  applicationId: string;
  
  /** Full path to the workspace directory */
  workspacePath: string;
  
  /** Application metadata */
  metadata: ApplicationMetadata;
  
  /** Whether Git is initialized */
  hasGitRepository: boolean;
  
  /** Workspace size in bytes */
  sizeBytes: number;
  
  /** Last modified timestamp */
  lastModified: Date;
}

/**
 * Manages application workspaces and file operations.
 * 
 * This class handles the creation of isolated workspaces for each
 * application development job, including directory structure setup,
 * spec template copying, and metadata management.
 */
export class WorkspaceManager {
  private readonly logger: Logger;
  private configuration: ExtensionConfiguration | null = null;
  private appsDirectoryPath: string = './apps';
  private specTemplatePath: string = '';
  private isInitialized: boolean = false;

  /**
   * Creates a new workspace manager instance.
   */
  constructor() {
    this.logger = new Logger('WorkspaceManager');
  }

  /**
   * Initializes the workspace manager with configuration.
   * 
   * @param config - Extension configuration
   */
  public async initialize(config: ExtensionConfiguration): Promise<void> {
    try {
      this.logger.info('Initializing workspace manager...');
      this.configuration = config;
      this.appsDirectoryPath = path.resolve(config.workspace.appsDirectory);
      this.specTemplatePath = path.resolve(config.workspace.specTemplatePath);
      
      // Create apps directory if it doesn't exist
      await this.ensureAppsDirectory();
      
      // Validate directory permissions
      await this.validateDirectoryPermissions();
      
      // Set up spec templates
      await this.setupSpecTemplates();
      
      this.isInitialized = true;
      this.logger.info('Workspace manager initialized successfully', {
        appsDirectory: this.appsDirectoryPath,
        specTemplatePath: this.specTemplatePath,
      });
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to initialize workspace manager: ${errorMessage}`);
      throw error;
    }
  }

  /**
   * Creates a new application workspace.
   * 
   * @param params - Workspace creation parameters
   * @returns Promise that resolves to the workspace path
   * @throws OrchestrationError if workspace creation fails
   */
  public async createWorkspace(params: CreateWorkspaceParams): Promise<string> {
    this.ensureInitialized();
    
    try {
      this.logger.info(`Creating workspace for application ${params.applicationId}...`);
      
      const workspacePath = this.getWorkspacePath(params.applicationId);
      
      // Check if workspace already exists
      if (await fs.pathExists(workspacePath)) {
        throw createWorkspaceError(
          workspacePath,
          'create',
          {
            message: `Workspace already exists for application ${params.applicationId}`,
            code: 'WORKSPACE_ALREADY_EXISTS',
            context: { applicationId: params.applicationId },
          }
        );
      }
      
      // Create workspace directory structure
      await this.createWorkspaceStructure(workspacePath);
      
      // Copy spec template
      const templatePath = params.customTemplatePath || this.specTemplatePath;
      await this.copySpecTemplate(templatePath, workspacePath);
      
      // Save application metadata
      await this.saveApplicationMetadata(workspacePath, params.metadata);
      
      // Initialize Git repository if requested (default is true)
      if (params.initializeGit !== false) {
        await this.initializeGitRepository(workspacePath);
      }
      
      this.logger.info(`Workspace created successfully: ${workspacePath}`);
      return workspacePath;
    } catch (error: unknown) {
      if (error instanceof Error && 'category' in error) {
        throw error; // Re-throw OrchestrationError
      }
      
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to create workspace: ${errorMessage}`);
      throw createWorkspaceError(
        this.getWorkspacePath(params.applicationId),
        'create',
        {
          message: `Failed to create workspace: ${errorMessage}`,
          cause: error instanceof Error ? error : undefined,
        }
      );
    }
  }

  /**
   * Gets information about an existing workspace.
   * 
   * @param applicationId - Application ID
   * @returns Promise that resolves to workspace information
   * @throws OrchestrationError if workspace doesn't exist or can't be read
   */
  public async getWorkspaceInfo(applicationId: string): Promise<WorkspaceInfo> {
    this.ensureInitialized();
    
    try {
      const workspacePath = this.getWorkspacePath(applicationId);
      
      if (!(await fs.pathExists(workspacePath))) {
        throw createWorkspaceError(
          workspacePath,
          'read',
          {
            message: `Workspace not found for application ${applicationId}`,
            code: 'WORKSPACE_NOT_FOUND',
          }
        );
      }
      
      // Load metadata
      const metadata = await this.loadApplicationMetadata(workspacePath);
      
      // Check for Git repository
      const gitPath = path.join(workspacePath, '.git');
      const hasGitRepository = await fs.pathExists(gitPath);
      
      // Calculate workspace size
      const sizeBytes = await this.calculateDirectorySize(workspacePath);
      
      // Get last modified time
      const stats = await fs.stat(workspacePath);
      
      return {
        applicationId,
        workspacePath,
        metadata,
        hasGitRepository,
        sizeBytes,
        lastModified: stats.mtime,
      };
    } catch (error: unknown) {
      if (error instanceof Error && 'category' in error) {
        throw error; // Re-throw OrchestrationError
      }
      
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to get workspace info: ${errorMessage}`);
      throw createWorkspaceError(
        this.getWorkspacePath(applicationId),
        'read',
        {
          message: `Failed to get workspace info: ${errorMessage}`,
          cause: error instanceof Error ? error : undefined,
        }
      );
    }
  }

  /**
   * Validates a workspace for integrity and completeness.
   * 
   * @param applicationId - Application ID to validate
   * @returns Promise that resolves to validation result
   */
  public async validateWorkspace(applicationId: string): Promise<WorkspaceValidationResult> {
    this.ensureInitialized();
    
    const issues: string[] = [];
    let recoverable = true;
    
    try {
      const workspacePath = this.getWorkspacePath(applicationId);
      
      // Check if workspace exists
      if (!(await fs.pathExists(workspacePath))) {
        issues.push('Workspace directory does not exist');
        recoverable = false;
        return { isValid: false, issues, recoverable };
      }
      
      // Check for metadata file
      const metadataPath = path.join(workspacePath, 'metadata.json');
      if (!(await fs.pathExists(metadataPath))) {
        issues.push('metadata.json file is missing');
      } else {
        try {
          await this.loadApplicationMetadata(workspacePath);
        } catch {
          issues.push('metadata.json file is corrupted or invalid');
        }
      }
      
      // Check for .kiro directory
      const kiroPath = path.join(workspacePath, '.kiro');
      if (!(await fs.pathExists(kiroPath))) {
        issues.push('.kiro directory is missing');
      } else {
        // Check for spec files
        const specsPath = path.join(kiroPath, 'specs');
        if (!(await fs.pathExists(specsPath))) {
          issues.push('.kiro/specs directory is missing');
        }
        
        // Check for steering files
        const steeringPath = path.join(kiroPath, 'steering');
        if (!(await fs.pathExists(steeringPath))) {
          issues.push('.kiro/steering directory is missing');
        }
      }
      
      // Check workspace permissions
      try {
        await fs.access(workspacePath, fs.constants.R_OK | fs.constants.W_OK);
      } catch {
        issues.push('Insufficient permissions for workspace directory');
        recoverable = false;
      }
      
      this.logger.debug(`Workspace validation completed for ${applicationId}`, {
        issuesFound: issues.length,
        recoverable,
      });
      
      return {
        isValid: issues.length === 0,
        issues,
        recoverable,
      };
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      issues.push(`Validation failed: ${errorMessage}`);
      return { isValid: false, issues, recoverable: false };
    }
  }

  /**
   * Updates application metadata in the workspace.
   * 
   * @param applicationId - Application ID
   * @param metadata - Updated metadata
   * @throws OrchestrationError if update fails
   */
  public async updateApplicationMetadata(applicationId: string, metadata: ApplicationMetadata): Promise<void> {
    this.ensureInitialized();
    
    try {
      const workspacePath = this.getWorkspacePath(applicationId);
      await this.saveApplicationMetadata(workspacePath, metadata);
      
      this.logger.debug(`Updated metadata for application ${applicationId}`);
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to update metadata: ${errorMessage}`);
      throw createWorkspaceError(
        this.getWorkspacePath(applicationId),
        'write',
        {
          message: `Failed to update metadata: ${errorMessage}`,
          cause: error instanceof Error ? error : undefined,
        }
      );
    }
  }

  /**
   * Cleans up a workspace by removing it completely.
   * 
   * @param applicationId - Application ID
   * @param force - Whether to force removal even if workspace is in use
   * @throws OrchestrationError if cleanup fails
   */
  public async cleanupWorkspace(applicationId: string, force: boolean = false): Promise<void> {
    this.ensureInitialized();
    
    try {
      const workspacePath = this.getWorkspacePath(applicationId);
      
      if (!(await fs.pathExists(workspacePath))) {
        this.logger.warn(`Workspace not found for cleanup: ${applicationId}`);
        return;
      }
      
      // TODO: Check if workspace is in use (unless force is true)
      if (!force) {
        // Add logic to check for active processes or locks
      }
      
      await fs.remove(workspacePath);
      this.logger.info(`Workspace cleaned up successfully: ${applicationId}`);
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to cleanup workspace: ${errorMessage}`);
      throw createWorkspaceError(
        this.getWorkspacePath(applicationId),
        'delete',
        {
          message: `Failed to cleanup workspace: ${errorMessage}`,
          cause: error instanceof Error ? error : undefined,
        }
      );
    }
  }

  /**
   * Lists all existing workspaces.
   * 
   * @returns Promise that resolves to array of application IDs
   */
  public async listWorkspaces(): Promise<string[]> {
    this.ensureInitialized();
    
    try {
      if (!(await fs.pathExists(this.appsDirectoryPath))) {
        return [];
      }
      
      const entries = await fs.readdir(this.appsDirectoryPath, { withFileTypes: true });
      const workspaces: string[] = [];
      
      for (const entry of entries) {
        if (entry.isDirectory()) {
          const workspacePath = path.join(this.appsDirectoryPath, entry.name);
          const metadataPath = path.join(workspacePath, 'metadata.json');
          
          // Only include directories that have metadata.json
          if (await fs.pathExists(metadataPath)) {
            workspaces.push(entry.name);
          }
        }
      }
      
      return workspaces;
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to list workspaces: ${errorMessage}`);
      throw createWorkspaceError(
        this.appsDirectoryPath,
        'read',
        {
          message: `Failed to list workspaces: ${errorMessage}`,
          cause: error instanceof Error ? error : undefined,
        }
      );
    }
  }

  /**
   * Gets the path to the apps directory.
   * 
   * @returns The absolute path to the apps directory
   */
  public getAppsDirectoryPath(): string {
    return this.appsDirectoryPath;
  }

  /**
   * Gets the workspace path for a specific application.
   * 
   * @param applicationId - Application ID
   * @returns Full path to the workspace directory
   */
  public getWorkspacePath(applicationId: string): string {
    return path.join(this.appsDirectoryPath, applicationId);
  }

  /**
   * Disposes of the workspace manager and cleans up resources.
   */
  public async dispose(): Promise<void> {
    this.logger.info('Disposing workspace manager...');
    this.isInitialized = false;
    this.configuration = null;
    this.logger.info('Workspace manager disposed');
  }

  /**
   * Ensures the workspace manager is initialized.
   * 
   * @throws Error if not initialized
   */
  private ensureInitialized(): void {
    if (!this.isInitialized || !this.configuration) {
      throw new Error('WorkspaceManager is not initialized. Call initialize() first.');
    }
  }

  /**
   * Ensures the apps directory exists and is accessible.
   */
  private async ensureAppsDirectory(): Promise<void> {
    try {
      await fs.ensureDir(this.appsDirectoryPath);
      this.logger.debug(`Apps directory ensured: ${this.appsDirectoryPath}`);
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      throw createWorkspaceError(
        this.appsDirectoryPath,
        'create',
        {
          message: `Failed to create apps directory: ${errorMessage}`,
          cause: error instanceof Error ? error : undefined,
        }
      );
    }
  }

  /**
   * Validates directory permissions for the apps directory.
   */
  private async validateDirectoryPermissions(): Promise<void> {
    try {
      await fs.access(this.appsDirectoryPath, fs.constants.R_OK | fs.constants.W_OK);
      this.logger.debug('Directory permissions validated');
    } catch (error: unknown) {
      throw createWorkspaceError(
        this.appsDirectoryPath,
        'permissions',
        {
          message: 'Insufficient permissions for apps directory',
          cause: error instanceof Error ? error : undefined,
        }
      );
    }
  }

  /**
   * Sets up spec templates for workspace creation.
   */
  private async setupSpecTemplates(): Promise<void> {
    try {
      // For now, we'll create a default template if it doesn't exist
      if (!(await fs.pathExists(this.specTemplatePath))) {
        await this.createDefaultSpecTemplate();
      }
      
      this.logger.debug('Spec templates set up successfully');
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.warn(`Failed to setup spec templates: ${errorMessage}`);
      // Don't throw here - we can create workspaces without templates
    }
  }

  /**
   * Creates the default spec template structure.
   */
  private async createDefaultSpecTemplate(): Promise<void> {
    await fs.ensureDir(this.specTemplatePath);
    
    const kiroDir = path.join(this.specTemplatePath, '.kiro');
    const specsDir = path.join(kiroDir, 'specs');
    const steeringDir = path.join(kiroDir, 'steering');
    
    await fs.ensureDir(specsDir);
    await fs.ensureDir(steeringDir);
    
    // Create default coding standards file
    const codingStandardsPath = path.join(steeringDir, 'coding-standards.md');
    const codingStandards = `# Coding Standards

This document defines the coding standards and best practices for this application.

## General Principles

- Write clean, readable, and maintainable code
- Follow established patterns and conventions
- Include comprehensive error handling
- Write meaningful tests for all functionality
- Document complex logic and business rules

## Code Quality

- Use TypeScript for type safety
- Follow consistent naming conventions
- Keep functions small and focused
- Avoid deep nesting and complex conditionals
- Use meaningful variable and function names
`;
    
    await fs.writeFile(codingStandardsPath, codingStandards, 'utf8');
    
    this.logger.debug('Default spec template created');
  }

  /**
   * Creates the workspace directory structure.
   * 
   * @param workspacePath - Path to the workspace
   */
  private async createWorkspaceStructure(workspacePath: string): Promise<void> {
    const directories = [
      workspacePath,
      path.join(workspacePath, 'src'),
      path.join(workspacePath, 'tests'),
      path.join(workspacePath, 'docs'),
      path.join(workspacePath, '.kiro'),
      path.join(workspacePath, '.kiro', 'specs'),
      path.join(workspacePath, '.kiro', 'steering'),
    ];
    
    for (const dir of directories) {
      await fs.ensureDir(dir);
    }
    
    this.logger.debug('Workspace structure created', { workspacePath });
  }

  /**
   * Copies the spec template to the workspace.
   * 
   * @param templatePath - Path to the template
   * @param workspacePath - Path to the workspace
   */
  private async copySpecTemplate(templatePath: string, workspacePath: string): Promise<void> {
    if (await fs.pathExists(templatePath)) {
      const kiroTemplatePath = path.join(templatePath, '.kiro');
      const kiroWorkspacePath = path.join(workspacePath, '.kiro');
      
      if (await fs.pathExists(kiroTemplatePath)) {
        await fs.copy(kiroTemplatePath, kiroWorkspacePath, { overwrite: false });
        this.logger.debug('Spec template copied to workspace');
      }
    }
  }

  /**
   * Saves application metadata to the workspace.
   * 
   * @param workspacePath - Path to the workspace
   * @param metadata - Application metadata
   */
  private async saveApplicationMetadata(workspacePath: string, metadata: ApplicationMetadata): Promise<void> {
    const metadataPath = path.join(workspacePath, 'metadata.json');
    const metadataJson = serializeApplicationMetadata(metadata);
    await fs.writeFile(metadataPath, metadataJson, 'utf8');
    
    this.logger.debug('Application metadata saved', { metadataPath });
  }

  /**
   * Loads application metadata from the workspace.
   * 
   * @param workspacePath - Path to the workspace
   * @returns Application metadata
   */
  private async loadApplicationMetadata(workspacePath: string): Promise<ApplicationMetadata> {
    const metadataPath = path.join(workspacePath, 'metadata.json');
    const metadataJson = await fs.readFile(metadataPath, 'utf8');
    return deserializeApplicationMetadata(metadataJson);
  }

  /**
   * Initializes a Git repository in the workspace.
   * 
   * @param workspacePath - Path to the workspace
   */
  private async initializeGitRepository(workspacePath: string): Promise<void> {
    try {
      // Create .gitignore file
      const gitignorePath = path.join(workspacePath, '.gitignore');
      const gitignoreContent = `# Dependencies
node_modules/
*.log

# Build outputs
dist/
build/
out/

# IDE files
.vscode/
.idea/

# OS files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
`;
      
      await fs.writeFile(gitignorePath, gitignoreContent, 'utf8');
      
      // Initialize Git repository (we'll use a simple approach for now)
      const gitDir = path.join(workspacePath, '.git');
      await fs.ensureDir(gitDir);
      
      this.logger.debug('Git repository initialized', { workspacePath });
    } catch (error: unknown) {
      const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
      this.logger.warn(`Failed to initialize Git repository: ${errorMessage}`);
      // Don't throw - Git initialization is optional
    }
  }

  /**
   * Calculates the total size of a directory.
   * 
   * @param dirPath - Path to the directory
   * @returns Size in bytes
   */
  private async calculateDirectorySize(dirPath: string): Promise<number> {
    let totalSize = 0;
    
    try {
      const entries = await fs.readdir(dirPath, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dirPath, entry.name);
        
        if (entry.isDirectory()) {
          totalSize += await this.calculateDirectorySize(fullPath);
        } else if (entry.isFile()) {
          const stats = await fs.stat(fullPath);
          totalSize += stats.size;
        }
      }
    } catch (error: unknown) {
      // If we can't read a directory, just skip it
      this.logger.debug(`Could not calculate size for directory: ${dirPath}`);
    }
    
    return totalSize;
  }
}