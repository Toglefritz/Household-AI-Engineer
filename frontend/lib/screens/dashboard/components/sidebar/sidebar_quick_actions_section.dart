import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';

/// Quick actions section component for the dashboard sidebar.
///
/// Provides quick access to frequently used actions like creating new applications. Adapts display based on sidebar
/// expansion state.
class SidebarQuickActionsSection extends StatelessWidget {
  /// Creates a sidebar quick actions section widget.
  ///
  /// @param showExpandedContent Whether to show expanded content based on actual width
  const SidebarQuickActionsSection({
    required this.showExpandedContent,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Insets.small),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Insets.medium),
            // Create new app button with smooth transition
            child: SizedBox(
              width: double.infinity,
              height: 40, // Fixed height to prevent layout shifts
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: showExpandedContent
                    ? const _ExpandedCreateButton(key: ValueKey('expanded'))
                    : const _CollapsedCreateButton(key: ValueKey('collapsed')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expanded create button when sidebar is expanded.
///
/// Shows the full button with icon and label.
class _ExpandedCreateButton extends StatelessWidget {
  /// Creates an expanded create button.
  const _ExpandedCreateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO(Toglefritz): Implement create new app functionality
      },
      icon: const Icon(Icons.add, size: 18),
      label: Text(AppLocalizations.of(context)!.buttonCreateNewApp),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.small,
          vertical: Insets.small,
        ),
        minimumSize: const Size(double.infinity, 40),
      ),
    );
  }
}

/// Collapsed create button when sidebar is collapsed.
///
/// Shows only the icon in a compact button format.
class _CollapsedCreateButton extends StatelessWidget {
  /// Creates a collapsed create button.
  const _CollapsedCreateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // TODO(Toglefritz): Implement create new app functionality
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.all(Insets.xSmall),
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Icon(Icons.add, size: 18),
      ),
    );
  }
}
