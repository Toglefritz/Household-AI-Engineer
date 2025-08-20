---
sidebar_position: 2
---

# Application Metadata Types

This page documents the TypeScript interfaces and types used for representing application metadata in the Kiro Communication Bridge system. These types define the structure of application data, development progress, and job configuration throughout the orchestration system.

## Core Application Types

### ApplicationStatus

Enumeration representing the current state of an application in the development lifecycle.

```typescript
type ApplicationStatus = 
  | 'queued'          // Application is queued for development
  | 'developing'      // Application is currently being developed
  | 'waiting-input'   // Development is paused waiting for user input
  | 'paused'          // Development has been manually paused
  | 'completed'       // Application development is complete
  | 'failed'          // Application development has failed
  | 'cancelled';      // Application development was cancelled
```

#### Status Values

| Status | Description | Next Actions |
|--------|-------------|--------------|
| `queued` | Application is waiting to be processed | Will transition to `developing` |
| `developing` | Active development in progress | May transition to `waiting-input`, `completed`, or `failed` |
| `waiting-input` | Paused for user interaction | Requires user input to continue |
| `paused` | Manually paused by user | Can be resumed to `developing` |
| `completed` | Development finished successfully | Ready for deployment |
| `failed` | Development encountered unrecoverable error | May be retried or cancelled |
| `cancelled` | Development was cancelled by user | Terminal state |

### DevelopmentPhase

Enumeration representing the current phase of the development process.

```typescript
type DevelopmentPhase = 
  | 'requirements'    // Analyzing and documenting requirements
  | 'design'          // Creating technical design and architecture
  | 'implementation'  // Writing code and implementing features
  | 'testing'         // Running tests and quality assurance
  | 'finalization';   // Final packaging and deployment preparation
```

#### Phase Descriptions

| Phase | Description | Typical Duration |
|-------|-------------|------------------|
| `requirements` | Analyzing user request and generating requirements | 2-5 minutes |
| `design` | Creating technical architecture and design | 5-10 minutes |
| `implementation` | Writing code and implementing features | 15-45 minutes |
| `testing` | Running tests and quality assurance | 5-15 minutes |
| `finalization` | Final packaging and deployment preparation | 2-5 minutes |

### JobPriority

Priority levels for development queue management.

```typescript
type JobPriority = 'low' | 'normal' | 'high';
```

#### Priority Levels

| Priority | Description | Processing Order |
|----------|-------------|------------------|
| `low` | Non-urgent development tasks | Processed after normal and high priority |
| `normal` | Standard development requests | Default priority level |
| `high` | Urgent or time-sensitive requests | Processed before normal and low priority |

## Progress and Configuration

### DevelopmentProgress

Interface tracking the current state and progress of the development process.

```typescript
interface DevelopmentProgress {
  /** Completion percentage (0-100) */
  readonly percentage: number;
  
  /** Current development phase */
  readonly currentPhase: DevelopmentPhase;
  
  /** Description of current task being performed */
  readonly currentTask: string;
  
  /** Estimated completion timestamp (ISO 8601 format) */
  readonly estimatedCompletion?: string;
  
  /** List of completed milestones */
  readonly completedMilestones: readonly string[];
  
  /** List of remaining milestones */
  readonly remainingMilestones: readonly string[];
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `percentage` | `number` | Completion percentage from 0 to 100 |
| `currentPhase` | `DevelopmentPhase` | Current phase of development |
| `currentTask` | `string` | Human-readable description of current activity |
| `estimatedCompletion` | `string` | ISO 8601 timestamp of estimated completion |
| `completedMilestones` | `string[]` | Array of completed milestone descriptions |
| `remainingMilestones` | `string[]` | Array of remaining milestone descriptions |

#### Example

```json
{
  "percentage": 65,
  "currentPhase": "implementation",
  "currentTask": "Implementing user authentication system",
  "estimatedCompletion": "2025-01-19T11:15:00Z",
  "completedMilestones": [
    "Requirements analysis completed",
    "Technical design finalized",
    "Project structure created",
    "Database schema implemented"
  ],
  "remainingMilestones": [
    "Complete authentication implementation",
    "Add user interface components",
    "Write unit tests",
    "Package for deployment"
  ]
}
```

### JobConfiguration

Interface controlling various aspects of how development jobs are processed.

```typescript
interface JobConfiguration {
  /** Priority level for job processing */
  readonly priority: JobPriority;
  
  /** Maximum development time in milliseconds */
  readonly timeoutMs: number;
  
