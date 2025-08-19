/**
 * Unit tests for WorkspaceManager functionality.
 * 
 * This test suite ensures that workspace creation, management, and cleanup
 * operations work correctly, including error handling and validation.
 */

import * as fs from 'fs-extra';
import * as path from 'path';
import * as os from 'os';
import { WorkspaceManager, CreateWorkspaceParams, WorkspaceValidationResult } from '../workspace/workspace-manager';
import { ExtensionConfiguration } from '../core/configuration-manager';
import { createApplicationMetadata } from '../types/application-metadata-factory';
import { ApplicationMetadata } from '../types/application-metadata';

describe('WorkspaceManager', () => {
  let workspaceManager: WorkspaceManager;
  let testConfig: ExtensionConfiguration;
  let tempDir: string;
  let appsDir: string;
  let templateDir: string;

  beforeEach(async () => {
    // Create temporary directories for testing
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'workspace-test-'));
    appsDir = path.join(tempDir, 'apps');
    templateDir = path.join(tempDir, 'templates');

    // Create test configuration
    testConfig = {
      api: {
        port: 3001,
        host: 'localhost',
        apiKey: 'test-key',
        timeoutMs: 30000,
      },
      websocket: {
        port: 3002,
        maxConnections: 100,
        connectionTimeoutMs: 60000,
      },
      workspace: {
        appsDirectory: appsDir,
        specTemplatePath: templateDir,
        maxWorkspaceSizeMb: 1024,
      },
      jobs: {
        maxConcurrentJobs: 3,
        defaultTimeoutMs: 1800000,
        cleanupIntervalMs: 300000,
      },
      logging: {
        level: 'info',
        logFilePath: './logs/test.log',
        maxLogSizeMb: 100,
      },
      general: {
        autoStart: true,
      },
    };

    workspaceManager = new WorkspaceManager();
  });

  afterEach(async () => {
    // Clean up temporary directories
    await workspaceManager.dispose();
    await fs.remove(tempDir);
  });

  describe('initialization', () => {
    it('should initialize successfully with valid configuration', async () => {
      await workspaceManager.initialize(testConfig);
      
      expect(workspaceManager.getAppsDirectoryPath()).toBe(appsDir);
      expect(await fs.pathExists(appsDir)).toBe(true);
    });

    it('should create apps directory if it does not exist', async () => {
      expect(await fs.pathExists(appsDir)).toBe(false);
      
      await workspaceManager.initialize(testConfig);
      
      expect(await fs.pathExists(appsDir)).toBe(true);
    });

    it('should create default spec template if template directory does not exist', async () => {
      await workspaceManager.initialize(testConfig);
      
      expect(await fs.pathExists(templateDir)).toBe(true);
      expect(await fs.pathExists(path.join(templateDir, '.kiro'))).toBe(true);
      expect(await fs.pathExists(path.join(templateDir, '.kiro', 'steering', 'coding-standards.md'))).toBe(true);
    });

    it('should throw error if apps directory cannot be created', async () => {
      // Create a file where the apps directory should be
      await fs.ensureDir(tempDir);
      await fs.writeFile(appsDir, 'blocking file');

      await expect(workspaceManager.initialize(testConfig)).rejects.toMatchObject({
        category: 'workspace',
      });
    });
  });

  describe('workspace creation', () => {
    let testMetadata: ApplicationMetadata;
    let createParams: CreateWorkspaceParams;

    beforeEach(async () => {
      await workspaceManager.initialize(testConfig);
      
      testMetadata = createApplicationMetadata({
        title: 'Test Application',
        description: 'A test application for unit testing',
        userRequestDescription: 'I need a test application',
      });

      createParams = {
        applicationId: 'test-app-123',
        metadata: testMetadata,
        initializeGit: true,
      };
    });

    it('should create workspace with correct structure', async () => {
      const workspacePath = await workspaceManager.createWorkspace(createParams);
      
      expect(workspacePath).toBe(path.join(appsDir, 'test-app-123'));
      expect(await fs.pathExists(workspacePath)).toBe(true);
      
      // Check directory structure
      expect(await fs.pathExists(path.join(workspacePath, 'src'))).toBe(true);
      expect(await fs.pathExists(path.join(workspacePath, 'tests'))).toBe(true);
      expect(await fs.pathExists(path.join(workspacePath, 'docs'))).toBe(true);
      expect(await fs.pathExists(path.join(workspacePath, '.kiro'))).toBe(true);
      expect(await fs.pathExists(path.join(workspacePath, '.kiro', 'specs'))).toBe(true);
      expect(await fs.pathExists(path.join(workspacePath, '.kiro', 'steering'))).toBe(true);
      
      // Check metadata file
      expect(await fs.pathExists(path.join(workspacePath, 'metadata.json'))).toBe(true);
      
      // Check Git initialization
      expect(await fs.pathExists(path.join(workspacePath, '.git'))).toBe(true);
      expect(await fs.pathExists(path.join(workspacePath, '.gitignore'))).toBe(true);
    });

    it('should save metadata correctly', async () => {
      const workspacePath = await workspaceManager.createWorkspace(createParams);
      const metadataPath = path.join(workspacePath, 'metadata.json');
      
      const savedMetadata = JSON.parse(await fs.readFile(metadataPath, 'utf8'));
      expect(savedMetadata.id).toBe(testMetadata.id);
      expect(savedMetadata.title).toBe(testMetadata.title);
      expect(savedMetadata.description).toBe(testMetadata.description);
    });

    it('should copy spec template if it exists', async () => {
      // Create a custom template
      const customTemplatePath = path.join(tempDir, 'custom-template');
      const customKiroPath = path.join(customTemplatePath, '.kiro');
      const customSteeringPath = path.join(customKiroPath, 'steering');
      
      await fs.ensureDir(customSteeringPath);
      await fs.writeFile(
        path.join(customSteeringPath, 'custom-standards.md'),
        '# Custom Standards\nCustom coding standards'
      );

      createParams.customTemplatePath = customTemplatePath;
      const workspacePath = await workspaceManager.createWorkspace(createParams);
      
      expect(await fs.pathExists(path.join(workspacePath, '.kiro', 'steering', 'custom-standards.md'))).toBe(true);
    });

    it('should skip Git initialization if requested', async () => {
      createParams.initializeGit = false;
      const workspacePath = await workspaceManager.createWorkspace(createParams);
      
      // When Git initialization is disabled, these files should not exist
      expect(await fs.pathExists(path.join(workspacePath, '.git'))).toBe(false);
      expect(await fs.pathExists(path.join(workspacePath, '.gitignore'))).toBe(false);
    });

    it('should throw error if workspace already exists', async () => {
      await workspaceManager.createWorkspace(createParams);
      
      await expect(workspaceManager.createWorkspace(createParams)).rejects.toMatchObject({
        category: 'workspace',
        code: 'WORKSPACE_ALREADY_EXISTS',
      });
    });

    it('should throw error if not initialized', async () => {
      const uninitializedManager = new WorkspaceManager();
      
      await expect(uninitializedManager.createWorkspace(createParams)).rejects.toThrow('not initialized');
    });
  });

  describe('workspace information', () => {
    let testMetadata: ApplicationMetadata;

    beforeEach(async () => {
      await workspaceManager.initialize(testConfig);
      
      testMetadata = createApplicationMetadata({
        title: 'Test Application',
        description: 'A test application for unit testing',
        userRequestDescription: 'I need a test application',
      });

      await workspaceManager.createWorkspace({
        applicationId: 'test-app-123',
        metadata: testMetadata,
      });
    });

    it('should get workspace information correctly', async () => {
      const workspaceInfo = await workspaceManager.getWorkspaceInfo('test-app-123');
      
      expect(workspaceInfo.applicationId).toBe('test-app-123');
      expect(workspaceInfo.workspacePath).toBe(path.join(appsDir, 'test-app-123'));
      expect(workspaceInfo.metadata.id).toBe(testMetadata.id);
      expect(workspaceInfo.hasGitRepository).toBe(true);
      expect(workspaceInfo.sizeBytes).toBeGreaterThan(0);
      expect(workspaceInfo.lastModified).toBeInstanceOf(Date);
    });

    it('should throw error for non-existent workspace', async () => {
      await expect(workspaceManager.getWorkspaceInfo('non-existent')).rejects.toMatchObject({
        category: 'workspace',
      });
    });
  });

  describe('workspace validation', () => {
    let testMetadata: ApplicationMetadata;

    beforeEach(async () => {
      await workspaceManager.initialize(testConfig);
      
      testMetadata = createApplicationMetadata({
        title: 'Test Application',
        description: 'A test application for unit testing',
        userRequestDescription: 'I need a test application',
      });
    });

    it('should validate complete workspace as valid', async () => {
      await workspaceManager.createWorkspace({
        applicationId: 'test-app-123',
        metadata: testMetadata,
      });

      const validation = await workspaceManager.validateWorkspace('test-app-123');
      
      expect(validation.isValid).toBe(true);
      expect(validation.issues).toHaveLength(0);
      expect(validation.recoverable).toBe(true);
    });

    it('should detect missing workspace directory', async () => {
      const validation = await workspaceManager.validateWorkspace('non-existent');
      
      expect(validation.isValid).toBe(false);
      expect(validation.issues).toContain('Workspace directory does not exist');
      expect(validation.recoverable).toBe(false);
    });

    it('should detect missing metadata file', async () => {
      const workspacePath = path.join(appsDir, 'test-app-123');
      await fs.ensureDir(workspacePath);
      
      const validation = await workspaceManager.validateWorkspace('test-app-123');
      
      expect(validation.isValid).toBe(false);
      expect(validation.issues).toContain('metadata.json file is missing');
      expect(validation.recoverable).toBe(true);
    });

    it('should detect missing .kiro directory', async () => {
      const workspacePath = path.join(appsDir, 'test-app-123');
      await fs.ensureDir(workspacePath);
      
      // Create metadata file
      const metadataPath = path.join(workspacePath, 'metadata.json');
      await fs.writeFile(metadataPath, JSON.stringify(testMetadata), 'utf8');
      
      const validation = await workspaceManager.validateWorkspace('test-app-123');
      
      expect(validation.isValid).toBe(false);
      expect(validation.issues).toContain('.kiro directory is missing');
      expect(validation.recoverable).toBe(true);
    });

    it('should detect corrupted metadata file', async () => {
      const workspacePath = path.join(appsDir, 'test-app-123');
      await fs.ensureDir(workspacePath);
      
      // Create invalid metadata file
      const metadataPath = path.join(workspacePath, 'metadata.json');
      await fs.writeFile(metadataPath, '{ invalid json }', 'utf8');
      
      const validation = await workspaceManager.validateWorkspace('test-app-123');
      
      expect(validation.isValid).toBe(false);
      expect(validation.issues).toContain('metadata.json file is corrupted or invalid');
      expect(validation.recoverable).toBe(true);
    });
  });

  describe('metadata management', () => {
    let testMetadata: ApplicationMetadata;

    beforeEach(async () => {
      await workspaceManager.initialize(testConfig);
      
      testMetadata = createApplicationMetadata({
        title: 'Test Application',
        description: 'A test application for unit testing',
        userRequestDescription: 'I need a test application',
      });

      await workspaceManager.createWorkspace({
        applicationId: 'test-app-123',
        metadata: testMetadata,
      });
    });

    it('should update metadata successfully', async () => {
      const updatedMetadata = {
        ...testMetadata,
        title: 'Updated Test Application',
        status: 'developing' as const,
      };

      await workspaceManager.updateApplicationMetadata('test-app-123', updatedMetadata);
      
      const workspaceInfo = await workspaceManager.getWorkspaceInfo('test-app-123');
      expect(workspaceInfo.metadata.title).toBe('Updated Test Application');
      expect(workspaceInfo.metadata.status).toBe('developing');
    });

    it('should throw error when updating metadata for non-existent workspace', async () => {
      await expect(
        workspaceManager.updateApplicationMetadata('non-existent', testMetadata)
      ).rejects.toMatchObject({
        category: 'workspace',
      });
    });
  });

  describe('workspace cleanup', () => {
    let testMetadata: ApplicationMetadata;

    beforeEach(async () => {
      await workspaceManager.initialize(testConfig);
      
      testMetadata = createApplicationMetadata({
        title: 'Test Application',
        description: 'A test application for unit testing',
        userRequestDescription: 'I need a test application',
      });

      await workspaceManager.createWorkspace({
        applicationId: 'test-app-123',
        metadata: testMetadata,
      });
    });

    it('should cleanup workspace successfully', async () => {
      const workspacePath = path.join(appsDir, 'test-app-123');
      expect(await fs.pathExists(workspacePath)).toBe(true);
      
      await workspaceManager.cleanupWorkspace('test-app-123');
      
      expect(await fs.pathExists(workspacePath)).toBe(false);
    });

    it('should handle cleanup of non-existent workspace gracefully', async () => {
      await expect(workspaceManager.cleanupWorkspace('non-existent')).resolves.not.toThrow();
    });

    it('should force cleanup when requested', async () => {
      const workspacePath = path.join(appsDir, 'test-app-123');
      expect(await fs.pathExists(workspacePath)).toBe(true);
      
      await workspaceManager.cleanupWorkspace('test-app-123', true);
      
      expect(await fs.pathExists(workspacePath)).toBe(false);
    });
  });

  describe('workspace listing', () => {
    beforeEach(async () => {
      await workspaceManager.initialize(testConfig);
    });

    it('should return empty list when no workspaces exist', async () => {
      const workspaces = await workspaceManager.listWorkspaces();
      expect(workspaces).toEqual([]);
    });

    it('should list existing workspaces', async () => {
      const metadata1 = createApplicationMetadata({
        title: 'App 1',
        description: 'First app',
        userRequestDescription: 'I need app 1',
      });

      const metadata2 = createApplicationMetadata({
        title: 'App 2',
        description: 'Second app',
        userRequestDescription: 'I need app 2',
      });

      await workspaceManager.createWorkspace({
        applicationId: 'app-1',
        metadata: metadata1,
      });

      await workspaceManager.createWorkspace({
        applicationId: 'app-2',
        metadata: metadata2,
      });

      const workspaces = await workspaceManager.listWorkspaces();
      expect(workspaces).toHaveLength(2);
      expect(workspaces).toContain('app-1');
      expect(workspaces).toContain('app-2');
    });

    it('should only include directories with metadata.json', async () => {
      // Create a workspace with metadata
      const metadata = createApplicationMetadata({
        title: 'Valid App',
        description: 'Valid app',
        userRequestDescription: 'I need a valid app',
      });

      await workspaceManager.createWorkspace({
        applicationId: 'valid-app',
        metadata: metadata,
      });

      // Create a directory without metadata
      const invalidWorkspacePath = path.join(appsDir, 'invalid-app');
      await fs.ensureDir(invalidWorkspacePath);

      const workspaces = await workspaceManager.listWorkspaces();
      expect(workspaces).toHaveLength(1);
      expect(workspaces).toContain('valid-app');
      expect(workspaces).not.toContain('invalid-app');
    });

    it('should handle non-existent apps directory', async () => {
      await fs.remove(appsDir);
      
      const workspaces = await workspaceManager.listWorkspaces();
      expect(workspaces).toEqual([]);
    });
  });

  describe('utility methods', () => {
    beforeEach(async () => {
      await workspaceManager.initialize(testConfig);
    });

    it('should return correct workspace path', () => {
      const workspacePath = workspaceManager.getWorkspacePath('test-app-123');
      expect(workspacePath).toBe(path.join(appsDir, 'test-app-123'));
    });

    it('should return correct apps directory path', () => {
      const appsPath = workspaceManager.getAppsDirectoryPath();
      expect(appsPath).toBe(appsDir);
    });
  });

  describe('error handling', () => {
    it('should throw meaningful errors for workspace operations', async () => {
      await workspaceManager.initialize(testConfig);
      
      // Test error when workspace doesn't exist
      await expect(workspaceManager.getWorkspaceInfo('non-existent')).rejects.toMatchObject({
        category: 'workspace',
      });
    });

    it('should handle file system errors gracefully', async () => {
      await workspaceManager.initialize(testConfig);
      
      // Create a workspace
      const metadata = createApplicationMetadata({
        title: 'Test App',
        description: 'Test app',
        userRequestDescription: 'I need a test app',
      });

      await workspaceManager.createWorkspace({
        applicationId: 'test-app',
        metadata: metadata,
      });

      // Make the workspace directory read-only to simulate permission error
      const workspacePath = path.join(appsDir, 'test-app');
      await fs.chmod(workspacePath, 0o444);

      try {
        // This should handle the permission error gracefully
        const validation = await workspaceManager.validateWorkspace('test-app');
        expect(validation.isValid).toBe(false);
        expect(validation.recoverable).toBe(false);
      } finally {
        // Restore permissions for cleanup
        await fs.chmod(workspacePath, 0o755);
      }
    });
  });
});