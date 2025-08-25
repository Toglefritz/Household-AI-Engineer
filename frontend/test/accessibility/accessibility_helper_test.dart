/// Tests for the AccessibilityHelper utility class.
///
/// Verifies that accessibility helper functions work correctly
/// and provide proper semantic information for screen readers.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/theme/accessibility_helper.dart';

void main() {
  group('AccessibilityHelper Tests', () {
    group('High Contrast Detection', () {
      testWidgets('detects high contrast mode correctly', (WidgetTester tester) async {
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

      testWidgets('detects normal contrast mode correctly', (WidgetTester tester) async {
        bool isHighContrast = true; // Start with true to verify it changes

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              highContrast: false,
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

        expect(isHighContrast, isFalse);
      });
    });

    group('Large Text Detection', () {
      testWidgets('detects large text correctly', (WidgetTester tester) async {
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

      testWidgets('detects normal text correctly', (WidgetTester tester) async {
        bool isLargeText = true; // Start with true to verify it changes

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.0), // Normal text scale
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

        expect(isLargeText, isFalse);
      });

      testWidgets('gets text scale factor correctly', (WidgetTester tester) async {
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
    });

    group('Semantic Widget Creation', () {
      testWidgets('creates semantic widget with proper properties', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibilityHelper.createSemanticWidget(
                label: 'Test Widget',
                hint: 'This is a test widget',
                button: true,
                enabled: true,
                selected: false,
                child: const Text('Test'),
              ),
            ),
          ),
        );

        // Find the semantic widget
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsOneWidget);

        final Semantics semanticsWidget = tester.widget<Semantics>(semanticsFinder);
        expect(semanticsWidget.properties.label, equals('Test Widget'));
        expect(semanticsWidget.properties.hint, equals('This is a test widget'));
        expect(semanticsWidget.properties.button, isTrue);
        expect(semanticsWidget.properties.enabled, isTrue);
        expect(semanticsWidget.properties.selected, isFalse);
      });

      testWidgets('creates semantic container correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibilityHelper.createSemanticContainer(
                label: 'Test Container',
                hint: 'Contains test content',
                child: const Text('Content'),
              ),
            ),
          ),
        );

        // Find the semantic container
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsOneWidget);

        final Semantics semanticsWidget = tester.widget<Semantics>(semanticsFinder);
        expect(semanticsWidget.properties.label, equals('Test Container'));
        expect(semanticsWidget.properties.hint, equals('Contains test content'));
      });

      testWidgets('creates semantic header correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibilityHelper.createSemanticHeader(
                level: 2,
                child: const Text('Test Header'),
              ),
            ),
          ),
        );

        // Find the semantic header
        final Finder semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsOneWidget);

        final Semantics semanticsWidget = tester.widget<Semantics>(semanticsFinder);
        expect(semanticsWidget.properties.header, isTrue);
        expect(semanticsWidget.properties.sortKey, isNotNull);
      });

      testWidgets('excludes widgets from focus correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibilityHelper.excludeFromFocus(
                const Icon(Icons.star),
              ),
            ),
          ),
        );

        // Find the ExcludeFromSemantics widget
        final Finder excludeFinder = find.byType(ExcludeSemantics);
        expect(excludeFinder, findsOneWidget);
      });
    });

    group('Focus Management', () {
      testWidgets('focus can be requested and managed', (WidgetTester tester) async {
        final FocusNode testFocusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Focus(
                focusNode: testFocusNode,
                child: const TextField(),
              ),
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

      testWidgets('focus navigation works correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const TextField(decoration: InputDecoration(hintText: 'First')),
                  const TextField(decoration: InputDecoration(hintText: 'Second')),
                  ElevatedButton(onPressed: () {}, child: const Text('Button')),
                ],
              ),
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

      testWidgets('creates focus traversal order correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibilityHelper.createFocusTraversalOrder(
                order: 1.0,
                child: const TextField(),
              ),
            ),
          ),
        );

        // Find the focus traversal order widget
        final Finder traversalFinder = find.byType(FocusTraversalOrder);
        expect(traversalFinder, findsOneWidget);

        final FocusTraversalOrder traversalWidget = tester.widget<FocusTraversalOrder>(traversalFinder);
        expect(traversalWidget.order, isA<NumericFocusOrder>());
      });
    });

    group('Accessible Widget Helpers', () {
      testWidgets('creates accessible button correctly', (WidgetTester tester) async {
        bool buttonPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibilityHelper.createAccessibleButton(
                label: 'Test Button',
                hint: 'Press to test',
                onPressed: () => buttonPressed = true,
                child: const Text('Button'),
              ),
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

      testWidgets('creates accessible text field correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibilityHelper.createAccessibleTextField(
                label: 'Test Field',
                hint: 'Enter text here',
                child: const TextField(),
              ),
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
    });

    group('Grid Navigation', () {
      testWidgets('handles grid key navigation correctly', (WidgetTester tester) async {
        int currentIndex = 0;
        int newIndex = 0;

        // Simulate arrow right navigation in a 2x2 grid
        final bool handled = AccessibilityHelper.handleGridKeyNavigation(
          event: const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowRight,
            logicalKey: LogicalKeyboardKey.arrowRight,
            character: null,
            timeStamp: Duration.zero,
          ),
          currentIndex: currentIndex,
          itemCount: 4,
          crossAxisCount: 2,
          onIndexChanged: (int index) => newIndex = index,
        );

        expect(handled, isTrue);
        expect(newIndex, equals(1)); // Should move from 0 to 1
      });

      testWidgets('handles grid boundary conditions correctly', (WidgetTester tester) async {
        int currentIndex = 1; // Right edge of first row
        int newIndex = 1;

        // Try to move right from right edge - should not move
        final bool handled = AccessibilityHelper.handleGridKeyNavigation(
          event: const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowRight,
            logicalKey: LogicalKeyboardKey.arrowRight,
            character: null,
            timeStamp: Duration.zero,
          ),
          currentIndex: currentIndex,
          itemCount: 4,
          crossAxisCount: 2,
          onIndexChanged: (int index) => newIndex = index,
        );

        expect(handled, isFalse);
        expect(newIndex, equals(1)); // Should not change
      });
    });

    group('Screen Reader Support', () {
      testWidgets('announcement method works without errors', (WidgetTester tester) async {
        // This test verifies that the announcement method doesn't throw errors
        // Actual screen reader testing requires integration testing on real devices

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('Test')),
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
    });
  });
}
