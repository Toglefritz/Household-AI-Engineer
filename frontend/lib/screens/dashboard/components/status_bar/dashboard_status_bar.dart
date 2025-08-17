import 'package:flutter/material.dart';
import '../../../../theme/insets.dart';
import '../../models/status_bar/connection_status.dart';
import 'status_bar_left_section.dart';
import 'status_bar_right_section.dart';

/// Status bar component for the main dashboard interface.
///
/// Displays system status information, connection indicators, and quick actions at the top of the dashboard. Provides
/// users with real-time feedback about system health and connectivity to backend services.
///
/// Features:
/// * Connection status indicators with visual feedback
/// * System status and health monitoring
/// * Quick action buttons for common operations
/// * Responsive design that adapts to window width
/// * macOS-style design with proper spacing and typography
class DashboardStatusBar extends StatelessWidget {
  /// Creates a dashboard status bar widget.
  ///
  /// @param connectionStatus Current connection status to display
  /// @param onToggleSidebar Callback for sidebar toggle button
  /// @param isSidebarExpanded Current sidebar expansion state
  const DashboardStatusBar({
    required this.connectionStatus,
    required this.onToggleSidebar,
    required this.isSidebarExpanded,
    super.key,
  });

  /// Current connection status to backend services.
  ///
  /// Used to display appropriate indicators and colors in the status bar. Provides users with immediate feedback about
  /// system availability.
  final ConnectionStatus connectionStatus;

  /// Callback function for the sidebar toggle button.
  ///
  /// Called when the user clicks the sidebar toggle in the status bar. Provides an alternative way to control sidebar
  /// visibility.
  final VoidCallback onToggleSidebar;

  /// Whether the sidebar is currently expanded.
  ///
  /// Used to determine the appropriate icon for the sidebar toggle button and adjust layout spacing accordingly.
  final bool isSidebarExpanded;

  /// Height of the status bar component.
  ///
  /// Consistent height that provides enough space for status indicators and buttons while maintaining visual hierarchy.
  static const double _statusBarHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _statusBarHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.small),
        child: Row(
          children: [
            // Left section: Connection status and system info
            Expanded(
              child: StatusBarLeftSection(
                connectionStatus: connectionStatus,
              ),
            ),

            // Right section: Quick actions and controls
            const StatusBarRightSection(),
          ],
        ),
      ),
    );
  }
}
