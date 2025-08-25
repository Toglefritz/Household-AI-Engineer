part of 'sidebar_quick_actions.dart';

/// Expanded create button when sidebar is expanded.
///
/// Shows the full button with icon and label with enhanced animations.
class _ExpandedCreateButton extends StatelessWidget {
  /// Creates an expanded create button.
  const _ExpandedCreateButton({
    required this.openNewApplicationConversation,
    super.key,
  });

  /// A callback for when the button to create a new application is tapped.
  final VoidCallback openNewApplicationConversation;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: openNewApplicationConversation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.small,
          vertical: Insets.small,
        ),
        minimumSize: const Size(double.infinity, 40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, size: 18),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.buttonCreateNewApp),
        ],
      ),
    );
  }
}
