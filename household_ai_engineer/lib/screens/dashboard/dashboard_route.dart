import 'package:flutter/material.dart';

import 'dashboard_controller.dart';

/// Displays a page for an authenticated user without any devices associated to their account. The page invites the
/// user to add a device to their account.
class DashboardRoute extends StatefulWidget {
  /// Creates and instance of [DashboardRoute].
  const DashboardRoute({super.key});

  @override
  State<DashboardRoute> createState() => DashboardController();
}
