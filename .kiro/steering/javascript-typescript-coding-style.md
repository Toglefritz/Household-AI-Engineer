# JavaScript/TypeScript Coding Standards

## Architecture Pattern: MVC

This project follows a strict MVC (Model-View-Controller) pattern for all components:

### Route/Component (Entry Point)
- Each feature has a main component file that serves as the entry point
- Components are responsible only for defining the component structure and delegating to controllers
- Use functional components with hooks for React, or class-based components for vanilla JS

```typescript
// React example
interface WelcomeProps {
  userId: string;
}

export const WelcomeComponent: React.FC<WelcomeProps> = ({ userId }) => {
  const controller = useWelcomeController(userId);
  return <WelcomeView controller={controller} />;
};

// Vanilla JS/Node.js example
export class WelcomeRoute {
  private readonly controller: WelcomeController;

  constructor(dependencies: RouteDependencies) {
    this.controller = new WelcomeController(dependencies);
  }

  public async handle(request: Request): Promise<Response> {
    return this.controller.handleRequest(request);
  }
}
```

### Controller (Business Logic)
- Controllers handle all business logic and state management
- Controllers manage application state and trigger view updates
- All event handlers and data manipulation logic belongs in controllers
- Controllers expose methods and state to views through well-defined interfaces

```typescript
export class WelcomeController {
  private selectedDevice: Device | null = null;
  private readonly deviceService: DeviceService;
  private readonly eventEmitter: EventEmitter;

  constructor(deviceService: DeviceService, eventEmitter: EventEmitter) {
    this.deviceService = deviceService;
    this.eventEmitter = eventEmitter;
  }

  // Event handlers
  public onDeviceSelected(device: Device): void {
    this.selectedDevice = device;
    this.eventEmitter.emit('stateChanged', this.getState());
  }

  public async loadDevices(): Promise<Device[]> {
    try {
      const devices: Device[] = await this.deviceService.getDevices();
      this.eventEmitter.emit('devicesLoaded', devices);
      return devices;
    } catch (error: unknown) {
      this.handleError(error);
      throw error;
    }
  }

  public getState(): WelcomeState {
    return {
      selectedDevice: this.selectedDevice,
      isLoading: this.isLoading,
      error: this.error,
    };
  }

  private handleError(error: unknown): void {
    const errorMessage: string = error instanceof Error ? error.message : 'Unknown error';
    this.eventEmitter.emit('error', errorMessage);
  }
}
```

### View (Presentation)
- Views handle only UI presentation and user interaction
- Views receive controllers as parameters for accessing state and methods
- Views should be "dumb" and purely declarative
- No business logic should exist in view classes

```typescript
interface WelcomeViewProps {
  controller: WelcomeController;
}

export const WelcomeView: React.FC<WelcomeViewProps> = ({ controller }) => {
  const [state, setState] = useState<WelcomeState>(controller.getState());

  useEffect(() => {
    const handleStateChange = (newState: WelcomeState): void => {
      setState(newState);
    };

    controller.eventEmitter.on('stateChanged', handleStateChange);
    return () => {
      controller.eventEmitter.off('stateChanged', handleStateChange);
    };
  }, [controller]);

  return (
    <div className="welcome-container">
      {/* UI only - no business logic */}
      <DeviceSelector
        devices={state.devices}
        selectedDevice={state.selectedDevice}
        onDeviceSelect={controller.onDeviceSelected}
      />
    </div>
  );
};
```

## State Management

### Primary Pattern: Controller-Based State
- Use controller classes to manage application state
- Controllers emit events when state changes occur
- Views subscribe to state changes through event listeners or hooks
- Avoid complex state management libraries (Redux, MobX, Zustand) unless absolutely necessary
- Keep state management simple and predictable

### State Organization
- Declare state as private properties in controller classes
- Initialize state in constructor or initialization methods
- Use TypeScript interfaces to define state shape
- Expose state through getter methods or state objects

```typescript
interface ApplicationState {
  readonly applications: Application[];
  readonly isLoading: boolean;
  readonly error: string | null;
  readonly selectedApplication: Application | null;
}

export class ApplicationController {
  private applications: Application[] = [];
  private isLoading: boolean = false;
  private error: string | null = null;
  private selectedApplication: Application | null = null;

  public getState(): ApplicationState {
    return {
      applications: [...this.applications], // Return immutable copy
      isLoading: this.isLoading,
      error: this.error,
      selectedApplication: this.selectedApplication,
    };
  }
}
```

