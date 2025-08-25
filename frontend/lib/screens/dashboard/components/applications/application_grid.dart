// This library groups widgets related to the grid of user applications.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/accessibility_helper.dart';
import '../../../../theme/insets.dart';
import 'application_tile.dart';
import 'bulk_selection_toolbar.dart';

// Parts
part 'application_grid_empty_state.dart';

/// A responsive grid widget for displaying application tiles.
///
/// Automatically adjusts the number of columns based on available width
/// while maintaining consistent tile sizing and spacing. Supports selection,
/// hover states, context menus, and full keyboard navigation for accessibility.
class ApplicationGrid extends StatefulWidget {
  /// Creates an application grid widget.
  ///
  /// @param applications List of applications to display
  /// @param onApplicationTap Callback when an application tile is tapped
  /// @param onApplicationSecondaryTap Callback when an application tile is right-clicked
  /// @param onCreateNewApplication Callback when the create new application button is tapped
  /// @param selectedApplicationIds Set of currently selected application IDs
  /// @param onSelectionChanged Callback when selection state changes
  /// @param onSelectAll Callback when select all is requested
  /// @param onSelectNone Callback when clear selection is requested
  /// @param onBulkDelete Callback when bulk delete is requested
  const ApplicationGrid({
    required this.applications,
    this.onApplicationTap,
    this.onApplicationSecondaryTap,
    this.onCreateNewApplication,
    this.selectedApplicationIds = const {},
    this.onSelectionChanged,
    this.onSelectAll,
    this.onSelectNone,
    this.onBulkDelete,
    super.key,
  });

  /// List of applications to display in the grid.
  ///
  /// Each application will be rendered as an individual tile
  /// with appropriate status indicators and metadata.
  final List<UserApplication> applications;

  /// Callback invoked when a user taps an application tile.
  ///
  /// Receives the tapped application as a parameter.
  /// Typically used for launching applications or showing details.
  final void Function(UserApplication application)? onApplicationTap;

  /// Callback invoked when a user right-clicks an application tile.
  ///
  /// Receives the right-clicked application as a parameter and the tap position.
  /// Used for showing context menus with management options.
  final void Function(UserApplication application, Offset position)? onApplicationSecondaryTap;

  /// Callback invoked when the create new application button is tapped.
  ///
  /// Used to open the conversational interface for creating new applications.
  final VoidCallback? onCreateNewApplication;

  /// Set of application IDs that are currently selected.
  ///
  /// Selected tiles will display selection styling to indicate
  /// they are part of a multi-selection or current focus.
  final Set<String> selectedApplicationIds;

  /// Callback invoked when an application's selection state changes.
  ///
  /// Receives the application and whether it should be selected.
  /// Used for multi-selection operations.
  final void Function(UserApplication application, {required bool isSelected})? onSelectionChanged;

  /// Callback invoked when select all is requested.
  ///
  /// Should select all applications in the current view.
  final VoidCallback? onSelectAll;

  /// Callback invoked when clear selection is requested.
  ///
  /// Should clear all current selections.
  final VoidCallback? onSelectNone;

  /// Callback invoked when bulk delete is requested.
  ///
  /// Receives the list of applications to delete.
  final void Function(List<UserApplication> applications)? onBulkDelete;

  @override
  State<ApplicationGrid> createState() => _ApplicationGridState();
}

/// State for the ApplicationGrid that manages keyboard navigation and focus.
class _ApplicationGridState extends State<ApplicationGrid> {
  /// Currently focused application index for keyboard navigation.
  int _focusedIndex = 0;

  /// Focus node for the grid container.
  late FocusNode _gridFocusNode;

  @override
  void initState() {
    super.initState();
    _gridFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _gridFocusNode.dispose();
    super.dispose();
  }

