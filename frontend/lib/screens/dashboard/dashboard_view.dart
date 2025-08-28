import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/accessibility_helper.dart';
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Status bar at the top with accessibility support
          AccessibilityHelper.createSemanticContainer(
            label: l10n.accessibilityStatusBar,
            hint: l10n.accessibilityStatusBarHint,
            child: DashboardStatusBar(
              connectionStatus: state.connectionStatus,
              onToggleSidebar: state.toggleSidebar,
              isSidebarExpanded: state.isSidebarExpanded,
              applications: state.applications,
            ),
          ),

          // Main content area with sidebar
          Expanded(
            child: Row(
              children: [
                // Sidebar with accessibility support
                AccessibilityHelper.createSemanticContainer(
                  label: l10n.accessibilitySidebar,
                  hint: l10n.accessibilitySidebarHint,
                  child: DashboardSidebar(
                    isExpanded: state.isSidebarExpanded,
                    onToggle: state.toggleSidebar,
                    applications: state.applications,
                    openNewApplicationConversation: state.openNewApplicationConversation,
                    searchController: state.searchController,
                  ),
                ),

                // Main content area with accessibility support
                Expanded(
                  child: AccessibilityHelper.createSemanticContainer(
                    label: l10n.accessibilityMainContent,
                    hint: l10n.accessibilityMainContentHint,
                    child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(Insets.medium),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              key: ValueKey('dashboard-${state.filteredApplications.length}'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Greeting with semantic header
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 500),
                                  opacity: 0.6,
                                  child: AccessibilityHelper.createSemanticHeader(
                                    child: Text(
                                      '${l10n.greeting},',
                                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // Welcome message
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: Insets.small,
                                    bottom: Insets.large,
                                  ),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 600),
                                    opacity: 1.0,
                                    child: Text(
                                      l10n.welcomeMessage,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.displayMedium,
                                    ),
                                  ),
                                ),

                                // Application grid with fade transition
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    child: ApplicationGrid(
                                      key: ValueKey('grid-${state.filteredApplications.length}'),
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
                                ),
                              ],
                            ),
                          ),
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