## Component Composition

### Avoid Functions Returning JSX/HTML
**❌ Don't do this:**
```typescript
function renderHeader(): JSX.Element {
  return (
    <div className="header">
      <h1>Header</h1>
    </div>
  );
}
```

**✅ Do this instead:**
```typescript
interface HeaderProps {
  title: string;
}

export const Header: React.FC<HeaderProps> = ({ title }) => {
  return (
    <div className="header">
      <h1>{title}</h1>
    </div>
  );
};
```

### Component Extraction Guidelines
- Extract reusable UI components into separate component files
- Place feature-specific components in `components/` subdirectories
- Place shared components in `src/components/` or `lib/components/`
- Prefer composition over inheritance
- Use TypeScript interfaces to define component props

### Styling and Layout
- Use CSS classes for styling, avoid inline styles except for dynamic values
- Use consistent spacing values from a design system or constants file
- Prefer semantic HTML elements and CSS Grid/Flexbox for layout

**✅ Preferred styling pattern:**
```typescript
export const ItemList: React.FC<ItemListProps> = ({ items }) => {
  return (
    <div className="item-list">
      {items.map((item: Item, index: number) => (
        <div key={item.id} className="item-list__item">
          <span className="item-list__title">{item.title}</span>
          <div className="item-list__spacing" />
          <span className="item-list__description">{item.description}</span>
        </div>
      ))}
    </div>
  );
};
```

**❌ Avoid inline styles for static values:**
```typescript
export const ItemList: React.FC<ItemListProps> = ({ items }) => {
  return (
    <div style={{ padding: '16px', margin: '8px' }}>
      {items.map((item: Item) => (
        <div key={item.id} style={{ marginBottom: '16px' }}>
          {item.title}
        </div>
      ))}
    </div>
  );
};
```

## Routing and Navigation

### Use Framework Router
- Use the router provided by your framework (React Router, Next.js Router, Express Router)
- Avoid string-based route definitions in favor of typed route objects
- Use programmatic navigation through controller methods

**✅ Preferred navigation pattern:**
```typescript
// React Router example
export class NavigationController {
  constructor(private readonly navigate: NavigateFunction) {}

  public navigateToApplication(applicationId: string): void {
    this.navigate(`/applications/${applicationId}`);
  }

  public navigateBack(): void {
    this.navigate(-1);
  }
}

// Express Router example
export class ApplicationRoutes {
  constructor(private readonly controller: ApplicationController) {}

  public setupRoutes(router: Router): void {
    router.get('/applications', this.controller.getApplications.bind(this.controller));
    router.post('/applications', this.controller.createApplication.bind(this.controller));
    router.get('/applications/:id', this.controller.getApplication.bind(this.controller));
  }
}
```

**❌ Avoid string-based navigation in components:**
```typescript
// Don't do this
const handleClick = (): void => {
  window.location.href = '/applications/123';
};
```

### Navigation Best Practices
- Handle navigation in controllers, not views
- Pass data through URL parameters or state, not global variables
- Use type-safe route parameters and query strings
- Implement proper error handling for navigation failures

## Code Style

### Type Safety and Strong Typing
- All variables must be explicitly typed, including local variables within function bodies
- Never use `any` type unless absolutely necessary for third-party library integration
- Use specific types rather than generic types when possible
- Prefer union types over `any` when multiple types are acceptable

**✅ Preferred strong typing:**
```typescript
function processApplications(): void {
  const applications: Application[] = getApplications();
  const statusCounts: Map<string, number> = new Map<string, number>();
  const defaultStatus: string = 'pending';
  
  for (const app: Application of applications) {
    const status: string = app.status ?? defaultStatus;
    const currentCount: number = statusCounts.get(status) ?? 0;
    statusCounts.set(status, currentCount + 1);
  }
}
```

**❌ Avoid type inference and any:**
```typescript
function processApplications() {
  const applications = getApplications(); // Type unclear
  const statusCounts = new Map(); // Any type
  const defaultStatus = 'pending'; // Could be inferred, but be explicit
  
  for (const app of applications) { // Type unclear
    const status = app.status ?? defaultStatus;
    const currentCount = statusCounts.get(status) ?? 0;
    statusCounts.set(status, currentCount + 1);
  }
}
```

### Strong Typing Guidelines
- Declare explicit types for all function parameters and return values
- Use generic types with constraints: `Array<string>`, `Map<string, number>`, `Set<Application>`
- Create interfaces for object shapes and function signatures
- Use type assertions sparingly and prefer type guards
- Document complex generic types with meaningful names

