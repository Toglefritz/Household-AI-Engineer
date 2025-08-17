import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:household_ai_engineer/l10n/app_localizations.dart';
import 'package:household_ai_engineer/theme/app_theme.dart';

/// Creates a test app wrapper with proper theme and localization setup.
///
/// This helper function provides a consistent testing environment with
/// the same theme and localization configuration used in the main app.
///
/// @param child The widget to wrap in the test app
/// @param theme Optional custom theme data (defaults to light theme)
/// @returns MaterialApp configured for testing
Widget createTestApp({
  required Widget child,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightThemeData,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en', ''),
    ],
    home: Scaffold(body: child),
  );
}

/// Creates a test app wrapper with dark theme.
///
/// Convenience method for testing widgets with dark theme styling.
///
/// @param child The widget to wrap in the test app
/// @returns MaterialApp configured with dark theme for testing
Widget createTestAppDark({
  required Widget child,
}) {
  return createTestApp(
    child: child,
    theme: AppTheme.darkThemeData,
  );
}
