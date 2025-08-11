import 'milestone_status.dart';

/// Represents a single milestone in the application development process.
///
/// Milestones track specific phases of development such as code generation,
/// testing, containerization, and deployment. Each milestone has a status,
/// timing information, and optional error details for failed milestones.
///
/// Milestones are used to provide detailed progress feedback to users and
/// enable fine-grained monitoring of the development process.
class DevelopmentMilestone {
  /// Creates a new development milestone.
  ///
  /// All parameters except [completedAt] and [errorMessage] are required.
  /// The [completedAt] timestamp is set when the milestone reaches completed status.
  /// The [errorMessage] is populated when the milestone fails.
  const DevelopmentMilestone({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.order,
    this.completedAt,
    this.errorMessage,
  });

  /// Unique identifier for this milestone.
  ///
  /// Used to track milestone progress across system updates and
  /// correlate with backend development logs.
  final String id;

  /// Human-readable name of the milestone.
  ///
  /// Short, descriptive name suitable for display in progress indicators.
  /// Examples: "Generate Code", "Run Tests", "Build Container"
  final String name;

  /// Detailed description of what this milestone accomplishes.
  ///
  /// Provides additional context about the milestone's purpose and
  /// what work is performed during this phase.
  final String description;

  /// Current status of this milestone.
  ///
  /// Indicates whether the milestone is pending, in progress, completed, or failed.
  /// Used to determine visual indicators and available actions.
  final MilestoneStatus status;

  /// Order of this milestone in the development sequence.
  ///
  /// Lower numbers indicate earlier milestones. Used for sorting
  /// and displaying milestones in the correct sequence.
  final int order;

  /// Timestamp when this milestone was completed.
  ///
  /// Null if the milestone has not been completed yet.
  /// Used for progress tracking and development timeline analysis.
  final DateTime? completedAt;

  /// Error message if this milestone failed.
  ///
  /// Null if the milestone has not failed. Contains user-friendly
  /// error description when the milestone encounters problems.
  final String? errorMessage;

  /// Creates a DevelopmentMilestone from JSON data.
  ///
  /// Parses milestone data received from the backend API and creates
  /// a properly typed milestone object with validation.
  ///
  /// Throws [FormatException] if the JSON structure is invalid or
  /// required fields are missing.
  factory DevelopmentMilestone.fromJson(Map<String, dynamic> json) {
    try {
      return DevelopmentMilestone(
        id: json['id'] as String? ?? (throw ArgumentError('Missing required field: id')),
        name: json['name'] as String? ?? (throw ArgumentError('Missing required field: name')),
        description: json['description'] as String? ?? (throw ArgumentError('Missing required field: description')),
        status: _parseStatus(json['status'] as String?),
        order: json['order'] as int? ?? (throw ArgumentError('Missing required field: order')),
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        errorMessage: json['errorMessage'] as String?,
      );
    } catch (e) {
      throw FormatException('Failed to parse DevelopmentMilestone from JSON: $e');
    }
  }

  /// Converts this milestone to JSON format.
  ///
  /// Creates a JSON representation suitable for API communication
  /// and local storage. All fields are included with proper type conversion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.name,
      'order': order,
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  /// Creates a copy of this milestone with updated fields.
  ///
  /// Allows updating specific fields while preserving others.
  /// Commonly used when receiving status updates from the backend.
  DevelopmentMilestone copyWith({
    String? id,
    String? name,
    String? description,
    MilestoneStatus? status,
    int? order,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return DevelopmentMilestone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      order: order ?? this.order,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Parses a milestone status string into the corresponding enum value.
  ///
  /// Handles case-insensitive parsing and provides clear error messages
  /// for invalid status values.
  static MilestoneStatus _parseStatus(String? statusString) {
    if (statusString == null) {
      throw ArgumentError('Missing required field: status');
    }

    switch (statusString.toLowerCase()) {
      case 'pending':
        return MilestoneStatus.pending;
      case 'inprogress':
      case 'in_progress':
        return MilestoneStatus.inProgress;
      case 'completed':
        return MilestoneStatus.completed;
      case 'failed':
        return MilestoneStatus.failed;
      default:
        throw ArgumentError('Invalid milestone status: $statusString');
    }
  }
}
