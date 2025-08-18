import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/sample_data_service.dart';
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
  bool _isSidebarExpanded = true;

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

    // Load the user applications.
    _loadApplications();
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
  /// Handles launching applications based on their launch configuration.
  /// For now, this is a placeholder that will be implemented in future tasks.
  ///
  /// @param application The application to launch
  void _launchApplication(UserApplication application) {
    debugPrint('Launching application: ${application.title}');
    // TODO(Scott): Implement actual application launching in future tasks

    // For now, simulate launching by updating the status to running
    setState(() {
      final int index = _applications.indexWhere((UserApplication app) => app.id == application.id);
      if (index != -1 && application.status == ApplicationStatus.ready) {
        _applications[index] = application.copyWith(
          status: ApplicationStatus.running,
          updatedAt: DateTime.now(),
        );
      }
    });
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
          onConversationComplete: _onConversationComplete,
        );
      },
    );
  }

  /// Handles conversation completion.
  ///
  /// Called when a conversation is successfully completed and an application
  /// specification has been generated and submitted.
  ///
  /// @param conversation The completed conversation thread
  void _onConversationComplete(ConversationThread conversation) {
    debugPrint('Conversation completed: ${conversation.id}');

    // In a real implementation, this would trigger the application creation
    // process and add the new application to the list

    // For now, simulate adding a new application in development
    if (conversation.context.isCreatingApplication) {
      final UserApplication newApplication = UserApplication(
        id: 'app_new_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Application', // Would be extracted from conversation
        description: 'Application created through conversation',
        status: ApplicationStatus.developing,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3000',
        ),
        tags: ['conversation-created'],
        progress: DevelopmentProgress(
          percentage: 5.0,
          currentPhase: 'Analyzing Requirements',
          milestones: [],
          lastUpdated: DateTime.now(),
        ),
      );

      setState(() {
        _applications.add(newApplication);
      });
    }
  }

  /// Loads applications from the sample data service.
  ///
  /// In future tasks, this will be replaced with actual API calls
  /// to load applications from the backend service.
  void _loadApplications() {
    setState(() {
      _applications = SampleDataService.getSampleApplications();
    });
  }

  @override
  Widget build(BuildContext context) => DashboardView(this);
}
