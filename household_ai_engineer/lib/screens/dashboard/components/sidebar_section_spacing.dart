import 'package:flutter/material.dart';
import 'sidebar_spacing.dart';

/// Consistent vertical spacing widget for separating sidebar sections.
///
/// Provides uniform spacing between major sidebar sections (navigation,
/// categories, quick actions) to maintain visual rhythm and hierarchy.
/// Used instead of conditional margins to ensure consistent spacing
/// regardless of sidebar expansion state.
class SidebarSectionSpacing extends StatelessWidget {
  /// Creates a section spacing widget with standard height.
  const SidebarSectionSpacing({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: SidebarSpacing.sectionSpacing);
  }
}
