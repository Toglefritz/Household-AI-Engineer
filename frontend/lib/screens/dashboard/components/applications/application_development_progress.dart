part of 'application_tile.dart';

/// Displays development progress with an animated linear progress bar and phase text.
///
/// Features:
/// * Smooth progress value transitions
/// * Pulsing animation during active development
/// * Color transitions based on progress milestones
/// * Success animation when reaching 100%
/// * Phase text with fade transitions
class ApplicationDevelopmentProgress extends StatefulWidget {
  /// Creates an instance of [ApplicationDevelopmentProgress].
  const ApplicationDevelopmentProgress({
    required this.progress,
    super.key,
  });

  /// The progress information displayed by this widget.
  final DevelopmentProgress? progress;

  @override
  State<ApplicationDevelopmentProgress> createState() => _ApplicationDevelopmentProgressState();
}

/// State for the [ApplicationDevelopmentProgress] widget.
class _ApplicationDevelopmentProgressState extends State<ApplicationDevelopmentProgress> with TickerProviderStateMixin {
  /// Animation controller for progress value transitions.
  late final AnimationController _progressController;

  /// Animation controller for pulsing effect during active development.
  late final AnimationController _pulseController;

  /// Animation controller for success celebration.
  late final AnimationController _successController;

  /// Animation for smooth progress value changes.
  late final Animation<double> _progressAnimation;

  /// Animation for pulsing effect.
  late final Animation<double> _pulseAnimation;

  /// Animation for success celebration.
  late final Animation<double> _successAnimation;

  /// Current animated progress value.
  double _currentProgress = 0.0;

  /// Previous progress value for smooth transitions.
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _progressAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeInOut,
          ),
        );

    _pulseAnimation =
        Tween<double>(
          begin: 0.7,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _pulseController,
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

    // Set initial values
    if (widget.progress != null) {
      _currentProgress = widget.progress!.percentage / 100;
      _previousProgress = _currentProgress;
    }

    // Start pulsing animation for active development
    if (widget.progress != null && widget.progress!.percentage < 100) {
      _pulseController.repeat(reverse: true);
    }

    // Listen for progress animation updates
    _progressController.addListener(() {
      if (mounted) {
        setState(() {
          _currentProgress =
              _previousProgress +
              ((widget.progress?.percentage ?? 0) / 100 - _previousProgress) * _progressAnimation.value;
        });
      }
    });
  }

  @override
  void didUpdateWidget(ApplicationDevelopmentProgress oldWidget) {
    super.didUpdateWidget(oldWidget);

    final double? newProgress = widget.progress?.percentage;
    final double? oldProgress = oldWidget.progress?.percentage;

    // Handle progress changes
    if (newProgress != oldProgress && newProgress != null) {
      _previousProgress = _currentProgress;
      _progressController..reset()
      ..forward();

      // Handle completion
      if (newProgress >= 100 && (oldProgress ?? 0) < 100) {
        _pulseController.stop();
        _successController.forward();
      } else if (newProgress < 100 && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.progress == null) {
      return const SizedBox.shrink();
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double progressValue = widget.progress!.percentage / 100;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _progressAnimation,
        _pulseAnimation,
        _successAnimation,
      ]),
      builder: (context, child) {
        // Calculate progress bar color based on completion and success state
        Color progressColor = Colors.blue;
        if (_successAnimation.value > 0) {
          progressColor = Color.lerp(Colors.blue, Colors.green, _successAnimation.value)!;
        }

        // Calculate opacity for pulsing effect
        double opacity = 1.0;
        if (progressValue < 1.0 && _pulseController.isAnimating) {
          opacity = _pulseAnimation.value;
        }

        // Calculate glow effect for success
        final bool showGlow = _successAnimation.value > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar with glow effect
            Container(
              decoration: showGlow
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(
                            alpha: 0.4 * _successAnimation.value,
                          ),
                          blurRadius: 6 * _successAnimation.value,
                          spreadRadius: 1 * _successAnimation.value,
                        ),
                      ],
                    )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: opacity,
                  child: LinearProgressIndicator(
                    value: _currentProgress,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 6,
                  ),
                ),
              ),
            ),

            // Progress text with fade transition
            Padding(
              padding: const EdgeInsets.only(top: Insets.xxSmall),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '${widget.progress!.percentage.toInt()}% • ${widget.progress!.currentPhase}',
                  key: ValueKey('${widget.progress!.percentage}-${widget.progress!.currentPhase}'),
                  style: textTheme.bodySmall?.copyWith(
                    color: showGlow
                        ? Color.lerp(colorScheme.tertiary, Colors.green, _successAnimation.value)
                        : colorScheme.tertiary,
                    fontSize: 11,
                    fontWeight: showGlow ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }
}