  /** Whether debug logging is enabled for this job */
  readonly debugLogging: boolean;
}
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `priority` | `JobPriority` | `'normal'` | Processing priority in the job queue |
| `timeoutMs` | `number` | `1800000` | Maximum time allowed for development (30 minutes) |
| `debugLogging` | `boolean` | `false` | Enable detailed logging for debugging |

#### Example

```json
{
  "priority": "high",
  "timeoutMs": 3600000,
  "debugLogging": true
}
```

## Error and File Management

### ApplicationError

Interface providing detailed information about errors that occur during development.

```typescript
interface ApplicationError {
  /** Human-readable error message */
  readonly message: string;
  
  /** Error code for programmatic handling */
  readonly code: string;
  
  /** Whether the error is recoverable through retry or user action */
  readonly recoverable: boolean;
  
  /** Timestamp when the error occurred (ISO 8601 format) */
  readonly occurredAt: string;
  
  /** Additional context information for debugging */
  readonly context?: Record<string, unknown>;
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `string` | User-friendly error description |
| `code` | `string` | Unique error identifier for programmatic handling |
| `recoverable` | `boolean` | Whether the error can be resolved through retry or user action |
| `occurredAt` | `string` | ISO 8601 timestamp when the error occurred |
| `context` | `Record<string, unknown>` | Additional debugging information |

#### Common Error Codes

| Code | Description | Recoverable |
|------|-------------|-------------|
| `REQUIREMENTS_ANALYSIS_FAILED` | Failed to analyze user requirements | Yes |
| `DESIGN_GENERATION_FAILED` | Failed to generate technical design | Yes |
| `CODE_GENERATION_FAILED` | Failed to generate application code | Yes |
| `TESTING_FAILED` | Application tests failed | Yes |
| `DEPLOYMENT_FAILED` | Failed to package for deployment | Yes |
| `TIMEOUT_EXCEEDED` | Development exceeded maximum time limit | No |
| `RESOURCE_EXHAUSTED` | Insufficient system resources | Yes |

#### Example

```json
{
  "message": "Failed to generate application code due to invalid requirements",
  "code": "CODE_GENERATION_FAILED",
  "recoverable": true,
  "occurredAt": "2025-01-19T10:45:00Z",
  "context": {
    "phase": "implementation",
    "attemptCount": 2,
    "lastSuccessfulStep": "database_schema_creation"
  }
}
```

### ApplicationFiles

Interface tracking important files generated during development.

```typescript
interface ApplicationFiles {
  /** Path to the main application entry point */
  readonly mainFile?: string;
  
  /** Path to the README file */
  readonly readme?: string;
  
  /** Path to the package.json or equivalent configuration file */
  readonly packageFile?: string;
  
