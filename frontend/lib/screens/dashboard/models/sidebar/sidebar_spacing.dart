/// Spacing constants and components for the dashboard sidebar.
///
/// Provides consistent spacing values and reusable spacing widgets to maintain
/// visual rhythm and prevent layout shifts during sidebar state transitions.
class SidebarSpacing {
  /// Height of major sections like search and quick actions.
  ///
  /// Used to maintain consistent vertical space allocation regardless of
  /// sidebar expansion state.
  static const double sectionHeight = 56.0;

  /// Height of individual category items.
  ///
  /// Ensures consistent spacing for category list items in both expanded
  /// and collapsed states.
  static const double categoryItemHeight = 40.0;

  /// Height of section headers like "Categories".
  ///
  /// Maintains consistent space allocation for section titles and their
  /// collapsed state equivalents.
  static const double headerHeight = 24.0;
}
