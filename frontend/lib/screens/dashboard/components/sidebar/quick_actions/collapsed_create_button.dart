part of 'sidebar_quick_actions.dart';

/// Collapsed create button when sidebar is collapsed.
///
/// Shows only the icon in a compact button format.
class _CollapsedCreateButton extends StatelessWidget {
  /// Creates a collapsed create button.
  const _CollapsedCreateButton({
    required this.openNewApplicationConversation,
    super.key,
  });

  /// A callback for when the button to create a new application is tapped.
  final VoidCallback openNewApplicationConversation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: openNewApplicationConversation,
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
