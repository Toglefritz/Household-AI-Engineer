part of 'sidebar_search.dart';

/// Search overlay dialog for collapsed sidebar state.
///
/// Provides a full-screen search interface when the sidebar is collapsed
/// and the user clicks the search button. Includes proper focus management
/// and keyboard navigation support.
class _SearchOverlay extends StatefulWidget {
  /// Creates a search overlay dialog.
  const _SearchOverlay();

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

/// State for the search overlay dialog.
///
/// Manages the search text field focus and handles search interactions
/// with proper keyboard navigation and accessibility support.
class _SearchOverlayState extends State<_SearchOverlay> {
  /// Text editing controller for the search input field.
  ///
  /// Manages the search query text and provides access to the current
  /// search value for processing and filtering operations.
  late final TextEditingController _searchController;

  /// Focus node for the search input field.
  ///
  /// Manages keyboard focus and ensures the search field is automatically
  /// focused when the overlay opens for immediate user interaction.
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Auto-focus the search field when overlay opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  /// Handles search submission when user presses enter or search button.
  ///
  /// Processes the search query and closes the overlay. In a full implementation,
  /// this would trigger application filtering and update the main dashboard view.
  void _handleSearchSubmit() {
    final String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // TODO(Scott): Implement actual search functionality
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.searchingFor(query),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Semantics(
        label: AppLocalizations.of(context)!.searchApplicationsDialog,
        child: Container(
          margin: const EdgeInsets.all(Insets.medium),
          padding: const EdgeInsets.all(Insets.medium),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, Insets.xxSmall),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchApplicationsHint,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _searchFocusNode.requestFocus();
                    },
                    tooltip: AppLocalizations.of(context)!.clearSearch,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Insets.small,
                    vertical: Insets.xSmall,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                onSubmitted: (_) => _handleSearchSubmit(),
              ),

              Padding(
                padding: const EdgeInsets.only(top: Insets.small),

                // Action buttons
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppLocalizations.of(context)!.buttonCancel),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: Insets.xSmall),
                      child: ElevatedButton(
                        onPressed: _handleSearchSubmit,
                        child: Text(AppLocalizations.of(context)!.search),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }
}
