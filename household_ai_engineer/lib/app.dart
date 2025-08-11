import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/dashboard/dashboard_route.dart';
import 'theme/app_theme.dart';

/// Root application widget that configures the MaterialApp.
///
/// Provides theme configuration, routing setup, and overall app structure
/// following macOS design guidelines and Material 3 design system.
class HouseholdAIEngineerApp extends StatelessWidget {
  /// Creates the root application widget.
  const HouseholdAIEngineerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Household Software Engineer',
      debugShowCheckedModeBanner: false,

      // Localizations
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Themes
      theme: AppTheme.lightThemeData,
      darkTheme: AppTheme.darkThemeData,

      home: const DashboardRoute(),
    );
  }
}
