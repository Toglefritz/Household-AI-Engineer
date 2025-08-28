/// Test wrapper widget that provides necessary context for testing.
///
/// Wraps test widgets with MaterialApp and localization support
/// to provide the necessary context for accessibility testing.
library;

import 'package:dwellware/l10n/app_localizations.dart';
import 'package:dwellware/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Wrapper widget for testing that provides MaterialApp context.
///
/// Includes theme, localization, and other necessary providers
/// for testing widgets that depend on these contexts.
class TestAppWrapper extends StatelessWidget {
  /// Creates a test app wrapper.
  ///
  /// @param child The widget to wrap with test context
  /// @param theme Optional theme to use (defaults to light theme)
  /// @param highContrast Whether to simulate high contrast mode
  /// @param textScaleFactor Text scale factor for accessibility testing
  const TestAppWrapper({
    required this.child,
    this.theme,
    this.highContrast = false,
    this.textScaleFactor = 1.0,
    super.key,
  });

  /// The widget to wrap with test context.
  final Widget child;

  /// Optional theme to use for testing.
  final ThemeData? theme;

  /// Whether to simulate high contrast mode.
  final bool highContrast;

  /// Text scale factor for accessibility testing.
  final double textScaleFactor;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(
        highContrast: highContrast,
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: MaterialApp(
        theme: theme ?? AppTheme.lightThemeData,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }
}
