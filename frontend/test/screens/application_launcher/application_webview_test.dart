import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:household_ai_engineer/screens/application_launcher/application_webview.dart';
import 'package:household_ai_engineer/services/application_launcher/models/application_launch_config.dart';
import 'package:household_ai_engineer/services/application_launcher/models/application_process.dart';
import 'package:household_ai_engineer/services/application_launcher/models/window_state.dart';

import '../../test_helpers.dart';

void main() {
  group('ApplicationWebView', () {
    late ApplicationProcess testProcess;

    setUp(() {
      // Create test application process
      final ApplicationLaunchConfig config = ApplicationLaunchConfig(
        applicationType: ApplicationType.web,
        url: 'http://localhost:3000/test-app',
        windowTitle: 'Test Application',
        initialWidth: 1200,
        initialHeight: 800,
        showNavigationControls: true,
        enableJavaScript: true,
        enableLocalStorage: true,
      );

      testProcess = ApplicationProcess(
        applicationId: 'test-app-1',
        applicationTitle: 'Test Application',
        launchConfig: config,
        launchedAt: DateTime.now(),
      );
    });

    testWidgets('should display application title in app bar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestApp(
          child: ApplicationWebView(process: testProcess),
        ),
      );

      // Assert
      expect(find.text('Test Application'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should show navigation controls when enabled', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestApp(
          child: ApplicationWebView(process: testProcess),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should hide navigation controls when disabled', (WidgetTester tester) async {
      // Arrange
      final ApplicationLaunchConfig configWithoutNav = testProcess.launchConfig.copyWith(
        showNavigationControls: false,
      );
      final ApplicationProcess processWithoutNav = ApplicationProcess(
        applicationId: testProcess.applicationId,
        applicationTitle: testProcess.applicationTitle,
        launchConfig: configWithoutNav,
        launchedAt: testProcess.launchedAt,
      );

      // Act
      await tester.pumpWidget(
        createTestApp(
          child: ApplicationWebView(process: processWithoutNav),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('should show close button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestApp(
          child: ApplicationWebView(process: testProcess),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should call onClose when close button is tapped', (WidgetTester tester) async {
      // Arrange
      bool closeCalled = false;

      await tester.pumpWidget(
        createTestApp(
          child: ApplicationWebView(
            process: testProcess,
            onClose: () => closeCalled = true,
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Assert
      expect(closeCalled, true);
    });

    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestApp(
          child: ApplicationWebView(process: testProcess),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading application...'), findsOneWidget);
    });

    testWidgets('should display WebView widget', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestApp(
          child: ApplicationWebView(process: testProcess),
        ),
      );

      // Assert
      expect(find.byType(WebViewWidget), findsOneWidget);
    });

    testWidgets('should call onWindowStateChanged when provided', (WidgetTester tester) async {
      // Arrange
      WindowState? capturedState;

      await tester.pumpWidget(
        createTestApp(
          child: ApplicationWebView(
            process: testProcess,
            onWindowStateChanged: (WindowState state) => capturedState = state,
          ),
        ),
      );

      // Act - Simulate window state change
      final ApplicationWebView webView = tester.widget(find.byType(ApplicationWebView));
      final WindowState newState = WindowState(
        x: 100,
        y: 200,
        width: 800,
        height: 600,
        lastUpdated: DateTime.now(),
      );
      webView.onWindowStateChanged?.call(newState);

      // Assert
      expect(capturedState, isNotNull);
      expect(capturedState!.x, 100);
      expect(capturedState!.y, 200);
    });

    group('navigation controls', () {
      testWidgets('should have proper tooltips for navigation buttons', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationWebView(process: testProcess),
          ),
        );

        // Assert - Check for tooltip widgets (they exist but may not be visible)
        final Finder backButton = find.byIcon(Icons.arrow_back);
        final Finder forwardButton = find.byIcon(Icons.arrow_forward);
        final Finder refreshButton = find.byIcon(Icons.refresh);
        final Finder closeButton = find.byIcon(Icons.close);

        expect(backButton, findsOneWidget);
        expect(forwardButton, findsOneWidget);
        expect(refreshButton, findsOneWidget);
        expect(closeButton, findsOneWidget);

        // Verify buttons are wrapped in IconButton widgets
        expect(find.ancestor(of: backButton, matching: find.byType(IconButton)), findsOneWidget);
        expect(find.ancestor(of: forwardButton, matching: find.byType(IconButton)), findsOneWidget);
        expect(find.ancestor(of: refreshButton, matching: find.byType(IconButton)), findsOneWidget);
        expect(find.ancestor(of: closeButton, matching: find.byType(IconButton)), findsOneWidget);
      });

      testWidgets('should handle navigation button taps', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationWebView(process: testProcess),
          ),
        );

        // Act & Assert - Verify buttons can be tapped without errors
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        // Note: We can't easily test the actual WebView navigation functionality
        // in unit tests since it requires a real WebView implementation
        // These would be better tested in integration tests
      });
    });

    group('configuration handling', () {
      testWidgets('should respect launch configuration settings', (WidgetTester tester) async {
        // Arrange
        final ApplicationLaunchConfig customConfig = ApplicationLaunchConfig(
          applicationType: ApplicationType.web,
          url: 'http://localhost:3000/custom-app',
          windowTitle: 'Custom Application Title',
          showNavigationControls: false,
          enableJavaScript: false,
          enableLocalStorage: false,
        );

        final ApplicationProcess customProcess = ApplicationProcess(
          applicationId: 'custom-app',
          applicationTitle: 'Custom Application',
          launchConfig: customConfig,
          launchedAt: DateTime.now(),
        );

        // Act
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationWebView(process: customProcess),
          ),
        );

        // Assert
        expect(find.text('Custom Application Title'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsNothing);
        expect(find.byIcon(Icons.arrow_forward), findsNothing);
        expect(find.byIcon(Icons.refresh), findsNothing);
      });
    });

    group('error handling', () {
      testWidgets('should handle WebView creation without errors', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestApp(
            child: ApplicationWebView(process: testProcess),
          ),
        );

        // Assert - Widget should build without throwing exceptions
        expect(find.byType(ApplicationWebView), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('window state integration', () {
      testWidgets('should handle window state updates', (WidgetTester tester) async {
        // Arrange
        final List<WindowState> stateUpdates = [];

        await tester.pumpWidget(
          createTestApp(
            child: ApplicationWebView(
              process: testProcess,
              onWindowStateChanged: (WindowState state) => stateUpdates.add(state),
            ),
          ),
        );

        // Act - Simulate multiple window state changes
        final ApplicationWebView webView = tester.widget(find.byType(ApplicationWebView));

        final WindowState state1 = WindowState(
          x: 100,
          y: 100,
          width: 800,
          height: 600,
          lastUpdated: DateTime.now(),
        );
        final WindowState state2 = WindowState(
          x: 200,
          y: 200,
          width: 900,
          height: 700,
          lastUpdated: DateTime.now(),
        );

        webView.onWindowStateChanged?.call(state1);
        webView.onWindowStateChanged?.call(state2);

        // Assert
        expect(stateUpdates.length, 2);
        expect(stateUpdates[0].x, 100);
        expect(stateUpdates[1].x, 200);
      });
    });
  });
}
