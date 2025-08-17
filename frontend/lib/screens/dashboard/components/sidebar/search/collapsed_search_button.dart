part of 'sidebar_search.dart';

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
        hint: AppLocalizations.of(context)!.openSearchDialogHint,
        button: true,
        child: IconButton(
          onPressed: () => _handleSearchAction(context),
          icon: const Icon(Icons.search, size: 20),
          tooltip: AppLocalizations.of(context)!.searchApplicationsHint,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.all(Insets.xSmall),
          ),
        ),
      ),
    );
  }
}
