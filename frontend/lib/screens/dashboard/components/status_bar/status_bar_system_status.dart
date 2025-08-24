import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_application/models/application_status.dart';
import '../../../../services/user_application/models/user_application.dart';

/// System status text component for the status bar.
///
/// Displays supplementary system information like available applications and background processes.
/// Shows the count of applications that are ready to launch versus those currently in development.
class StatusBarSystemStatus extends StatelessWidget {
  /// Creates a status bar system status widget.
  ///
  /// @param applications List of all user applications to analyze for status counts
  const StatusBarSystemStatus({
    required this.applications,
    super.key,
  });

  /// List of all user applications to analyze for status display.
  ///
  /// Used to calculate the number of available applications (ready or running)
  /// and applications currently in development (developing, testing, updating).
  final List<UserApplication> applications;

  @override
  Widget build(BuildContext context) {
    // Calculate available applications (ready to launch or already running)
    final int availableApps = applications.where((UserApplication app) {
      return app.status == ApplicationStatus.ready ||
          app.status == ApplicationStatus.running;
    }).length;

    // Calculate developing applications (actively being worked on)
    final int developingApps = applications.where((UserApplication app) {
      return app.status.isActive;
    }).length;

    return Text(
      AppLocalizations.of(
        context,
      )!.systemStatusAvailableDeveloping(availableApps, developingApps),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}
