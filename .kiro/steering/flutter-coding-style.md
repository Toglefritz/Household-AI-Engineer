# Flutter Coding Standards

## Architecture Pattern: MVC

This project follows a strict MVC (Model-View-Controller) pattern for all screens:

### Route (Entry Point)
- Each screen has a `*_route.dart` file containing a `StatefulWidget`
- The route's `createState()` method returns the corresponding controller
- Routes are responsible only for defining the screen entry point

```dart
class WelcomeRoute extends StatefulWidget {
  const WelcomeRoute({super.key});

  @override
  State<WelcomeRoute> createState() => WelcomeController();
}
```

### Controller (Business Logic)
- Controllers extend `State<RouteWidget>` and handle all business logic
- Controllers manage state and call `setState()` to trigger UI updates
- All event handlers and data manipulation logic belongs in controllers
- Controllers pass themselves to views for access to state and methods

```dart
class WelcomeController extends State<WelcomeRoute> {
  // State variables
  late BrineDevice selectedDevice;

  // Event handlers
  void onDeviceSelected(BrineDevice device) {
    setState(() {
      selectedDevice = device;
    });
  }

  @override
  Widget build(BuildContext context) => WelcomeView(this);
}
```

### View (Presentation)
- Views are `StatelessWidget` classes that handle only UI presentation
- Views receive the controller as a parameter for accessing state and methods
- Views should be "dumb" and purely declarative
- No business logic should exist in view classes

```dart
class WelcomeView extends StatelessWidget {
  const WelcomeView(this.state, {super.key});

  final WelcomeController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI only - no business logic
    );
  }
}
```

## State Management

### Primary Pattern: setState()
- Use `setState()` as the primary state management mechanism
- Controllers call `setState()` to trigger UI rebuilds
- Avoid complex state management solutions (Provider, Bloc, Riverpod, etc.)
- Keep state management simple and predictable

### State Organization
- Declare state variables as instance variables in controllers
- Initialize state in `initState()` when needed
- Use `late` keyword for variables that will be initialized before first use

## Widget Composition

### Avoid Functions Returning Widgets
**❌ Don't do this:**
```dart
Widget _buildHeader() {
  return Container(
    child: Text('Header'),
  );
}
```

**✅ Do this instead:**
```dart
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Header'),
    );
  }
}
```

### Widget Extraction Guidelines
- Extract reusable UI components into separate widget classes
- Place screen-specific widgets in `components/` subdirectories
- Place shared widgets in `lib/components/`
- Prefer composition over inheritance

## Navigation

### Use MaterialApp Navigator
- Use the Navigator provided by MaterialApp
- Avoid named routes in favor of direct route construction
- Use `MaterialPageRoute` for standard transitions

**✅ Preferred navigation pattern:**
```dart
await Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (BuildContext context) => const TargetRoute(),
  ),
);
```

**❌ Avoid named routes:**
```dart
// Don't use this pattern
Navigator.pushNamed(context, '/target');
```

### Navigation Best Practices
- Use `pushReplacement` when the current screen should not be accessible via back button
- Pass data through constructor parameters rather than route arguments
- Handle navigation in controllers, not views

## Code Style

### Type Safety and Strong Typing
- All variables must be explicitly typed, including local variables within function bodies
- Never rely on type inference with `var` or `dynamic` unless absolutely necessary
- Use specific types rather than generic types when possible
- Prefer nullable types (`String?`) over dynamic when null values are expected

**✅ Preferred strong typing:**
```dart
void processApplications() {
  final List<Application> applications = getApplications();
  final Map<String, int> statusCounts = <String, int>{};
  final String defaultStatus = 'pending';
  
  for (final Application app in applications) {
    final String status = app.status ?? defaultStatus;
    final int currentCount = statusCounts[status] ?? 0;
    statusCounts[status] = currentCount + 1;
  }
}
```

**❌ Avoid type inference and dynamic:**
```dart
void processApplications() {
  var applications = getApplications(); // Type unclear
  var statusCounts = {}; // Dynamic map
  var defaultStatus = 'pending'; // Could be inferred as String, but be explicit
  
  for (var app in applications) { // Type unclear
    var status = app.status ?? defaultStatus;
    var currentCount = statusCounts[status] ?? 0;
    statusCounts[status] = currentCount + 1;
  }
}
```

### Strong Typing Guidelines
- Declare the full type for collections: `List<String>`, `Map<String, int>`, `Set<Application>`
- Use explicit types for function parameters and return values
- Type cast with `as` operator when necessary, but prefer strong typing to avoid casts
- Use `late` keyword with explicit types for variables initialized after declaration
- Document complex generic types with meaningful names

