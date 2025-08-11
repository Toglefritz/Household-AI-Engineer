import 'development_milestone.dart';
import 'milestone_status.dart';

/// Represents the overall progress of application development.
///
/// Aggregates information from multiple development phases including completion percentage, current phase, milestone
/// status, and recent build logs to provide comprehensive progress tracking.
///
/// This model is used throughout the UI to display progress indicators, phase information, and detailed development
/// status to users.
class DevelopmentProgress {
  /// Creates a new development progress instance.
  ///
  /// All parameters are required to ensure complete progress information.
  /// The [milestones] list should be ordered by milestone sequence.
  const DevelopmentProgress({
    required this.percentage,
    required this.currentPhase,
    required this.milestones,
    required this.lastUpdated,
    this.estimatedCompletion,
  });

  /// Overall completion percentage (0.0 to 100.0).
  ///
  /// Calculated based on completed milestones and current phase progress.
  /// Used for progress bars and completion estimates in the UI.
  final double percentage;

  /// Human-readable description of the current development phase.
  ///
  /// Provides context about what work is currently being performed.
  /// Examples: "Generating Code", "Running Tests", "Building Container"
  final String currentPhase;

  /// List of all development milestones in sequence order.
  ///
  /// Milestones are ordered by their sequence number and provide
  /// detailed progress information for each development phase.
  final List<DevelopmentMilestone> milestones;

  /// Timestamp of the last progress update.
  ///
  /// Indicates when this progress information was last refreshed from
  /// the backend development system. Used for staleness detection.
  final DateTime lastUpdated;

  /// Estimated completion time for the development process.
  ///
  /// Null if no estimate is available. Based on historical data and
  /// current progress rate when provided by the backend system.
  final DateTime? estimatedCompletion;

  /// Creates a DevelopmentProgress from JSON data.
  ///
  /// Parses progress data received from the backend API and creates
  /// a properly typed progress object with validation.
  ///
  /// Throws [FormatException] if the JSON structure is invalid or
  /// required fields are missing.
  factory DevelopmentProgress.fromJson(Map<String, dynamic> json) {
    try {
      return DevelopmentProgress(
        percentage:
            (json['percentage'] as num?)?.toDouble() ?? (throw ArgumentError('Missing required field: percentage')),
        currentPhase: json['currentPhase'] as String? ?? (throw ArgumentError('Missing required field: currentPhase')),
        milestones:
            (json['milestones'] as List<dynamic>?)
                ?.map((milestone) => DevelopmentMilestone.fromJson(milestone as Map<String, dynamic>))
                .toList() ??
            [],
        lastUpdated: DateTime.parse(
          json['lastUpdated'] as String? ?? (throw ArgumentError('Missing required field: lastUpdated')),
        ),
        estimatedCompletion: json['estimatedCompletion'] != null
            ? DateTime.parse(json['estimatedCompletion'] as String)
            : null,
      );
    } catch (e) {
      throw FormatException('Failed to parse DevelopmentProgress from JSON: $e');
    }
  }

  /// Converts this progress to JSON format.
  ///
  /// Creates a JSON representation suitable for API communication
  /// and local storage with proper type conversion.
  Map<String, dynamic> toJson() {
    return {
      'percentage': percentage,
      'currentPhase': currentPhase,
      'milestones': milestones.map((milestone) => milestone.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'estimatedCompletion': estimatedCompletion?.toIso8601String(),
    };
  }

  /// Creates a copy of this progress with updated fields.
  ///
  /// Allows updating specific fields while preserving others.
  /// Commonly used when receiving progress updates from the backend.
  DevelopmentProgress copyWith({
    double? percentage,
    String? currentPhase,
    List<DevelopmentMilestone>? milestones,
    DateTime? lastUpdated,
    DateTime? estimatedCompletion,
  }) {
    return DevelopmentProgress(
      percentage: percentage ?? this.percentage,
      currentPhase: currentPhase ?? this.currentPhase,
      milestones: milestones ?? this.milestones,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
    );
  }

  /// Returns the current active milestone, if any.
  ///
  /// Finds the milestone that is currently in progress.
  /// Returns null if no milestone is currently active.
  DevelopmentMilestone? get currentMilestone {
    try {
      return milestones.firstWhere((milestone) => milestone.status == MilestoneStatus.inProgress);
    } catch (e) {
      return null;
    }
  }

  /// Returns the number of completed milestones.
  ///
  /// Used for calculating progress and displaying milestone completion status.
  int get completedMilestoneCount {
    return milestones.where((milestone) => milestone.status == MilestoneStatus.completed).length;
  }

  /// Returns the total number of milestones.
  ///
  /// Used for calculating progress percentages and displaying
  /// overall development phase information.
  int get totalMilestoneCount {
    return milestones.length;
  }

  /// Returns true if development has failed.
  ///
  /// Indicates that one or more critical milestones have failed
  /// and development cannot continue without intervention.
  bool get hasFailed {
    return milestones.any((milestone) => milestone.status == MilestoneStatus.failed);
  }

  /// Returns true if all milestones are completed.
  ///
  /// Indicates that development has finished successfully and
  /// the application is ready for deployment or use.
  bool get isComplete {
    return milestones.isNotEmpty && milestones.every((milestone) => milestone.status == MilestoneStatus.completed);
  }
}
