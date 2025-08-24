/// Highlighted text component for search result display.
///
/// This component renders text with highlighted search matches,
/// providing visual feedback for search results and improving
/// the user experience by showing exactly what matched their query.

import 'package:flutter/material.dart';

import '../../../../services/search/models/search_result.dart';

/// Widget for displaying text with highlighted search matches.
///
/// Takes a text string and a list of text matches, then renders
/// the text with highlighted portions to show search results.
/// Supports customizable highlight styling and overflow handling.
class HighlightedText extends StatelessWidget {
  /// Creates a highlighted text widget.
  ///
  /// @param text The full text to display
  /// @param matches List of text matches to highlight
  /// @param style Base text style for non-highlighted text
  /// @param highlightStyle Style for highlighted text portions
  /// @param maxLines Maximum number of lines to display
  /// @param overflow How to handle text overflow
  const HighlightedText({
    required this.text,
    required this.matches,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
    super.key,
  });

  /// The full text to display with highlighting.
  ///
  /// This is the complete text content that will be rendered
  /// with highlighted portions based on the provided matches.
  final String text;

  /// List of text matches to highlight within the text.
  ///
  /// Each match contains position information for highlighting
  /// specific portions of the text. Matches should not overlap.
  final List<TextMatch> matches;

  /// Base text style for non-highlighted portions.
  ///
  /// Applied to all text that is not part of a highlighted match.
  /// If null, uses the default text style from the theme.
  final TextStyle? style;

  /// Text style for highlighted portions.
  ///
  /// Applied to text that matches the search query. If null,
  /// uses a default highlight style with background color.
  final TextStyle? highlightStyle;

  /// Maximum number of lines to display.
  ///
  /// If null, text can wrap to any number of lines.
  /// Used for controlling layout in constrained spaces.
  final int? maxLines;

  /// How to handle text overflow.
  ///
  /// Determines what happens when text exceeds the available space.
  /// Common values are TextOverflow.ellipsis and TextOverflow.fade.
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    // If no matches, display plain text
    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Build text spans with highlighting
    final List<TextSpan> spans = _buildTextSpans(context);

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  /// Builds a list of text spans with highlighting.
  ///
  /// Processes the text and matches to create a list of TextSpan objects
  /// that can be rendered with different styles for highlighted portions.
  ///
  /// @param context Build context for theming
  /// @returns List of text spans with appropriate styling
  List<TextSpan> _buildTextSpans(BuildContext context) {
    final List<TextSpan> spans = [];

    // Sort matches by start position to process in order
    final List<TextMatch> sortedMatches = List.from(matches);
    sortedMatches.sort((a, b) => a.start.compareTo(b.start));

    // Get default highlight style if not provided
    final TextStyle effectiveHighlightStyle = highlightStyle ?? _getDefaultHighlightStyle(context);
    final TextStyle effectiveBaseStyle = style ?? DefaultTextStyle.of(context).style;

    int currentPosition = 0;

    for (final TextMatch match in sortedMatches) {
      // Add non-highlighted text before this match
      if (match.start > currentPosition) {
        spans.add(
          TextSpan(
            text: text.substring(currentPosition, match.start),
            style: effectiveBaseStyle,
          ),
        );
      }

      // Add highlighted text for this match
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: effectiveHighlightStyle,
        ),
      );

      currentPosition = match.end;
    }

    // Add remaining non-highlighted text after the last match
    if (currentPosition < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentPosition),
          style: effectiveBaseStyle,
        ),
      );
    }

    return spans;
  }

  /// Gets the default highlight style for the current theme.
  ///
  /// Creates a highlight style with background color and appropriate
  /// text color based on the current theme colors.
  ///
  /// @param context Build context for accessing theme
  /// @returns Default highlight text style
  TextStyle _getDefaultHighlightStyle(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextStyle baseStyle = style ?? DefaultTextStyle.of(context).style;

    return baseStyle.copyWith(
      backgroundColor: colorScheme.primaryContainer,
      color: colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w600,
    );
  }
}

/// Widget for displaying application title with search highlighting.
///
/// Specialized version of HighlightedText optimized for application titles
/// with appropriate styling and truncation for tile display.
class HighlightedTitle extends StatelessWidget {
  /// Creates a highlighted title widget.
  ///
  /// @param title Application title text
  /// @param matches List of text matches in the title
  /// @param style Optional base text style
  const HighlightedTitle({
    required this.title,
    required this.matches,
    this.style,
    super.key,
  });

  /// Application title text to display.
  final String title;

  /// List of text matches to highlight in the title.
  final List<TextMatch> matches;

  /// Optional base text style for the title.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return HighlightedText(
      text: title,
      matches: matches,
      style:
          style ??
          Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Widget for displaying application description with search highlighting.
///
/// Specialized version of HighlightedText optimized for application descriptions
/// with appropriate styling and truncation for tile display.
class HighlightedDescription extends StatelessWidget {
  /// Creates a highlighted description widget.
  ///
  /// @param description Application description text
  /// @param matches List of text matches in the description
  /// @param style Optional base text style
  const HighlightedDescription({
    required this.description,
    required this.matches,
    this.style,
    super.key,
  });

  /// Application description text to display.
  final String description;

  /// List of text matches to highlight in the description.
  final List<TextMatch> matches;

  /// Optional base text style for the description.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return HighlightedText(
      text: description,
      matches: matches,
      style:
          style ??
          Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
