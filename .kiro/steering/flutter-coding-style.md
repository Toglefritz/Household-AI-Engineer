# Flutter Coding Style Guide

## Purpose

These rules guide development agents in building and editing Flutter applications using a consistent, scalable, and maintainable structure for the Household Software Engineer project. The guidelines are inspired by clean architecture principles and practical Flutter development experience.

## Documentation Philosophy

All code should be documented with the assumption that another developer will continue the work. Excellent documentation ensures knowledge transfer, supports scalability, and reduces onboarding time.

**Documentation Requirements:**
- Every feature should include inline comments for complex logic
- Usage examples should be provided when helpful
- Each feature folder should include README-style explanations when appropriate
- Public APIs, classes, and methods must use Dartdoc comments
- Keep documentation updated alongside code changes

## Flexibility Notice

This is a recommended project structure, but be flexible and adapt to existing project structures. Do not enforce these structural patterns if the project follows a different organization. Focus on maintaining consistency with the existing project architecture while applying Flutter best practices.

## Flutter Best Practices

When working on the Flutter dashboard, follow these core principles:

1. **Adapt to existing project architecture** while maintaining clean code principles
2. **Use Flutter 3.x features** and Material 3 design system
3. **Use MVC-inspired architecture** where controllers manage state for the view
4. **Follow proper state management** principles with Provider or similar
5. **Use proper dependency injection** with GetIt or similar service locator
6. **Implement comprehensive error handling** with Either types or similar patterns
7. **Follow macOS platform-specific** design guidelines for native feel
8. **Use proper localization techniques** for future internationalization support

## Project Structure Reference

Adapt this structure to the existing project organization:

```
lib/
├── main.dart
├── app.dart
├── components/
│   ├── buttons/
│   │   └── primary_button.dart
│   ├── loaders/
│   │   └── spinner.dart
│   ├── layout/
│   │   └── responsive_container.dart
│   └── tiles/
│       └── application_tile.dart
├── extensions/
│   ├── context_extensions.dart
│   └── string_extensions.dart
├── models/
│   ├── application.dart
│   ├── conversation.dart
│   └── progress.dart
├── screens/
│   ├── dashboard/
│   │   ├── dashboard_view.dart
│   │   ├── dashboard_controller.dart
│   │   └── dashboard_route.dart
│   ├── conversation/
│   │   ├── conversation_view.dart
│   │   ├── conversation_controller.dart
│   │   └── conversation_route.dart
│   └── progress/
│       ├── progress_view.dart
│       ├── progress_controller.dart
│       └── progress_route.dart
├── services/
│   ├── api_service.dart
│   ├── websocket_service.dart
│   └── launch_service.dart
├── providers/
│   ├── app_state_provider.dart
│   ├── ui_state_provider.dart
│   └── conversation_provider.dart
├── theme/
│   ├── app_theme.dart
│   ├── color_palette.dart
│   └── spacing.dart
└── values/
    ├── strings.dart
    ├── assets.dart
    └── constants.dart
```

## Coding Guidelines

### 1. Null Safety and Error Handling
```dart
// Good: Proper null safety with error handling
Future<Either<AppError, List<Application>>> fetchApplications() async {
  try {
    final response = await apiService.getApplications();
    return Right(response.map((json) => Application.fromJson(json)).toList());
  } catch (e) {
    return Left(AppError.networkError(e.toString()));
  }
}

// Good: Null-aware operators
final title = application?.title ?? 'Untitled Application';
```

### 2. Widget Composition and Performance
```dart
// Good: Small, focused widgets with const constructors
class ApplicationTile extends StatelessWidget {
  const ApplicationTile({
    Key? key,
    required this.application,
    this.onTap,
  }) : super(key: key);

  final Application application;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: _buildTileContent(),
      ),
    );
  }

  Widget _buildTileContent() {
    // Extract complex widget building to separate methods
    return Column(
      children: [
        _buildHeader(),
        _buildStatus(),
        _buildActions(),
      ],
    );
  }
}
```

### 3. State Management with Controllers
```dart
// Good: MVC-style controller managing state
class DashboardController extends ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _webSocketService;

  DashboardController(this._apiService, this._webSocketService);

  List<Application> _applications = [];
  bool _isLoading = false;
  String? _error;

  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches applications from the backend
  Future<void> loadApplications() async {
    _setLoading(true);
    
    final result = await _apiService.getApplications();
    result.fold(
      (error) => _setError(error.message),
      (apps) => _setApplications(apps),
    );
    
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setApplications(List<Application> apps) {
    _applications = apps;
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}
```

### 4. Proper Routing with GoRouter
```dart
// Good: Declarative routing configuration
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: '/conversation',
      builder: (context, state) => const ConversationView(),
    ),
    GoRoute(
      path: '/progress/:appId',
      builder: (context, state) => ProgressView(
        appId: state.params['appId']!,
      ),
    ),
  ],
);
```

## Widget Guidelines

