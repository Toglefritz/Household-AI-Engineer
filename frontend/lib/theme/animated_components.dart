/// Animated UI components providing enhanced visual feedback.
///
/// This library contains reusable animated components that provide smooth
/// transitions, hover effects, and visual feedback for user interactions.
/// All components follow the application's design system and animation
/// guidelines for consistent user experience.
library;

import 'package:flutter/material.dart';

/// An animated button that provides visual feedback for user interactions.
///
/// Features:
/// * Smooth hover animations with scale and color transitions
/// * Press feedback with immediate visual response
/// * Success animation for completed operations
/// * Loading state with animated progress indicator
/// * Customizable animation durations and curves
/// * Accessibility support with semantic labels
///
/// The button automatically handles different states:
/// * Normal: Default appearance with subtle hover effects
/// * Hovered: Slightly scaled with enhanced colors
/// * Pressed: Quick scale-down feedback
/// * Loading: Animated progress indicator
/// * Success: Brief success animation with checkmark
/// * Disabled: Reduced opacity with no interactions
class AnimatedButton extends StatefulWidget {
  /// Creates an animated button.
  ///
  /// @param onPressed Callback when button is pressed
  /// @param child Widget to display inside the button
  /// @param isLoading Whether to show loading state
  /// @param isSuccess Whether to show success state
  /// @param style Optional button style override
  /// @param animationDuration Duration for animations
  /// @param successDuration How long to show success state
  const AnimatedButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isSuccess = false,
    this.style,
    this.animationDuration = const Duration(milliseconds: 200),
    this.successDuration = const Duration(milliseconds: 1500),
    super.key,
  });

  /// Callback invoked when the button is pressed.
  ///
  /// If null, the button is disabled and shows disabled styling.
  final VoidCallback? onPressed;

  /// Widget to display inside the button.
  ///
  /// Typically a Text widget or Row with icon and text.
  final Widget child;

  /// Whether the button is in loading state.
  ///
  /// When true, shows an animated progress indicator and disables interaction.
  final bool isLoading;

  /// Whether the button is in success state.
  ///
  /// When true, shows a success animation with checkmark icon.
  final bool isSuccess;

  /// Optional button style override.
  ///
  /// If not provided, uses the theme's default button style.
  final ButtonStyle? style;

  /// Duration for hover and press animations.
  ///
  /// Controls how quickly the button responds to user interactions.
  final Duration animationDuration;

  /// Duration to show success state.
  ///
  /// After this duration, the button returns to normal state.
  final Duration successDuration;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

/// State for the [AnimatedButton] widget.
class _AnimatedButtonState extends State<AnimatedButton> with TickerProviderStateMixin {
  /// Animation controller for hover and press effects.
  late final AnimationController _hoverController;

  /// Animation controller for success state.
  late final AnimationController _successController;

  /// Animation controller for loading state.
  late final AnimationController _loadingController;

  /// Scale animation for hover effects.
  late final Animation<double> _scaleAnimation;

  /// Color animation for hover effects.
  late final Animation<double> _colorAnimation;

  /// Success animation for checkmark appearance.
  late final Animation<double> _successAnimation;

  /// Loading animation for progress indicator.
  late final Animation<double> _loadingAnimation;

  /// Whether the mouse is currently hovering over the button.
  bool _isHovered = false;

