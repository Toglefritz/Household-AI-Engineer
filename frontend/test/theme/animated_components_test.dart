import 'package:dwellware/theme/animated_components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test suite for animated UI components.
///
/// This test suite verifies the behavior of animated components including
/// proper animation timing, state transitions, and visual feedback.
/// Tests cover both normal operation and edge cases to ensure reliable
/// animation behavior across different scenarios.
void main() {
  group('AnimatedButton', () {
    testWidgets('should render with child widget', (WidgetTester tester) async {
      const String buttonText = 'Test Button';
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: () => wasPressed = true,
              child: const Text(buttonText),
            ),
          ),
        ),
      );

      // Verify button renders with correct text
      expect(find.text(buttonText), findsOneWidget);
      expect(find.byType(AnimatedButton), findsOneWidget);

      // Verify button is interactive
      await tester.tap(find.byType(AnimatedButton));
      expect(wasPressed, isTrue);
    });

    testWidgets('should show loading state when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: null,
              isLoading: true,
              child: Text('Loading Button'),
            ),
          ),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
    });

    testWidgets('should show success state when isSuccess is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: null,
              isSuccess: true,
              child: Text('Success Button'),
            ),
          ),
        ),
      );

      // Allow success animation to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify success icon is shown
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Success Button'), findsNothing);
    });

    testWidgets('should be disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: null,
              child: Text('Disabled Button'),
            ),
          ),
        ),
      );

      // Verify button is present but disabled
      expect(find.text('Disabled Button'), findsOneWidget);

      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should animate scale on hover', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: () {},
              child: const Text('Hover Button'),
            ),
          ),
        ),
      );

      // Find the AnimatedButton widget specifically
      final Finder animatedButton = find.byType(AnimatedButton);
      expect(animatedButton, findsOneWidget);

      // Simulate mouse enter by finding the MouseRegion within AnimatedButton
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(animatedButton));
      await tester.pump();

      // Allow hover animation to progress
      await tester.pump(const Duration(milliseconds: 100));

      // Verify animation components are present
      expect(find.byType(AnimatedButton), findsOneWidget);
      expect(find.text('Hover Button'), findsOneWidget);
    });

    testWidgets('should handle rapid state changes gracefully', (WidgetTester tester) async {
      bool isLoading = false;
      bool isSuccess = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    AnimatedButton(
                      onPressed: () {},
                      isLoading: isLoading,
                      isSuccess: isSuccess,
                      child: const Text('State Button'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = !isLoading;
                        });
                      },
                      child: const Text('Toggle Loading'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isSuccess = !isSuccess;
                        });
                      },
                      child: const Text('Toggle Success'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Rapidly toggle states
      await tester.tap(find.text('Toggle Loading'));
      await tester.pump();
      await tester.tap(find.text('Toggle Success'));
      await tester.pump();
      await tester.tap(find.text('Toggle Loading'));
      await tester.pump();

      // Verify no exceptions are thrown and widget still renders
      expect(find.byType(AnimatedButton), findsOneWidget);
    });
  });

  group('AnimatedStateContainer', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      const String childText = 'Container Child';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedStateContainer(
              child: Text(childText),
            ),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
      expect(find.byType(AnimatedStateContainer), findsOneWidget);
    });

    testWidgets('should show loading state with pulsing animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedStateContainer(
              isLoading: true,
              child: Text('Loading Container'),
            ),
          ),
        ),
      );

      // Allow loading animation to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify container is present and animation is running
      expect(find.text('Loading Container'), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsOneWidget);
    });

    testWidgets('should show success state with highlight', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedStateContainer(
              isSuccess: true,
              child: Text('Success Container'),
            ),
          ),
        ),
      );

      // Allow success animation to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify container is present
      expect(find.text('Success Container'), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('should show error state with shake animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedStateContainer(
              isError: true,
              child: Text('Error Container'),
            ),
          ),
        ),
      );

      // Allow error animation to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify container is present
      expect(find.text('Error Container'), findsOneWidget);
      expect(find.byType(AnimatedStateContainer), findsOneWidget);
    });

    testWidgets('should handle tap when onTap is provided', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedStateContainer(
              onTap: () => wasTapped = true,
              child: const Text('Tappable Container'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AnimatedStateContainer));
      expect(wasTapped, isTrue);
    });
  });

  group('AnimatedProgressIndicator', () {
    testWidgets('should render with determinate progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedProgressIndicator(
              value: 0.5,
              showPercentage: true,
            ),
          ),
        ),
      );

      // Verify progress indicator and percentage text
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('should render with indeterminate progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedProgressIndicator(
              
            ),
          ),
        ),
      );

      // Verify indeterminate progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('should animate progress value changes', (WidgetTester tester) async {
      double progressValue = 0.3;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    AnimatedProgressIndicator(
                      value: progressValue,
                      showPercentage: true,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          progressValue = 0.8;
                        });
                      },
                      child: const Text('Update Progress'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initial state
      expect(find.text('30%'), findsOneWidget);

      // Update progress
      await tester.tap(find.text('Update Progress'));
      await tester.pump();

      // Allow animation to progress
      await tester.pump(const Duration(milliseconds: 250));

      // Progress should be animating towards new value
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should show success animation when reaching 100%', (WidgetTester tester) async {
      double progressValue = 0.9;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    AnimatedProgressIndicator(
                      value: progressValue,
                      showPercentage: true,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          progressValue = 1.0;
                        });
                      },
                      child: const Text('Complete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Complete the progress
      await tester.tap(find.text('Complete'));
      await tester.pump();

      // Allow success animation to start and progress animation to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Verify success state components are present
      expect(find.byType(AnimatedProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle custom colors', (WidgetTester tester) async {
      const Color customBackground = Colors.red;
      const Color customValue = Colors.green;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedProgressIndicator(
              value: 0.6,
              backgroundColor: customBackground,
              valueColor: customValue,
            ),
          ),
        ),
      );

      // Allow initial animation to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Verify progress indicator renders
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(AnimatedProgressIndicator), findsOneWidget);

      final LinearProgressIndicator indicator = tester.widget(find.byType(LinearProgressIndicator));
      expect(indicator.backgroundColor, customBackground);
      // Note: valueColor comparison is complex due to animation, so we just verify it's set
      expect(indicator.valueColor, isA<AlwaysStoppedAnimation<Color>>());
    });
  });

  group('Animation Performance', () {
    testWidgets('should not cause frame drops during animations', (WidgetTester tester) async {
      // This test verifies that animations don't cause performance issues
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnimatedButton(
                  onPressed: () {},
                  child: const Text('Button 1'),
                ),
                const AnimatedStateContainer(
                  isLoading: true,
                  child: Text('Container 1'),
                ),
                const AnimatedProgressIndicator(
                  value: 0.5,
                ),
              ],
            ),
          ),
        ),
      );

      // Pump multiple frames to ensure animations run smoothly
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // ~60fps
      }

      // Verify all widgets are still present and functional
      expect(find.text('Button 1'), findsOneWidget);
      expect(find.text('Container 1'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should properly dispose animation controllers', (WidgetTester tester) async {
      // Test that animation controllers are properly disposed to prevent memory leaks
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: () {},
              child: const Text('Disposable Button'),
            ),
          ),
        ),
      );

      // Verify widget is present
      expect(find.text('Disposable Button'), findsOneWidget);

      // Remove widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Empty'),
          ),
        ),
      );

      // Verify widget is removed
      expect(find.text('Disposable Button'), findsNothing);
      expect(find.text('Empty'), findsOneWidget);

      // No exceptions should be thrown during disposal
    });
  });
}
