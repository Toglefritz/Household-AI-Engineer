import 'package:flutter/material.dart';

import 'setup_controller.dart';

/// Entry point route for the application setup flow.
///
/// This route manages the initial setup process for new users, including
/// Kiro IDE detection and tutorial presentation. The setup flow ensures
/// that all required dependencies are available before allowing access
/// to the main application features.
///
/// The route follows the MVC pattern by delegating all business logic
/// to the [SetupController] and serving only as the entry point.
class SetupRoute extends StatefulWidget {
  /// Creates the setup route widget.
  const SetupRoute({super.key});

  @override
  State<SetupRoute> createState() => SetupController();
}
