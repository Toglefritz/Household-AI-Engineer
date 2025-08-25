/// Accessibility tests for the Flutter dashboard.
///
/// Tests VoiceOver support, keyboard navigation, focus management,
/// and high contrast support to ensure the application is fully
/// accessible to users with disabilities.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/l10n/app_localizations.dart';
import '../../lib/screens/dashboard/components/applications/application_grid.dart';
import '../../lib/screens/dashboard/components/applications/application_tile.dart';
import '../../lib/screens/dashboard/dashboard_view.dart';
import '../../lib/services/user_application/models/application_status.dart';
import '../../lib/services/user_application/models/user_application.dart';
import '../../lib/theme/accessibility_helper.dart';
import '../../lib/theme/app_theme.dart';

import '../test_helpers/mock_dashboard_controller.dart';
import '../test_helpers/test_app_wrapper.dart';

void main() {
  group('Accessibility Tests', () {
    group('Semantic Labels and Hints', () {
      testWidgets('ApplicationTile has proper semantic information', (WidgetTester tester) async {
        // Create a test application
        final UserApplication testApp = UserApplication(
          id: 'test-app-1',
          title: 'Test Application',
          description: 'A test application for accessibility testing',
          status: ApplicationStatus.ready,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Build the widget
        await tester.pumpWidget(
          TestAppWrapper(
            child: ApplicationTile(
              application: testApp,
              onTap: () {},
              onSecondaryTap: () {},
            ),
          ),
        );

        // Find the semantic widget
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsWidgets);

        // Verify semantic properties
        final Semantics semanticsWidget = tester.widget<Semantics>(semanticsFinder.first);
        expect(semanticsWidget.properties.label, contains('Test Application'));
        expect(semanticsWidget.properties.hint, contains('Ready'));
        expect(semanticsWidget.properties.hint, contains('A test application for accessibility testing'));
        expect(semanticsWidget.properties.button, isTrue);
        expect(semanticsWidget.properties.enabled, isTrue);
      });

      testWidgets('ApplicationGrid has proper semantic container', (WidgetTester tester) async {
        // Create test applications
        final List<UserApplication> testApps = [
          UserApplication(
            id: 'test-app-1',
            title: 'Test App 1',
            description: 'First test application',
            status: ApplicationStatus.ready,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          UserApplication(
            id: 'test-app-2',
            title: 'Test App 2',
            description: 'Second test application',
            status: ApplicationStatus.developing,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Build the widget
        await tester.pumpWidget(
          TestAppWrapper(
            child: ApplicationGrid(
              applications: testApps,
              onApplicationTap: (_) {},
              onApplicationSecondaryTap: (_, __) {},
            ),
          ),
        );

        // Find semantic containers
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsWidgets);

        // Verify grid semantic container exists
        bool foundGridSemantics = false;
        for (final Element element in semanticsFinder.evaluate()) {
          final Semantics semantics = element.widget as Semantics;
          if (semantics.properties.label?.contains('Application grid') == true) {
            foundGridSemantics = true;
            expect(semantics.properties.hint, contains('2 applications'));
            break;
          }
        }
        expect(foundGridSemantics, isTrue);
      });

      testWidgets('Empty state has proper accessibility labels', (WidgetTester tester) async {
        // Build the widget with empty applications list
        await tester.pumpWidget(
          TestAppWrapper(
            child: ApplicationGrid(
              applications: const [],
              onCreateNewApplication: () {},
            ),
          ),
        );

        // Find semantic widgets
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsWidgets);

        // Verify empty state semantics
        bool foundEmptyStateSemantics = false;
        bool foundCreateButtonSemantics = false;

        for (final Element element in semanticsFinder.evaluate()) {
          final Semantics semantics = element.widget as Semantics;

          if (semantics.properties.label?.contains('No applications') == true) {
            foundEmptyStateSemantics = true;
            expect(semantics.properties.hint, contains('haven\'t created any applications yet'));
          }

          if (semantics.properties.label?.contains('Create new application') == true) {
            foundCreateButtonSemantics = true;
            expect(semantics.properties.button, isTrue);
          }
        }

        expect(foundEmptyStateSemantics, isTrue);
        expect(foundCreateButtonSemantics, isTrue);
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('ApplicationGrid supports arrow key navigation', (WidgetTester tester) async {
        // Create test applications in a 2x2 grid
        final List<UserApplication> testApps = List.generate(
          4,
          (index) => UserApplication(
            id: 'test-app-$index',
            title: 'Test App $index',
            description: 'Test application $index',
            status: ApplicationStatus.ready,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Build the widget
        await tester.pumpWidget(
          TestAppWrapper(
            child: SizedBox(
              width: 600, // Ensure 2 columns
              height: 400,
              child: ApplicationGrid(
                applications: testApps,
                onApplicationTap: (_) {},
                onApplicationSecondaryTap: (_, __) {},
              ),
            ),
          ),
        );

        // Find the grid widget
        final Finder gridFinder = find.byType(ApplicationGrid);
        expect(gridFinder, findsOneWidget);

        // Focus the grid
        await tester.tap(gridFinder);
        await tester.pumpAndSettle();

        // Test right arrow navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        // Test down arrow navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        // Test left arrow navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        // Test up arrow navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        // Verify no exceptions were thrown during navigation
        expect(tester.takeException(), isNull);
      });

      testWidgets('ApplicationTile responds to Enter and Space keys', (WidgetTester tester) async {
        bool tapCalled = false;
        bool secondaryTapCalled = false;

        final UserApplication testApp = UserApplication(
          id: 'test-app-1',
          title: 'Test Application',
          description: 'A test application',
          status: ApplicationStatus.ready,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Build the widget
        await tester.pumpWidget(
          TestAppWrapper(
            child: ApplicationTile(
              application: testApp,
              onTap: () => tapCalled = true,
              onSecondaryTap: () => secondaryTapCalled = true,
            ),
          ),
        );

        // Find and focus the tile
        final Finder tileFinder = find.byType(ApplicationTile);
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        // Test Enter key
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(tapCalled, isTrue);

        // Reset and test Space key
        tapCalled = false;
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(tapCalled, isTrue);

        // Test context menu key
        await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
        await tester.pumpAndSettle();
        expect(secondaryTapCalled, isTrue);
      });

      testWidgets('Focus traversal order is correct', (WidgetTester tester) async {
        final List<UserApplication> testApps = List.generate(
          3,
          (index) => UserApplication(
            id: 'test-app-$index',
            title: 'Test App $index',
            description: 'Test application $index',
            status: ApplicationStatus.ready,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Build the widget
        await tester.pumpWidget(
          TestAppWrapper(
            child: ApplicationGrid(
              applications: testApps,
              onApplicationTap: (_) {},
            ),
          ),
        );

        // Find focus traversal order widgets
        final Finder traversalOrderFinder = find.byType(FocusTraversalOrder);
        expect(traversalOrderFinder, findsWidgets);

        // Verify traversal order widgets exist for each application
        expect(traversalOrderFinder.evaluate().length, equals(testApps.length));
      });
    });

    group('High Contrast Support', () {
      testWidgets('High contrast theme is applied correctly', (WidgetTester tester) async {
        // Build app with high contrast media query
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              highContrast: true,
              textScaler: TextScaler.linear(1.0),
            ),
            child: MaterialApp(
              theme: AppTheme.highContrastLightThemeData,
              home: const Scaffold(
                body: Text('High Contrast Test'),
              ),
            ),
          ),
        );

        // Verify high contrast theme is applied
        final BuildContext context = tester.element(find.byType(MaterialApp));
        final ThemeData theme = Theme.of(context);

        // Check that high contrast colors are being used
        expect(theme.colorScheme.primary, equals(const Color(0xFF0000FF)));
        expect(theme.colorScheme.surface, equals(const Color(0xFFFFFFFF)));
        expect(theme.colorScheme.onSurface, equals(const Color(0xFF000000)));
      });

      testWidgets('AccessibilityHelper detects high contrast mode', (WidgetTester tester) async {
        // Build widget with high contrast media query
        bool isHighContrast = false;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              highContrast: true,
              textScaler: TextScaler.linear(1.0),
            ),
            child: MaterialApp(
              home: Builder(
                builder: (BuildContext context) {
                  isHighContrast = AccessibilityHelper.isHighContrastEnabled(context);
                  return const Scaffold(body: Text('Test'));
                },
              ),
            ),
          ),
        );

        expect(isHighContrast, isTrue);
      });
    });

    group('Large Text Support', () {
      testWidgets('Large text is detected correctly', (WidgetTester tester) async {
        bool isLargeText = false;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5), // Large text scale
            ),
            child: MaterialApp(
              home: Builder(
                builder: (BuildContext context) {
                  isLargeText = AccessibilityHelper.isLargeTextEnabled(context);
                  return const Scaffold(body: Text('Test'));
                },
              ),
            ),
          ),
        );

        expect(isLargeText, isTrue);
      });

      testWidgets('Text scale factor is retrieved correctly', (WidgetTester tester) async {
        double textScaleFactor = 1.0;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              home: Builder(
                builder: (BuildContext context) {
                  textScaleFactor = AccessibilityHelper.getTextScaleFactor(context);
                  return const Scaffold(body: Text('Test'));
                },
              ),
            ),
          ),
        );

        expect(textScaleFactor, equals(1.3));
      });

      testWidgets('Accessible text theme scales properly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5), // Large text
            ),
            child: MaterialApp(
              theme: AppTheme.lightThemeData,
              home: Builder(
                builder: (BuildContext context) {
                  final TextTheme accessibleTheme = AppTheme.getAccessibleTextTheme(
                    context,
                    Theme.of(context),
                  );

                  // Verify text theme has been scaled
                  expect(accessibleTheme.bodyLarge?.height, greaterThan(1.4));
                  expect(accessibleTheme.headlineSmall?.height, greaterThan(1.2));

                  return const Scaffold(body: Text('Test'));
                },
              ),
            ),
          ),
        );
      });
    });

    group('Screen Reader Support', () {
      testWidgets('Semantic announcements work correctly', (WidgetTester tester) async {
        // This test verifies that the announcement method doesn't throw errors
        // Actual screen reader testing requires integration testing on real devices

        await tester.pumpWidget(
          const TestAppWrapper(
            child: Scaffold(body: Text('Test')),
          ),
        );

        final BuildContext context = tester.element(find.byType(Scaffold));

        // Test that announcement doesn't throw
        expect(
          () => AccessibilityHelper.announceToScreenReader('Test announcement', context),
          returnsNormally,
        );

        // Test empty message handling
        expect(
          () => AccessibilityHelper.announceToScreenReader('', context),
          returnsNormally,
        );
      });

      testWidgets('Semantic headers are properly marked', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestAppWrapper(
            child: AccessibilityHelper.createSemanticHeader(
              level: 2,
              child: const Text('Test Header'),
            ),
          ),
        );

        // Find the semantic header
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsOneWidget);

        final Semantics semanticsWidget = tester.widget<Semantics>(semanticsFinder);
        expect(semanticsWidget.properties.header, isTrue);
        expect(semanticsWidget.properties.sortKey, isA<OrdinalSortKey>());
      });

      testWidgets('Decorative elements are excluded from focus', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestAppWrapper(
            child: AccessibilityHelper.excludeFromFocus(
              const Icon(Icons.star),
            ),
          ),
        );

        // Find the ExcludeFromSemantics widget
        final Finder excludeFinder = find.byType(ExcludeFromSemantics);
        expect(excludeFinder, findsOneWidget);
      });
    });

    group('Focus Management', () {
      testWidgets('Focus can be requested and managed', (WidgetTester tester) async {
        final FocusNode testFocusNode = FocusNode();

        await tester.pumpWidget(
          TestAppWrapper(
            child: Focus(
              focusNode: testFocusNode,
              child: const TextField(),
            ),
          ),
        );

        // Test focus request
        AccessibilityHelper.requestFocus(testFocusNode);
        await tester.pumpAndSettle();

        expect(testFocusNode.hasFocus, isTrue);

        // Test unfocus
        final BuildContext context = tester.element(find.byType(TextField));
        AccessibilityHelper.unfocus(context);
        await tester.pumpAndSettle();

        expect(testFocusNode.hasFocus, isFalse);

        testFocusNode.dispose();
      });

      testWidgets('Focus navigation works correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestAppWrapper(
            child: Column(
              children: [
                const TextField(decoration: InputDecoration(hintText: 'First')),
                const TextField(decoration: InputDecoration(hintText: 'Second')),
                ElevatedButton(onPressed: () {}, child: const Text('Button')),
              ],
            ),
          ),
        );

        // Focus first field
        await tester.tap(find.byType(TextField).first);
        await tester.pumpAndSettle();

        // Test focus next
        final BuildContext context = tester.element(find.byType(TextField).first);
        AccessibilityHelper.focusNext(context);
        await tester.pumpAndSettle();

        // Test focus previous
        AccessibilityHelper.focusPrevious(context);
        await tester.pumpAndSettle();

        // Verify no exceptions were thrown
        expect(tester.takeException(), isNull);
      });
    });

    group('Accessible Widget Helpers', () {
      testWidgets('Accessible button is created correctly', (WidgetTester tester) async {
        bool buttonPressed = false;

        await tester.pumpWidget(
          TestAppWrapper(
            child: AccessibilityHelper.createAccessibleButton(
              label: 'Test Button',
              hint: 'Press to test',
              onPressed: () => buttonPressed = true,
              child: const Text('Button'),
            ),
          ),
        );

        // Find the semantic button
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsWidgets);

        // Verify button properties
        bool foundButtonSemantics = false;
        for (final Element element in semanticsFinder.evaluate()) {
          final Semantics semantics = element.widget as Semantics;
          if (semantics.properties.button == true) {
            foundButtonSemantics = true;
            expect(semantics.properties.label, equals('Test Button'));
            expect(semantics.properties.hint, equals('Press to test'));
            expect(semantics.properties.enabled, isTrue);
            break;
          }
        }
        expect(foundButtonSemantics, isTrue);

        // Test button tap
        await tester.tap(find.text('Button'));
        expect(buttonPressed, isTrue);
      });

      testWidgets('Accessible text field is created correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestAppWrapper(
            child: AccessibilityHelper.createAccessibleTextField(
              label: 'Test Field',
              hint: 'Enter text here',
              child: const TextField(),
            ),
          ),
        );

        // Find the semantic text field
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsWidgets);

        // Verify text field properties
        bool foundTextFieldSemantics = false;
        for (final Element element in semanticsFinder.evaluate()) {
          final Semantics semantics = element.widget as Semantics;
          if (semantics.properties.textField == true) {
            foundTextFieldSemantics = true;
            expect(semantics.properties.label, equals('Test Field'));
            expect(semantics.properties.hint, equals('Enter text here'));
            expect(semantics.properties.enabled, isTrue);
            break;
          }
        }
        expect(foundTextFieldSemantics, isTrue);
      });

      testWidgets('Semantic containers are created correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestAppWrapper(
            child: AccessibilityHelper.createSemanticContainer(
              label: 'Test Container',
              hint: 'Contains test content',
              child: const Text('Content'),
            ),
          ),
        );

        // Find the semantic container
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsOneWidget);

        final Semantics semanticsWidget = tester.widget<Semantics>(semanticsFinder);
        expect(semanticsWidget.properties.container, isTrue);
        expect(semanticsWidget.properties.label, equals('Test Container'));
        expect(semanticsWidget.properties.hint, equals('Contains test content'));
      });
    });
  });
}
