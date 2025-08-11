import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// System status text component for the status bar.
///
/// Displays supplementary system information like active applications, background processes, or other relevant status
/// details.
class StatusBarSystemStatus extends StatelessWidget {
  /// Creates a status bar system status widget.
  const StatusBarSystemStatus({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(Toglefritz): Replace with actual system status data
    const int activeApps = 3;
    const int developingApps = 1;

    return Text(
      AppLocalizations.of(context)!.systemStatusRunningDeveloping(activeApps, developingApps),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}
