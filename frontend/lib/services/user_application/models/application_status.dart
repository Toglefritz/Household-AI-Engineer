/// An enumeration of values representing the status of a user application.
///
/// This enum defines all possible states an application can be in throughout its lifecycle from initial request to
/// deployment and runtime management. It is used throughout the system to track application progress, display
/// appropriate UI states, and control available user actions.
///
/// Applications progress through these states in a typical workflow:
///
/// 1. [requested] - User has submitted a request, waiting for processing
/// 2. [developing] - Application is being built by the development system
/// 3. [testing] - Application is undergoing automated testing
/// 4. [ready] - Application is built and ready to be launched
/// 5. [running] - Application is currently active and accessible
/// 6. [failed] - Development or deployment has failed
/// 7. [updating] - Application is being modified based on user changes
enum ApplicationStatus {
  /// Application has been requested but development has not started.
  ///
  /// This is the initial state when a user submits a new application request through the conversational interface. The
  /// request is queued for processing.
  requested,

  /// Application is currently being developed by the backend system.
  ///
  /// The development process includes code generation, dependency resolution, and initial compilation. Progress updates
  /// are available during this phase.
  developing,

  /// Application is undergoing automated testing and validation.
  ///
  /// This phase includes unit tests, integration tests, and quality checks to ensure the application meets requirements
  /// and functions correctly.
  testing,

  /// Application is fully built and ready to be launched by the user.
  ///
  /// All development and testing phases have completed successfully. The application is deployed and waiting for user
  /// activation.
  ready,

  /// Application is currently running and accessible to users.
  ///
  /// The application has been launched and is actively serving requests. Users can interact with the application
  /// through its interface.
  running,

  /// Application development or deployment has failed.
  ///
  /// An error occurred during development, testing, or deployment that prevents the application from being completed.
  /// Error details are available.
  failed,

  /// Application is being updated based on user modifications.
  ///
  /// The user has requested changes to an existing application, and the system is rebuilding it with the new
  /// requirements.
  updating,
}

/// Extension methods for [ApplicationStatus] enum.
///
/// Provides utility methods for working with application status values, including display formatting and state
/// validation.
extension ApplicationStatusExtension on ApplicationStatus {
  /// Returns a human-readable display name for the status.
  ///
  /// These names are suitable for display in the user interface and follow consistent capitalization and terminology
  /// conventions.
  String get displayName {
    switch (this) {
      case ApplicationStatus.requested:
        return 'Requested';
      case ApplicationStatus.developing:
        return 'Developing';
      case ApplicationStatus.testing:
        return 'Testing';
      case ApplicationStatus.ready:
        return 'Ready';
      case ApplicationStatus.running:
        return 'Running';
      case ApplicationStatus.failed:
        return 'Failed';
      case ApplicationStatus.updating:
        return 'Updating';
    }
  }

  /// Returns true if the application is in an active development state.
  ///
  /// Active states include developing, testing, and updating where the backend system is actively working on the
  /// application.
  bool get isActive {
    return this == ApplicationStatus.developing ||
        this == ApplicationStatus.testing ||
        this == ApplicationStatus.updating;
  }

  /// Returns true if the application is in a terminal state.
  ///
  /// Terminal states are ready, running, and failed where no further automatic progression will occur without user
  /// intervention.
  bool get isTerminal {
    return this == ApplicationStatus.ready ||
        this == ApplicationStatus.running ||
        this == ApplicationStatus.failed;
  }

  /// Returns true if the application can be launched by the user.
  ///
  /// Applications can be launched when they are ready or already running (in which case the existing instance will be
  /// brought to foreground).
  bool get canLaunch {
    return this == ApplicationStatus.ready || this == ApplicationStatus.running;
  }

  /// Returns true if the application can be modified by the user.
  ///
  /// Applications can be modified when they are in stable states (ready, running, or failed) but not during active
  /// development.
  bool get canModify {
    return this == ApplicationStatus.ready ||
        this == ApplicationStatus.running ||
        this == ApplicationStatus.failed;
  }
}
