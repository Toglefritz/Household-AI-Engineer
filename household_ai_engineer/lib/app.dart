/// Main application widget for the Household Software Engineer.
///
/// This widget configures the overall app theme, routing, and provides
/// the root MaterialApp configuration for the macOS desktop application.
library;

import 'package:flutter/material.dart';

import 'screens/temporary_home_page.dart';

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

      // Theme configuration for light and dark modes
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // Blue primary color
          brightness: Brightness.light,
        ),
        // macOS-style typography
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.25),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3), brightness: Brightness.dark),
      ),

      // Follow system theme preference
      themeMode: ThemeMode.system,

      // Temporary home page - will be replaced with dashboard
      home: const TemporaryHomePage(),
    );
  }
}
