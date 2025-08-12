import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/insets.dart';
import '../../models/sidebar/sidebar_spacing.dart';

/// Search section component for the dashboard sidebar.
///
/// Provides search functionality in both expanded and collapsed sidebar states. In expanded state, shows a full
/// search input field. In collapsed state, shows a search icon button that maintains the same vertical space to
/// prevent layout shifts during state transitions.
class SidebarSearchSection extends StatelessWidget {
  /// Creates a sidebar search section widget.
  ///
  /// @param showExpandedContent Whether to show expanded content based on actual width
  const SidebarSearchSection({
    required this.showExpandedContent,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  /// When true, shows full search field. When false, shows search icon button.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.small),
      child: SizedBox(
        height: SidebarSpacing.sectionHeight,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: showExpandedContent
              ? const _ExpandedSearchField(key: ValueKey('expanded'))
              : const _CollapsedSearchButton(key: ValueKey('collapsed')),
        ),
      ),
    );
  }
}

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

/// Collapsed search button widget for when sidebar is collapsed.
///
/// Shows only a search icon button that maintains the same vertical space
/// as the expanded search field to prevent layout shifts. Includes tooltip
/// for accessibility and user guidance.
class _CollapsedSearchButton extends StatelessWidget {
  /// Creates a collapsed search button widget.
  const _CollapsedSearchButton({super.key});

  /// Handles search action when the collapsed search button is pressed.
  ///
  /// Shows a search overlay dialog that allows users to search for applications
  /// without expanding the sidebar. Provides proper focus management and
  /// keyboard navigation support.
  void _handleSearchAction(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => const _SearchOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: AppLocalizations.of(context)!.searchApplicationsHint,
        hint: 'Double tap to open search dialog',
        button: true,
        child: IconButton(
          onPressed: () => _handleSearchAction(context),
          icon: const Icon(Icons.search, size: 20),
          tooltip: AppLocalizations.of(context)!.searchApplicationsHint,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ),
    );
  }
}

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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Handles search submission when user presses enter or search button.
  ///
  /// Processes the search query and closes the overlay. In a full implementation,
  /// this would trigger application filtering and update the main dashboard view.
  void _handleSearchSubmit() {
    final String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // TODO: Implement actual search functionality
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for: $query'),
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
        label: 'Search applications dialog',
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                    tooltip: 'Clear search',
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
                        child: const Text('Search'),
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
}