```typescript
// Good: Explicit interface definitions
interface ApiResponse<T> {
  readonly data: T;
  readonly status: number;
  readonly message: string;
}

interface ApplicationRepository {
  getApplications(): Promise<Application[]>;
  getApplication(id: string): Promise<Application | null>;
  createApplication(request: CreateApplicationRequest): Promise<Application>;
  updateApplication(id: string, updates: Partial<Application>): Promise<Application>;
  deleteApplication(id: string): Promise<void>;
}

// Good: Type guards instead of type assertions
function isApplication(obj: unknown): obj is Application {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'id' in obj &&
    'title' in obj &&
    'status' in obj
  );
}
```

### Linting and Formatting
- Use ESLint with TypeScript rules for code quality
- Use Prettier for consistent code formatting
- Follow Airbnb or similar established style guide
- Always declare return types for functions
- Use single quotes for strings consistently
- Avoid lines longer than 100 characters when practical

### Documentation
- Document all public classes, interfaces, and methods using JSDoc
- Use `/** */` for documentation comments
- Include parameter descriptions and examples for complex methods
- Document business logic and architectural decisions

```typescript
/**
 * Manages the lifecycle and state of household applications.
 * 
 * This controller handles application creation, modification, deployment,
 * and monitoring. It serves as the primary interface between the UI and
 * the backend orchestration services.
 */
export class ApplicationController {
  /**
   * Creates a new application based on the user's natural language request.
   * 
   * This method processes the user request through the conversation system,
   * generates a specification, and initiates the development process.
   * 
   * @param userRequest - Natural language description of the desired application
   * @param conversationId - Optional ID to continue an existing conversation
   * @returns Promise that resolves to the created application
   * @throws {ValidationError} When the user request is invalid or incomplete
   * @throws {NetworkError} When backend communication fails
   * @throws {QuotaError} When the user has reached their application limit
   * 
   * @example
   * ```typescript
   * const application = await controller.createApplication(
   *   'I need a family chore tracker with weekly rotation'
   * );
   * console.log(`Created application: ${application.title}`);
   * ```
   */
  public async createApplication(
    userRequest: string,
    conversationId?: string
  ): Promise<Application> {
    // Implementation details...
  }
}
```

### Error Handling
- Use specific error classes that extend the base Error class
- Implement proper error boundaries in React applications
- Handle async operations with try-catch blocks
- Log errors with appropriate log levels (debug, info, warn, error)
- Never swallow errors silently

```typescript
export class ValidationError extends Error {
  public readonly field: string;
  public readonly code: string;

  constructor(message: string, field: string, code: string = 'VALIDATION_FAILED') {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
    this.code = code;
  }
}

export class ApplicationService {
  public async createApplication(request: CreateApplicationRequest): Promise<Application> {
    try {
      this.validateRequest(request);
      const application: Application = await this.apiClient.createApplication(request);
      this.logger.info(`Application created successfully: ${application.id}`);
      return application;
    } catch (error: unknown) {
      if (error instanceof ValidationError) {
        this.logger.warn(`Validation failed: ${error.message}`, { field: error.field });
        throw error;
      }
      
      this.logger.error('Failed to create application', { error, request });
      throw new Error('Application creation failed');
    }
  }
}
```

## File Organization

### Naming Conventions
- Use kebab-case for file names: `application-controller.ts`, `user-service.ts`
- Use PascalCase for class names: `ApplicationController`, `UserService`
- Use camelCase for variable and method names: `selectedDevice`, `handleClick`
- Use SCREAMING_SNAKE_CASE for constants: `MAX_RETRY_ATTEMPTS`, `DEFAULT_TIMEOUT`

### Directory Structure
- Group related files in feature directories
- Place shared components in `src/components/` or `lib/components/`
- Place business logic in `src/services/` or `lib/services/`
- Keep models/types in `src/types/` or `lib/types/`
- Organize by feature, not by file type

```
src/
├── components/           # Shared UI components
├── features/            # Feature-specific code
│   ├── applications/
│   │   ├── components/  # Feature-specific components
│   │   ├── controllers/ # Business logic controllers
│   │   ├── services/    # Feature-specific services
│   │   └── types/       # Feature-specific types
│   └── users/
├── services/            # Shared business services
├── types/               # Shared type definitions
└── utils/               # Utility functions
```

