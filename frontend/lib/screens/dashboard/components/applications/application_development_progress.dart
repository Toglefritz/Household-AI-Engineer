part of 'application_tile.dart';

/// Displays development progress with a linear progress bar and phase text.
class ApplicationDevelopmentProgress extends StatelessWidget {
  /// Creates an instance of [ApplicationDevelopmentProgress].
  const ApplicationDevelopmentProgress({
    required this.progress,
    super.key,
  });

  /// The progress information displayed by this widget.
  final DevelopmentProgress? progress;

  @override
  Widget build(BuildContext context) {
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
            value: progress!.percentage / 100,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
          ),
        ),

        // Progress text
        Padding(
          padding: const EdgeInsets.only(top: Insets.xxSmall),
          child: Text(
            '${progress!.percentage.toInt()}% • ${progress!.currentPhase}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.tertiary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