### 1. Widget Structure
- Keep widgets small and focused on a single responsibility
- Use const constructors whenever possible for performance
- Implement proper widget keys for complex lists and animations
- Extract complex build logic into separate methods
- Use proper widget lifecycle methods (initState, dispose, etc.)

### 2. Layout and Responsiveness
```dart
// Good: Responsive layout with proper constraints
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({Key? key, required this.children}) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 400) return 2;
    return 1;
  }
}
```

### 3. Error Boundaries and Loading States
```dart
// Good: Proper error handling in widgets
class ApplicationGrid extends StatelessWidget {
  const ApplicationGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null) {
          return ErrorWidget(
            error: controller.error!,
            onRetry: controller.loadApplications,
          );
        }

        if (controller.applications.isEmpty) {
          return const EmptyStateWidget();
        }

        return ResponsiveGrid(
          children: controller.applications
              .map((app) => ApplicationTile(application: app))
              .toList(),
        );
      },
    );
  }
}
```

## Performance Guidelines

### 1. List Optimization
```dart
// Good: Efficient list building with proper keys
ListView.builder(
  itemCount: applications.length,
  itemBuilder: (context, index) {
    final app = applications[index];
    return ApplicationTile(
      key: ValueKey(app.id), // Proper key for performance
      application: app,
    );
  },
)
```

### 2. Image and Asset Management
```dart
// Good: Proper image caching and optimization
class OptimizedImage extends StatelessWidget {
  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
  }) : super(key: key);

  final String imageUrl;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      placeholder: (context, url) => const ShimmerPlaceholder(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }
}
```

## Testing Guidelines

### 1. Unit Tests for Business Logic
```dart
// Good: Comprehensive unit tests for controllers
void main() {
  group('DashboardController', () {
    late DashboardController controller;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      controller = DashboardController(mockApiService);
    });

    test('should load applications successfully', () async {
      // Arrange
      final apps = [Application(id: '1', title: 'Test App')];
      when(mockApiService.getApplications())
          .thenAnswer((_) async => Right(apps));

      // Act
      await controller.loadApplications();

      // Assert
      expect(controller.applications, equals(apps));
      expect(controller.isLoading, false);
      expect(controller.error, null);
    });
  });
}
```

### 2. Widget Tests for UI Components
```dart
// Good: Widget tests with proper setup
void main() {
  group('ApplicationTile', () {
    testWidgets('should display application title and status', (tester) async {
      // Arrange
      final app = Application(
        id: '1',
        title: 'Test App',
        status: ApplicationStatus.ready,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ApplicationTile(application: app),
        ),
      );

      // Assert
      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
    });
  });
}
```

## macOS Platform Integration

### 1. Native Window Behavior
```dart
// Good: macOS-specific window configuration
class MacOSWindowConfig {
  static void configureWindow() {
    if (Platform.isMacOS) {
      // Configure native macOS window behavior
      windowManager.setTitle('Household Software Engineer');
      windowManager.setMinimumSize(const Size(800, 600));
      windowManager.setMaximizable(true);
    }
  }
}
```

### 2. Platform-Specific UI Elements
```dart
// Good: Platform-adaptive UI components
Widget buildPlatformButton({
  required String text,
  required VoidCallback onPressed,
}) {
  if (Platform.isMacOS) {
    return CupertinoButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
  return ElevatedButton(
    onPressed: onPressed,
    child: Text(text),
  );
}
```

## Documentation Standards

### 1. Class and Method Documentation
```dart
/// A tile widget that displays application information and status.
/// 
/// This widget shows the application title, description, current status,
/// and provides interaction capabilities for launching or managing the app.
/// 
/// Example usage:
/// ```dart
/// ApplicationTile(
///   application: myApp,
///   onTap: () => launchApplication(myApp),
/// )
/// ```
class ApplicationTile extends StatelessWidget {
  /// Creates an application tile.
  /// 
  /// The [application] parameter is required and contains the app data to display.
  /// The [onTap] callback is optional and will be called when the tile is tapped.
  const ApplicationTile({
    Key? key,
    required this.application,
    this.onTap,
  }) : super(key: key);

  /// The application data to display in this tile.
  final Application application;

  /// Callback function called when the tile is tapped.
  /// 
  /// Typically used to launch the application or show details.
  final VoidCallback? onTap;
}
```

### 2. Complex Logic Comments
```dart
// Calculate the optimal number of columns based on available width
// This ensures tiles maintain a minimum width while maximizing screen usage
int _calculateCrossAxisCount(double width) {
  const double minTileWidth = 200.0;
  const double spacing = 16.0;
  
  // Account for spacing between tiles when calculating columns
  final availableWidth = width - (spacing * 2);
  final maxColumns = (availableWidth / (minTileWidth + spacing)).floor();
  
  // Ensure at least one column is always shown
  return math.max(1, maxColumns);
}
```

This steering document will guide all Flutter development work to maintain consistency, quality, and adherence to best practices throughout the project.