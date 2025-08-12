import 'package:flutter/material.dart';
import '../../../../theme/insets.dart';
import '../../dashboard_controller.dart';
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
  const StatusBarLeftSection({
    required this.connectionStatus,
    super.key,
  });

  /// Current connection status to backend services.
  ///
  /// Used to display appropriate indicators and colors.
  final ConnectionStatus connectionStatus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Connection status indicator
        StatusBarConnectionIndicator(
          connectionStatus: connectionStatus,
        ),

        const Padding(
          padding: EdgeInsets.only(left: Insets.medium),
          child: StatusBarSystemStatus(),
        ),

        // Spacer to push right section to the end
        const Spacer(),
      ],
    );
  }
}
