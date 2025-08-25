/// Filter panel component for advanced filtering options.
///
/// This component provides comprehensive filtering capabilities including
/// category filters, status filters, date range selection, and filter
/// management. Integrates with the search controller for real-time
/// filter updates and state management.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_application/models/application_category.dart';
import '../../../../services/user_application/models/application_status.dart';
import '../../../../theme/insets.dart';
import 'search_controller.dart' as search;

/// Filter panel widget with comprehensive filtering options.
///
/// Provides category filters, status filters, date range selection,
/// and filter management controls. Integrates with SearchController
/// for real-time filter updates and state synchronization.
class FilterPanel extends StatefulWidget {
  /// Creates a filter panel widget.
  ///
  /// @param controller Search controller for managing filter state
  /// @param onFiltersChanged Optional callback when filters change
  const FilterPanel({
    required this.controller,
    this.onFiltersChanged,
    super.key,
  });

  /// Search controller for managing filter state and operations.
  ///
  /// Provides access to current filter criteria and methods
  /// for updating filter settings and clearing filters.
  final search.ApplicationSearchController controller;

  /// Optional callback invoked when filter criteria change.
  ///
  /// Called whenever any filter setting is modified.
  /// Useful for additional UI updates or analytics.
  final VoidCallback? onFiltersChanged;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

/// State for the FilterPanel widget.
///
/// Manages the expansion state of filter sections and handles
/// user interactions with filter controls.
class _FilterPanelState extends State<FilterPanel> {
  /// Whether the category filter section is expanded.
  bool _categoryExpanded = true;

  /// Whether the status filter section is expanded.
  bool _statusExpanded = true;

