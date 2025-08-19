/**
 * Mock implementation of VS Code API for testing.
 */

export const window = {
  createOutputChannel: jest.fn(() => ({
    appendLine: jest.fn(),
    show: jest.fn(),
    dispose: jest.fn(),
  })),
  showInformationMessage: jest.fn(),
  showErrorMessage: jest.fn(),
  showWarningMessage: jest.fn(),
};

export const workspace = {
  getConfiguration: jest.fn(() => ({
    get: jest.fn(),
  })),
};

export const commands = {
  executeCommand: jest.fn(),
  registerCommand: jest.fn(() => ({ dispose: jest.fn() })),
};

export const Uri = {
  file: jest.fn((path: string) => ({ fsPath: path, path })),
};

export const constants = {
  R_OK: 4,
  W_OK: 2,
};