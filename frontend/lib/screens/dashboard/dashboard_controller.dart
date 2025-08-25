import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

import '../../services/application_launcher/application_launcher_service.dart';
import '../../services/application_launcher/models/application_process.dart';
import '../../services/application_launcher/models/launch_result.dart';
import '../../services/application_launcher/models/window_state.dart';
import '../../services/conversation/models/conversation_thread.dart';
import '../../services/user_application/models/application_status.dart';
import '../../services/user_application/models/user_application.dart';
import '../../services/user_application/user_application_service.dart';
import 'components/search/search_controller.dart' as search;
import '../application_launcher/application_launcher_window.dart';
import 'components/applications/application_context_menu.dart';
import 'components/applications/application_details_dialog.dart';
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

  /// List of filtered applications based on search and filter criteria.
  ///
  /// This list is updated by the search and filter interface and represents
  /// the applications that should be displayed in the grid.
  List<UserApplication> _filteredApplications = [];

  /// Set of currently selected application IDs.
  ///
  /// Used for multi-selection operations and visual feedback
  /// in the application grid.
  final Set<String> _selectedApplicationIds = <String>{};

  /// Service for managing user applications through the local file system.
  ///
  /// Handles loading, creating, and managing applications with real-time updates.
  final UserApplicationService _userApplicationService = UserApplicationService();

  /// Service for launching and managing running applications.
  ///
  /// Handles WebView integration, process monitoring, and window state management.
  ApplicationLauncherService? _applicationLauncherService;

  /// Stream subscription for application updates.
  ///
  /// Listens to real-time application changes and updates the UI accordingly.
  StreamSubscription<List<UserApplication>>? _applicationSubscription;

  /// Stream subscription for application launch events.
  ///
  /// Listens to launch results and status updates from the launcher service.
  StreamSubscription<LaunchResult>? _launchEventsSubscription;

  /// Search controller for managing search and filtering functionality.
  ///
  /// Handles text search, category filtering, status filtering, and sorting
  /// for the application grid. Integrates with sidebar search components.
  late search.ApplicationSearchController _searchController;

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

  /// List of filtered applications for display in the grid.
  ///
  /// Returns the applications that match the current search and filter criteria.
  /// This is what should be displayed in the application grid.
  List<UserApplication> get filteredApplications => List.unmodifiable(_filteredApplications);

  /// Set of currently selected application IDs.
  ///
  /// Used by the application grid to show selection states
  /// and enable multi-selection operations.
  Set<String> get selectedApplicationIds => Set.unmodifiable(_selectedApplicationIds);

  @override
  void initState() {
    super.initState();

    // Initialize search controller
    _searchController = search.ApplicationSearchController();
    _searchController.addListener(_onSearchResultsChanged);

    // Initialize services and load applications
    _initializeServices();
    _loadApplications();
  }

  /// Initializes the application launcher service and sets up event listeners.
  ///
  /// Creates the launcher service with required dependencies and subscribes
  /// to launch events for UI updates and error handling.
  Future<void> _initializeServices() async {
    try {
      // Initialize dependencies for the launcher service
      final http.Client httpClient = http.Client();
      final SharedPreferences preferences = await SharedPreferences.getInstance();

      // Create the application launcher service
      _applicationLauncherService = ApplicationLauncherService(
        httpClient,
        preferences,
      );

      // Subscribe to launch events
      _launchEventsSubscription = _applicationLauncherService!.launchEvents.listen(
        _handleLaunchEvent,
        onError: (Object error) {
          debugPrint('Launch event error: $error');
        },
      );

      debugPrint('Application launcher service initialized');
    } catch (e) {
      debugPrint('Failed to initialize application launcher service: $e');
    }
  }

  /// Handles launch events from the application launcher service.
  ///
  /// Updates UI state and shows user feedback based on launch results.
  /// For successful launches, opens the application in a WebView window.
  ///
  /// @param result The launch result containing success/failure information
  void _handleLaunchEvent(LaunchResult result) {
    if (result.success) {
      debugPrint('Launch event: ${result.description}');

      // Update connection status to show successful operation
      setState(() {
        _connectionStatus = ConnectionStatus.connected;
      });

      // For successful launches, show the application in a WebView
      if (result.process != null && result.message != null && !result.message!.contains('foreground')) {
        _showApplicationWindow(result.process!);
      }

      // Show success message for foreground events
      if (result.message != null && result.message!.contains('foreground')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.description),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      debugPrint('Launch error: ${result.description}');

      // Update connection status to show error
      setState(() {
        _connectionStatus = ConnectionStatus.error;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.description),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows the application in a WebView window.
  ///
  /// Creates a full-screen dialog containing the WebView for the application.
  /// The dialog can be closed by the user, which will stop the application process.
  ///
  /// @param process The application process to display
  void _showApplicationWindow(ApplicationProcess process) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ApplicationLauncherWindow(
          process: process,
          onWindowStateChanged: (WindowState windowState) {
            // Update the process with new window state
            process.updateWindowState(windowState);
          },
          onApplicationClosed: (String applicationId) {
            // Close the dialog
            Navigator.of(context).pop();

            // Stop the application process
            _applicationLauncherService?.stopApplication(applicationId);
          },
        );
      },
    );
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

            // Update search controller with new applications
            _searchController.updateApplications(applications);

            // Initialize filtered applications to show all applications by default
            if (_filteredApplications.isEmpty) {
              _filteredApplications = applications;
            }

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

      setState(() {
        _connectionStatus = ConnectionStatus.connected;
      });
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
    debugPrint(
      'Application tapped: ${application.title} (${application.status.displayName})',
    );

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
  /// @param position Screen position where the menu should appear
  void onApplicationSecondaryTap(UserApplication application, Offset position) {
    debugPrint('Application right-clicked: ${application.title}');

    _showApplicationContextMenu(application, position);
  }

  /// Handles application selection state changes.
  ///
  /// Updates the selected applications set and triggers UI updates.
  ///
  /// @param application The application whose selection changed
  /// @param isSelected Whether the application should be selected
  void onApplicationSelectionChanged(UserApplication application, {required bool isSelected}) {
    setState(() {
      if (isSelected) {
        _selectedApplicationIds.add(application.id);
      } else {
        _selectedApplicationIds.remove(application.id);
      }
    });
  }

  /// Selects all applications in the current view.
  ///
  /// Adds all application IDs to the selection set.
  void onSelectAllApplications() {
    setState(() {
      _selectedApplicationIds.addAll(
        _applications.map((app) => app.id),
      );
    });
  }

  /// Clears all application selections.
  ///
  /// Removes all application IDs from the selection set.
  void onSelectNoApplications() {
    setState(() {
      _selectedApplicationIds.clear();
    });
  }

  /// Handles bulk delete operation for selected applications.
  ///
  /// Deletes multiple applications and shows appropriate feedback.
  ///
  /// @param applications List of applications to delete
  void onBulkDeleteApplications(List<UserApplication> applications) {
    debugPrint('Bulk deleting ${applications.length} applications');

    // Delete each application
    for (final UserApplication app in applications) {
      _deleteApplication(app, showIndividualFeedback: false);
    }

    // Clear selection
    setState(() {
      _selectedApplicationIds.clear();
    });

    // Show bulk feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.applicationsDeleted(applications.length),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Launches the specified application.
  ///
  /// Uses the application launcher service to create a WebView window
  /// for web-based applications with proper process monitoring.
  ///
  /// @param application The application to launch
  Future<void> _launchApplication(UserApplication application) async {
    debugPrint('Launching application: ${application.title}');

    if (_applicationLauncherService == null) {
      debugPrint('Application launcher service not initialized');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application launcher not ready. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
      });

      // Launch the application using the launcher service
      final LaunchResult result = await _applicationLauncherService!.launchApplication(application);

      if (result.success) {
        debugPrint('Successfully launched application: ${application.title}');

        // The launch event handler will update the UI state
        // No need to manually update connection status here
      } else {
        debugPrint('Failed to launch application: ${result.error}');

        setState(() {
          _connectionStatus = ConnectionStatus.error;
        });
      }
    } catch (e) {
      debugPrint('Exception during application launch: $e');

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

    ApplicationDetailsDialog.show(
      context: context,
      application: application,
      onLaunch: (app) => _launchApplication(app),
      onModify: (app) => openModifyApplicationConversation(app),
      onRestart: (app) => _restartApplication(app),
      onStop: (app) => _stopApplication(app),
      onDelete: (app) => _deleteApplication(app),
      onToggleFavorite: (app) => _toggleApplicationFavorite(app),
    );
  }

  /// Shows a context menu for the specified application.
  ///
  /// Displays available management actions based on the application
  /// status and user permissions.
  ///
  /// @param application The application to show context menu for
  /// @param position Screen position where the menu should appear
  void _showApplicationContextMenu(UserApplication application, Offset position) {
    debugPrint('Showing context menu for application: ${application.title}');

    ApplicationContextMenu.show(
      context: context,
      position: position,
      application: application,
      onLaunch: (app) => _launchApplication(app),
      onModify: (app) => openModifyApplicationConversation(app),
      onRestart: (app) => _restartApplication(app),
      onStop: (app) => _stopApplication(app),
      onDelete: (app) => _deleteApplication(app),
      onViewDetails: (app) => _showApplicationDetails(app),
      onToggleFavorite: (app) => _toggleApplicationFavorite(app),
    );
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
    ).then((_) {
      // Refresh applications after conversation modal closes
      // This ensures any new applications created during the conversation are displayed
      debugPrint('Conversation modal closed, refreshing applications');
      _refreshApplicationsAfterDelay();
    });
  }

  /// Handles changes in search results from the search controller.
  ///
  /// Updates the filtered applications list with the new search results
  /// and triggers a UI update to reflect the changes in the grid.
  void _onSearchResultsChanged() {
    setState(() {
      _filteredApplications = _searchController.filteredApplications;
    });
  }

  /// Gets the search controller for use by sidebar components.
  ///
  /// Provides access to the search controller so sidebar components
  /// can update search queries and filter criteria.
  search.ApplicationSearchController get searchController => _searchController;

  /// Refreshes applications after a short delay.
  ///
  /// This method is called after conversation modals close to ensure
  /// any newly created applications are detected and displayed.
  /// The delay allows time for file system operations to complete.
  void _refreshApplicationsAfterDelay() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _userApplicationService
            .refreshApplications()
            .then((List<UserApplication> apps) {
              debugPrint(
                'Manual refresh completed, found ${apps.length} applications',
              );
            })
            .catchError((Object error) {
              debugPrint('Manual refresh failed: $error');
            });
      }
    });
  }

  /// Restarts the specified application.
  ///
  /// Stops and then relaunches the application with proper error handling.
  ///
  /// @param application The application to restart
  Future<void> _restartApplication(UserApplication application) async {
    debugPrint('Restarting application: ${application.title}');

    if (_applicationLauncherService == null) {
      debugPrint('Application launcher service not initialized');
      return;
    }

    try {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
      });

      // Stop the application first
      await _applicationLauncherService!.stopApplication(application.id);

      // Wait a moment for cleanup
      await Future.delayed(const Duration(milliseconds: 500));

      // Launch it again
      final LaunchResult result = await _applicationLauncherService!.launchApplication(application);

      if (result.success) {
        debugPrint('Successfully restarted application: ${application.title}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.applicationRestarted,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('Failed to restart application: ${result.error}');
        setState(() {
          _connectionStatus = ConnectionStatus.error;
        });
      }
    } catch (e) {
      debugPrint('Exception during application restart: $e');

      setState(() {
        _connectionStatus = ConnectionStatus.error;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restart ${application.title}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Stops the specified application.
  ///
  /// Terminates the application process and updates the UI accordingly.
  ///
  /// @param application The application to stop
  Future<void> _stopApplication(UserApplication application) async {
    debugPrint('Stopping application: ${application.title}');

    if (_applicationLauncherService == null) {
      debugPrint('Application launcher service not initialized');
      return;
    }

    try {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
      });

      await _applicationLauncherService!.stopApplication(application.id);

      debugPrint('Successfully stopped application: ${application.title}');

      setState(() {
        _connectionStatus = ConnectionStatus.connected;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.applicationStopped,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception during application stop: $e');

      setState(() {
        _connectionStatus = ConnectionStatus.error;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop ${application.title}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Toggles the favorite status of the specified application.
  ///
  /// Updates the application's favorite status and shows appropriate feedback.
  ///
  /// @param application The application to toggle favorite status for
  Future<void> _toggleApplicationFavorite(UserApplication application) async {
    debugPrint('Toggling favorite status for application: ${application.title}');

    try {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
      });

      // Toggle the favorite status
      final bool newFavoriteStatus = !application.isFavorite;
      await _userApplicationService.updateFavoriteStatus(application.id, newFavoriteStatus);

      debugPrint('Successfully toggled favorite status for application: ${application.title}');

      setState(() {
        _connectionStatus = ConnectionStatus.connected;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavoriteStatus
                  ? AppLocalizations.of(context)!.applicationAddedToFavorites
                  : AppLocalizations.of(context)!.applicationRemovedFromFavorites,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception during favorite status toggle: $e');

      setState(() {
        _connectionStatus = ConnectionStatus.error;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite status for ${application.title}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Deletes the specified application.
  ///
  /// Removes the application from the system with confirmation and cleanup.
  ///
  /// @param application The application to delete
  /// @param showIndividualFeedback Whether to show feedback for this deletion
  Future<void> _deleteApplication(
    UserApplication application, {
    bool showIndividualFeedback = true,
  }) async {
    debugPrint('Deleting application: ${application.title}');

    try {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
      });

      // If the application is running, stop it first
      if (application.status == ApplicationStatus.running && _applicationLauncherService != null) {
        await _applicationLauncherService!.stopApplication(application.id);
      }

      // Delete the application through the service
      await _userApplicationService.deleteApplication(application.id);

      debugPrint('Successfully deleted application: ${application.title}');

      setState(() {
        _connectionStatus = ConnectionStatus.connected;
        // Remove from selection if it was selected
        _selectedApplicationIds.remove(application.id);
      });

      if (showIndividualFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.applicationDeleted,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception during application deletion: $e');

      setState(() {
        _connectionStatus = ConnectionStatus.error;
      });

      if (showIndividualFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete ${application.title}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => DashboardView(this);

  @override
  void dispose() {
    // Clean up resources
    _applicationSubscription?.cancel();
    _launchEventsSubscription?.cancel();
    _searchController.removeListener(_onSearchResultsChanged);
    _searchController.dispose();
    _userApplicationService.dispose();
    _applicationLauncherService?.dispose();
    super.dispose();
  }
}
