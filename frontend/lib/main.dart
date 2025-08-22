import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

/// Application entry point.
///
/// Initializes the Flutter application with proper window management for macOS desktop environment.
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure macOS window settings
  await windowManager.ensureInitialized();

  // Set up window properties for macOS
  const WindowOptions windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
  );

  // Apply window configuration
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Keep window always on top so the Kiro IDE can run in the background.
  await windowManager.setAlwaysOnTop(true);

  // Launch the application
  runApp(const HouseholdAIEngineerApp());
}