  /** Paths to key source files */
  readonly sourceFiles: readonly string[];
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `mainFile` | `string` | Path to the primary application entry point |
| `readme` | `string` | Path to the README documentation file |
| `packageFile` | `string` | Path to package.json, pubspec.yaml, or similar |
| `sourceFiles` | `string[]` | Array of paths to important source code files |

#### Example

```json
{
  "mainFile": "src/main.ts",
  "readme": "README.md",
  "packageFile": "package.json",
  "sourceFiles": [
    "src/main.ts",
    "src/auth/auth.service.ts",
    "src/auth/auth.controller.ts",
    "src/database/database.service.ts",
    "src/models/user.model.ts"
  ]
}
```

## Complete Application Metadata

### ApplicationMetadata

Complete interface representing all information about an application managed by the orchestration system.

```typescript
interface ApplicationMetadata {
  /** Unique identifier for the application */
  readonly id: string;
  
  /** Human-readable application title */
  readonly title: string;
  
  /** Detailed description of the application's purpose and functionality */
  readonly description: string;
  
  /** Current development status */
  readonly status: ApplicationStatus;
  
  /** Timestamp when the application was created (ISO 8601 format) */
  readonly createdAt: string;
  
  /** Timestamp of the last status update (ISO 8601 format) */
  readonly updatedAt: string;
  
  /** Current development progress information */
  readonly progress: DevelopmentProgress;
  
  /** Development job configuration */
  readonly jobConfig: JobConfiguration;
  
  /** Error information if development failed */
  readonly error?: ApplicationError;
  
  /** Paths to important files within the workspace */
  readonly files: ApplicationFiles;
  
  /** Original user request that initiated this application */
  readonly userRequest: {
    /** Natural language description provided by user */
    readonly description: string;
    
    /** Optional conversation context ID */
    readonly conversationId?: string;
  };
}
```

#### Complete Example

```json
{
  "id": "app_01HMX8K9P2Q3R4S5T6U7V8W9X0",
  "title": "Family Chore Tracker",
  "description": "A household chore management system with weekly rotation scheduling and progress tracking for family members.",
  "status": "developing",
  "createdAt": "2025-01-19T10:00:00Z",
  "updatedAt": "2025-01-19T10:30:00Z",
  "progress": {
    "percentage": 45,
    "currentPhase": "implementation",
    "currentTask": "Implementing chore assignment logic",
    "estimatedCompletion": "2025-01-19T11:30:00Z",
    "completedMilestones": [
      "Requirements analysis completed",
      "Database schema designed",
      "User authentication implemented"
    ],
    "remainingMilestones": [
      "Complete chore management features",
      "Add notification system",
      "Implement reporting dashboard",
      "Write comprehensive tests"
    ]
  },
  "jobConfig": {
    "priority": "normal",
    "timeoutMs": 1800000,
    "debugLogging": false
  },
  "files": {
    "mainFile": "src/app.ts",
    "readme": "README.md",
    "packageFile": "package.json",
    "sourceFiles": [
      "src/app.ts",
      "src/models/chore.model.ts",
      "src/models/user.model.ts",
      "src/services/chore.service.ts",
      "src/controllers/chore.controller.ts",
      "src/database/migrations/001_initial.sql"
    ]
  },
  "userRequest": {
    "description": "I need a family chore tracker with weekly rotation and progress tracking",
    "conversationId": "conv_01HMX8K9P2Q3R4S5T6U7V8W9X0"
  }
}
```

## Type Usage Examples

### TypeScript Client Implementation

```typescript
import { ApplicationMetadata, ApplicationStatus, DevelopmentPhase } from './application-types';

class ApplicationManager {
  private applications: Map<string, ApplicationMetadata> = new Map();

  addApplication(metadata: ApplicationMetadata): void {
    this.applications.set(metadata.id, metadata);
  }

  getApplication(id: string): ApplicationMetadata | undefined {
    return this.applications.get(id);
  }

  getApplicationsByStatus(status: ApplicationStatus): ApplicationMetadata[] {
    return Array.from(this.applications.values())
      .filter(app => app.status === status);
  }

  getApplicationsByPhase(phase: DevelopmentPhase): ApplicationMetadata[] {
    return Array.from(this.applications.values())
      .filter(app => app.progress.currentPhase === phase);
  }

  updateApplicationProgress(
    id: string, 
    progress: Partial<DevelopmentProgress>
  ): boolean {
    const app = this.applications.get(id);
    if (!app) return false;

    const updatedApp: ApplicationMetadata = {
      ...app,
      progress: { ...app.progress, ...progress },
      updatedAt: new Date().toISOString(),
    };

    this.applications.set(id, updatedApp);
    return true;
  }

  getCompletionEstimate(id: string): Date | null {
    const app = this.applications.get(id);
    if (!app?.progress.estimatedCompletion) return null;
    
    return new Date(app.progress.estimatedCompletion);
  }

  isApplicationRecoverable(id: string): boolean {
    const app = this.applications.get(id);
    return app?.error?.recoverable ?? false;
  }
}

// Usage example
const manager = new ApplicationManager();

// Add a new application
const newApp: ApplicationMetadata = {
  id: 'app_123',
  title: 'Task Manager',
  description: 'Simple task management application',
  status: 'queued',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  progress: {
    percentage: 0,
    currentPhase: 'requirements',
    currentTask: 'Analyzing user requirements',
    completedMilestones: [],
    remainingMilestones: ['Complete requirements', 'Design system', 'Implement features'],
  },
  jobConfig: {
    priority: 'normal',
    timeoutMs: 1800000,
    debugLogging: false,
  },
  files: {
    sourceFiles: [],
  },
  userRequest: {
    description: 'I need a simple task manager',
  },
};

manager.addApplication(newApp);

// Update progress
manager.updateApplicationProgress('app_123', {
  percentage: 25,
  currentPhase: 'design',
  currentTask: 'Creating system architecture',
});

// Query applications
const developingApps = manager.getApplicationsByStatus('developing');
const designPhaseApps = manager.getApplicationsByPhase('design');
```

### Dart/Flutter Type Definitions

```dart
enum ApplicationStatus {
  queued,
  developing,
  waitingInput,
  paused,
  completed,
  failed,
  cancelled,
}

enum DevelopmentPhase {
  requirements,
  design,
  implementation,
  testing,
  finalization,
}

enum JobPriority {
  low,
  normal,
  high,
}

class DevelopmentProgress {
  final int percentage;
  final DevelopmentPhase currentPhase;
  final String currentTask;
  final DateTime? estimatedCompletion;
  final List<String> completedMilestones;
  final List<String> remainingMilestones;

  DevelopmentProgress({
    required this.percentage,
    required this.currentPhase,
    required this.currentTask,
    this.estimatedCompletion,
    required this.completedMilestones,
    required this.remainingMilestones,
  });

  factory DevelopmentProgress.fromJson(Map<String, dynamic> json) {
    return DevelopmentProgress(
      percentage: json['percentage'] as int,
      currentPhase: _parsePhase(json['currentPhase'] as String),
      currentTask: json['currentTask'] as String,
      estimatedCompletion: json['estimatedCompletion'] != null
          ? DateTime.parse(json['estimatedCompletion'] as String)
          : null,
      completedMilestones: List<String>.from(json['completedMilestones'] as List),
      remainingMilestones: List<String>.from(json['remainingMilestones'] as List),
    );
  }

  static DevelopmentPhase _parsePhase(String phase) {
    switch (phase) {
      case 'requirements': return DevelopmentPhase.requirements;
      case 'design': return DevelopmentPhase.design;
      case 'implementation': return DevelopmentPhase.implementation;
      case 'testing': return DevelopmentPhase.testing;
      case 'finalization': return DevelopmentPhase.finalization;
      default: return DevelopmentPhase.requirements;
    }
  }
}

class ApplicationMetadata {
  final String id;
  final String title;
  final String description;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DevelopmentProgress progress;
  final JobConfiguration jobConfig;
  final ApplicationError? error;
  final ApplicationFiles files;
  final UserRequest userRequest;

  ApplicationMetadata({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.progress,
    required this.jobConfig,
    this.error,
    required this.files,
    required this.userRequest,
  });

  factory ApplicationMetadata.fromJson(Map<String, dynamic> json) {
    return ApplicationMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      progress: DevelopmentProgress.fromJson(json['progress'] as Map<String, dynamic>),
      jobConfig: JobConfiguration.fromJson(json['jobConfig'] as Map<String, dynamic>),
      error: json['error'] != null 
          ? ApplicationError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      files: ApplicationFiles.fromJson(json['files'] as Map<String, dynamic>),
      userRequest: UserRequest.fromJson(json['userRequest'] as Map<String, dynamic>),
    );
  }

  static ApplicationStatus _parseStatus(String status) {
    switch (status) {
      case 'queued': return ApplicationStatus.queued;
      case 'developing': return ApplicationStatus.developing;
      case 'waiting-input': return ApplicationStatus.waitingInput;
      case 'paused': return ApplicationStatus.paused;
      case 'completed': return ApplicationStatus.completed;
      case 'failed': return ApplicationStatus.failed;
      case 'cancelled': return ApplicationStatus.cancelled;
      default: return ApplicationStatus.queued;
    }
  }
}
```

## Validation and Utilities

### Progress Calculation

```typescript
function calculateProgress(
  currentPhase: DevelopmentPhase,
  phaseProgress: number
): number {
  const phaseWeights = {
    requirements: 10,
    design: 20,
    implementation: 50,
    testing: 15,
    finalization: 5,
  };

  const phaseOrder: DevelopmentPhase[] = [
    'requirements',
    'design', 
    'implementation',
    'testing',
    'finalization'
  ];

  let totalProgress = 0;
  const currentIndex = phaseOrder.indexOf(currentPhase);

  // Add completed phases
  for (let i = 0; i < currentIndex; i++) {
    totalProgress += phaseWeights[phaseOrder[i]];
  }

  // Add current phase progress
  totalProgress += (phaseWeights[currentPhase] * phaseProgress) / 100;

  return Math.round(totalProgress);
}
```

### Status Validation

```typescript
function isValidStatusTransition(
  from: ApplicationStatus,
  to: ApplicationStatus
): boolean {
  const validTransitions: Record<ApplicationStatus, ApplicationStatus[]> = {
    queued: ['developing', 'cancelled'],
    developing: ['waiting-input', 'paused', 'completed', 'failed', 'cancelled'],
    'waiting-input': ['developing', 'cancelled'],
    paused: ['developing', 'cancelled'],
    completed: [], // Terminal state
    failed: ['developing', 'cancelled'], // Can retry
    cancelled: [], // Terminal state
  };

  return validTransitions[from].includes(to);
}
```

## Next Steps

- **[Development Job Types](/docs/api/types/development-job)** - Job lifecycle and execution types
- **[Error Types](/docs/api/types/error-types)** - Error handling and recovery types
- **[Command Execution Types](/docs/api/types/command-execution)** - Command execution interfaces
- **[Flutter Integration](/docs/guides/flutter-setup)** - Use these types in Flutter applications