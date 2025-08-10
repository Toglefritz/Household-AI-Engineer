/// Status of a development milestone.
///
/// Milestones progress through these states as development advances:
/// - [pending] - Milestone has not been started yet
/// - [inProgress] - Milestone is currently being worked on
/// - [completed] - Milestone has been successfully completed
/// - [failed] - Milestone failed and requires attention
enum MilestoneStatus {
  /// Milestone is waiting to be started.
  ///
  /// This milestone is queued but development has not begun.
  /// It may be waiting for previous milestones to complete.
  pending,

  /// Milestone is currently being processed.
  ///
  /// Active work is being performed on this milestone.
  /// Progress updates may be available for detailed tracking.
  inProgress,

  /// Milestone has been successfully completed.
  ///
  /// All work for this milestone is finished and validated.
  /// Development can proceed to the next milestone.
  completed,

  /// Milestone has failed and requires intervention.
  ///
  /// An error occurred that prevents this milestone from completing.
  /// Manual review or system intervention may be required.
  failed,
}

/// Extension methods for MilestoneStatus enum.
///
/// Provides utility methods for working with milestone status values,
/// including display formatting and state validation.
extension MilestoneStatusExtension on MilestoneStatus {
  /// Returns a human-readable display name for the milestone status.
  ///
  /// These names are suitable for display in progress indicators and
  /// development timeline views.
  String get displayName {
    switch (this) {
      case MilestoneStatus.pending:
        return 'Pending';
      case MilestoneStatus.inProgress:
        return 'In Progress';
      case MilestoneStatus.completed:
        return 'Completed';
      case MilestoneStatus.failed:
        return 'Failed';
    }
  }

  /// Returns true if the milestone is in an active state.
  ///
  /// Active milestones are currently being processed and may
  /// have progress updates or require monitoring.
  bool get isActive {
    return this == MilestoneStatus.inProgress;
  }

  /// Returns true if the milestone is in a terminal state.
  ///
  /// Terminal milestones have reached a final state (completed or failed)
  /// and will not change without external intervention.
  bool get isTerminal {
    return this == MilestoneStatus.completed || this == MilestoneStatus.failed;
  }
}
