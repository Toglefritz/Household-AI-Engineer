import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/debug/setup_debug_helper.dart';

/// Test file for manually resetting setup state during development.
///
/// Run this test to reset the setup completion flag:
/// ```bash
/// flutter test test/debug/reset_setup_test.dart
/// ```
///
/// This is useful when you want to test the setup flow again without
/// having to manually clear SharedPreferences or reinstall the app.
void main() {
  /// Initialize Flutter bindings before running tests.
  ///
  /// This is required for SharedPreferences to work in test environment.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up mock method channel for SharedPreferences
    const MethodChannel('plugins.flutter.io/shared_preferences').setMockMethodCallHandler((
      MethodCall methodCall,
    ) async {
      if (methodCall.method == 'getAll') {
        return <String, Object>{}; // Return empty preferences
      } else if (methodCall.method == 'remove') {
        return true; // Simulate successful removal
      } else if (methodCall.method == 'setBool') {
        return true; // Simulate successful setting
      }
      return null;
    });
  });

  group('Setup Debug Operations', () {
    /// Test that resets the setup state.
    ///
    /// Run this specific test to reset setup:
    /// ```bash
    /// flutter test test/debug/reset_setup_test.dart --name "should reset setup state"
    /// ```
    test('should reset setup state', () async {
      await SetupDebugHelper.resetSetupForTesting();

      // Verify it was reset
      final bool isComplete = await SetupDebugHelper.checkSetupStatus();
      expect(isComplete, false);

      print('🎉 Setup state has been reset successfully!');
      print('🔄 Restart the app to see the setup flow again.');
    });

    /// Test that marks setup as complete.
    ///
    /// Run this specific test to skip setup:
    /// ```bash
    /// flutter test test/debug/reset_setup_test.dart --name "should mark setup as complete"
    /// ```
    test('should mark setup as complete', () async {
      await SetupDebugHelper.markSetupCompleteForTesting();

      // Verify it was marked complete
      final bool isComplete = await SetupDebugHelper.checkSetupStatus();
      expect(isComplete, true);

      print('✅ Setup state has been marked as complete!');
      print('⏭️ The app will skip the setup flow on next launch.');
    });

    /// Test that checks current setup status without changing it.
    test('should check current setup status', () async {
      final bool isComplete = await SetupDebugHelper.checkSetupStatus();

      print('📊 Current setup status: ${isComplete ? "COMPLETED" : "NOT COMPLETED"}');
    });
  });
}
