---
sidebar_position: 3
---

# Development Job Types

This page documents the TypeScript interfaces and types used for representing development jobs in the Kiro Communication Bridge system. These types define the structure of job lifecycle management, execution tracking, and user interaction during the development process.

## Job Status and Lifecycle

### JobStatus

Enumeration representing the current state of a development job in the processing pipeline.

```typescript
type JobStatus = 
  | 'queued'          // Job is queued and waiting to be processed
  | 'initializing'    // Job is being initialized and workspace is being set up
  | 'developing'      // Job is actively being developed by Kiro
  | 'waiting-input'   // Job is paused waiting for user input
  | 'paused'          // Job has been manually paused
  | 'testing'         // Job is in the testing phase
  | 'finalizing'      // Job is being finalized and packaged
  | 'completed'       // Job has completed successfully
  | 'failed'          // Job has failed and cannot continue
  | 'cancelled';      // Job was cancelled by user or system
```

#### Status Descriptions

| Status | Description | Duration | Next States |
|--------|-------------|----------|-------------|
| `queued` | Waiting in job queue | Seconds to minutes | `initializing`, `cancelled` |
| `initializing` | Setting up workspace and dependencies | 1-3 minutes | `developing`, `failed` |
| `developing` | Active development by Kiro | 10-45 minutes | `waiting-input`, `testing`, `failed`, `cancelled` |
| `waiting-input` | Paused for user interaction | Until user responds | `developing`, `cancelled` |
| `paused` | Manually paused by user | Until resumed | `developing`, `cancelled` |
| `testing` | Running tests and validation | 2-10 minutes | `finalizing`, `failed` |
| `finalizing` | Packaging and cleanup | 1-3 minutes | `completed`, `failed` |
| `completed` | Successfully finished | Terminal state | None |
| `failed` | Encountered unrecoverable error | Terminal state | None (can be retried) |
| `cancelled` | Cancelled by user or system | Terminal state | None |

### UserInputType

Enumeration of user input types for interactive development sessions.

```typescript
type UserInputType = 'text' | 'choice' | 'file' | 'confirmation';
```

#### Input Type Descriptions

| Type | Description | Example Values |
|------|-------------|----------------|
| `text` | Free-form text input | `"MyApp"`, `"Enter description"` |
| `choice` | Selection from predefined options | `"React"`, `"Vue"`, `"Angular"` |
| `file` | File or directory path | `"/path/to/file.txt"`, `"./src"` |
| `confirmation` | Yes/no confirmation | `"yes"`, `"no"`, `"y"`, `"n"` |

## Logging and Tracking

### JobLogEntry

Interface representing a single log entry for job execution tracking.

```typescript
interface JobLogEntry {
  /** Timestamp when the log entry was created (ISO 8601 format) */
  readonly timestamp: string;
  
  /** Log level */
  readonly level: 'debug' | 'info' | 'warn' | 'error';
  
  /** Log message */
  readonly message: string;
  
  /** Component that generated the log entry */
  readonly component: string;
  
  /** Additional context data */
  readonly context?: Record<string, unknown>;
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `timestamp` | `string` | ISO 8601 timestamp when log was created |
| `level` | `'debug' \| 'info' \| 'warn' \| 'error'` | Severity level of the log entry |
| `message` | `string` | Human-readable log message |
| `component` | `string` | System component that generated the log |
| `context` | `Record<string, unknown>` | Additional structured data |

#### Example

```json
{
  "timestamp": "2025-01-19T10:30:15.123Z",
  "level": "info",
  "message": "Starting code generation for user authentication module",
  "component": "CodeGenerator",
  "context": {
    "jobId": "job_123",
    "phase": "implementation",
    "module": "authentication"
  }
}
```

### UserInteractionState

Interface representing the state of user interaction for jobs requiring input.

```typescript
interface UserInteractionState {
  /** Whether the job is currently waiting for user input */
  readonly waitingForInput: boolean;
  
  /** Question or prompt posed to the user */
  readonly question?: string;
  
  /** Type of input expected from the user */
  readonly inputType?: UserInputType;
  
  /** Available choices for choice-type inputs */
  readonly choices?: readonly string[];
  
  /** Timestamp when input was requested (ISO 8601 format) */
  readonly requestedAt?: string;
  
