import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/conversation/models/conversation_thread.dart';
import '../../services/user_application/models/application_status.dart';
import '../../services/user_application/models/user_application.dart';
import '../../services/user_application/user_application_service.dart';
import 'components/conversation/conversation_modal.dart';
import 'dashboard_route.dart';
import 'dashboard_view.dart';
import 'models/status_bar/connection_status.dart';

/// Controller for [DashboardRoute].
///
/// Manages the main dashboard state including sidebar visibility,
/// connection status, and overall layout configuration. Handles
/// user interactions and coordinates between the sidebar, main content,
/// and status bar components.
class DashboardController extends State<DashboardRoute> {
  /// Whether the sidebar is currently expanded.
  ///
  /// Controls the sidebar visibility state for responsive behavior.
  /// When false, the sidebar shows only icons; when true, it shows
  /// full labels and expanded content.
  ///
  /// Initially set to false and automatically updated based on application
  /// availability: opens when applications are present, stays closed when none exist.
  bool _isSidebarExpanded = false;

  /// Current connection status to the backend services.
  ///
  /// Used by the status bar to display appropriate connection indicators
  /// and inform users of system availability.
  ConnectionStatus _connectionStatus = ConnectionStatus.connected;

  /// List of all applications currently managed by this controller.
  ///
  /// Applications are loaded from the sample data service for now,
  /// but will be replaced with real data from the backend in future tasks.
  List<UserApplication> _applications = [];

  /// Set of currently selected application IDs.
  ///
  /// Used for multi-selection operations and visual feedback
  /// in the application grid.
  final Set<String> _selectedApplicationIds = <String>{};

  /// Service for managing user applications through the local file system.
  ///
  /// Handles loading, creating, and managing applications with real-time updates.
  final UserApplicationService _userApplicationService = UserApplicationService();

  /// Stream subscription for application updates.
  ///
  /// Listens to real-time application changes and updates the UI accordingly.
  StreamSubscription<List<UserApplication>>? _applicationSubscription;

  /// Whether the sidebar is currently expanded.
  ///
  /// Used by the view to determine sidebar layout and animation states.
  bool get isSidebarExpanded => _isSidebarExpanded;

  /// Current connection status for display in the status bar.
  ///
  /// Provides real-time feedback about backend service availability
  /// and helps users understand system state.
  ConnectionStatus get connectionStatus => _connectionStatus;

  /// List of all applications for display in the grid.
  ///
  /// Returns an immutable view of the applications to prevent
  /// external modification of the internal state.
  List<UserApplication> get applications => List.unmodifiable(_applications);

  /// Set of currently selected application IDs.
  ///
  /// Used by the application grid to show selection states
  /// and enable multi-selection operations.
  Set<String> get selectedApplicationIds => Set.unmodifiable(_selectedApplicationIds);

  @override
  void initState() {
    super.initState();

    // Load and watch for application updates
    _loadApplications();
  }

  /// Loads applications from the user application service and sets up real-time updates.
  ///
  /// Establishes a stream subscription to receive real-time application updates
  /// from both local manifests and the Kiro Bridge API. Also manages sidebar
  /// state based on application availability - opens when applications exist,
  /// stays closed when none are present.
  Future<void> _loadApplications() async {
    try {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
      });

      // Set up stream subscription for real-time updates
      _applicationSubscription = _userApplicationService.watchApplications().listen(
        (List<UserApplication> applications) {
          setState(() {
            _applications = applications;

            // Set sidebar state based on application availability
            // Open sidebar if there are applications, keep closed if none
            _isSidebarExpanded = applications.isNotEmpty;
          });
        },
        onError: (Object error) {
          debugPrint('Error loading applications: $error');
          setState(() {
            _connectionStatus = ConnectionStatus.error;
          });
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize application loading: $e');
      setState(() {
        _connectionStatus = ConnectionStatus.error;
      });
    }
  }

  /// Toggles the sidebar expansion state.
  ///
  /// Called when the user clicks the sidebar toggle button or uses
  /// keyboard shortcuts. Triggers a rebuild to update the layout.
  void toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  /// Updates the connection status and refreshes the UI.
  ///
  /// Called by background services when connection state changes.
  /// Updates the status bar indicators to reflect current connectivity.
  ///
  /// @param status New connection status to display
  void updateConnectionStatus(ConnectionStatus status) {
    setState(() {
      _connectionStatus = status;
    });
  }

  /// Handles application tile tap events.
  ///
  /// Called when a user taps on an application tile. Behavior depends
  /// on the application status - ready/running apps are launched,
  /// others show details or status information.
  ///
  /// @param application The application that was tapped
  void onApplicationTap(UserApplication application) {
    debugPrint('Application tapped: ${application.title} (${application.status.displayName})');

    if (application.canLaunch) {
      _launchApplication(application);
    } else {
      _showApplicationDetails(application);
    }
  }

  /// Handles application tile secondary tap (right-click) events.
  ///
  /// Shows a context menu with application management options
  /// based on the current application status and capabilities.
  ///
  /// @param application The application that was right-clicked
  void onApplicationSecondaryTap(UserApplication application) {
    debugPrint('Application right-clicked: ${application.title}');

    _showApplicationContextMenu(application);
  }

  /// Launches the specified application.
  ///
  /// Handles launching applications through the Kiro Bridge service.
  /// Updates the connection status based on the success of the operation.
  ///
  /// @param application The application to launch
  Future<void> _launchApplication(UserApplication application) async {
    debugPrint('Launching application: ${application.title}');

    try {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
      });

      await _userApplicationService.launchApplication(application.id);

      setState(() {
        _connectionStatus = ConnectionStatus.connected;
      });

      debugPrint('Successfully launched application: ${application.title}');
    } catch (e) {
      debugPrint('Failed to launch application: $e');

      setState(() {
        _connectionStatus = ConnectionStatus.error;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch ${application.title}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows detailed information about the specified application.
  ///
  /// Displays application details, progress information, and available
  /// actions in a modal or detail view.
  ///
  /// @param application The application to show details for
  void _showApplicationDetails(UserApplication application) {
    debugPrint('Showing details for application: ${application.title}');
    // TODO(Scott): Implement application details view in future tasks
  }

  /// Shows a context menu for the specified application.
  ///
  /// Displays available management actions based on the application
  /// status and user permissions.
  ///
  /// @param application The application to show context menu for
  void _showApplicationContextMenu(UserApplication application) {
    debugPrint('Showing context menu for application: ${application.title}');
    // TODO(Scott): Implement context menu in future tasks
  }

  /// Opens the conversation modal for creating a new application.
  ///
  /// Shows the conversational interface that guides users through
  /// the application creation process.
  void openNewApplicationConversation() {
    debugPrint('Opening new application conversation');
    _showConversationModal();
  }

  /// Opens the conversation modal for modifying an existing application.
  ///
  /// @param application The application to modify
  void openModifyApplicationConversation(UserApplication application) {
    debugPrint('Opening modify conversation for: ${application.title}');
    _showConversationModal(applicationToModify: application);
  }

  /// Shows the conversation modal with optional parameters.
  ///
  /// @param initialConversation Optional conversation to load
  /// @param applicationToModify Optional application to modify
  void _showConversationModal({
    ConversationThread? initialConversation,
    UserApplication? applicationToModify,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConversationModal(
          initialConversation: initialConversation,
          applicationToModify: applicationToModify,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => DashboardView(this);

  @override
  void dispose() {
    // Clean up resources
    _applicationSubscription?.cancel();
    _userApplicationService.dispose();
    super.dispose();
  }
}
