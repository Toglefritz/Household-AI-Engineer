import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/insets.dart';
import 'components/applications/application_grid.dart';

import 'components/sidebar/dashboard_sidebar.dart';
import 'components/status_bar/dashboard_status_bar.dart';
import 'dashboard_controller.dart';
import 'dashboard_route.dart';

/// View for [DashboardRoute].
///
/// Implements the main dashboard layout with sidebar, main content area,
/// and status bar. Provides a responsive design that adapts to different
/// window sizes while maintaining macOS design conventions.
///
/// Layout Structure:
/// * Top: Status bar with connection indicators and system status
/// * Middle: Horizontal split between sidebar and main content
/// * Sidebar: Navigation, filters, and application categories
/// * Main Content: Application grid and primary interface elements
class DashboardView extends StatelessWidget {
  /// Creates an instance of [DashboardView].
  ///
  /// @param state Controller instance providing state and event handlers
  const DashboardView(this.state, {super.key});

  /// Controller for this view providing state and event handlers.
  ///
  /// Used to access sidebar expansion state, connection status,
  /// and handle user interactions like sidebar toggling.
  final DashboardController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Status bar at the top
          DashboardStatusBar(
            connectionStatus: state.connectionStatus,
            onToggleSidebar: state.toggleSidebar,
            isSidebarExpanded: state.isSidebarExpanded,
            applications: state.applications,
          ),

          // Main content area with sidebar
          Expanded(
            child: Row(
              children: [
                // Sidebar
                DashboardSidebar(
                  isExpanded: state.isSidebarExpanded,
                  onToggle: state.toggleSidebar,
                  applications: state.applications,
                  openNewApplicationConversation: state.openNewApplicationConversation,
                  searchController: state.searchController,
                ),

                // Main content area
                Expanded(
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.medium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Opacity(
                              opacity: 0.6,
                              child: Text(
                                '${AppLocalizations.of(context)!.greeting},',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                top: Insets.small,
                                bottom: Insets.large,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.welcomeMessage,
                                style: Theme.of(
                                  context,
                                ).textTheme.displayMedium,
                              ),
                            ),

                            // Application grid
                            Expanded(
                              child: ApplicationGrid(
                                applications: state.filteredApplications,
                                selectedApplicationIds: state.selectedApplicationIds,
                                onApplicationTap: state.onApplicationTap,
                                onApplicationSecondaryTap: state.onApplicationSecondaryTap,
                                onCreateNewApplication: state.openNewApplicationConversation,
                                onSelectionChanged: state.onApplicationSelectionChanged,
                                onSelectAll: state.onSelectAllApplications,
                                onSelectNone: state.onSelectNoApplications,
                                onBulkDelete: state.onBulkDeleteApplications,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