  /** Timeout for user input in milliseconds */
  readonly timeoutMs?: number;
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `waitingForInput` | `boolean` | Whether job is currently paused for input |
| `question` | `string` | Prompt or question displayed to user |
| `inputType` | `UserInputType` | Type of input expected |
| `choices` | `string[]` | Available options for choice inputs |
| `requestedAt` | `string` | ISO 8601 timestamp when input was requested |
| `timeoutMs` | `number` | Milliseconds before input request times out |

#### Example

```json
{
  "waitingForInput": true,
  "question": "Which frontend framework would you like to use?",
  "inputType": "choice",
  "choices": ["React", "Vue", "Angular", "Svelte"],
  "requestedAt": "2025-01-19T10:30:00Z",
  "timeoutMs": 300000
}
```

## Session and Progress Management

### KiroSessionInfo

Interface containing information about active Kiro development sessions.

```typescript
interface KiroSessionInfo {
  /** Unique session identifier */
  readonly sessionId: string;
  
  /** Path to the workspace directory */
  readonly workspacePath: string;
  
  /** Process ID of the active Kiro command */
  readonly processId?: number;
  
  /** Current command being executed */
  readonly currentCommand?: string;
  
  /** Session start timestamp (ISO 8601 format) */
  readonly startedAt: string;
  
  /** Last activity timestamp (ISO 8601 format) */
  readonly lastActivityAt: string;
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `sessionId` | `string` | Unique identifier for the Kiro session |
| `workspacePath` | `string` | Absolute path to the development workspace |
| `processId` | `number` | OS process ID of the active Kiro command |
| `currentCommand` | `string` | Command currently being executed |
| `startedAt` | `string` | ISO 8601 timestamp when session started |
| `lastActivityAt` | `string` | ISO 8601 timestamp of last activity |

#### Example

```json
{
  "sessionId": "kiro_session_1642598400000",
  "workspacePath": "/tmp/kiro_workspace_app_123",
  "processId": 12345,
  "currentCommand": "kiro.generateCode",
  "startedAt": "2025-01-19T10:00:00Z",
  "lastActivityAt": "2025-01-19T10:30:00Z"
}
```

### JobProgressInfo

Interface for tracking detailed job progress information.

```typescript
interface JobProgressInfo {
  /** Current completion percentage (0-100) */
  readonly percentage: number;
  
  /** Current development phase */
  readonly phase: DevelopmentPhase;
  
  /** Timestamp when the current phase started (ISO 8601 format) */
  readonly phaseStartedAt: string;
  
  /** List of completed tasks */
  readonly completedTasks: readonly string[];
  
  /** Current task being executed */
  readonly currentTask?: string;
  
  /** Estimated time remaining in milliseconds */
  readonly estimatedRemainingMs?: number;
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `percentage` | `number` | Overall completion percentage (0-100) |
| `phase` | `DevelopmentPhase` | Current development phase |
| `phaseStartedAt` | `string` | ISO 8601 timestamp when current phase began |
| `completedTasks` | `string[]` | Array of completed task descriptions |
| `currentTask` | `string` | Description of task currently being executed |
| `estimatedRemainingMs` | `number` | Estimated milliseconds until completion |

#### Example

```json
{
  "percentage": 75,
  "phase": "testing",
  "phaseStartedAt": "2025-01-19T10:45:00Z",
  "completedTasks": [
    "Generated project structure",
    "Implemented authentication system",
    "Created user interface components",
    "Added database integration"
  ],
  "currentTask": "Running unit tests for authentication module",
  "estimatedRemainingMs": 600000
}
```

### UserRequestInfo

Interface containing information about the original user request that initiated the job.

```typescript
interface UserRequestInfo {
  /** Natural language description of the desired application */
  readonly description: string;
  
  /** Optional conversation context ID */
  readonly conversationId?: string;
  
  /** Job priority level */
  readonly priority: JobPriority;
  
  /** Timestamp when the request was made (ISO 8601 format) */
  readonly requestedAt: string;
  
  /** User ID or identifier (if available) */
  readonly userId?: string;
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `description` | `string` | Natural language description from user |
| `conversationId` | `string` | Optional conversation context identifier |
| `priority` | `JobPriority` | Priority level for job processing |
| `requestedAt` | `string` | ISO 8601 timestamp when request was made |
| `userId` | `string` | Optional user identifier |

#### Example

```json
{
  "description": "I need a family chore tracker with weekly rotation and progress tracking",
  "conversationId": "conv_01HMX8K9P2Q3R4S5T6U7V8W9X0",
  "priority": "normal",
  "requestedAt": "2025-01-19T09:30:00Z",
  "userId": "user_01HMX8K9P2Q3R4S5T6U7V8W9X0"
}
```

## Complete Development Job

### DevelopmentJob

Complete interface representing all information about a development job managed by the orchestration system.

```typescript
interface DevelopmentJob {
  /** Unique job identifier */
  readonly id: string;
  
