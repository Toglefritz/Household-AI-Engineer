import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/models.dart';
import '../../../../theme/insets.dart';

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
class _ApplicationTileState extends State<ApplicationTile> with SingleTickerProviderStateMixin {
  /// Whether the mouse is currently hovering over this tile.
  ///
  /// Used to show hover effects and provide visual feedback
  /// for interactive elements.
  bool _isHovered = false;

  /// Animation controller for hover and selection effects.
  ///
  /// Provides smooth transitions between different visual states
  /// to enhance the user experience.
  late AnimationController _animationController;

  /// Animation for scaling effects during hover and selection.
  ///
  /// Creates subtle scale changes that provide tactile feedback
  /// without being distracting.
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation =
        Tween<double>(
          begin: 1.0,
          end: 1.02,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  /// Handles mouse enter events for hover effects.
  ///
  /// Starts hover animations and updates the visual state
  /// to provide immediate feedback to the user.
  void _onMouseEnter() {
    setState(() {
      _isHovered = true;
    });
    _animationController.forward();
  }

  /// Handles mouse exit events for hover effects.
  ///
  /// Stops hover animations and returns the tile to its
  /// default visual state.
  void _onMouseExit() {
    setState(() {
      _isHovered = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => _onMouseEnter(),
      onExit: (_) => _onMouseExit(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (BuildContext context, Widget? child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              onSecondaryTap: widget.onSecondaryTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isSelected
                        ? colorScheme.primary
                        : _isHovered
                        ? colorScheme.outline.withValues(alpha: 0.5)
                        : colorScheme.outline,
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: _isHovered || widget.isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
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
                          child: _buildProgressIndicator(context),
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
            ),
          );
        },
      ),
    );
  }

  /// Builds the status indicator widget based on application status.
  ///
  /// Returns appropriate visual indicators for each application state
  /// including colors, icons, and animations where applicable.
  Widget _buildStatusIndicator(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // The widget returned depends upon the application status.
    switch (widget.application.status) {
      case ApplicationStatus.requested:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.xSmall,
            vertical: Insets.xxSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: Insets.xxSmall),
                child: Icon(
                  Icons.schedule,
                  size: 12,
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
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.xSmall,
            vertical: Insets.xxSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: Insets.xxSmall),
                child: SizedBox(
                  width: 12,
                  height: 12,
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
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.small,
            vertical: Insets.xxSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: Insets.small),
                child: Icon(
                  Icons.check_circle,
                  size: 12,
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
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.xSmall,
            vertical: Insets.xxSmall,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: Insets.small),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
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
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.xSmall,
            vertical: Insets.xxSmall,
          ),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error,
                size: 12,
                color: colorScheme.error,
              ),
              const SizedBox(width: 4),
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

  /// Builds a progress indicator for applications in development.
  ///
  /// Shows development progress with percentage and current phase
  /// information when available.
  Widget _buildProgressIndicator(BuildContext context) {
    final DevelopmentProgress? progress = widget.application.progress;
    if (progress == null) {
      return const SizedBox.shrink();
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.percentage / 100,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
          ),
        ),

        // Progress text
        Padding(
          padding: const EdgeInsets.only(top: Insets.xxSmall),
          child: Text(
            '${progress.percentage.toInt()}% • ${progress.currentPhase}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.tertiary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
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
    _animationController.dispose();
    super.dispose();
  }
}