  /// Whether the date filter section is expanded.
  bool _dateExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(Insets.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter panel header
                _buildHeader(context),

                const SizedBox(height: Insets.medium),

                // Category filters
                _buildCategorySection(context),

                const SizedBox(height: Insets.medium),

                // Status filters
                _buildStatusSection(context),

                const SizedBox(height: Insets.medium),

                // Date range filters
                _buildDateSection(context),

                // Clear filters button
                if (widget.controller.hasActiveFilters) ...[
                  const SizedBox(height: Insets.medium),
                  _buildClearFiltersButton(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the filter panel header.
  ///
  /// Shows the panel title and active filter count.
  ///
  /// @param context Build context for theming
  /// @returns Widget for the filter panel header
  Widget _buildHeader(BuildContext context) {
    final int activeFilterCount = _getActiveFilterCount();

    return Row(
      children: [
        Icon(
          Icons.filter_list,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: Insets.small),
        Text(
          AppLocalizations.of(context)!.filters,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (activeFilterCount > 0) ...[
          const SizedBox(width: Insets.small),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.xSmall,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              activeFilterCount.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the category filter section.
  ///
  /// Shows available categories with checkboxes and application counts.
  ///
  /// @param context Build context for theming
  /// @returns Widget for the category filter section
  Widget _buildCategorySection(BuildContext context) {
    final Set<ApplicationCategory> availableCategories = widget.controller.getAvailableCategories();
    final Set<ApplicationCategory> selectedCategories = widget.controller.currentFilter.selectedCategories;

    return ExpansionTile(
      title: Text(
        AppLocalizations.of(context)!.categories,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      initiallyExpanded: _categoryExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _categoryExpanded = expanded;
        });
      },
      children: [
        ...availableCategories.map((category) {
          final bool isSelected = selectedCategories.contains(category);
          final int count = widget.controller.getCategoryCount(category);

          return CheckboxListTile(
            title: Text(category.displayName),
            subtitle: Text(
              AppLocalizations.of(context)!.applicationCount(count),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: isSelected,
            onChanged: (bool? value) {
              widget.controller.toggleCategory(category);
              widget.onFiltersChanged?.call();
            },
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: Insets.small),
          );
        }),
      ],
    );
  }

  /// Builds the status filter section.
  ///
  /// Shows available statuses with checkboxes and application counts.
  ///
  /// @param context Build context for theming
  /// @returns Widget for the status filter section
  Widget _buildStatusSection(BuildContext context) {
    final Set<ApplicationStatus> availableStatuses = widget.controller.getAvailableStatuses();
    final Set<ApplicationStatus> selectedStatuses = widget.controller.currentFilter.selectedStatuses;

    return ExpansionTile(
      title: Text(
        AppLocalizations.of(context)!.status,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      initiallyExpanded: _statusExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _statusExpanded = expanded;
        });
      },
      children: [
        ...availableStatuses.map((status) {
          final bool isSelected = selectedStatuses.contains(status);
          final int count = widget.controller.getStatusCount(status);

          return CheckboxListTile(
            title: Row(
              children: [
                Icon(
                  status.icon,
                  size: 16,
                  color: status.color,
                ),
                const SizedBox(width: Insets.small),
                Text(status.displayName),
              ],
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.applicationCount(count),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: isSelected,
            onChanged: (bool? value) {
              widget.controller.toggleStatus(status);
              widget.onFiltersChanged?.call();
            },
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: Insets.small),
          );
        }),
      ],
    );
  }

  /// Builds the date range filter section.
  ///
  /// Shows date range selection controls for filtering by creation date.
  ///
  /// @param context Build context for theming
  /// @returns Widget for the date filter section
  Widget _buildDateSection(BuildContext context) {
    final DateTime? startDate = widget.controller.currentFilter.dateRangeStart;
    final DateTime? endDate = widget.controller.currentFilter.dateRangeEnd;

    return ExpansionTile(
      title: Text(
        AppLocalizations.of(context)!.dateRange,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      initiallyExpanded: _dateExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _dateExpanded = expanded;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.medium),
          child: Column(
            children: [
              // Start date picker
              ListTile(
                title: Text(AppLocalizations.of(context)!.startDate),
                subtitle: Text(
                  startDate != null ? _formatDate(startDate) : AppLocalizations.of(context)!.noDateSelected,
                ),
                trailing: startDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          widget.controller.updateDateRange(null, endDate);
                          widget.onFiltersChanged?.call();
                        },
                      )
                    : null,
                onTap: () => _selectStartDate(context),
                dense: true,
              ),

              // End date picker
              ListTile(
                title: Text(AppLocalizations.of(context)!.endDate),
                subtitle: Text(
                  endDate != null ? _formatDate(endDate) : AppLocalizations.of(context)!.noDateSelected,
                ),
                trailing: endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          widget.controller.updateDateRange(startDate, null);
                          widget.onFiltersChanged?.call();
                        },
                      )
                    : null,
                onTap: () => _selectEndDate(context),
                dense: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the clear filters button.
  ///
  /// Shows a button to clear all active filters when filters are applied.
  ///
  /// @param context Build context for theming
  /// @returns Widget for the clear filters button
  Widget _buildClearFiltersButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          widget.controller.clearAllFilters();
          widget.onFiltersChanged?.call();
        },
        icon: const Icon(Icons.clear_all),
        label: Text(AppLocalizations.of(context)!.clearAllFilters),
      ),
    );
  }

  /// Selects a start date using a date picker.
  ///
  /// Shows a date picker dialog and updates the filter with the selected date.
  ///
  /// @param context Build context for showing the dialog
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.controller.currentFilter.dateRangeStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      widget.controller.updateDateRange(
        picked,
        widget.controller.currentFilter.dateRangeEnd,
      );
      widget.onFiltersChanged?.call();
    }
  }

  /// Selects an end date using a date picker.
  ///
  /// Shows a date picker dialog and updates the filter with the selected date.
  ///
  /// @param context Build context for showing the dialog
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.controller.currentFilter.dateRangeEnd ?? DateTime.now(),
      firstDate: widget.controller.currentFilter.dateRangeStart ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      widget.controller.updateDateRange(
        widget.controller.currentFilter.dateRangeStart,
        picked,
      );
      widget.onFiltersChanged?.call();
    }
  }

  /// Formats a date for display.
  ///
  /// @param date Date to format
  /// @returns Formatted date string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Gets the count of active filters.
  ///
  /// @returns Number of active filter criteria
  int _getActiveFilterCount() {
    int count = 0;
    final filter = widget.controller.currentFilter;

    if (filter.selectedCategories.isNotEmpty) count++;
    if (filter.selectedStatuses.isNotEmpty) count++;
    if (filter.dateRangeStart != null || filter.dateRangeEnd != null) count++;

    return count;
  }
}
