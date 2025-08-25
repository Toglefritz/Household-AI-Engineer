/// Accessibility helper utilities for the Flutter dashboard.
///
/// Provides common accessibility functions, focus management utilities,
/// and semantic helpers to ensure consistent accessibility implementation
/// across all components.
///
/// This helper follows Flutter's accessibility best practices and provides
/// utilities for VoiceOver support, keyboard navigation, and focus management.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Helper class providing accessibility utilities and focus management.
///
/// Contains static methods for common accessibility operations including
/// focus management, semantic announcements, and keyboard navigation helpers.
class AccessibilityHelper {
  /// Private constructor to prevent instantiation.
  AccessibilityHelper._();

  /// Announces a message to screen readers.
  ///
  /// Uses Flutter's SemanticsService to announce important information
  /// to users with screen readers. Should be used sparingly for critical
  /// updates that users need to know about immediately.
  ///
  /// @param message The message to announce to screen readers
  /// @param context BuildContext for accessing the current route
  static void announceToScreenReader(String message, BuildContext context) {
    if (message.isNotEmpty) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  /// Requests focus for a specific widget.
  ///
  /// Safely requests focus for a widget using its FocusNode.
  /// Includes error handling to prevent crashes if the focus node
  /// is not properly initialized.
  ///
  /// @param focusNode The FocusNode to request focus for
  static void requestFocus(FocusNode? focusNode) {
    if (focusNode != null && focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
  }

  /// Moves focus to the next focusable widget.
  ///
  /// Uses Flutter's focus traversal system to move focus to the next
  /// widget in the tab order. Useful for custom keyboard navigation.
  ///
  /// @param context BuildContext for accessing the focus scope
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Moves focus to the previous focusable widget.
  ///
  /// Uses Flutter's focus traversal system to move focus to the previous
  /// widget in the tab order. Useful for custom keyboard navigation.
  ///
  /// @param context BuildContext for accessing the focus scope
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Unfocuses the currently focused widget.
  ///
  /// Removes focus from the currently focused widget, typically used
  /// when dismissing modals or completing interactions.
  ///
  /// @param context BuildContext for accessing the focus scope
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Creates a semantic widget with proper labeling and hints.
  ///
  /// Wraps a child widget with Semantics to provide proper accessibility
  /// information including labels, hints, and interaction descriptions.
  ///
  /// @param child The widget to wrap with semantic information
  /// @param label The semantic label describing what the widget is
  /// @param hint Optional hint describing how to interact with the widget
  /// @param button Whether this widget should be treated as a button
  /// @param enabled Whether this widget is currently enabled
  /// @param selected Whether this widget is currently selected
  /// @param onTap Optional callback for tap interactions
  /// @returns Widget wrapped with appropriate semantic information
  static Widget createSemanticWidget({
    required Widget child,
    required String label,
    String? hint,
    bool button = false,
    bool enabled = true,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      enabled: enabled,
      selected: selected,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates a semantic container for grouping related elements.
  ///
  /// Wraps multiple related widgets in a semantic container with
  /// appropriate labeling for screen readers. Useful for grouping
  /// related controls or content sections.
  ///
  /// @param child The widget(s) to wrap in a semantic container
  /// @param label The label describing the group of elements
  /// @param hint Optional hint describing the group's purpose
  /// @returns Widget wrapped with semantic container information
  static Widget createSemanticContainer({
    required Widget child,
    required String label,
    String? hint,
  }) {
    return Semantics(
      container: true,
      label: label,
      hint: hint,
      child: child,
    );
  }

  /// Checks if high contrast mode is enabled.
  ///
  /// Determines if the user has enabled high contrast mode in their
  /// system accessibility settings. Can be used to adjust UI elements
  /// for better visibility.
  ///
  /// @param context BuildContext for accessing media query
  /// @returns true if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Checks if large text is enabled.
  ///
  /// Determines if the user has enabled large text in their system
  /// accessibility settings. Can be used to adjust text sizes and
  /// layout spacing accordingly.
  ///
  /// @param context BuildContext for accessing media query
  /// @returns true if large text is enabled
  static bool isLargeTextEnabled(BuildContext context) {
    final double textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    return textScaleFactor > 1.3; // Consider 1.3x and above as "large text"
  }

  /// Gets the appropriate text scale factor for accessibility.
  ///
  /// Returns the current text scale factor from the system, which
  /// reflects the user's text size preferences in accessibility settings.
  ///
  /// @param context BuildContext for accessing media query
  /// @returns The current text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// Creates an accessible button with proper focus and semantic information.
  ///
  /// Wraps a button widget with proper focus management, semantic labeling,
  /// and keyboard interaction support. Provides consistent button behavior
  /// across the application.
  ///
  /// @param child The button content widget
  /// @param label The semantic label for the button
  /// @param hint Optional hint describing the button's action
  /// @param onPressed Callback when the button is pressed
  /// @param focusNode Optional focus node for focus management
  /// @param enabled Whether the button is currently enabled
  /// @returns Accessible button widget
  static Widget createAccessibleButton({
    required Widget child,
    required String label,
    String? hint,
    required VoidCallback? onPressed,
    FocusNode? focusNode,
    bool enabled = true,
  }) {
    return Focus(
      focusNode: focusNode,
      child: Semantics(
        label: label,
        hint: hint,
        button: true,
        enabled: enabled && onPressed != null,
        onTap: onPressed,
        child: child,
      ),
    );
  }

  /// Creates an accessible text field with proper focus and semantic information.
  ///
  /// Wraps a text field widget with proper focus management, semantic labeling,
  /// and keyboard interaction support. Provides consistent text field behavior
  /// across the application.
  ///
  /// @param child The text field widget
  /// @param label The semantic label for the text field
  /// @param hint Optional hint describing how to use the text field
  /// @param focusNode Optional focus node for focus management
  /// @param enabled Whether the text field is currently enabled
  /// @returns Accessible text field widget
  static Widget createAccessibleTextField({
    required Widget child,
    required String label,
    String? hint,
    FocusNode? focusNode,
    bool enabled = true,
  }) {
    return Focus(
      focusNode: focusNode,
      child: Semantics(
        label: label,
        hint: hint,
        textField: true,
        enabled: enabled,
        child: child,
      ),
    );
  }

  /// Handles keyboard navigation for grid layouts.
  ///
  /// Processes keyboard events for grid-based layouts, handling arrow key
  /// navigation to move focus between grid items. Supports both horizontal
  /// and vertical navigation.
  ///
  /// @param event The keyboard event to process
  /// @param currentIndex The currently focused item index
  /// @param itemCount Total number of items in the grid
  /// @param crossAxisCount Number of items per row
  /// @param onIndexChanged Callback when the focused index changes
  /// @returns true if the event was handled, false otherwise
  static bool handleGridKeyNavigation({
    required KeyEvent event,
    required int currentIndex,
    required int itemCount,
    required int crossAxisCount,
    required void Function(int newIndex) onIndexChanged,
  }) {
    if (event is! KeyDownEvent) return false;

    int newIndex = currentIndex;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (currentIndex % crossAxisCount > 0) {
          newIndex = currentIndex - 1;
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (currentIndex % crossAxisCount < crossAxisCount - 1 && currentIndex < itemCount - 1) {
          newIndex = currentIndex + 1;
        }
        break;
      case LogicalKeyboardKey.arrowUp:
        if (currentIndex >= crossAxisCount) {
          newIndex = currentIndex - crossAxisCount;
        }
        break;
      case LogicalKeyboardKey.arrowDown:
        if (currentIndex + crossAxisCount < itemCount) {
          newIndex = currentIndex + crossAxisCount;
        }
        break;
      default:
        return false;
    }

    if (newIndex != currentIndex) {
      onIndexChanged(newIndex);
      return true;
    }

    return false;
  }

  /// Creates a focus traversal order for a list of widgets.
  ///
  /// Generates a FocusTraversalOrder widget that defines the tab order
  /// for a group of widgets. Ensures consistent keyboard navigation
  /// throughout the application.
  ///
  /// @param order The numeric order for this widget in the traversal
  /// @param child The widget to include in the traversal order
  /// @returns Widget with defined focus traversal order
  static Widget createFocusTraversalOrder({
    required double order,
    required Widget child,
  }) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: child,
    );
  }

  /// Excludes a widget from focus traversal.
  ///
  /// Wraps a widget to exclude it from keyboard focus traversal.
  /// Useful for decorative elements or widgets that shouldn't receive focus.
  ///
  /// @param child The widget to exclude from focus traversal
  /// @returns Widget excluded from focus traversal
  static Widget excludeFromFocus(Widget child) {
    return ExcludeSemantics(
      child: child,
    );
  }

  /// Creates a semantic header widget.
  ///
  /// Wraps a widget to mark it as a header for screen readers.
  /// Helps users navigate through content structure.
  ///
  /// @param child The header widget
  /// @param level The header level (1-6, similar to HTML h1-h6)
  /// @returns Widget marked as a semantic header
  static Widget createSemanticHeader({
    required Widget child,
    int level = 1,
  }) {
    return Semantics(
      header: true,
      sortKey: const OrdinalSortKey(0),
      child: child,
    );
  }
}
