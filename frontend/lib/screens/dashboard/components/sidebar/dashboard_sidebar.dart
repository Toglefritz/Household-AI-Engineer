import 'package:flutter/material.dart';

import 'navigation/sidebar_navigation_content.dart';
import 'sidebar_header.dart';

/// Sidebar component for the main dashboard interface.
///
/// Provides navigation, filtering, and organization tools for managing household applications.
/// Supports both expanded and collapsed states with smooth two-stage animations that prevent
/// overflow errors and text wrapping issues.
///
/// ## Architecture
///
/// The sidebar uses a **state-aware rendering** approach where all components remain present
/// in both expanded and collapsed states, adapting their visual representation rather than
/// appearing/disappearing. This prevents jarring layout shifts during state transitions.
///
/// ## Two-Stage Animation System
///
/// To prevent overflow errors and text wrapping during transitions, the sidebar uses a
/// two-stage animation approach with different sequences for each direction:
///
/// **Expanding (Collapsed → Expanded)**:
/// - Stage 1: Width expands from 76px to 280px (200ms)
/// - Stage 2: Content transitions from icons to full elements (150ms)
/// - Prevents content from appearing cramped in narrow space
///
/// **Collapsing (Expanded → Collapsed)**:
/// - Stage 1: Content transitions from full elements to icons (150ms)
/// - Stage 2: Width collapses from 280px to 76px (200ms)
/// - Prevents overflow and text wrapping during width reduction
///
/// ## Features
///
/// * **Search functionality**: Full search field (expanded) or search icon with overlay (collapsed)
/// * **Navigation items**: Application filters with icons and labels (expanded) or icons only (collapsed)
/// * **Category organization**: Application categories with counts (expanded) or icons with tooltips (collapsed)
/// * **Quick actions**: Create new app button with full text (expanded) or icon only (collapsed)
/// * **Two-stage animations**: Content transitions first, then width, preventing overflow
/// * **Accessibility support**: Comprehensive semantic labels, tooltips, and keyboard navigation
/// * **Consistent spacing**: Fixed heights and spacing prevent layout shifts
/// * **macOS-style design**: Proper spacing, typography, and visual hierarchy
///
/// ## State Management
///
/// The sidebar manages its expansion state through the `isExpanded` boolean parameter.
/// Internally, it uses `_SidebarAnimationController` to coordinate the two-stage animation
/// and determine when to show expanded vs collapsed content.
///
/// ## Animation Timing
///
/// * **Content transition**: 100ms fade transition
/// * **Width transition**: 150ms width animation
/// * **Stage delay**: 50ms between stages
/// * **Total duration**: ~300ms for complete transition (both directions)
///
/// ## Accessibility
///
/// Provides comprehensive accessibility support including:
/// * Semantic labels for all interactive elements
/// * Tooltips for collapsed state elements
/// * Proper focus management during state transitions
/// * Screen reader compatibility
/// * Keyboard navigation support
class DashboardSidebar extends StatefulWidget {
  /// Creates a dashboard sidebar widget.
  ///
  /// @param isExpanded Whether the sidebar should show full content or icons only
  /// @param onToggle Callback function when the user toggles sidebar state
  const DashboardSidebar({
    required this.isExpanded,
    required this.onToggle,
    required this.openNewApplicationConversation,
    super.key,
  });

  /// Whether the sidebar is currently expanded to show full content.
  ///
  /// When true, shows full labels and expanded interface elements. When false, shows only icons and minimal interface
  /// for space saving.
  final bool isExpanded;

  /// Callback function invoked when the user toggles the sidebar state.
  ///
  /// Called when the user clicks the collapse/expand button or uses keyboard shortcuts to change sidebar visibility.
  final VoidCallback onToggle;

