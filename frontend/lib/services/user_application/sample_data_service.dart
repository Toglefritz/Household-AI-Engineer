import '../../models/models.dart';

/// Service providing sample application data for development and testing.
///
/// This service generates realistic sample applications with various statuses
/// and configurations to demonstrate the dashboard functionality before
/// backend integration is complete.
class SampleDataService {
  /// Returns a list of sample applications for development and testing.
  ///
  /// Includes applications in various states to demonstrate all possible
  /// UI states and interactions in the dashboard.
  static List<UserApplication> getSampleApplications() {
    final DateTime now = DateTime.now();

    return [
      // Running application
      UserApplication(
        id: 'app_001',
        title: 'Family Chore Tracker',
        description:
            'Track and rotate household chores among family members with weekly schedules and completion tracking.',
        status: ApplicationStatus.running,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3001',
        ),
        tags: ['home-management', 'family', 'organization'],
      ),

      // Application in development
      UserApplication(
        id: 'app_002',
        title: 'Budget Planner',
        description: 'Personal finance management with expense tracking, budget categories, and spending insights.',
        status: ApplicationStatus.developing,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3002',
        ),
        tags: ['finance', 'budgeting', 'planning'],
        progress: DevelopmentProgress(
          percentage: 65.0,
          currentPhase: 'Building User Interface',
          milestones: [
            DevelopmentMilestone(
              id: 'milestone_001',
              name: 'Database Schema',
              description: 'Create database tables and relationships',
              status: MilestoneStatus.completed,
              order: 1,
              completedAt: now.subtract(const Duration(hours: 3)),
            ),
            DevelopmentMilestone(
              id: 'milestone_002',
              name: 'API Endpoints',
              description: 'Implement REST API endpoints',
              status: MilestoneStatus.completed,
              order: 2,
              completedAt: now.subtract(const Duration(hours: 2)),
            ),
            const DevelopmentMilestone(
              id: 'milestone_003',
              name: 'User Interface',
              description: 'Build responsive user interface',
              status: MilestoneStatus.inProgress,
              order: 3,
            ),
            const DevelopmentMilestone(
              id: 'milestone_004',
              name: 'Testing',
              description: 'Run automated tests and validation',
              status: MilestoneStatus.pending,
              order: 4,
            ),
          ],
          lastUpdated: now.subtract(const Duration(minutes: 15)),
        ),
      ),

      // Ready to launch application
      UserApplication(
        id: 'app_003',
        title: 'Home Maintenance Log',
        description: 'Keep track of home maintenance tasks, schedules, and service provider contacts.',
        status: ApplicationStatus.ready,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3003',
        ),
        tags: ['home-management', 'maintenance', 'scheduling'],
      ),

      // Failed application
      UserApplication(
        id: 'app_004',
        title: 'Recipe Organizer',
        description: 'Organize family recipes with ingredient lists, cooking instructions, and meal planning.',
        status: ApplicationStatus.failed,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3004',
        ),
        tags: ['cooking', 'recipes', 'meal-planning'],
      ),

      // Application in testing
      UserApplication(
        id: 'app_005',
        title: 'Event Calendar',
        description: 'Family event calendar with shared scheduling, reminders, and coordination features.',
        status: ApplicationStatus.testing,
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3005',
        ),
        tags: ['planning', 'calendar', 'family'],
        progress: DevelopmentProgress(
          percentage: 90.0,
          currentPhase: 'Running Integration Tests',
          milestones: [
            DevelopmentMilestone(
              id: 'milestone_005',
              name: 'Core Features',
              description: 'Implement core application features',
              status: MilestoneStatus.completed,
              order: 1,
              completedAt: now.subtract(const Duration(hours: 2)),
            ),
            DevelopmentMilestone(
              id: 'milestone_006',
              name: 'User Interface',
              description: 'Build user interface components',
              status: MilestoneStatus.completed,
              order: 2,
              completedAt: now.subtract(const Duration(hours: 1)),
            ),
            const DevelopmentMilestone(
              id: 'milestone_007',
              name: 'Testing',
              description: 'Execute comprehensive test suite',
              status: MilestoneStatus.inProgress,
              order: 3,
            ),
          ],
          lastUpdated: now.subtract(const Duration(minutes: 5)),
        ),
      ),

      // Requested application
      UserApplication(
        id: 'app_006',
        title: 'Fitness Tracker',
        description: 'Track family fitness goals, activities, and health metrics with progress visualization.',
        status: ApplicationStatus.requested,
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3006',
        ),
        tags: ['health', 'fitness', 'tracking'],
      ),

      // Another running application
      UserApplication(
        id: 'app_007',
        title: 'Garden Planner',
        description: 'Plan and track your garden with planting schedules, harvest tracking, and care reminders.',
        status: ApplicationStatus.running,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3007',
        ),
        tags: ['gardening', 'planning', 'outdoor'],
      ),

      // Application being updated
      UserApplication(
        id: 'app_008',
        title: 'Pet Care Manager',
        description: 'Manage pet care schedules, vet appointments, and health records for all family pets.',
        status: ApplicationStatus.updating,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
        launchConfig: const LaunchConfiguration(
          type: LaunchType.web,
          url: 'http://localhost:3008',
        ),
        tags: ['pets', 'health', 'scheduling'],
        progress: DevelopmentProgress(
          percentage: 25.0,
          currentPhase: 'Applying Updates',
          milestones: [
            DevelopmentMilestone(
              id: 'milestone_008',
              name: 'Backup Data',
              description: 'Create backup of existing application data',
              status: MilestoneStatus.completed,
              order: 1,
              completedAt: now.subtract(const Duration(minutes: 15)),
            ),
            const DevelopmentMilestone(
              id: 'milestone_009',
              name: 'Apply Changes',
              description: 'Apply user-requested modifications',
              status: MilestoneStatus.inProgress,
              order: 2,
            ),
            const DevelopmentMilestone(
              id: 'milestone_010',
              name: 'Test Updates',
              description: 'Validate updated functionality',
              status: MilestoneStatus.pending,
              order: 3,
            ),
          ],
          lastUpdated: now.subtract(const Duration(minutes: 10)),
        ),
      ),
    ];
  }

  /// Returns sample applications filtered by status.
  ///
  /// Useful for testing specific UI states or demonstrating
  /// filtered views in the dashboard.
  ///
  /// @param status The application status to filter by
  /// @returns List of applications matching the specified status
  static List<UserApplication> getSampleApplicationsByStatus(ApplicationStatus status) {
    return getSampleApplications().where((UserApplication app) => app.status == status).toList();
  }

  /// Returns sample applications that are currently in development.
  ///
  /// Includes applications with active progress information
  /// for testing progress monitoring features.
  static List<UserApplication> getSampleDevelopingApplications() {
    return getSampleApplications().where((UserApplication app) => app.isInDevelopment).toList();
  }

  /// Returns sample applications that can be launched.
  ///
  /// Useful for testing launch functionality and demonstrating
  /// ready-to-use applications.
  static List<UserApplication> getSampleLaunchableApplications() {
    return getSampleApplications().where((UserApplication app) => app.canLaunch).toList();
  }
}
