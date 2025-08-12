import 'package:flutter/material.dart';

import 'dashboard_route.dart';
import 'dashboard_view.dart';

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

  /// Whether the sidebar is currently expanded.
  ///
  /// Used by the view to determine sidebar layout and animation states.
  bool get isSidebarExpanded => _isSidebarExpanded;

  /// Current connection status for display in the status bar.
  ///
  /// Provides real-time feedback about backend service availability
  /// and helps users understand system state.
  ConnectionStatus get connectionStatus => _connectionStatus;

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

  @override
  Widget build(BuildContext context) => DashboardView(this);
}

/// Represents the current connection status to backend services.
///
/// Used by the status bar to display appropriate indicators and
/// provide users with feedback about system availability.
enum ConnectionStatus {
  /// All services are connected and functioning normally.
  ///
  /// Displays green indicators and allows full functionality.
  connected,

  /// Some services are experiencing issues or delays.
  ///
  /// Displays yellow indicators and may show degraded functionality warnings.
  degraded,

  /// Services are disconnected or unavailable.
  ///
  /// Displays red indicators and shows offline mode or error messages.
  disconnected,

  /// Currently attempting to establish or restore connection.
  ///
  /// Displays animated indicators to show connection attempts in progress.
  connecting,
}
