import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/setup/setup_route.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';

/// Basic test for the setup flow user interface.
///
/// Tests that the setup flow can be instantiated and rendered
/// without crashing. More detailed testing would require mocking
/// the Kiro detection service.
void main() {
  group('Setup Flow Basic Tests', () {
    /// Helper function to create a testable widget with proper localization.
    Widget createTestableWidget() {
      return const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SetupRoute(),
      );
    }

    /// Tests that the setup route can be created and rendered.
    testWidgets('should create and render setup route', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Allow the widget to build
      await tester.pump();

      // The setup route should be present
      expect(find.byType(SetupRoute), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    /// Tests that the setup route displays some form of content.
    testWidgets('should display setup content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Allow initial build
      await tester.pump();

      // Should have basic UI structure
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(SetupRoute), findsOneWidget);
    });
  });
}
