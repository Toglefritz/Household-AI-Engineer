/// Application Tile Model
///
/// This module contains the ApplicationTile model class that represents
/// a household application tile with complete metadata for display,
/// interaction, progress tracking, and lifecycle management.
library;

import 'application_status.dart';
import 'development_progress.dart';
import 'launch_configuration.dart';

/// Represents a household application tile with complete metadata.
///
/// Application tiles are the primary unit of application management
/// within the dashboard. They contain all information needed for
/// display, interaction, progress tracking, and lifecycle management.
///
/// This model supports the complete application lifecycle from initial
/// request through development, deployment, and runtime management.
class ApplicationTile {
  /// Creates a new application tile.
  ///
  /// All parameters except [iconUrl], [progress], and [tags] are required
  /// to ensure complete application information for proper management.
  const ApplicationTile({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.launchConfig,
    this.iconUrl,
    this.progress,
    this.tags = const [],
  });

  /// Unique identifier for this application.
  ///
  /// Used throughout the system to track, update, and manage
  /// the application across all components and services.
  final String id;

  /// User-facing title of the application.
  ///
  /// Displayed prominently in the application tile and used
  /// for identification and search purposes.
  final String title;

  /// Detailed description of the application's purpose and functionality.
  ///
  /// Provides context about what the application does and how
  /// it serves the user's household needs.
  final String description;

  /// Current status of the application in its lifecycle.
  ///
  /// Determines available actions, visual indicators, and
  /// user interface states for this application.
  final ApplicationStatus status;

  /// Timestamp when this application was first created.
  ///
  /// Used for sorting, analytics, and displaying creation information.
  /// Immutable after application creation.
  final DateTime createdAt;

  /// Timestamp when this application was last updated.
  ///
  /// Updated whenever application metadata, status, or progress changes.
  /// Used for staleness detection and change tracking.
  final DateTime updatedAt;

  /// Optional URL for the application's icon or logo.
  ///
  /// Used for visual identification in the application tile.
  /// Null if no custom icon is available (default icon will be used).
  final String? iconUrl;

  /// List of tags for categorizing and organizing applications.
  ///
  /// Used for filtering, searching, and organizing applications
  /// within the dashboard interface.
  final List<String> tags;

  /// Development progress information for applications being built.
  ///
  /// Null for applications that are not currently in development.
  /// Contains detailed progress tracking for active development.
  final DevelopmentProgress? progress;

  /// Configuration for launching this application.
  ///
  /// Contains platform-specific settings and parameters needed
  /// to properly launch and manage the running application.
  final LaunchConfiguration launchConfig;