### One Class Per File
- Each file must contain exactly one primary class, interface, or type definition
- The file name should match the primary export in kebab-case
- This architecture makes maintenance, testing, and code navigation easier
- Use barrel exports (index.ts) to group related exports

**✅ Preferred structure for related classes:**
```
src/services/authentication/
├── authentication-service.ts    # Contains AuthenticationService class
├── authentication-types.ts     # Contains authentication-related types
├── authentication-errors.ts    # Contains authentication error classes
└── index.ts                    # Barrel export file
```

**✅ Barrel export pattern:**
```typescript
// src/services/authentication/index.ts
export { AuthenticationService } from './authentication-service';
export type { AuthenticationRequest, AuthenticationResponse } from './authentication-types';
export { AuthenticationError, InvalidCredentialsError } from './authentication-errors';
```

**✅ Importing from barrel exports:**
```typescript
import { AuthenticationService, AuthenticationError } from '../services/authentication';
```

**❌ Never put multiple classes in one file:**
```typescript
// Don't do this - even for related classes
export class AuthenticationService { }
export class AuthorizationService { }
export interface AuthenticationRequest { }
```

### File Naming Rules
- Use kebab-case for all file names
- File name should reflect the primary class/interface it contains
- Use descriptive names that indicate the file's purpose
- Avoid generic names like `utils.ts` or `helpers.ts`

## JSON and Data Handling

### Avoid Code Generation When Possible
- Prefer explicit, readable code over generated code
- Keep JSON parsing logic transparent and maintainable
- Use TypeScript interfaces to define data shapes
- Implement proper validation for external data

### Use Factory Functions and Type Guards
**✅ Preferred pattern:**
```typescript
export interface Device {
  readonly id: string;
  readonly name: string;
  readonly saltLevel: number;
  readonly batteryLevel: number;
}

export function createDeviceFromJson(json: unknown): Device {
  if (!isValidDeviceJson(json)) {
    throw new ValidationError('Invalid device JSON structure');
  }

  return {
    id: json.id,
    name: json.name,
    saltLevel: Number(json.saltLevel),
    batteryLevel: Number(json.batteryLevel),
  };
}

export function deviceToJson(device: Device): Record<string, unknown> {
  return {
    id: device.id,
    name: device.name,
    saltLevel: device.saltLevel,
    batteryLevel: device.batteryLevel,
  };
}

function isValidDeviceJson(json: unknown): json is {
  id: string;
  name: string;
  saltLevel: number;
  batteryLevel: number;
} {
  return (
    typeof json === 'object' &&
    json !== null &&
    'id' in json &&
    'name' in json &&
    'saltLevel' in json &&
    'batteryLevel' in json &&
    typeof (json as any).id === 'string' &&
    typeof (json as any).name === 'string' &&
    typeof (json as any).saltLevel === 'number' &&
    typeof (json as any).batteryLevel === 'number'
  );
}
```

### JSON Best Practices
- Always validate external JSON data with type guards
- Handle nullable fields appropriately with optional properties
- Use explicit type conversion for numeric values
- Include both serialization and deserialization functions
- Throw meaningful errors for invalid data
- Document expected JSON structure in interface comments

### Error Handling in JSON Parsing
```typescript
export function createDeviceFromJson(json: unknown): Device {
  try {
    if (!isValidDeviceJson(json)) {
      throw new ValidationError(
        'Invalid device JSON: missing required fields or incorrect types'
      );
    }

    return {
      id: json.id,
      name: json.name,
      saltLevel: Number(json.saltLevel),
      batteryLevel: Number(json.batteryLevel),
    };
  } catch (error: unknown) {
    if (error instanceof ValidationError) {
      throw error;
    }
    
    throw new Error(`Failed to parse device from JSON: ${error}`);
  }
}
```

## Internationalization and Localization

### Use Internationalization Libraries
- Use established i18n libraries (react-i18next, i18next, formatjs)
- Never hard-code user-facing strings in components
- All user-facing text must use translation functions
- Organize translation keys by feature or component

**✅ Preferred localization pattern:**
```typescript
// translations/en.json
{
  "welcome": {
    "title": "Welcome to the Application",
    "subtitle": "How can I help you today?",
    "buttons": {
      "getStarted": "Get Started",
      "learnMore": "Learn More"
    }
  },
  "errors": {
    "networkConnection": "Unable to connect to the server. Please check your internet connection.",
    "validation": {
      "required": "This field is required",
      "email": "Please enter a valid email address"
    }
  }
}

// Component usage
import { useTranslation } from 'react-i18next';

export const WelcomeView: React.FC = () => {
  const { t } = useTranslation();

  return (
    <div>
      <h1>{t('welcome.title')}</h1>
      <p>{t('welcome.subtitle')}</p>
      <button>{t('welcome.buttons.getStarted')}</button>
    </div>
  );
};
```

