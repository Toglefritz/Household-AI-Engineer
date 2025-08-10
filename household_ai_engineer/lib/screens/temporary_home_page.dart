/// Temporary Home Page Screen
///
/// This module contains the temporary home page widget that serves as a
/// placeholder during initial project setup. This screen displays a welcome
/// message and confirms that the Flutter project setup is complete.
///
/// This temporary screen will be replaced with the actual dashboard
/// implementation in subsequent development phases.
library;

import 'package:flutter/material.dart';

/// Temporary home page widget for initial project setup.
///
/// This widget serves as a placeholder home screen that displays
/// a welcome message and project status information. It provides
/// visual confirmation that the Flutter application is properly
/// configured and ready for dashboard implementation.
///
/// Key Features:
/// * Displays application branding with icon and title
/// * Shows project setup completion status
/// * Follows Material 3 design guidelines
/// * Responsive layout that works across different screen sizes
///
/// This screen will be replaced with the actual dashboard once
/// the dashboard components are implemented in later tasks.
class TemporaryHomePage extends StatelessWidget {
  /// Creates a new temporary home page widget.
  ///
  /// This widget requires no parameters and displays static content
  /// to confirm successful project setup and readiness for development.
  const TemporaryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Household Software Engineer',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Flutter project setup complete!\nReady for dashboard implementation.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
