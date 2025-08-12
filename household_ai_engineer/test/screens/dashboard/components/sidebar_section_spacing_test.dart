import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_section_spacing.dart';
import 'package:household_ai_engineer/screens/dashboard/components/sidebar_spacing.dart';

/// Widget tests for the SidebarSectionSpacing component.
///
/// Verifies that the spacing widget renders correctly and maintains
/// consistent dimensions for visual hierarchy.
void main() {
  group('SidebarSectionSpacing', () {
    /// Verifies that the spacing widget renders without errors.
    ///
    /// Ensures the basic widget structure is valid and can be
    /// included in the widget tree.
    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SidebarSectionSpacing(),
          ),
        ),
      );

      expect(find.byType(SidebarSectionSpacing), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    /// Verifies that the spacing widget has the correct height.
    ///
    /// Ensures the widget maintains consistent spacing dimensions
    /// as defined in the SidebarSpacing constants.
    testWidgets('should have correct height from spacing constants', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SidebarSectionSpacing(),
          ),
        ),
      );

      final SizedBox sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.height, SidebarSpacing.sectionSpacing);
    });

    /// Verifies that multiple spacing widgets maintain consistent dimensions.
    ///
    /// Ensures that spacing remains uniform when multiple instances
    /// are used throughout the sidebar.
    testWidgets('should maintain consistent spacing across multiple instances', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SidebarSectionSpacing(),
                Text('Section 1'),
                SidebarSectionSpacing(),
                Text('Section 2'),
                SidebarSectionSpacing(),
              ],
            ),
          ),
        ),
      );

      final List<SizedBox> spacingWidgets = tester.widgetList<SizedBox>(find.byType(SizedBox)).toList();

      // All spacing widgets should have the same height
      for (final SizedBox widget in spacingWidgets) {
        expect(widget.height, SidebarSpacing.sectionSpacing);
      }
    });

    /// Verifies that the spacing widget integrates properly in a ListView.
    ///
    /// Ensures the spacing works correctly in the sidebar's scrollable
    /// content structure.
    testWidgets('should work correctly in ListView context', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                Text('Item 1'),
                SidebarSectionSpacing(),
                Text('Item 2'),
                SidebarSectionSpacing(),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SidebarSectionSpacing), findsNWidgets(2));
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });
  });
}
