// This library groups widgets related to the application tiles.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/user_application/models/application_status.dart';
import '../../../../services/user_application/models/development_progress.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/insets.dart';

// Parts
part 'application_development_progress.dart';

/// A tile widget representing a single household application.
///
/// Displays application metadata including title, description, status,
/// and last updated time. Provides visual feedback for different application
/// states and supports user interactions like launching and context menus.
///
/// The tile adapts its appearance based on the application status:
/// * [ApplicationStatus.requested] - Shows queued indicator
/// * [ApplicationStatus.developing] - Shows progress indicator
/// * [ApplicationStatus.testing] - Shows testing indicator
/// * [ApplicationStatus.ready] - Shows ready to launch state
/// * [ApplicationStatus.running] - Shows active/running indicator
/// * [ApplicationStatus.failed] - Shows error state with retry option
/// * [ApplicationStatus.updating] - Shows updating indicator
class ApplicationTile extends StatefulWidget {
  /// Creates an application tile widget.
  ///
  /// @param application The application data to display
  /// @param onTap Callback when the tile is tapped (for launching)
  /// @param onSecondaryTap Callback when the tile is right-clicked (context menu)
  /// @param isSelected Whether this tile is currently selected
  const ApplicationTile({
    required this.application,
    this.onTap,
    this.onSecondaryTap,
    this.isSelected = false,
    super.key,
  });

  /// The application data to display in this tile.
  ///
  /// Contains all metadata needed for rendering including title,
  /// description, status, timestamps, and progress information.
  final UserApplication application;

  /// Callback invoked when the user taps the tile.
  ///
  /// Typically used for launching the application or showing details.
  /// May be null if the tile should not respond to tap gestures.
  final VoidCallback? onTap;

  /// Callback invoked when the user right-clicks or long-presses the tile.
  ///
  /// Used for showing context menus with application management options.
  /// May be null if context menus are not supported.
  final VoidCallback? onSecondaryTap;

  /// Whether this tile is currently selected.
  ///
  /// When true, the tile displays selection styling to indicate
  /// it is part of a multi-selection or current focus.
  final bool isSelected;

  @override
  State<ApplicationTile> createState() => _ApplicationTileState();
}

/// State for the [ApplicationTile] widget.
class _ApplicationTileState extends State<ApplicationTile> with TickerProviderStateMixin {
  /// Whether the mouse is currently hovering over this tile.
  ///
  /// Used to show hover effects and provide visual feedback
  /// for interactive elements.
  bool _isHovered = false;

  /// Animation controller for hover and selection effects.
  ///
  /// Provides smooth transitions between different visual states
  /// to enhance the user experience.
  late AnimationController _hoverController;

  /// Animation controller for press feedback.
  ///
  /// Provides immediate visual feedback when the tile is pressed.
  late AnimationController _pressController;

  /// Animation controller for success states.
  ///
  /// Used when applications complete development or launch successfully.
  late AnimationController _successController;

  /// Animation for scaling effects during hover and selection.
  ///
  /// Creates subtle scale changes that provide tactile feedback
  /// without being distracting.
  late Animation<double> _scaleAnimation;

  /// Animation for press feedback scaling.
  ///
  /// Provides quick scale-down effect when tile is pressed.
  late Animation<double> _pressAnimation;

  /// Animation for success celebration effects.
  ///
  /// Creates a brief highlight and scale effect for successful operations.
  late Animation<double> _successAnimation;

  /// Animation for shadow opacity during hover.
  ///
  /// Creates depth perception through shadow transitions.
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _scaleAnimation =
        Tween<double>(
          begin: 1.0,
          end: 1.03,
        ).animate(
          CurvedAnimation(
            parent: _hoverController,
            curve: Curves.easeInOut,
          ),
        );

    _pressAnimation =
        Tween<double>(
          begin: 1.0,
          end: 0.97,
        ).animate(
          CurvedAnimation(
            parent: _pressController,
            curve: Curves.easeInOut,
          ),
        );

