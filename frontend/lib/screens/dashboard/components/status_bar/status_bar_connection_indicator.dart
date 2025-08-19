import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';
import '../../models/status_bar/connection_status.dart';
import '../../models/status_bar/connection_status_info.dart';

/// Connection status indicator component for the status bar.
///
/// Shows a colored dot and icon that represents the current connection state to backend services. Provides immediate
/// visual feedback about system availability and health.
class StatusBarConnectionIndicator extends StatelessWidget {
  /// Creates a status bar connection indicator widget.
  ///
  /// @param connectionStatus Current connection status to display
  const StatusBarConnectionIndicator({
    required this.connectionStatus,
    super.key,
  });

  /// Current connection status to backend services.
  ///
  /// Used to display appropriate indicators and colors.
  final ConnectionStatus connectionStatus;

  @override
  Widget build(BuildContext context) {
    final ConnectionStatusInfo statusInfo = _getConnectionStatusInfo(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status dot with animation for connecting state
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusInfo.color,
            shape: BoxShape.circle,
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: Insets.xSmall),
          child: Icon(
            statusInfo.icon,
            size: 16,
            color: statusInfo.color,
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: Insets.xSmall),
          child: Text(
            statusInfo.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusInfo.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Gets the appropriate visual information for the current connection status.
  ///
  /// Maps connection status enum values to their corresponding colors, icons, and labels for display in the status bar.
  ///
  /// @param context Build context for accessing theme colors
  /// @returns Connection status information for visual display
  ConnectionStatusInfo _getConnectionStatusInfo(BuildContext context) {
    switch (connectionStatus) {
      case ConnectionStatus.connected:
        return ConnectionStatusInfo(
          color: const Color(0xFF10B981), // Green
          icon: Icons.check_circle,
          label: AppLocalizations.of(context)!.statusConnected,
        );

      case ConnectionStatus.degraded:
        return ConnectionStatusInfo(
          color: const Color(0xFFF59E0B), // Yellow/Orange
          icon: Icons.warning,
          label: AppLocalizations.of(context)!.statusDegraded,
        );

      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        return ConnectionStatusInfo(
          color: const Color(0xFFEF4444), // Red
          icon: Icons.error,
          label: AppLocalizations.of(context)!.statusDisconnected,
        );

      case ConnectionStatus.connecting:
        return ConnectionStatusInfo(
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.sync,
          label: AppLocalizations.of(context)!.statusConnecting,
        );
    }
  }
}
