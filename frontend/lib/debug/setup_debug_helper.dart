import '../services/setup/setup_state_service.dart';

/// Debug helper for resetting setup state during development and testing.
///
/// This class provides convenient methods for developers to reset the setup
/// completion state without having to manually clear SharedPreferences or
/// reinstall the application.
///
/// **Note**: This should only be used during development and testing.
class SetupDebugHelper {
  /// Resets the setup completion state to force the setup flow to show again.
  ///
  /// This method initializes the SetupStateService and clears the setup
  /// completion flag, causing the setup flow to be displayed on the next
  /// application launch.
  ///
  /// Usage:
  /// ```dart
  /// await SetupDebugHelper.resetSetupForTesting();
  /// ```
  ///
  /// Returns [Future<void>] that completes when the reset is finished.
  ///
  /// Throws [SetupStateException] if the reset operation fails.
  static Future<void> resetSetupForTesting() async {
    final SetupStateService setupService = SetupStateService();
    await setupService.initialize();
    await setupService.resetSetupState();

    print('✅ Setup state has been reset. The setup flow will show on next app launch.');
  }

  /// Checks the current setup completion status for debugging.
  ///
  /// This method allows developers to verify whether setup has been
  /// completed without affecting the state.
  ///
  /// Returns [Future<bool>] indicating the current setup status.
  static Future<bool> checkSetupStatus() async {
    final SetupStateService setupService = SetupStateService();
    await setupService.initialize();
    final bool isComplete = await setupService.isSetupComplete();

    print('ℹ️ Setup completion status: ${isComplete ? "COMPLETED" : "NOT COMPLETED"}');
    return isComplete;
  }

  /// Forces setup to be marked as complete for testing scenarios.
  ///
  /// This method allows developers to skip the setup flow during testing
  /// by marking it as already completed.
  ///
  /// Returns [Future<void>] that completes when the setup is marked complete.
  static Future<void> markSetupCompleteForTesting() async {
    final SetupStateService setupService = SetupStateService();
    await setupService.initialize();
    await setupService.markSetupComplete();

    print('✅ Setup has been marked as complete. The app will skip setup flow.');
  }
}