**❌ Never hard-code strings:**
```typescript
// Don't do this
export const WelcomeView: React.FC = () => {
  return (
    <div>
      <h1>Welcome to the Application</h1>
      <p>How can I help you today?</p>
    </div>
  );
};
```

### Translation Key Organization
- Use nested objects to group related translations
- Use descriptive key names that indicate context
- Include pluralization rules for countable items
- Provide context comments for translators

**✅ Required translation structure:**
```json
{
  "application": {
    "status": {
      "pending": "Pending",
      "inProgress": "In Progress", 
      "completed": "Completed",
      "failed": "Failed"
    },
    "actions": {
      "create": "Create Application",
      "edit": "Edit Application",
      "delete": "Delete Application",
      "deploy": "Deploy Application"
    },
    "messages": {
      "createSuccess": "Application '{{name}}' created successfully",
      "deleteConfirm": "Are you sure you want to delete '{{name}}'?",
      "itemCount_one": "{{count}} application",
      "itemCount_other": "{{count}} applications"
    }
  }
}
```

### Advanced Localization Features

#### Interpolation and Pluralization
```typescript
// Using interpolation
const message: string = t('application.messages.createSuccess', { name: application.name });

// Using pluralization
const countMessage: string = t('application.messages.itemCount', { count: applications.length });

// Using date/number formatting
const formattedDate: string = t('common.dateFormat', { 
  date: new Date(),
  formatParams: {
    date: { year: 'numeric', month: 'long', day: 'numeric' }
  }
});
```

### Localization Best Practices
- Group related translations with consistent prefixes
- Use meaningful key names that describe the content's purpose
- Test localization with different languages and text lengths
- Consider text expansion when designing UI layouts
- Implement fallback mechanisms for missing translations
- Use TypeScript to ensure translation key safety

## Testing

### Test Organization
- Mirror the `src/` structure in `test/` or `__tests__/`
- Write unit tests for controllers and services
- Write integration tests for API endpoints
- Write component tests for UI components
- Use mocking for external dependencies

### Testing Best Practices
- Test business logic in controllers and services
- Mock external services and APIs in tests
- Use test utilities for common setup and teardown
- Test error scenarios and edge cases
- Maintain high test coverage for critical business logic

```typescript
// Example test structure
describe('ApplicationController', () => {
  let controller: ApplicationController;
  let mockApiService: jest.Mocked<ApiService>;
  let mockEventEmitter: jest.Mocked<EventEmitter>;

  beforeEach(() => {
    mockApiService = createMockApiService();
    mockEventEmitter = createMockEventEmitter();
    controller = new ApplicationController(mockApiService, mockEventEmitter);
  });

  describe('createApplication', () => {
    it('should create application successfully with valid request', async () => {
      // Arrange
      const request: CreateApplicationRequest = {
        title: 'Test Application',
        description: 'A test application',
      };
      const expectedApplication: Application = {
        id: 'app-123',
        ...request,
        status: 'pending',
        createdAt: new Date(),
      };
      
      mockApiService.createApplication.mockResolvedValue(expectedApplication);

      // Act
      const result: Application = await controller.createApplication(request);

      // Assert
      expect(result).toEqual(expectedApplication);
      expect(mockApiService.createApplication).toHaveBeenCalledWith(request);
      expect(mockEventEmitter.emit).toHaveBeenCalledWith('applicationCreated', expectedApplication);
    });

    it('should handle validation errors appropriately', async () => {
      // Arrange
      const invalidRequest: CreateApplicationRequest = {
        title: '',
        description: 'A test application',
      };
      
      mockApiService.createApplication.mockRejectedValue(
        new ValidationError('Title is required', 'title')
      );

      // Act & Assert
      await expect(controller.createApplication(invalidRequest))
        .rejects
        .toThrow(ValidationError);
      
      expect(mockEventEmitter.emit).toHaveBeenCalledWith('error', expect.any(String));
    });
  });
});
```

### Testing Tools and Libraries
- Use Jest for unit and integration testing
- Use React Testing Library for component testing
- Use MSW (Mock Service Worker) for API mocking
- Use Supertest for API endpoint testing
- Use Playwright or Cypress for end-to-end testing