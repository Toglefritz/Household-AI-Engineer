part of 'sidebar_quick_actions.dart';

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
    required this.openNewApplicationConversation,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  /// A callback for when the button to create a new application is tapped.
  final VoidCallback openNewApplicationConversation;

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
                    ? _ExpandedCreateButton(
                        key: const ValueKey('expanded'),
                        openNewApplicationConversation: openNewApplicationConversation,
                      )
                    : _CollapsedCreateButton(
                        key: const ValueKey('collapsed'),
                        openNewApplicationConversation: openNewApplicationConversation,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