### Linting
- Follow `very_good_analysis` linting rules
- Prefer single quotes for strings
- Always declare return types
- Use relative imports for local files
- Avoid lines longer than 80 characters when practical

### Documentation
- Document all public classes and methods
- Use `///` for documentation comments
- Include parameter descriptions for complex methods
- Document business logic and architectural decisions

### Error Handling
- Use specific exception types when possible
- Log errors with `debugPrint()` in debug mode
- Implement proper error boundaries in UI
- Handle async operations with try-catch blocks

## File Organization

### Naming Conventions
- Use snake_case for file names
- Use PascalCase for class names
- Use camelCase for variable and method names
- Suffix controller files with `_controller.dart`
- Suffix view files with `_view.dart`
- Suffix route files with `_route.dart`

### Directory Structure
- Group related files in feature directories
- Place shared components in `lib/components/`
- Place business logic in `lib/services/`
- Keep models in `lib/models/`
- Organize by feature, not by file type

### One Class Per File
- Each file must contain exactly one class or enum, regardless of relationship
- The file name should match the class or enum name in snake_case
- This architecture makes maintenance, testing, and code navigation easier
- Use Dart's `library` directive to group related files into logical units

**✅ Preferred structure for related classes:**
```
lib/services/authentication/models/
├── auth_method.dart         # Contains AuthMethod enum
├── auth_credentials.dart    # Contains AuthCredentials class
└── auth_result.dart         # Contains AuthResult class
```

**✅ Using library directive to group related files:**
```dart
// lib/services/authentication/models/auth_method.dart
library authentication.models;

enum AuthMethod { basicAuth, google, apple }
```

```dart
// lib/services/authentication/models/auth_credentials.dart
library authentication.models;

class AuthCredentials {
  // Implementation
}
```

```dart
// lib/services/authentication/models/auth_result.dart
library authentication.models;

class AuthResult {
  // Implementation
}
```

**✅ Importing a library:**
```dart
// Import individual files as needed
import '../models/auth_method.dart';
import '../models/auth_credentials.dart';
import '../models/auth_result.dart';
```

**❌ Never put multiple classes in one file:**
```dart
// Don't do this - even for related classes
class AuthCredentials { }
class AuthResult { }
enum AuthMethod { basicAuth, google, apple }
```

### File Naming Rules
- Use snake_case for file names
- File name should reflect the primary class/enum it contains
- For related classes, use a descriptive library name
- Avoid generic names like `models.dart` or `utils.dart`

## JSON Handling

### Avoid Code Generation
- Avoid packages like `json_serializable` that generate opaque classes
- Prefer explicit, readable code over generated code
- Keep JSON parsing logic transparent and maintainable

### Use fromJson Factory Constructors
**✅ Preferred pattern:**
```dart
class BrineDevice {
  const BrineDevice({
    required this.id,
    required this.name,
    required this.saltLevel,
    required this.batteryLevel,
  });

  final String id;
  final String name;
  final double saltLevel;
  final double batteryLevel;

  factory BrineDevice.fromJson(Map<String, dynamic> json) {
    return BrineDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      saltLevel: (json['saltLevel'] as num).toDouble(),
      batteryLevel: (json['batteryLevel'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'saltLevel': saltLevel,
      'batteryLevel': batteryLevel,
    };
  }
}
```

### JSON Best Practices
- Always use explicit type casting with `as` operator
- Handle nullable fields appropriately
- Use `toDouble()` for numeric values that should be doubles
- Include both `fromJson` and `toJson` methods for complete serialization
- Validate required fields and throw meaningful errors for missing data
- Document expected JSON structure in class documentation

### Error Handling in JSON Parsing
```dart
factory BrineDevice.fromJson(Map<String, dynamic> json) {
  try {
    return BrineDevice(
      id: json['id'] as String? ?? 
          throw ArgumentError('Missing required field: id'),
      name: json['name'] as String? ?? 
          throw ArgumentError('Missing required field: name'),
      saltLevel: (json['saltLevel'] as num?)?.toDouble() ?? 0.0,
      batteryLevel: (json['batteryLevel'] as num?)?.toDouble() ?? 0.0,
    );
  } catch (e) {
    throw FormatException('Failed to parse BrineDevice from JSON: $e');
  }
}
```

## Testing

### Test Organization
- Mirror the `lib/` structure in `test/`
- Write unit tests for controllers and services
- Write widget tests for complex UI components
- Use mocking for external dependencies

### Testing Best Practices
- Test business logic in controllers
- Mock Firebase services in tests
- Use `fake_http_client` for HTTP mocking
- Test error scenarios and edge cases