import 'package:flutter/material.dart';

import '../../services/setup/setup_state_service.dart';
import '../dashboard/dashboard_route.dart';
import '../setup/setup_route.dart';
import 'splash_route.dart';
import 'splash_view.dart';

/// Controller for the application splash screen and initial routing.
///
/// Manages the startup process including setup state checking and
/// navigation to the appropriate initial screen. The controller
/// determines whether to show the setup flow or go directly to
/// the main dashboard based on the user's previous completion status.
class SplashController extends State<SplashRoute> {
  /// Service for managing setup completion state.
  late final SetupStateService _setupStateService;

  /// Whether the initialization process is currently in progress.
  bool _isInitializing = true;

  /// Error message from initialization, if any occurred.
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _setupStateService = SetupStateService();
    _performInitialization();
  }

  /// Whether the app is currently initializing.
  bool get isInitializing => _isInitializing;

  /// Current initialization error message, if any.
  String? get initializationError => _initializationError;

  /// Performs the application initialization and routing logic.
  ///
  /// This method handles the complete startup sequence:
  /// 1. Initialize setup state service
  /// 2. Check if setup has been completed
  /// 3. Navigate to appropriate screen (setup or dashboard)
  /// 4. Handle any errors that occur during initialization
  Future<void> _performInitialization() async {
    try {
      // Initialize the setup state service
      await _setupStateService.initialize();

      // Check if setup has been completed
      final bool setupComplete = await _setupStateService.isSetupComplete();

      // Add a brief delay to show the splash screen
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Navigate to appropriate screen based on setup status
      if (setupComplete) {
        _navigateToDashboard();
      } else {
        _navigateToSetup();
      }
    } on SetupStateException catch (e) {
      // Handle setup state service errors
      setState(() {
        _initializationError = 'Setup state error: ${e.message}';
        _isInitializing = false;
      });

      debugPrint('Setup state service error: $e');
    } catch (e) {
      // Handle unexpected initialization errors
      setState(() {
        _initializationError = 'Initialization failed: $e';
        _isInitializing = false;
      });

      debugPrint('Unexpected initialization error: $e');
    }
  }

  /// Navigates to the main dashboard screen.
  ///
  /// This method is called when setup has been completed and the user
  /// should go directly to the main application interface.
  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const DashboardRoute(),
      ),
    );
  }

  /// Navigates to the setup flow screen.
  ///
  /// This method is called when setup has not been completed and the user
  /// needs to go through the initial setup process including Kiro detection
  /// and tutorial presentation.
  void _navigateToSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SetupRoute(),
      ),
    );
  }

  /// Handles retry button press when initialization fails.
  ///
  /// Resets the error state and attempts initialization again.
  /// This allows users to recover from temporary initialization failures
  /// without restarting the application.
  void onRetryInitialization() {
    setState(() {
      _isInitializing = true;
      _initializationError = null;
    });

    _performInitialization();
  }

  /// Handles force setup button press when initialization fails.
  ///
  /// Bypasses the setup state check and goes directly to the setup flow.
  /// This provides a fallback option when setup state cannot be determined
  /// but the user wants to proceed with setup.
  void onForceSetup() {
    _navigateToSetup();
  }

  @override
  Widget build(BuildContext context) => SplashView(this);
}
