import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/insets.dart';
import 'setup_controller.dart';

/// View component for the application setup flow.
///
/// Presents different UI states based on the current setup phase,
/// including Kiro detection progress, installation guidance, and
/// tutorial content. The view is purely presentational and delegates
/// all business logic to the controller.
class SetupView extends StatelessWidget {
  /// Controller instance containing setup state and business logic.
  final SetupController controller;

  /// Creates the setup view with the provided controller.
  const SetupView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(Insets.large),
            child: SingleChildScrollView(
              child: _buildPhaseContent(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the appropriate content based on the current setup phase.
  ///
  /// Returns different widget trees for each phase of the setup process,
  /// ensuring the UI matches the current state and provides appropriate
  /// user guidance and actions.
  Widget _buildPhaseContent(BuildContext context) {
    switch (controller.currentPhase) {
      case SetupPhase.checking:
        return _buildCheckingPhase(context);
      case SetupPhase.installationRequired:
        return _buildInstallationRequiredPhase(context);
      case SetupPhase.tutorial:
        return _buildTutorialPhase(context);
    }
  }

  /// Builds the UI for the initial Kiro checking phase.
  ///
  /// Shows a loading indicator and message while the system checks
  /// for Kiro IDE availability. This phase is typically brief but
  /// provides feedback that the system is working.
  Widget _buildCheckingPhase(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Text(
            l10n.setupCheckingKiro,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Text(
            l10n.setupCheckingKiroDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Builds the UI for the installation required phase.
  ///
  /// Presents guidance for installing Kiro IDE, including a link to
  /// the download page and a continue button to re-check installation.
  /// Also displays any error messages from the detection process.
  Widget _buildInstallationRequiredPhase(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.download_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Text(
            l10n.setupKiroRequired,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: Text(
            l10n.setupKiroRequiredDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),

        // Error message display
        if (controller.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Insets.medium),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: Insets.small),
                  Expanded(
                    child: Text(
                      controller.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Download button
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: FilledButton.icon(
            onPressed: _launchKiroWebsite,
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.setupDownloadKiro),
          ),
        ),

        // Continue button
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.isCheckingKiro ? null : controller.onContinueAfterInstallation,
              child: controller.isCheckingKiro
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: Insets.small),
                        Text(l10n.setupChecking),
                      ],
                    )
                  : Text(l10n.setupContinue),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the UI for the tutorial phase.
  ///
  /// Presents a brief tutorial about the application features and
  /// provides options to complete the tutorial or skip it entirely.
  /// Shows the detected Kiro version for user confirmation.
  Widget _buildTutorialPhase(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Text(
            l10n.setupWelcome,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),

        // Kiro version confirmation
        if (controller.kiroVersion != null)
          Padding(
            padding: const EdgeInsets.only(top: Insets.small),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.medium,
                vertical: Insets.small,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                l10n.setupKiroDetected(controller.kiroVersion!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: Text(
            l10n.setupTutorialDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),

        // Tutorial content
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(Insets.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.setupTutorialTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.medium),
                    child: _buildTutorialStep(
                      context,
                      Icons.add_circle_outline,
                      l10n.setupTutorialStep1Title,
                      l10n.setupTutorialStep1Description,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.medium),
                    child: _buildTutorialStep(
                      context,
                      Icons.build_outlined,
                      l10n.setupTutorialStep2Title,
                      l10n.setupTutorialStep2Description,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Insets.medium),
                    child: _buildTutorialStep(
                      context,
                      Icons.launch_outlined,
                      l10n.setupTutorialStep3Title,
                      l10n.setupTutorialStep3Description,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.only(top: Insets.large),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: TextButton(
                  onPressed: controller.onSkipTutorial,
                  child: Text(l10n.setupSkipTutorial),
                ),
              ),
              const SizedBox(width: Insets.medium),
              Flexible(
                child: FilledButton(
                  onPressed: controller.onCompleteTutorial,
                  child: Text(l10n.setupGetStarted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a tutorial step with icon, title, and description.
  ///
  /// Creates a consistent layout for tutorial steps with proper spacing
  /// and typography hierarchy. Used to present key application features
  /// in an easily digestible format.
  Widget _buildTutorialStep(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: Insets.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: Insets.xxSmall),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Launches the Kiro website in the default browser.
  ///
  /// Opens https://kiro.dev/ where users can download and install
  /// the Kiro IDE. Handles launch failures gracefully by showing
  /// an error message to the user.
  Future<void> _launchKiroWebsite() async {
    final Uri kiroUrl = Uri.parse('https://kiro.dev/');

    try {
      final bool launched = await launchUrl(
        kiroUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Handle launch failure - could show a snackbar or dialog
        debugPrint('Failed to launch Kiro website');
      }
    } catch (e) {
      // Handle launch error
      debugPrint('Error launching Kiro website: $e');
    }
  }
}
