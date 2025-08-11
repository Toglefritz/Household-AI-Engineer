import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/insets.dart';
import 'dashboard_controller.dart';
import 'dashboard_route.dart';

/// View for [DashboardRoute].
///
/// View is dumb, and purely declarative.
class HomeView extends StatelessWidget {
  /// Creates an instance of [HomeView].
  const HomeView(this.state, {super.key});

  /// A controller for this view.
  final DashboardController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Insets.medium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.medium,
                ),
                child: Opacity(
                  opacity: 0.6,
                  child: Text(
                    '${AppLocalizations.of(context)!.greeting},',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.medium,
                ),
                child: Text(
                  AppLocalizations.of(context)!.welcomeMessage,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
