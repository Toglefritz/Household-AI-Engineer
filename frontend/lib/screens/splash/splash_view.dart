import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/insets.dart';
import 'splash_controller.dart';

/// View component for the application splash screen.
///
/// Displays the application logo, loading indicator, and handles
/// initialization error states. The view provides a branded
/// introduction to the application while startup processes complete.
class SplashView extends StatelessWidget {
  /// Controller instance containing splash state and business logic.
  final SplashController controller;

  /// Creates the splash view with the provided controller.
  const SplashView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(Insets.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(context),
              Padding(
                padding: const EdgeInsets.only(top: Insets.large),
                child: _buildContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the application logo and branding section.
  ///
  /// Displays the application icon and title with appropriate
  /// styling and spacing for the splash screen presentation.
  Widget _buildLogo(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.home_work_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Text(
            l10n.splashTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Text(
            l10n.splashSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Builds the main content area based on initialization state.
  ///
  /// Shows different content depending on whether initialization
  /// is in progress, completed successfully, or encountered an error.
  Widget _buildContent(BuildContext context) {
    if (controller.initializationError != null) {
      return _buildErrorContent(context);
    } else if (controller.isInitializing) {
      return _buildLoadingContent(context);
    } else {
      // This state should not normally be reached as navigation
      // should occur before initialization completes
      return _buildLoadingContent(context);
    }
  }

  /// Builds the loading content shown during initialization.
  ///
  /// Displays a progress indicator and loading message while
  /// the application performs startup tasks.
  Widget _buildLoadingContent(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const CircularProgressIndicator(),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Text(
            l10n.splashInitializing,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Builds the error content shown when initialization fails.
  ///
  /// Displays the error message and provides options for the user
  /// to retry initialization or proceed to setup manually.
  Widget _buildErrorContent(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Text(
            l10n.splashInitializationFailed,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Container(
            padding: const EdgeInsets.all(Insets.medium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              controller.initializationError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: controller.onForceSetup,
                child: Text(l10n.splashForceSetup),
              ),
              Padding(
                padding: const EdgeInsets.only(left: Insets.medium),
                child: FilledButton(
                  onPressed: controller.onRetryInitialization,
                  child: Text(l10n.splashRetry),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
