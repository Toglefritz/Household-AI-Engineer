# Design Document

## Overview

The sidebar text wrapping issue occurs because Flutter's text widgets attempt to fit content within the available width during animation transitions. As the sidebar width changes from 280px to 88px (or vice versa), text elements try to wrap to multiple lines before the `showExpandedContent` logic hides them, creating visual artifacts.

The solution involves implementing a more sophisticated content visibility strategy that prevents text from attempting to wrap during transitions by controlling when text content is rendered based on animation progress rather than just final width thresholds.

## Architecture

### Current Animation Flow
1. User triggers sidebar toggle
2. `AnimatedContainer` begins width transition (250ms)
3. `LayoutBuilder` provides changing width constraints
4. `showExpandedContent` boolean switches at width threshold (_collapsedWidth + 20)
5. Text widgets attempt to fit within changing constraints before being hidden

### Proposed Animation Flow
1. User triggers sidebar toggle
2. Immediately hide/show text content based on animation direction
3. `AnimatedContainer` animates width smoothly without text interference
4. Text content appears/disappears at appropriate animation timing

## Components and Interfaces

### Enhanced DashboardSidebar

The main sidebar component will be enhanced with:

```dart
class DashboardSidebar extends StatefulWidget {
  // Convert to StatefulWidget to manage animation state
}

class _DashboardSidebarState extends State<DashboardSidebar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _contentOpacityAnimation;
  
  // Animation timing constants
  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const double _contentFadeThreshold = 0.3; // When to fade content
}
```

### Content Visibility Strategy

Instead of relying solely on width-based `showExpandedContent`, implement a multi-layered approach:

1. **Opacity Animation**: Fade text content in/out at specific animation progress points
2. **Overflow Prevention**: Use `ClipRect` to prevent text from overflowing during transitions
3. **Width-based Rendering**: Maintain current width-based logic as a fallback

### Animation Timing

```dart
// Content fade timing for smooth transitions
_contentOpacityAnimation = Tween<double>(
  begin: widget.isExpanded ? 1.0 : 0.0,
  end: widget.isExpanded ? 0.0 : 1.0,
).animate(CurvedAnimation(
  parent: _animationController,
  curve: Interval(0.0, _contentFadeThreshold, curve: Curves.easeOut),
));
```

## Data Models

### Animation State Management

```dart
/// Represents the current state of sidebar animation
enum SidebarAnimationState {
  /// Sidebar is fully expanded and stable
  expanded,
  /// Sidebar is fully collapsed and stable  
  collapsed,
  /// Sidebar is transitioning from expanded to collapsed
  collapsing,
  /// Sidebar is transitioning from collapsed to expanded
  expanding,
}

/// Configuration for sidebar animation behavior
class SidebarAnimationConfig {
  /// Total duration of the animation
  final Duration duration;
  /// Point in animation where content should fade (0.0 to 1.0)
  final double contentFadeThreshold;
  /// Curve for width animation
  final Curve widthCurve;
  /// Curve for content opacity animation
  final Curve contentCurve;
  
  const SidebarAnimationConfig({
    this.duration = const Duration(milliseconds: 250),
    this.contentFadeThreshold = 0.3,
    this.widthCurve = Curves.easeInOut,
    this.contentCurve = Curves.easeOut,
  });
}
```

## Error Handling

### Animation State Consistency

- Ensure animation state remains consistent even if user rapidly toggles sidebar
- Handle widget disposal during active animations
- Prevent memory leaks from animation controllers

### Fallback Behavior

- If animation controller fails to initialize, fall back to immediate state changes
- Maintain accessibility during animations (screen readers should get consistent state)
- Handle edge cases where animation is interrupted

## Testing Strategy

### Unit Tests

1. **Animation Controller Tests**
   - Verify animation controller initializes correctly
   - Test animation timing and curves
   - Validate state transitions

2. **Content Visibility Tests**
   - Test content opacity at different animation progress points
   - Verify text content is hidden during critical transition periods
   - Validate final visibility states

### Widget Tests

1. **Animation Integration Tests**
   - Test complete expand/collapse cycles
   - Verify no text wrapping occurs during transitions
   - Test rapid toggle scenarios

2. **Visual Regression Tests**
   - Capture screenshots at key animation frames
   - Compare against baseline to detect wrapping artifacts
   - Test on different screen sizes

### Performance Tests

1. **Animation Performance**
   - Measure frame rates during animation
   - Verify no dropped frames or stuttering
   - Test memory usage during repeated animations

## Implementation Approach

### Phase 1: Core Animation Infrastructure
- Convert `DashboardSidebar` to `StatefulWidget`
- Implement `AnimationController` and related animations
- Add animation state management

### Phase 2: Content Visibility Logic
- Implement opacity-based content hiding
- Add overflow clipping to prevent text spillover
- Integrate with existing `showExpandedContent` logic

### Phase 3: Component Updates
- Update all child components to support new animation system
- Ensure consistent behavior across all text elements
- Add proper animation disposal and cleanup

### Phase 4: Polish and Optimization
- Fine-tune animation timing and curves
- Add accessibility improvements
- Optimize performance and memory usage

## Technical Considerations

### Performance Impact
- Additional `AnimationController` adds minimal overhead
- Opacity animations are GPU-accelerated and performant
- `ClipRect` may have slight performance cost but prevents visual artifacts

### Accessibility
- Ensure screen readers receive consistent state information
- Maintain keyboard navigation during animations
- Provide reduced motion alternatives if needed

### Maintainability
- Keep animation logic centralized in main sidebar component
- Use configuration objects for easy tuning
- Maintain clear separation between animation and business logic