  /// Whether the button is currently being pressed.
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _hoverController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _scaleAnimation =
        Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).animate(
          CurvedAnimation(
            parent: _hoverController,
            curve: Curves.easeInOut,
          ),
        );

    _colorAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _hoverController,
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

    _loadingAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _loadingController,
            curve: Curves.easeInOut,
          ),
        );

    // Start loading animation if needed
    if (widget.isLoading) {
      _loadingController.repeat();
    }

    // Start success animation if needed
    if (widget.isSuccess) {
      _startSuccessAnimation();
    }
  }

  @override
  void didUpdateWidget(AnimatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle loading state changes
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController..stop()
        ..reset();
      }
    }

    // Handle success state changes
    if (widget.isSuccess != oldWidget.isSuccess) {
      if (widget.isSuccess) {
        _startSuccessAnimation();
      } else {
        _successController.reset();
      }
    }
  }

  /// Starts the success animation sequence.
  ///
  /// Plays the success animation and automatically resets after the
  /// specified success duration.
  void _startSuccessAnimation() {
    _successController.forward().then((_) {
      Future.delayed(widget.successDuration, () {
        if (mounted) {
          _successController.reverse();
        }
      });
    });
  }

  /// Handles mouse enter events.
  void _onMouseEnter() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _isHovered = true;
      });
      _hoverController.forward();
    }
  }

  /// Handles mouse exit events.
  void _onMouseExit() {
    setState(() {
      _isHovered = false;
      _isPressed = false;
    });
    _hoverController.reverse();
  }

  /// Handles tap down events.
  void _onTapDown() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  /// Handles tap up events.
  void _onTapUp() {
    setState(() {
      _isPressed = false;
    });
  }

  /// Handles tap events.
  void _onTap() {
    if (widget.onPressed != null && !widget.isLoading && !widget.isSuccess) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      onEnter: (_) => _onMouseEnter(),
      onExit: (_) => _onMouseExit(),
      child: GestureDetector(
        onTapDown: (_) => _onTapDown(),
        onTapUp: (_) => _onTapUp(),
        onTapCancel: _onTapUp,
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _colorAnimation,
            _successAnimation,
            _loadingAnimation,
          ]),
          builder: (context, child) {
            // Calculate current scale based on state
            double currentScale = _scaleAnimation.value;
            if (_isPressed) {
              currentScale *= 0.95; // Slight scale down when pressed
            }

            return Transform.scale(
              scale: currentScale,
              child: AnimatedContainer(
                duration: widget.animationDuration,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isHovered && isEnabled
                      ? [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: isEnabled ? _onTap : null,
                  style: widget.style?.copyWith(
                    elevation: WidgetStateProperty.all(0),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildButtonContent(context),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the button content based on current state.
  Widget _buildButtonContent(BuildContext context) {
    if (widget.isSuccess && _successAnimation.value > 0) {
      return Transform.scale(
        scale: _successAnimation.value,
        child: const Icon(
          Icons.check,
          key: ValueKey('success'),
        ),
      );
    }

    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          key: const ValueKey('loading'),
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _successController.dispose();
    _loadingController.dispose();
    super.dispose();
  }
}

/// An animated container that provides smooth transitions between states.
///
/// Features:
/// * Smooth color and size transitions
/// * Hover effects with scale and shadow animations
/// * Loading state with pulsing animation
/// * Success state with brief highlight
/// * Error state with shake animation
/// * Customizable animation curves and durations
class AnimatedStateContainer extends StatefulWidget {
  /// Creates an animated state container.
  ///
  /// @param child Widget to display inside the container
  /// @param isLoading Whether to show loading state
  /// @param isSuccess Whether to show success state
  /// @param isError Whether to show error state
  /// @param onTap Optional tap callback
  /// @param padding Container padding
  /// @param margin Container margin
  /// @param decoration Base decoration for the container
  const AnimatedStateContainer({
    required this.child,
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
    this.onTap,
    this.padding,
    this.margin,
    this.decoration,
    super.key,
  });

  /// Widget to display inside the container.
  final Widget child;

  /// Whether the container is in loading state.
  final bool isLoading;

  /// Whether the container is in success state.
  final bool isSuccess;

  /// Whether the container is in error state.
  final bool isError;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Container padding.
  final EdgeInsetsGeometry? padding;

  /// Container margin.
  final EdgeInsetsGeometry? margin;

  /// Base decoration for the container.
  final BoxDecoration? decoration;

  @override
  State<AnimatedStateContainer> createState() => _AnimatedStateContainerState();
}

/// State for the [AnimatedStateContainer] widget.
class _AnimatedStateContainerState extends State<AnimatedStateContainer> with TickerProviderStateMixin {
  /// Animation controller for loading pulse effect.
  late final AnimationController _pulseController;

  /// Animation controller for success highlight.
  late final AnimationController _successController;

  /// Animation controller for error shake effect.
  late final AnimationController _shakeController;

  /// Animation controller for hover effects.
  late final AnimationController _hoverController;

  /// Pulse animation for loading state.
  late final Animation<double> _pulseAnimation;

  /// Success animation for highlight effect.
  late final Animation<double> _successAnimation;

  /// Shake animation for error state.
  late final Animation<double> _shakeAnimation;

  /// Hover animation for interactive feedback.
  late final Animation<double> _hoverAnimation;

  /// Whether the mouse is currently hovering.
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Initialize animations
    _pulseAnimation =
        Tween<double>(
          begin: 0.8,
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
            curve: Curves.easeOut,
          ),
        );

    _shakeAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _shakeController,
            curve: Curves.elasticOut,
          ),
        );

    _hoverAnimation =
        Tween<double>(
          begin: 1.0,
          end: 1.02,
        ).animate(
          CurvedAnimation(
            parent: _hoverController,
            curve: Curves.easeInOut,
          ),
        );

    // Start appropriate animations
    _updateAnimations();
  }

  @override
  void didUpdateWidget(AnimatedStateContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading ||
        widget.isSuccess != oldWidget.isSuccess ||
        widget.isError != oldWidget.isError) {
      _updateAnimations();
    }
  }

  /// Updates animations based on current state.
  void _updateAnimations() {
    // Stop all animations first
    _pulseController.stop();
    _successController.stop();
    _shakeController.stop();

    // Start appropriate animation
    if (widget.isLoading) {
      _pulseController.repeat(reverse: true);
    } else if (widget.isSuccess) {
      _successController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _successController.reverse();
          }
        });
      });
    } else if (widget.isError) {
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
    }
  }

  /// Handles mouse enter events.
  void _onMouseEnter() {
    if (widget.onTap != null) {
      setState(() {
        _isHovered = true;
      });
      _hoverController.forward();
    }
  }

  /// Handles mouse exit events.
  void _onMouseExit() {
    setState(() {
      _isHovered = false;
    });
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _onMouseEnter(),
      onExit: (_) => _onMouseExit(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseAnimation,
            _successAnimation,
            _shakeAnimation,
            _hoverAnimation,
          ]),
          builder: (context, child) {
            // Calculate shake offset
            double shakeOffset = 0.0;
            if (widget.isError && _shakeAnimation.value > 0) {
              shakeOffset =
                  4.0 * _shakeAnimation.value * (1.0 - _shakeAnimation.value) * (2.0 * _shakeAnimation.value - 1.0);
            }

            // Calculate opacity based on state
            double opacity = 1.0;
            if (widget.isLoading) {
              opacity = _pulseAnimation.value;
            }

            // Calculate border color based on state
            Color? borderColor;
            if (widget.isSuccess && _successAnimation.value > 0) {
              borderColor = Color.lerp(
                colorScheme.outline,
                Colors.green,
                _successAnimation.value,
              );
            } else if (widget.isError) {
              borderColor = colorScheme.error;
            }

            return Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: Transform.scale(
                scale: _hoverAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: widget.margin,
                  padding: widget.padding,
                  decoration: widget.decoration?.copyWith(
                    border: borderColor != null ? Border.all(color: borderColor) : widget.decoration?.border,
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : widget.decoration?.boxShadow,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: opacity,
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _shakeController.dispose();
    _hoverController.dispose();
    super.dispose();
  }
}

/// An animated progress indicator with smooth transitions.
///
/// Features:
/// * Smooth progress value transitions
/// * Pulsing animation during indeterminate state
/// * Color transitions based on progress value
/// * Success animation when reaching 100%
/// * Customizable colors and animation curves
class AnimatedProgressIndicator extends StatefulWidget {
  /// Creates an animated progress indicator.
  ///
  /// @param value Progress value from 0.0 to 1.0, null for indeterminate
  /// @param height Height of the progress bar
  /// @param backgroundColor Background color of the progress bar
  /// @param valueColor Color of the progress value
  /// @param borderRadius Border radius for rounded corners
  /// @param showPercentage Whether to show percentage text
  const AnimatedProgressIndicator({
    this.value,
    this.height = 6.0,
    this.backgroundColor,
    this.valueColor,
    this.borderRadius,
    this.showPercentage = false,
    super.key,
  });

  /// Progress value from 0.0 to 1.0, null for indeterminate.
  final double? value;

  /// Height of the progress bar.
  final double height;

  /// Background color of the progress bar.
  final Color? backgroundColor;

  /// Color of the progress value.
  final Color? valueColor;

  /// Border radius for rounded corners.
  final BorderRadius? borderRadius;

  /// Whether to show percentage text.
  final bool showPercentage;

  @override
  State<AnimatedProgressIndicator> createState() => _AnimatedProgressIndicatorState();
}

/// State for the [AnimatedProgressIndicator] widget.
class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator> with TickerProviderStateMixin {
  /// Animation controller for progress value changes.
  late final AnimationController _progressController;

  /// Animation controller for success celebration.
  late final AnimationController _successController;

  /// Animation for smooth progress transitions.
  late final Animation<double> _progressAnimation;

  /// Animation for success celebration effect.
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    // Set initial progress
    if (widget.value != null) {
      _currentProgress = widget.value!;
      _previousProgress = widget.value!;
    }

    // Listen for animation updates
    _progressController.addListener(() {
      setState(() {
        _currentProgress = _previousProgress + (widget.value! - _previousProgress) * _progressAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value && widget.value != null) {
      _previousProgress = _currentProgress;
      _progressController..reset()
      ..forward();

      // Trigger success animation if reaching 100%
      if (widget.value! >= 1.0 && (oldWidget.value ?? 0.0) < 1.0) {
        _successController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor = widget.backgroundColor ?? colorScheme.outline.withValues(alpha: 0.2);
    final Color valueColor = widget.valueColor ?? colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar
        AnimatedBuilder(
          animation: _successAnimation,
          builder: (context, child) {
            // Add success glow effect
            final bool showGlow = _successAnimation.value > 0;

            return Container(
              decoration: showGlow
                  ? BoxDecoration(
                      borderRadius: widget.borderRadius ?? BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(
                            alpha: 0.3 * _successAnimation.value,
                          ),
                          blurRadius: 8 * _successAnimation.value,
                          spreadRadius: 2 * _successAnimation.value,
                        ),
                      ],
                    )
                  : null,
              child: ClipRRect(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(3),
                child: SizedBox(
                  height: widget.height,
                  child: LinearProgressIndicator(
                    value: widget.value != null ? _currentProgress : null,
                    backgroundColor: backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      showGlow && _currentProgress >= 1.0
                          ? Color.lerp(valueColor, Colors.green, _successAnimation.value)!
                          : valueColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Percentage text
        if (widget.showPercentage && widget.value != null) ...[
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Text(
                '${(_currentProgress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _successController.dispose();
    super.dispose();
  }
}
