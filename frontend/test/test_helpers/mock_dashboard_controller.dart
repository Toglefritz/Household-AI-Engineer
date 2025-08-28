/// Mock dashboard controller for testing.
///
/// Provides a mock implementation of the dashboard controller
/// for use in accessibility and other tests.
library;

import 'package:dwellware/screens/dashboard/components/search/search_controller.dart' as search;
import 'package:dwellware/services/kiro/models/kiro_status.dart';
import 'package:dwellware/services/user_application/models/user_application.dart';
import 'package:flutter/material.dart';

/// Mock dashboard controller for testing.
class MockDashboardController {
  /// Creates a mock dashboard controller.
  MockDashboardController({
    this.applications = const [],
    this.isSidebarExpanded = true,
    this.connectionStatus = KiroStatus.available,
  });

  /// List of applications for testing.
  final List<UserApplication> applications;

  /// Whether the sidebar is expanded.
  final bool isSidebarExpanded;

  /// Connection status for testing.
  final KiroStatus connectionStatus;

  /// Mock search controller.
  final search.ApplicationSearchController searchController = search.ApplicationSearchController();

  /// Selected application IDs.
  final Set<String> selectedApplicationIds = <String>{};

  /// Filtered applications (same as applications for testing).
  List<UserApplication> get filteredApplications => applications;

  /// Mock method for toggling sidebar.
  void toggleSidebar() {
    // Mock implementation
  }

  /// Mock method for opening new application conversation.
  void openNewApplicationConversation() {
    // Mock implementation
  }

  /// Mock method for handling application tap.
  void onApplicationTap(UserApplication application) {
    // Mock implementation
  }

  /// Mock method for handling application secondary tap.
  void onApplicationSecondaryTap(UserApplication application, Offset position) {
    // Mock implementation
  }

  /// Mock method for handling application selection change.
  void onApplicationSelectionChanged(UserApplication application, {required bool isSelected}) {
    // Mock implementation
  }

  /// Mock method for selecting all applications.
  void onSelectAllApplications() {
    // Mock implementation
  }

  /// Mock method for selecting no applications.
  void onSelectNoApplications() {
    // Mock implementation
  }

  /// Mock method for bulk deleting applications.
  void onBulkDeleteApplications(List<UserApplication> applications) {
    // Mock implementation
  }
}
