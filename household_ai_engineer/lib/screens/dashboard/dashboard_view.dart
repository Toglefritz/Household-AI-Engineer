import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/insets.dart';
import 'components/dashboard_sidebar.dart';
import 'components/dashboard_status_bar.dart';
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
          ),

          // Main content area with sidebar
          Expanded(
            child: Row(
              children: [
                // Sidebar
                DashboardSidebar(
                  isExpanded: state.isSidebarExpanded,
                  onToggle: state.toggleSidebar,
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
                              padding: const EdgeInsets.only(top: Insets.small, bottom: Insets.large),
                              child: Text(
                                AppLocalizations.of(context)!.welcomeMessage,
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ),

                            // Placeholder for future application grid
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.apps,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.only(top: Insets.large),
                                      child: Text(
                                        'Application grid will be implemented in future tasks',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.tertiary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
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
