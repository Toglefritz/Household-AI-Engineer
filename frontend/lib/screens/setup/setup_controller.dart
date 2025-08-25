import 'package:flutter/material.dart';

import '../../services/setup/kiro_detection_service.dart';
import '../../services/setup/setup_state_service.dart';
import '../dashboard/dashboard_route.dart';
import 'setup_route.dart';
import 'setup_view.dart';

/// Controller for the application setup flow.
///
/// Manages the setup process including Kiro IDE detection, user guidance,
/// and tutorial presentation. The controller handles all business logic
/// for the setup flow and coordinates transitions between setup phases.
///
/// Setup Flow Phases:
/// 1. Initial Kiro detection check
/// 2. Installation guidance (if Kiro not found)
/// 3. Tutorial presentation (after Kiro is confirmed)
/// 4. Transition to main application
class SetupController extends State<SetupRoute> {
  /// Service for detecting Kiro IDE installation.
  late final KiroDetectionService _kiroDetectionService;

  /// Service for managing setup completion state.
  late final SetupStateService _setupStateService;

  /// Current phase of the setup process.
  SetupPhase _currentPhase = SetupPhase.checking;

  /// Whether a Kiro detection check is currently in progress.
  bool _isCheckingKiro = false;

  /// Error message from the most recent failed operation.
  String? _errorMessage;

  /// Detected Kiro version, if available.
  String? _kiroVersion;

  @override
  void initState() {
    super.initState();
    _kiroDetectionService = KiroDetectionService();
    _setupStateService = SetupStateService();
    _initializeServices();
  }

  /// Initializes required services and performs initial Kiro check.
  ///
  /// This method sets up the setup state service and then proceeds
  /// with the Kiro detection process.
  Future<void> _initializeServices() async {
    try {
      await _setupStateService.initialize();
      await _performInitialKiroCheck();
    } catch (e) {
      setState(() {
        _currentPhase = SetupPhase.installationRequired;
        _errorMessage = 'Failed to initialize setup services: $e';
        _isCheckingKiro = false;
      });

      debugPrint('Setup service initialization error: $e');
    }
  }

  /// Current setup phase for UI state management.
  SetupPhase get currentPhase => _currentPhase;

  /// Whether a Kiro check operation is in progress.
  bool get isCheckingKiro => _isCheckingKiro;

  /// Current error message, if any.
  String? get errorMessage => _errorMessage;

  /// Detected Kiro version string.
  String? get kiroVersion => _kiroVersion;

  /// Performs the initial Kiro installation check.
  ///
  /// This method is called automatically when the setup flow starts.
  /// It checks for Kiro availability and transitions to the appropriate
  /// phase based on the detection results.
  Future<void> _performInitialKiroCheck() async {
    await _checkKiroInstallation();
  }

  /// Checks if Kiro IDE is installed and updates the setup phase accordingly.
  ///
  /// This method can be called multiple times during the setup flow,
  /// such as when the user clicks "Continue" after installing Kiro.
  /// It handles all error scenarios and provides appropriate user feedback.
  Future<void> _checkKiroInstallation() async {
    setState(() {
      _isCheckingKiro = true;
      _errorMessage = null;
    });

    try {
      final bool isInstalled = await _kiroDetectionService.isKiroInstalled();

      if (isInstalled) {
        // Kiro is available - get version info and proceed to tutorial
        try {
          _kiroVersion = await _kiroDetectionService.getKiroVersion();
        } catch (e) {
          // Version detection failed, but Kiro is available
          debugPrint('Failed to get Kiro version: $e');
          _kiroVersion = 'Unknown';
        }

        setState(() {
          _currentPhase = SetupPhase.tutorial;
          _isCheckingKiro = false;
        });
      } else {
        // Kiro not found - show installation guidance
        setState(() {
          _currentPhase = SetupPhase.installationRequired;
          _isCheckingKiro = false;
        });
      }
    } on KiroDetectionException catch (e) {
      // Handle detection errors with user-friendly message
      setState(() {
        _currentPhase = SetupPhase.installationRequired;
        _errorMessage = 'Unable to check Kiro installation: ${e.message}';
        _isCheckingKiro = false;
      });
    } catch (e) {
      // Handle unexpected errors
      setState(() {
        _currentPhase = SetupPhase.installationRequired;
        _errorMessage = 'An unexpected error occurred while checking for Kiro.';
        _isCheckingKiro = false;
      });

      debugPrint('Unexpected error during Kiro detection: $e');
    }
  }

  /// Handles the "Continue" button press in the installation required phase.
  ///
  /// Re-checks for Kiro installation to see if the user has completed
  /// the installation process. This allows users to install Kiro and
  /// continue without restarting the application.
  Future<void> onContinueAfterInstallation() async {
    await _checkKiroInstallation();
  }

  /// Handles the "Complete Tutorial" button press.
  ///
  /// Marks setup as complete and transitions to the main application dashboard.
  /// This ensures the setup flow won't be shown again on future app launches.
  Future<void> onCompleteTutorial() async {
    await _completeSetupAndNavigate();
  }

  /// Handles the "Skip Tutorial" button press.
  ///
  /// Marks setup as complete and goes directly to the main application.
  /// This is useful for users who are already familiar with the system
  /// or want to explore on their own.
  Future<void> onSkipTutorial() async {
    await _completeSetupAndNavigate();
  }

  /// Marks setup as complete and navigates to the dashboard.
  ///
  /// This method handles the common logic for both completing and
  /// skipping the tutorial, ensuring setup state is properly saved.
  Future<void> _completeSetupAndNavigate() async {
    try {
      await _setupStateService.markSetupComplete();
    } catch (e) {
      // Log error but don't prevent navigation
      debugPrint('Failed to mark setup complete: $e');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const DashboardRoute(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SetupView(this);
}

/// Enumeration of setup flow phases.
///
/// Each phase represents a distinct step in the setup process with
/// different UI requirements and user interactions.
enum SetupPhase {
  /// Initial phase while checking for Kiro installation.
  checking,

  /// Phase shown when Kiro is not installed or not accessible.
  installationRequired,

  /// Phase shown when Kiro is available and tutorial is presented.
  tutorial,
}
