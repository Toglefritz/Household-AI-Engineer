import 'package:flutter/material.dart';

import 'splash_controller.dart';

/// Entry point route for application initialization and routing.
///
/// This route handles the initial application startup process, including
/// setup state checking and routing to either the setup flow or main
/// dashboard based on the user's completion status.
///
/// The splash screen is shown briefly while the application determines
/// the appropriate initial route for the user.
class SplashRoute extends StatefulWidget {
  /// Creates the splash route widget.
  const SplashRoute({super.key});

  @override
  State<SplashRoute> createState() => SplashController();
}