    _successAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _successController,
            curve: Curves.elasticOut,
          ),
        );

    _shadowAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _hoverController,
            curve: Curves.easeInOut,
          ),
        );

    // Success animation is only triggered when status changes to ready,
    // not when the widget is initially created with ready status
  }

  @override
  void didUpdateWidget(ApplicationTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger success animation when status changes to ready
    if (oldWidget.application.status != ApplicationStatus.ready &&
        widget.application.status == ApplicationStatus.ready) {
      _triggerSuccessAnimation();
    }
  }

  /// Triggers the success animation for completed applications.
  ///
  /// Plays a brief celebration animation when applications complete
  /// development or other successful operations.
  void _triggerSuccessAnimation() {
    _successController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _successController.reverse();
        }
      });
    });
  }

  /// Handles mouse enter events for hover effects.
  ///
  /// Starts hover animations and updates the visual state
  /// to provide immediate feedback to the user.
  void _onMouseEnter() {
    setState(() {
      _isHovered = true;
    });
    _hoverController.forward();
  }

  /// Handles mouse exit events for hover effects.
  ///
  /// Stops hover animations and returns the tile to its
  /// default visual state.
  void _onMouseExit() {
    setState(() {
      _isHovered = false;
    });
    _hoverController.reverse();
    _pressController.reverse();
  }

  /// Handles tap down events for press feedback.
  ///
  /// Provides immediate visual feedback when the user starts pressing.
  void _onTapDown() {
    _pressController.forward();
  }

  /// Handles tap up events for press feedback.
  ///
  /// Returns the tile to normal state after press is released.
  void _onTapUp() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => _onMouseEnter(),
      onExit: (_) => _onMouseExit(),
      child: GestureDetector(
        onTapDown: (_) => _onTapDown(),
        onTapUp: (_) => _onTapUp(),
        onTapCancel: _onTapUp,
        onTap: widget.onTap,
        onSecondaryTap: widget.onSecondaryTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _pressAnimation,
            _successAnimation,
            _shadowAnimation,
          ]),
          builder: (BuildContext context, Widget? child) {
            // Calculate combined scale from hover and press animations
            double combinedScale = _scaleAnimation.value * _pressAnimation.value;

            // Add success animation scaling
            if (_successAnimation.value > 0) {
              combinedScale *= 1.0 + 0.05 * _successAnimation.value;
            }

            // Calculate border color based on state
            Color borderColor;
            if (widget.isSelected) {
              borderColor = colorScheme.primary;
            } else if (_successAnimation.value > 0) {
              borderColor = Color.lerp(
                colorScheme.outline,
                Colors.green,
                _successAnimation.value,
              )!;
            } else if (_isHovered) {
              borderColor =
                  Color.lerp(
                    colorScheme.outline,
                    colorScheme.primary.withValues(alpha: 0.6),
                    _hoverController.value,
                  ) ??
                  colorScheme.outline;
            } else {
              borderColor = colorScheme.outline;
            }

            // Calculate shadow based on hover and success states
            List<BoxShadow>? boxShadow;
            if (_isHovered || widget.isSelected || _successAnimation.value > 0) {
              // Base shadow values for hover and selection
              double shadowOpacity = 0.0;
              double shadowBlur = 0.0;
              double shadowSpread = 0.0;
              Color shadowColor = colorScheme.shadow;

              // Apply hover/selection shadow effects
              if (_isHovered || widget.isSelected) {
                shadowOpacity = 0.1 * _shadowAnimation.value;
                shadowBlur = 8.0 * _shadowAnimation.value;
                shadowSpread = 0.0;
              }

              // Apply success shadow effects (independent of hover state)
              if (_successAnimation.value > 0) {
                shadowOpacity = math.max(shadowOpacity, 0.2 * _successAnimation.value);
                shadowBlur = math.max(shadowBlur, 12.0 * _successAnimation.value);
                shadowSpread = math.max(shadowSpread, 2.0 * _successAnimation.value);
                shadowColor = Colors.green;
              }

              // Only create shadow if there are actual shadow effects
              if (shadowOpacity > 0) {
                boxShadow = [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: shadowOpacity),
                    blurRadius: shadowBlur,
                    spreadRadius: shadowSpread,
                    offset: const Offset(0, 4),
                  ),
                ];
              }
            }

            return Transform.scale(
              scale: combinedScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: boxShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Insets.small),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon and status indicator
                      Row(
                        children: [
                          // Application icon
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getApplicationIcon(),
                              color: colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),

                          const Spacer(),

                          // Status indicator
                          _buildStatusIndicator(context),
                        ],
                      ),

                      // Application title
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.small),
                        child: Text(
                          widget.application.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Application description
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.xxSmall),
                        child: Text(
                          widget.application.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const Spacer(),

                      // Progress indicator for developing applications
                      if (widget.application.isInDevelopment) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: Insets.xSmall),
                          child: ApplicationDevelopmentProgress(
                            progress: widget.application.progress,
                          ),
                        ),
                      ],

                      // Footer with timestamp
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.xSmall),
                        child: Text(
                          widget.application.updatedTimeDescription,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the status indicator widget based on application status.
  ///
  /// Returns appropriate visual indicators for each application state
  /// including colors, icons, and animations where applicable.
  /// All status indicators use consistent padding and spacing for visual uniformity.
  Widget _buildStatusIndicator(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Consistent padding and spacing for all status indicators
    const EdgeInsets containerPadding = EdgeInsets.symmetric(
      horizontal: Insets.xSmall,
      vertical: Insets.xxSmall,
    );
    const EdgeInsets iconPadding = EdgeInsets.only(right: Insets.xxSmall);
    const double iconSize = 12.0;

    // The widget returned depends upon the application status.
    switch (widget.application.status) {
      case ApplicationStatus.requested:
        return Container(
          padding: containerPadding,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: iconPadding,
                child: Icon(
                  Icons.schedule,
                  size: iconSize,
                  color: Colors.orange,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.queued,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );

      case ApplicationStatus.developing:
      case ApplicationStatus.testing:
      case ApplicationStatus.updating:
        return Container(
          padding: containerPadding,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: iconPadding,
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
              Text(
                widget.application.status.displayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        );

      case ApplicationStatus.ready:
        return Container(
          padding: containerPadding,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: iconPadding,
                child: Icon(
                  Icons.check_circle,
                  size: iconSize,
                  color: Colors.green,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.ready,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );

      case ApplicationStatus.running:
        return Container(
          padding: containerPadding,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: iconPadding,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.running,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        );

      case ApplicationStatus.failed:
        return Container(
          padding: containerPadding,
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: iconPadding,
                child: Icon(
                  Icons.error,
                  size: iconSize,
                  color: colorScheme.error,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.failed,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        );
    }
  }

  /// Returns the appropriate icon for the application.
  ///
  /// Uses a default icon for now, but could be extended to support
  /// custom icons based on application type or user preferences.
  IconData _getApplicationIcon() {
    // For now, use a default icon. In the future, this could be based on
    // application category, custom icons, or other metadata.
    switch (widget.application.status) {
      case ApplicationStatus.failed:
        return Icons.error_outline;
      case ApplicationStatus.running:
        return Icons.play_circle_filled;
      case ApplicationStatus.ready:
        return Icons.check_circle_outline;
      default:
        return Icons.apps;
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _successController.dispose();
    super.dispose();
  }
}
