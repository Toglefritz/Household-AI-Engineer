/**
 * Testing framework exports for Kiro command research.
 * 
 * This module provides a comprehensive testing framework for discovering,
 * validating, executing, and analyzing Kiro commands.
 */

export { ParameterValidator, ValidationResult, ValidationError, ValidationContext } from './parameter-validator';
export { CommandExecutor, ExecutionContext, ExecutionResult, ExecutionError, SideEffect, WorkspaceSnapshot } from './command-executor';
export { 
  ResultCapture, 
  TestResult, 
  TestSession, 
  WorkspaceInfo, 
  TestConfiguration, 
  ResultAnalysis,
  PerformanceAnalysis,
  SideEffectAnalysis,
  ReturnValueAnalysis,
  RiskAssessment
} from './result-capture';
export { 
  SideEffectDetector, 
  DetailedSideEffect, 
  DetectionConfig, 
  WorkspaceStateSnapshot,
  FileInfo,
  DocumentInfo,
  EditorInfo
} from './side-effect-detector';
export { 
  TestResultStorage, 
  StorageConfig, 
  StorageStatistics, 
  SearchCriteria, 
  ExportOptions 
} from './test-result-storage';