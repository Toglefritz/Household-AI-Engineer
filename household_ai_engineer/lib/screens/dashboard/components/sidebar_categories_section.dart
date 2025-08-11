import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/insets.dart';
import 'sidebar_category_item.dart';

/// Categories section component for the dashboard sidebar.
///
/// Displays application categories and tags for filtering and organization. Only shown when sidebar is expanded to 
/// provide sufficient space for category labels.
class SidebarCategoriesSection extends StatelessWidget {
  /// Creates a sidebar categories section widget.
  ///
  /// @param showExpandedContent Whether to show expanded content based on actual width
  const SidebarCategoriesSection({
    required this.showExpandedContent,
    super.key,
  });

  /// Whether to show expanded content based on actual width during animation.
  ///
  /// Prevents content from appearing/disappearing abruptly during transitions.
  final bool showExpandedContent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: Insets.medium),
          ),
          Text(
            AppLocalizations.of(context)!.categoriesTitle,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: Insets.xSmall),
          ),

          // Category items
          SidebarCategoryItem(
            icon: Icons.home,
            label: AppLocalizations.of(context)!.categoryHomeManagement,
            count: 5,
            showExpandedContent: showExpandedContent,
          ),
          SidebarCategoryItem(
            icon: Icons.calculate,
            label: AppLocalizations.of(context)!.categoryFinance,
            count: 2,
            showExpandedContent: showExpandedContent,
          ),
          SidebarCategoryItem(
            icon: Icons.calendar_today,
            label: AppLocalizations.of(context)!.categoryPlanning,
            count: 3,
            showExpandedContent: showExpandedContent,
          ),
          SidebarCategoryItem(
            icon: Icons.fitness_center,
            label: AppLocalizations.of(context)!.categoryHealthFitness,
            count: 1,
            showExpandedContent: showExpandedContent,
          ),
          SidebarCategoryItem(
            icon: Icons.school,
            label: AppLocalizations.of(context)!.categoryEducation,
            count: 2,
            showExpandedContent: showExpandedContent,
          ),
        ],
      ),
    );
  }
}
