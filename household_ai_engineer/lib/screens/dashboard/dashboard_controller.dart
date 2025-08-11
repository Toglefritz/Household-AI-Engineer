import 'package:flutter/material.dart';

import 'dashboard_route.dart';
import 'dashboard_view.dart';

/// Controller for [DashboardRoute].
class DashboardController extends State<DashboardRoute> {
  @override
  Widget build(BuildContext context) => HomeView(this);
}
