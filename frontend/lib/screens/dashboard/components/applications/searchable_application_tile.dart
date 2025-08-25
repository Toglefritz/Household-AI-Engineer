/// Searchable application tile with highlighting support.
///
/// This component extends the basic application tile with search result
/// highlighting capabilities. It displays search matches in the title
/// and description with visual highlighting to show users exactly
/// what matched their search query.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../services/search/models/search_result.dart';
import '../../../../services/user_application/models/application_status.dart';
import '../../../../services/user_application/models/user_application.dart';
import '../../../../theme/insets.dart';
import '../search/highlighted_text.dart';

/// A searchable application tile with highlighting support.
///
/// Extends the basic application tile functionality with search result
/// highlighting. When search matches are provided, highlights the matched
/// text in the title and description to show users what matched their query.
class SearchableApplicationTile extends StatefulWidget {
  /// Creates a searchable application tile widget.
  ///
  /// @param application The application data to display
  /// @param searchResult Optional search result with match information
  /// @param onTap Callback when the tile is tapped
  /// @param onSecondaryTap Callback when the tile is right-clicked
  /// @param isSelected Whether this tile is currently selected
  const SearchableApplicationTile({
    required this.application,
    this.searchResult,
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

  /// Optional search result with match information for highlighting.
  ///
  /// When provided, the tile will highlight matched text in the title
  /// and description. When null, displays as a regular tile without highlighting.
  final SearchResult? searchResult;

  /// Callback invoked when the user taps the tile.
  ///
  /// Typically used for launching the application or showing details.
  final VoidCallback? onTap;

  /// Callback invoked when the user right-clicks the tile.
  ///
  /// Used for showing context menus with application management options.
  final VoidCallback? onSecondaryTap;

  /// Whether this tile is currently selected.
  ///
  /// When true, displays selection styling to indicate it is part
  /// of a multi-selection or current focus.
  final bool isSelected;

  @override
  State<SearchableApplicationTile> createState() => _SearchableApplicationTileState();
}

/// State for the SearchableApplicationTile widget.
class _SearchableApplicationTileState extends State<SearchableApplicationTile> with SingleTickerProviderStateMixin {
  /// Whether the mouse is currently hovering over this tile.
  bool _isHovered = false;

  /// Animation controller for hover and selection effects.
  late AnimationController _animationController;

  /// Animation for scaling effects during hover and selection.
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handles mouse enter events for hover effects.
  void _onMouseEnter() {
    setState(() {
      _isHovered = true;
    });
    _animationController.forward();
  }

  /// Handles mouse exit events for hover effects.
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
        builder: (context, child) {
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

                      // Application title with highlighting
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.small),
                        child: _buildTitle(context, textTheme, colorScheme),
                      ),

                      // Application description with highlighting
                      Padding(
                        padding: const EdgeInsets.only(top: Insets.xxSmall),
                        child: _buildDescription(context, textTheme, colorScheme),
                      ),

                      const Spacer(),

                      // Progress indicator for developing applications
                      if (widget.application.isInDevelopment) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: Insets.xSmall),
                          child: _buildProgressIndicator(),
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

  /// Builds the application title with optional highlighting.
  ///
  /// If search results are available, highlights matched text in the title.
  /// Otherwise, displays the title as plain text.
  ///
  /// @param context Build context for theming
  /// @param textTheme Text theme for styling
  /// @param colorScheme Color scheme for styling
  /// @returns Widget displaying the application title
  Widget _buildTitle(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    final List<TextMatch> titleMatches = widget.searchResult?.getMatchesForField('title') ?? [];

    if (titleMatches.isNotEmpty) {
      return HighlightedTitle(
        title: widget.application.title,
        matches: titleMatches,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      );
    } else {
      return Text(
        widget.application.title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  /// Builds the application description with optional highlighting.
  ///
  /// If search results are available, highlights matched text in the description.
  /// Otherwise, displays the description as plain text.
  ///
  /// @param context Build context for theming
  /// @param textTheme Text theme for styling
  /// @param colorScheme Color scheme for styling
  /// @returns Widget displaying the application description
  Widget _buildDescription(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    final List<TextMatch> descriptionMatches = widget.searchResult?.getMatchesForField('description') ?? [];

    if (descriptionMatches.isNotEmpty) {
      return HighlightedDescription(
        description: widget.application.description,
        matches: descriptionMatches,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.tertiary,
        ),
      );
    } else {
      return Text(
        widget.application.description,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.tertiary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  /// Builds the status indicator widget based on application status.
  ///
  /// Returns appropriate visual indicators for each application state
  /// including colors, icons, and animations where applicable.
  Widget _buildStatusIndicator(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    const EdgeInsets containerPadding = EdgeInsets.symmetric(
      horizontal: Insets.xSmall,
      vertical: Insets.xxSmall,
    );
    const EdgeInsets iconPadding = EdgeInsets.only(right: Insets.xxSmall);
    const double iconSize = 12.0;

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

  /// Builds the progress indicator for developing applications.
  ///
  /// Shows a linear progress bar and phase text when the application
  /// is in development with available progress information.
  Widget _buildProgressIndicator() {
    final progress = widget.application.progress;
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
  /// Uses different icons based on application status to provide
  /// visual context about the current state.
  IconData _getApplicationIcon() {
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
}
