part of 'sidebar_search.dart';

/// Expanded search field widget for when sidebar is expanded.
///
/// Shows the full search input field with placeholder text and search icon.
/// Maintains consistent height to prevent layout shifts during transitions.
class _ExpandedSearchField extends StatelessWidget {
  /// Creates an expanded search field widget.
  const _ExpandedSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchApplicationsHint,
        prefixIcon: const Icon(Icons.search, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.small,
          vertical: Insets.xSmall,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