  /// Calculates the optimal number of columns based on available width.
  ///
  /// Uses responsive breakpoints to ensure tiles are appropriately sized
  /// across different screen sizes while maintaining readability.
  ///
  /// @param availableWidth Total width available for the grid
  /// @returns Optimal number of columns for the current screen size
  int _calculateCrossAxisCount(double availableWidth) {
    const double minTileWidth = 280.0; // Minimum width for readability
    const double spacing = Insets.small; // Spacing between tiles

    // Calculate how many tiles can fit with minimum width and spacing
    final int maxColumns = ((availableWidth + spacing) / (minTileWidth + spacing)).floor();

    // Apply responsive constraints for better UX
    if (availableWidth < 600) {
      return 1; // Single column on very narrow screens
    } else if (availableWidth < 900) {
      return 2; // Two columns on medium screens
    } else if (availableWidth < 1200) {
      return 3; // Three columns on larger screens
    } else {
      return maxColumns.clamp(1, 4); // Maximum 4 columns for readability
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    // If there are no applications, build a view communicating this to the user.
    if (widget.applications.isEmpty) {
      return AccessibilityHelper.createSemanticContainer(
        label: l10n.accessibilityEmptyState,
        hint: l10n.accessibilityEmptyStateHint,
        child: ApplicationGridEmptyState(
          onCreateNewApplication: widget.onCreateNewApplication,
        ),
      );
    }

    final List<UserApplication> selectedApps = widget.applications
        .where((app) => widget.selectedApplicationIds.contains(app.id))
        .toList();

    // Create semantic label and hint for the grid
    final String gridLabel = l10n.accessibilityApplicationGrid;
    final String gridHint = l10n.accessibilityApplicationGridHint(widget.applications.length);

    return AccessibilityHelper.createSemanticContainer(
      label: gridLabel,
      hint: gridHint,
      child: Focus(
        focusNode: _gridFocusNode,
        onKeyEvent: _handleGridKeyEvent,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int crossAxisCount = _calculateCrossAxisCount(
                  constraints.maxWidth,
                );

                return GridView.builder(
                  padding: EdgeInsets.only(
                    left: Insets.small,
                    right: Insets.small,
                    top: Insets.small,
                    bottom: selectedApps.isNotEmpty ? 100 : Insets.small,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: Insets.small,
                    mainAxisSpacing: Insets.small,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: widget.applications.length,
                  itemBuilder: (BuildContext context, int index) {
                    final UserApplication application = widget.applications[index];
                    final bool isSelected = widget.selectedApplicationIds.contains(
                      application.id,
                    );
                    final bool isFocused = index == _focusedIndex;

                    return AccessibilityHelper.createFocusTraversalOrder(
                      order: index.toDouble(),
                      child: GestureDetector(
                        onTap: () => _handleTileTap(application),
                        onSecondaryTapDown: (TapDownDetails details) => _handleSecondaryTap(application, details),
                        onLongPress: () => _handleLongPress(application),
                        child: ApplicationTile(
                          application: application,
                          isSelected: isSelected || isFocused,
                          onTap: () => _handleTileTap(application),
                          onSecondaryTap: () => _handleSecondaryTap(
                            application,
                            TapDownDetails(globalPosition: Offset.zero),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Bulk selection toolbar
            if (selectedApps.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AccessibilityHelper.createSemanticContainer(
                  label: l10n.accessibilityBulkSelectionToolbar,
                  hint: l10n.accessibilityBulkSelectionToolbarHint(selectedApps.length),
                  child: BulkSelectionToolbar(
                    selectedApplications: selectedApps,
                    totalApplications: widget.applications.length,
                    onSelectAll: widget.onSelectAll,
                    onSelectNone: widget.onSelectNone,
                    onBulkDelete: widget.onBulkDelete,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Handles keyboard navigation for the grid.
  ///
  /// Processes keyboard events to enable arrow key navigation between
  /// application tiles and keyboard activation of tiles.
  ///
  /// @param node The focus node that received the key event
  /// @param event The keyboard event to process
  /// @returns KeyEventResult indicating if the event was handled
  KeyEventResult _handleGridKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.applications.isEmpty) {
      return KeyEventResult.ignored;
    }

    // Calculate cross axis count for current layout
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return KeyEventResult.ignored;

    final double availableWidth = renderBox.size.width;
    final int crossAxisCount = _calculateCrossAxisCount(availableWidth);

    // Handle grid navigation
    final bool handled = AccessibilityHelper.handleGridKeyNavigation(
      event: event,
      currentIndex: _focusedIndex,
      itemCount: widget.applications.length,
      crossAxisCount: crossAxisCount,
      onIndexChanged: (int newIndex) {
        setState(() {
          _focusedIndex = newIndex;
        });

        // Announce the focused application to screen readers
        final UserApplication focusedApp = widget.applications[newIndex];
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        final String announcement = l10n.accessibilityApplicationTile(focusedApp.title);
        AccessibilityHelper.announceToScreenReader(announcement, context);
      },
    );

    if (handled) return KeyEventResult.handled;

    // Handle activation keys
    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        if (_focusedIndex < widget.applications.length) {
          _handleTileTap(widget.applications[_focusedIndex]);
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.contextMenu:
        if (_focusedIndex < widget.applications.length) {
          _handleSecondaryTap(
            widget.applications[_focusedIndex],
            TapDownDetails(globalPosition: Offset.zero),
          );
          return KeyEventResult.handled;
        }
        break;
    }

    return KeyEventResult.ignored;
  }

  /// Handles tile tap events with multi-selection support.
  ///
  /// If Ctrl/Cmd is held, toggles selection. Otherwise, performs normal tap action.
  ///
  /// @param application The application that was tapped
  void _handleTileTap(UserApplication application) {
    // Update focused index to match the tapped application
    final int tappedIndex = widget.applications.indexOf(application);
    if (tappedIndex >= 0) {
      setState(() {
        _focusedIndex = tappedIndex;
      });
    }

    // Check if Ctrl (Windows/Linux) or Cmd (macOS) is pressed
    final bool isMultiSelectModifier =
        HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    if (isMultiSelectModifier && widget.onSelectionChanged != null) {
      // Toggle selection
      final bool isSelected = widget.selectedApplicationIds.contains(application.id);
      widget.onSelectionChanged!(application, isSelected: !isSelected);
    } else if (widget.selectedApplicationIds.isNotEmpty && widget.onSelectNone != null) {
      // Clear selection if any items are selected
      widget.onSelectNone!();
    } else if (widget.onApplicationTap != null) {
      // Normal tap action
      widget.onApplicationTap?.call(application);
    }
  }

  /// Handles secondary tap (right-click) events.
  ///
  /// Shows context menu at the tap position.
  ///
  /// @param application The application that was right-clicked
  /// @param details Tap details containing position information
  void _handleSecondaryTap(UserApplication application, TapDownDetails details) {
    // Update focused index to match the right-clicked application
    final int tappedIndex = widget.applications.indexOf(application);
    if (tappedIndex >= 0) {
      setState(() {
        _focusedIndex = tappedIndex;
      });
    }

    if (widget.onApplicationSecondaryTap != null) {
      widget.onApplicationSecondaryTap?.call(application, details.globalPosition);
    }
  }

  /// Handles long press events for mobile selection.
  ///
  /// Toggles selection state on long press for touch devices.
  ///
  /// @param application The application that was long-pressed
  void _handleLongPress(UserApplication application) {
    // Update focused index to match the long-pressed application
    final int tappedIndex = widget.applications.indexOf(application);
    if (tappedIndex >= 0) {
      setState(() {
        _focusedIndex = tappedIndex;
      });
    }

    if (widget.onSelectionChanged != null) {
      final bool isSelected = widget.selectedApplicationIds.contains(application.id);
      widget.onSelectionChanged!(application, isSelected: !isSelected);
    }
  }
}