  /// Creates an ApplicationTile from JSON data.
  ///
  /// Parses application data received from the backend API and creates
  /// a properly typed application object with validation.
  ///
  /// Throws [FormatException] if the JSON structure is invalid or
  /// required fields are missing.
  factory ApplicationTile.fromJson(Map<String, dynamic> json) {
    try {
      return ApplicationTile(
        id:
            json['id'] as String? ??
            (throw ArgumentError('Missing required field: id')),
        title:
            json['title'] as String? ??
            (throw ArgumentError('Missing required field: title')),
        description:
            json['description'] as String? ??
            (throw ArgumentError('Missing required field: description')),
        status: _parseStatus(json['status'] as String?),
        createdAt: DateTime.parse(
          json['createdAt'] as String? ??
              (throw ArgumentError('Missing required field: createdAt')),
        ),
        updatedAt: DateTime.parse(
          json['updatedAt'] as String? ??
              (throw ArgumentError('Missing required field: updatedAt')),
        ),
        launchConfig: LaunchConfiguration.fromJson(
          json['launchConfig'] as Map<String, dynamic>? ??
              (throw ArgumentError('Missing required field: launchConfig')),
        ),
        iconUrl: json['iconUrl'] as String?,
        tags:
            (json['tags'] as List<dynamic>?)
                ?.map((tag) => tag as String)
                .toList() ??
            [],
        progress: json['progress'] != null
            ? DevelopmentProgress.fromJson(
                json['progress'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (e) {
      throw FormatException('Failed to parse ApplicationTile from JSON: $e');
    }
  }

  /// Converts this application tile to JSON format.
  ///
  /// Creates a JSON representation suitable for API communication
  /// and local storage with proper type conversion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'launchConfig': launchConfig.toJson(),
      'iconUrl': iconUrl,
      'tags': tags,
      'progress': progress?.toJson(),
    };
  }

  /// Creates a copy of this application tile with updated fields.
  ///
  /// Allows updating specific fields while preserving others.
  /// Commonly used when receiving status updates from the backend.
  ApplicationTile copyWith({
    String? id,
    String? title,
    String? description,
    ApplicationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? iconUrl,
    List<String>? tags,
    DevelopmentProgress? progress,
    LaunchConfiguration? launchConfig,
  }) {
    return ApplicationTile(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconUrl: iconUrl ?? this.iconUrl,
      tags: tags ?? this.tags,
      progress: progress ?? this.progress,
      launchConfig: launchConfig ?? this.launchConfig,
    );
  }

  /// Parses an application status string into the corresponding enum value.
  ///
  /// Handles case-insensitive parsing and provides clear error messages
  /// for invalid status values.
  static ApplicationStatus _parseStatus(String? statusString) {
    if (statusString == null) {
      throw ArgumentError('Missing required field: status');
    }

    switch (statusString.toLowerCase()) {
      case 'requested':
        return ApplicationStatus.requested;
      case 'developing':
        return ApplicationStatus.developing;
      case 'testing':
        return ApplicationStatus.testing;
      case 'ready':
        return ApplicationStatus.ready;
      case 'running':
        return ApplicationStatus.running;
      case 'failed':
        return ApplicationStatus.failed;
      case 'updating':
        return ApplicationStatus.updating;
      default:
        throw ArgumentError('Invalid application status: $statusString');
    }
  }

  /// Returns true if this application is currently in development.
  ///
  /// Convenience method for checking if the application has active
  /// development progress that should be displayed to users.
  bool get isInDevelopment {
    return status.isActive && progress != null;
  }

  /// Returns true if this application can be launched.
  ///
  /// Applications can be launched when they are ready or already running.
  /// Uses the status extension method for consistent behavior.
  bool get canLaunch {
    return status.canLaunch;
  }

  /// Returns true if this application can be modified.
  ///
  /// Applications can be modified when they are in stable states.
  /// Uses the status extension method for consistent behavior.
  bool get canModify {
    return status.canModify;
  }

  /// Returns true if this application has a custom icon.
  ///
  /// Used to determine whether to display a custom icon or
  /// fall back to a default application icon.
  bool get hasCustomIcon {
    return iconUrl != null && iconUrl!.isNotEmpty;
  }

  /// Returns true if this application has tags.
  ///
  /// Used to determine whether to display tag information
  /// in the application tile interface.
  bool get hasTags {
    return tags.isNotEmpty;
  }

  /// Returns the age of this application since creation.
  ///
  /// Calculated as the time between creation and now.
  /// Used for displaying creation time and analytics.
  Duration get age {
    return DateTime.now().difference(createdAt);
  }

  /// Returns the time since this application was last updated.
  ///
  /// Calculated as the time between last update and now.
  /// Used for staleness detection and update indicators.
  Duration get timeSinceUpdate {
    return DateTime.now().difference(updatedAt);
  }

  /// Returns a formatted string describing when this application was created.
  ///
  /// Provides human-readable creation time information suitable
  /// for display in the application tile.
  String get createdTimeDescription {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns a formatted string describing when this application was last updated.
  ///
  /// Provides human-readable update time information suitable
  /// for display in the application tile.
  String get updatedTimeDescription {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inDays > 0) {
      return 'Updated ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return 'Updated ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return 'Updated ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just updated';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApplicationTile &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.iconUrl == iconUrl &&
        other.tags.length == tags.length &&
        other.progress == progress &&
        other.launchConfig == launchConfig;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      status,
      createdAt,
      updatedAt,
      iconUrl,
      tags.length,
      progress,
      launchConfig,
    );
  }

  @override
  String toString() {
    return 'ApplicationTile('
        'id: $id, '
        'title: $title, '
        'status: $status, '
        'createdAt: $createdAt'
        ')';
  }
}
