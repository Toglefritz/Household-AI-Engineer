import 'package:flutter/material.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/insets.dart';
import '../../models/status_bar/connection_status.dart';
import 'status_bar_connection_indicator.dart';
import 'status_bar_system_status.dart';

/// Left section component for the status bar.
///
/// Contains connection indicators, system health information, and other status-related information that users need to
/// monitor.
class StatusBarLeftSection extends StatelessWidget {
  /// Creates a status bar left section widget.
  ///
  /// @param connectionStatus Current connection status to display
  /// @param applications List of all user applications for status display
  const StatusBarLeftSection({
    required this.connectionStatus,
    required this.applications,
    super.key,
  });

  /// Current connection status to backend services.
  ///
  /// Used to display appropriate indicators and colors.
  final ConnectionStatus connectionStatus;

  /// List of all user applications for status display.
  ///
  /// Passed to the system status component to calculate application counts.
  final List<UserApplication> applications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Connection status indicator
        StatusBarConnectionIndicator(
          connectionStatus: connectionStatus,
        ),

        Padding(
          padding: const EdgeInsets.only(left: Insets.medium),
          child: StatusBarSystemStatus(
            applications: applications,
          ),
        ),

        // Spacer to push right section to the end
        const Spacer(),
      ],
    );
  }
}
