part of 'sidebar_search.dart';

/// Expanded search field widget for when sidebar is expanded.
///
/// Shows the full search input field with placeholder text and search icon.
/// Maintains consistent height to prevent layout shifts during transitions.
class _ExpandedSearchField extends StatefulWidget {
  /// Creates an expanded search field widget.
  const _ExpandedSearchField({
    required this.searchController,
    super.key,
  });

  /// Search controller for managing search state and operations.
  final search.ApplicationSearchController searchController;

  @override
  State<_ExpandedSearchField> createState() => _ExpandedSearchFieldState();
}

class _ExpandedSearchFieldState extends State<_ExpandedSearchField> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      onChanged: (query) {
        // Find the dashboard controller and update search
        final dashboardController = context.findAncestorStateOfType<DashboardController>();
        dashboardController?.searchController.updateSearchQuery(query);
      },
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchApplicationsHint,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: _textController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  _textController.clear();
                  final dashboardController = context.findAncestorStateOfType<DashboardController>();
                  dashboardController?.searchController.clearSearchQuery();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.small,
          vertical: Insets.xSmall,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
