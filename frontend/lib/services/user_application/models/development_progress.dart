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
  const DevelopmentProgress({
    required this.percentage,
    required this.currentPhase,
    required this.lastUpdated,
    this.developmentStatement,
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

  /// User-friendly message about the current development phase.
  ///
  /// This message is formatted as a chat message from Kiro IDE to the user
  /// and provides conversational updates about development progress.
  /// Examples: "I'm working on the user interface now", "Almost done! Just testing the final features"
  final String? developmentStatement;

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
            (json['percentage'] as num?)?.toDouble() ??
            (throw ArgumentError('Missing required field: percentage')),
        currentPhase:
            json['currentPhase'] as String? ??
            (throw ArgumentError('Missing required field: currentPhase')),
        lastUpdated: DateTime.parse(
          json['lastUpdated'] as String? ??
              (throw ArgumentError('Missing required field: lastUpdated')),
        ),
        developmentStatement: json['developmentStatement'] as String?,
        estimatedCompletion: json['estimatedCompletion'] != null
            ? DateTime.parse(json['estimatedCompletion'] as String)
            : null,
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse DevelopmentProgress from JSON: $e',
      );
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
      'lastUpdated': lastUpdated.toIso8601String(),
      'developmentStatement': developmentStatement,
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
    DateTime? lastUpdated,
    String? developmentStatement,
    DateTime? estimatedCompletion,
  }) {
    return DevelopmentProgress(
      percentage: percentage ?? this.percentage,
      currentPhase: currentPhase ?? this.currentPhase,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      developmentStatement: developmentStatement ?? this.developmentStatement,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
    );
  }

  /// Returns true if the application development is complete according to the completion percentage.
  bool get isComplete => percentage == 100;
}