  /** Associated application ID */
  readonly applicationId: string;
  
  /** Current job status */
  readonly status: JobStatus;
  
  /** Job creation timestamp (ISO 8601 format) */
  readonly createdAt: string;
  
  /** Job start timestamp (ISO 8601 format) */
  readonly startedAt?: string;
  
  /** Job completion timestamp (ISO 8601 format) */
  readonly completedAt?: string;
  
  /** Last update timestamp (ISO 8601 format) */
  readonly updatedAt: string;
  
  /** Original user request information */
  readonly userRequest: UserRequestInfo;
  
  /** Current Kiro session information */
  readonly kiroSession?: KiroSessionInfo;
  
  /** Progress tracking information */
  readonly progress: JobProgressInfo;
  
  /** User interaction state */
  readonly userInteraction?: UserInteractionState;
  
  /** Job execution logs */
  readonly logs: readonly JobLogEntry[];
  
  /** Job timeout in milliseconds */
  readonly timeoutMs: number;
  
  /** Whether debug logging is enabled */
  readonly debugLogging: boolean;
  
  /** Number of retry attempts made */
  readonly retryCount: number;
  
  /** Maximum number of retry attempts allowed */
  readonly maxRetries: number;
  
  /** Error information if job failed */
  readonly error?: {
    /** Error message */
    readonly message: string;
    
    /** Error code */
    readonly code: string;
    
    /** Whether the error is recoverable */
    readonly recoverable: boolean;
    
    /** Timestamp when error occurred (ISO 8601 format) */
    readonly occurredAt: string;
    
    /** Stack trace or additional error details */
    readonly details?: string;
  };
}
```

#### Complete Example

```json
{
  "id": "job_01HMX8K9P2Q3R4S5T6U7V8W9X0",
  "applicationId": "app_01HMX8K9P2Q3R4S5T6U7V8W9X0",
  "status": "developing",
  "createdAt": "2025-01-19T09:30:00Z",
  "startedAt": "2025-01-19T09:32:00Z",
  "updatedAt": "2025-01-19T10:15:00Z",
  "userRequest": {
    "description": "I need a family chore tracker with weekly rotation",
    "conversationId": "conv_01HMX8K9P2Q3R4S5T6U7V8W9X0",
    "priority": "normal",
    "requestedAt": "2025-01-19T09:30:00Z",
    "userId": "user_01HMX8K9P2Q3R4S5T6U7V8W9X0"
  },
  "kiroSession": {
    "sessionId": "kiro_session_1642598400000",
    "workspacePath": "/tmp/kiro_workspace_app_01HMX8K9P2Q3R4S5T6U7V8W9X0",
    "processId": 12345,
    "currentCommand": "kiro.generateCode",
    "startedAt": "2025-01-19T09:32:00Z",
    "lastActivityAt": "2025-01-19T10:15:00Z"
  },
  "progress": {
    "percentage": 60,
    "phase": "implementation",
    "phaseStartedAt": "2025-01-19T09:45:00Z",
    "completedTasks": [
      "Analyzed user requirements",
      "Generated technical design",
      "Created project structure",
      "Implemented database schema"
    ],
    "currentTask": "Implementing chore assignment logic",
    "estimatedRemainingMs": 1200000
  },
  "logs": [
    {
      "timestamp": "2025-01-19T09:32:00Z",
      "level": "info",
      "message": "Job started successfully",
      "component": "JobManager"
    },
    {
      "timestamp": "2025-01-19T09:35:00Z",
      "level": "info",
      "message": "Requirements analysis completed",
      "component": "RequirementsAnalyzer",
      "context": {
        "requirementsCount": 12,
        "complexityScore": 7.5
      }
    },
    {
      "timestamp": "2025-01-19T10:15:00Z",
      "level": "info",
      "message": "Code generation in progress",
      "component": "CodeGenerator",
      "context": {
        "filesGenerated": 8,
        "linesOfCode": 1250
      }
    }
  ],
  "timeoutMs": 1800000,
  "debugLogging": false,
  "retryCount": 0,
  "maxRetries": 3
}
```

## Type Usage Examples

### TypeScript Job Manager

```typescript
import { DevelopmentJob, JobStatus, UserInputType } from './development-job-types';

class JobManager {
  private jobs: Map<string, DevelopmentJob> = new Map();

