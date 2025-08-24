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

  // Read ALWAYS_ON_TOP flag from environment variable
  const String alwaysOnTopEnv = String.fromEnvironment(
    'ALWAYS_ON_TOP',
    defaultValue: 'true',
  );
  final bool alwaysOnTop = alwaysOnTopEnv.toLowerCase() == 'true';

  // Keep window always on top if the flag is true so the Kiro IDE can run in the background.
  if (alwaysOnTop) {
    await windowManager.setAlwaysOnTop(true);
  }

  // Launch the application
  runApp(const HouseholdAIEngineerApp());
}
