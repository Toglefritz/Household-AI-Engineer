part of 'sidebar_search.dart';

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
