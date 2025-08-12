// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get greeting => 'Hello';

  @override
  String get welcomeMessage => 'How can I help you today?';

  @override
  String get sidebarTitle => 'Household Engineer';

  @override
  String get sidebarToggleCollapse => 'Collapse sidebar';

  @override
  String get sidebarToggleExpand => 'Expand sidebar';

  @override
  String get searchApplicationsHint => 'Search applications...';

  @override
  String get navAllApplications => 'All Applications';

  @override
  String get navRecent => 'Recent';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navInDevelopment => 'In Development';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoryHomeManagement => 'Home Management';

  @override
  String get categoryFinance => 'Finance';

  @override
  String get categoryPlanning => 'Planning';

  @override
  String get categoryHealthFitness => 'Health & Fitness';

  @override
  String get categoryEducation => 'Education';

  @override
  String get buttonCreateNewApp => 'Create New App';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDegraded => 'Degraded';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get statusConnecting => 'Connecting...';

  @override
  String systemStatusRunningDeveloping(int activeApps, int developingApps) {
    return '$activeApps running • $developingApps developing';
  }

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipNotifications => 'Notifications';

  @override
  String get tooltipUserProfile => 'User Profile';

  @override
  String get buttonCancel => 'Cancel';
}