  /// A callback for when the button to create a new application is tapped.
  final VoidCallback openNewApplicationConversation;

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

/// State for the DashboardSidebar that manages two-stage animations.
///
/// Coordinates content transitions and width animations to prevent overflow
/// errors and text wrapping during sidebar state changes.
class _DashboardSidebarState extends State<DashboardSidebar> with TickerProviderStateMixin {
  /// Width of the sidebar when expanded to show full content.
  ///
  /// Provides enough space for navigation labels, search bar, and category listings while maintaining proper proportions.
  static const double _expandedWidth = 280.0;

  /// Width of the sidebar when collapsed to show only icons.
  ///
  /// Minimal width that still allows for recognizable icons and maintains visual hierarchy in the collapsed state.
  static const double _collapsedWidth = 76.0;

  /// Duration for content transition (stage 1).
  ///
  /// Content elements fade between expanded and collapsed states during this period.
  static const Duration _contentTransitionDuration = Duration(milliseconds: 100);

  /// Duration for width transition (stage 2).
  ///
  /// Sidebar width animates to final size after content has transitioned.
  static const Duration _widthTransitionDuration = Duration(milliseconds: 150);

  /// Delay before starting width transition.
  ///
  /// Allows content transition to complete before width animation begins.
  static const Duration _widthTransitionDelay = Duration(milliseconds: 50);

  /// Animation controller for content transitions.
  late AnimationController _contentController;

  /// Animation controller for width transitions.
  late AnimationController _widthController;

  /// Whether to show expanded content based on animation state.
  ///
  /// Determined by content animation controller rather than widget state
  /// to enable two-stage animation coordination.
  bool _showExpandedContent = true;

  /// Current width of the sidebar during animation.
  ///
  /// Interpolated between expanded and collapsed widths based on width
  /// animation controller progress.
  double _currentWidth = _expandedWidth;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _contentController = AnimationController(
      duration: _contentTransitionDuration,
      vsync: this,
    );

    _widthController = AnimationController(
      duration: _widthTransitionDuration,
      vsync: this,
    );

    // Set initial state based on widget state
    _showExpandedContent = widget.isExpanded;
    _currentWidth = widget.isExpanded ? _expandedWidth : _collapsedWidth;

    // Set animation controller values to match initial state
    if (widget.isExpanded) {
      _contentController.value = 1.0;
      _widthController.value = 1.0;
    } else {
      _contentController.value = 0.0;
      _widthController.value = 0.0;
    }

    // Listen to width animation to update current width
    _widthController.addListener(() {
      setState(() {
        _currentWidth = _collapsedWidth + (_expandedWidth - _collapsedWidth) * _widthController.value;
      });
    });
  }

  @override
  void didUpdateWidget(DashboardSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isExpanded != widget.isExpanded) {
      _animateToState(widget.isExpanded);
    }
  }

  /// Animates the sidebar to the specified expanded state.
  ///
  /// Coordinates two-stage animation with different sequences for expand vs collapse:
  /// - Expanding: width first, then content (prevents content appearing in narrow space)
  /// - Collapsing: content first, then width (prevents overflow and text wrapping)
  ///
  /// @param expanded Target expansion state
  Future<void> _animateToState(bool expanded) async {
    if (expanded) {
      // Expanding: width first, then content
      // Start width animation immediately
      await _widthController.forward();

      // Small delay to ensure width has expanded
      await Future<void>.delayed(_widthTransitionDelay);

      // Then show expanded content
      setState(() {
        _showExpandedContent = true;
      });

      // Animate content to expanded state
      await _contentController.forward();
    } else {
      // Collapsing: content first, then width
      setState(() {
        _showExpandedContent = false;
      });

      await _contentController.reverse();

      // Small delay to ensure content transition completes
      await Future<void>.delayed(_widthTransitionDelay);

      await _widthController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _currentWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: Column(
        children: [
          SidebarHeader(
            onToggle: widget.onToggle,
            isExpanded: widget.isExpanded,
            showExpandedContent: _showExpandedContent,
          ),
          const Divider(height: 1),
          Expanded(
            child: SidebarNavigationContent(
              showExpandedContent: _showExpandedContent,
                openNewApplicationConversation: widget.openNewApplicationConversation
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _widthController.dispose();
    super.dispose();
  }
}
