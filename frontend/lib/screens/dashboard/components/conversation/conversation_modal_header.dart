part of 'conversation_modal.dart';

/// Header for the ConversationModal with title, subtitle, and close button.
class ConversationModalHeader extends StatelessWidget {
  /// Creates an instance of [ConversationModalHeader].
  const ConversationModalHeader({
    required this.applicationToModify, required this.onClose, super.key,
  });

  /// The user application to modify.
  final UserApplication? applicationToModify;

  /// A callback for when the modal is closed.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String title = applicationToModify != null
        ? AppLocalizations.of(context)!
        .modifyApplication(applicationToModify!.title)
        : AppLocalizations.of(context)!.createNewApplication;

    return Container(
      padding: const EdgeInsets.all(Insets.medium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(right: Insets.small),
            child: Icon(
              applicationToModify != null ? Icons.edit : Icons.add,
              color: colorScheme.primary,
              size: 20,
            ),
          ),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!
                      .applicationCreationDescription,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: AppLocalizations.of(context)!.close,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