  createJob(userRequest: UserRequestInfo): DevelopmentJob {
    const jobId = `job_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const job: DevelopmentJob = {
      id: jobId,
      applicationId: `app_${jobId}`,
      status: 'queued',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      userRequest,
      progress: {
        percentage: 0,
        phase: 'requirements',
        phaseStartedAt: new Date().toISOString(),
        completedTasks: [],
      },
      logs: [{
        timestamp: new Date().toISOString(),
        level: 'info',
        message: 'Job created and queued',
        component: 'JobManager',
      }],
      timeoutMs: 1800000,
      debugLogging: false,
      retryCount: 0,
      maxRetries: 3,
    };

    this.jobs.set(jobId, job);
    return job;
  }

  updateJobStatus(jobId: string, status: JobStatus): boolean {
    const job = this.jobs.get(jobId);
    if (!job) return false;

    const updatedJob: DevelopmentJob = {
      ...job,
      status,
      updatedAt: new Date().toISOString(),
      ...(status === 'developing' && !job.startedAt && {
        startedAt: new Date().toISOString()
      }),
      ...((['completed', 'failed', 'cancelled'] as JobStatus[]).includes(status) && {
        completedAt: new Date().toISOString()
      }),
    };

    this.jobs.set(jobId, updatedJob);
    return true;
  }

  addJobLog(jobId: string, logEntry: Omit<JobLogEntry, 'timestamp'>): boolean {
    const job = this.jobs.get(jobId);
    if (!job) return false;

    const fullLogEntry: JobLogEntry = {
      ...logEntry,
      timestamp: new Date().toISOString(),
    };

    const updatedJob: DevelopmentJob = {
      ...job,
      logs: [...job.logs, fullLogEntry],
      updatedAt: new Date().toISOString(),
    };

    this.jobs.set(jobId, updatedJob);
    return true;
  }

  requestUserInput(
    jobId: string,
    question: string,
    inputType: UserInputType,
    choices?: string[],
    timeoutMs: number = 300000
  ): boolean {
    const job = this.jobs.get(jobId);
    if (!job) return false;

    const userInteraction: UserInteractionState = {
      waitingForInput: true,
      question,
      inputType,
      choices,
      requestedAt: new Date().toISOString(),
      timeoutMs,
    };

    const updatedJob: DevelopmentJob = {
      ...job,
      status: 'waiting-input',
      userInteraction,
      updatedAt: new Date().toISOString(),
    };

    this.jobs.set(jobId, updatedJob);
    return true;
  }

  getJobsByStatus(status: JobStatus): DevelopmentJob[] {
    return Array.from(this.jobs.values()).filter(job => job.status === status);
  }

  getActiveJobs(): DevelopmentJob[] {
    const activeStatuses: JobStatus[] = [
      'queued', 'initializing', 'developing', 'waiting-input', 'testing', 'finalizing'
    ];
    return Array.from(this.jobs.values()).filter(job => 
      activeStatuses.includes(job.status)
    );
  }

  getJobProgress(jobId: string): JobProgressInfo | null {
    const job = this.jobs.get(jobId);
    return job?.progress || null;
  }

  isJobWaitingForInput(jobId: string): boolean {
    const job = this.jobs.get(jobId);
    return job?.userInteraction?.waitingForInput ?? false;
  }
}

// Usage example
const jobManager = new JobManager();

// Create a new job
const userRequest: UserRequestInfo = {
  description: 'Create a task management app',
  priority: 'normal',
  requestedAt: new Date().toISOString(),
};

const job = jobManager.createJob(userRequest);
console.log(`Created job: ${job.id}`);

// Update job status
jobManager.updateJobStatus(job.id, 'developing');

// Add log entry
jobManager.addJobLog(job.id, {
  level: 'info',
  message: 'Starting code generation',
  component: 'CodeGenerator',
});

// Request user input
jobManager.requestUserInput(
  job.id,
  'Which database would you like to use?',
  'choice',
  ['PostgreSQL', 'MySQL', 'SQLite']
);

// Query jobs
const activeJobs = jobManager.getActiveJobs();
const waitingJobs = jobManager.getJobsByStatus('waiting-input');
```

### Dart/Flutter Job Tracking

```dart
enum JobStatus {
  queued,
  initializing,
  developing,
  waitingInput,
  paused,
  testing,
  finalizing,
  completed,
  failed,
  cancelled,
}

class JobLogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String component;
  final Map<String, dynamic>? context;

  JobLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.component,
    this.context,
  });

  factory JobLogEntry.fromJson(Map<String, dynamic> json) {
    return JobLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: json['level'] as String,
      message: json['message'] as String,
      component: json['component'] as String,
      context: json['context'] as Map<String, dynamic>?,
    );
  }
}

class DevelopmentJob {
  final String id;
  final String applicationId;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final UserRequestInfo userRequest;
  final KiroSessionInfo? kiroSession;
  final JobProgressInfo progress;
  final UserInteractionState? userInteraction;
  final List<JobLogEntry> logs;
  final int timeoutMs;
  final bool debugLogging;
  final int retryCount;
  final int maxRetries;
  final JobError? error;

  DevelopmentJob({
    required this.id,
    required this.applicationId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    required this.updatedAt,
    required this.userRequest,
    this.kiroSession,
    required this.progress,
    this.userInteraction,
    required this.logs,
    required this.timeoutMs,
    required this.debugLogging,
    required this.retryCount,
    required this.maxRetries,
    this.error,
  });

  factory DevelopmentJob.fromJson(Map<String, dynamic> json) {
    return DevelopmentJob(
      id: json['id'] as String,
      applicationId: json['applicationId'] as String,
      status: _parseJobStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt'] as String) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      userRequest: UserRequestInfo.fromJson(json['userRequest'] as Map<String, dynamic>),
      kiroSession: json['kiroSession'] != null 
          ? KiroSessionInfo.fromJson(json['kiroSession'] as Map<String, dynamic>)
          : null,
      progress: JobProgressInfo.fromJson(json['progress'] as Map<String, dynamic>),
      userInteraction: json['userInteraction'] != null 
          ? UserInteractionState.fromJson(json['userInteraction'] as Map<String, dynamic>)
          : null,
      logs: (json['logs'] as List)
          .map((log) => JobLogEntry.fromJson(log as Map<String, dynamic>))
          .toList(),
      timeoutMs: json['timeoutMs'] as int,
      debugLogging: json['debugLogging'] as bool,
      retryCount: json['retryCount'] as int,
      maxRetries: json['maxRetries'] as int,
      error: json['error'] != null 
          ? JobError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  static JobStatus _parseJobStatus(String status) {
    switch (status) {
      case 'queued': return JobStatus.queued;
      case 'initializing': return JobStatus.initializing;
      case 'developing': return JobStatus.developing;
      case 'waiting-input': return JobStatus.waitingInput;
      case 'paused': return JobStatus.paused;
      case 'testing': return JobStatus.testing;
      case 'finalizing': return JobStatus.finalizing;
      case 'completed': return JobStatus.completed;
      case 'failed': return JobStatus.failed;
      case 'cancelled': return JobStatus.cancelled;
      default: return JobStatus.queued;
    }
  }

  bool get isActive {
    return [
      JobStatus.queued,
      JobStatus.initializing,
      JobStatus.developing,
      JobStatus.waitingInput,
      JobStatus.testing,
      JobStatus.finalizing,
    ].contains(status);
  }

  bool get isWaitingForInput {
    return userInteraction?.waitingForInput ?? false;
  }

  Duration? get estimatedTimeRemaining {
    final remainingMs = progress.estimatedRemainingMs;
    return remainingMs != null ? Duration(milliseconds: remainingMs) : null;
  }
}
```

## Next Steps

- **[Error Types](/docs/api/types/error-types)** - Error handling and recovery types
- **[Application Metadata Types](/docs/api/types/application-metadata)** - Application metadata structures
- **[Command Execution Types](/docs/api/types/command-execution)** - Command execution interfaces
- **[User Input Endpoint](/docs/api/endpoints/user-input)** - Handle interactive job sessions