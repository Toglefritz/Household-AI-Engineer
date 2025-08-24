import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';

/// Right section component for the status bar.
///
/// Contains action buttons, settings access, and other controls that users might need quick access to from anywhere in
/// the application.
class StatusBarRightSection extends StatelessWidget {
  /// Creates a status bar right section widget.
  const StatusBarRightSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Settings button
        IconButton(
          onPressed: () {
            // TODO(Toglefritz): Implement settings functionality
          },
          icon: const Icon(Icons.settings, size: 18),
          tooltip: AppLocalizations.of(context)!.tooltipSettings,
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            padding: const EdgeInsets.all(6),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: Insets.xSmall),
          child: IconButton(
            onPressed: () {
              // TODO(Toglefritz): Implement notifications functionality
            },
            icon: const Icon(Icons.notifications_outlined, size: 18),
            tooltip: AppLocalizations.of(context)!.tooltipNotifications,
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(6),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: Insets.xSmall),
          child: IconButton(
            onPressed: () {
              // TODO(Toglefritz): Implement user profile functionality
            },
            icon: const Icon(Icons.account_circle_outlined, size: 18),
            tooltip: AppLocalizations.of(context)!.tooltipUserProfile,
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(6),
            ),
          ),
        ),
      ],
    );
  }
}
