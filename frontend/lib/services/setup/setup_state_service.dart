import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing setup completion state.
///
/// This service tracks whether the user has completed the initial setup flow,
/// including Kiro IDE detection and tutorial completion. It uses persistent
/// storage to remember the setup state across application restarts.
class SetupStateService {
  /// Key used to store setup completion status in shared preferences.
  static const String _setupCompleteKey = 'setup_complete';

  /// Cached instance of SharedPreferences for efficient access.
  SharedPreferences? _prefs;

  /// Initializes the service by loading shared preferences.
  ///
  /// This method must be called before using other service methods.
  /// It loads the SharedPreferences instance for persistent storage access.
  ///
  /// Returns a [Future<void>] that completes when initialization is finished.
  ///
  /// Throws [SetupStateException] if SharedPreferences cannot be initialized.
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      throw SetupStateException(
        'Failed to initialize SharedPreferences: $e',
        cause: e,
      );
    }
  }

  /// Checks if the user has completed the initial setup flow.
  ///
  /// Returns true if the user has previously completed setup (including
  /// Kiro detection and tutorial), false if setup is required.
  ///
  /// This method requires [initialize] to be called first.
  ///
  /// Returns [Future<bool>] indicating setup completion status.
  ///
  /// Throws [SetupStateException] if the service is not initialized.
  Future<bool> isSetupComplete() async {
    if (_prefs == null) {
      throw const SetupStateException('SetupStateService not initialized');
    }

    return _prefs!.getBool(_setupCompleteKey) ?? false;
  }

  /// Marks the setup flow as completed.
  ///
  /// This method should be called when the user successfully completes
  /// the setup flow, including Kiro detection and tutorial (if not skipped).
  /// The completion state is persisted and will prevent the setup flow
  /// from showing on subsequent application launches.
  ///
  /// Returns [Future<void>] that completes when the state is saved.
  ///
  /// Throws [SetupStateException] if the service is not initialized
  /// or if saving the state fails.
  Future<void> markSetupComplete() async {
    if (_prefs == null) {
      throw const SetupStateException('SetupStateService not initialized');
    }

    try {
      await _prefs!.setBool(_setupCompleteKey, true);
    } catch (e) {
      throw SetupStateException(
        'Failed to save setup completion state: $e',
        cause: e,
      );
    }
  }

  /// Resets the setup completion state.
  ///
  /// This method clears the setup completion flag, causing the setup flow
  /// to be shown on the next application launch. This is useful for testing
  /// or if the user wants to go through setup again.
  ///
  /// Returns [Future<void>] that completes when the state is cleared.
  ///
  /// Throws [SetupStateException] if the service is not initialized
  /// or if clearing the state fails.
  Future<void> resetSetupState() async {
    if (_prefs == null) {
      throw const SetupStateException('SetupStateService not initialized');
    }

    try {
      await _prefs!.remove(_setupCompleteKey);
    } catch (e) {
      throw SetupStateException(
        'Failed to reset setup state: $e',
        cause: e,
      );
    }
  }

  /// Checks if the service has been properly initialized.
  ///
  /// Returns true if [initialize] has been called successfully,
  /// false otherwise. This can be used to verify service readiness
  /// before calling other methods.
  bool get isInitialized => _prefs != null;
}

/// Exception thrown when setup state operations fail.
///
/// This exception is used for errors related to setup state management,
/// such as SharedPreferences initialization failures or storage errors.
class SetupStateException implements Exception {
  /// Human-readable error message describing what went wrong.
  final String message;

  /// Optional underlying cause of this exception.
  final Object? cause;

  /// Creates a new setup state exception.
  ///
  /// @param message Description of the error that occurred
  /// @param cause Optional underlying exception that caused this error
  const SetupStateException(this.message, {this.cause});

  @override
  String toString() => 'SetupStateException: $message';
}
