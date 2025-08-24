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
  String systemStatusAvailableDeveloping(
    int availableApps,
    int developingApps,
  ) {
    return '$availableApps available • $developingApps developing';
  }

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipNotifications => 'Notifications';

  @override
  String get tooltipUserProfile => 'User Profile';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get applicationStatusRequested => 'Queued';

  @override
  String get applicationStatusDeveloping => 'Developing';

  @override
  String get applicationStatusTesting => 'Testing';

  @override
  String get applicationStatusReady => 'Ready';

  @override
  String get applicationStatusRunning => 'Running';

  @override
  String get applicationStatusFailed => 'Failed';

  @override
  String get applicationStatusUpdating => 'Updating';

  @override
  String get emptyStateTitle => 'No Applications Yet';

  @override
  String get emptyStateMessage =>
      'Create your first application to get started';

  @override
  String progressPercentagePhase(int percentage, String phase) {
    return '$percentage% • $phase';
  }

  @override
  String get conversationTitleCreate => 'Create New Application';

  @override
  String conversationTitleModify(String applicationName) {
    return 'Modify $applicationName';
  }

  @override
  String get conversationSubtitle =>
      'Describe what you need and I\'ll help you build it';

  @override
  String get conversationInputPlaceholder => 'Type your message...';

  @override
  String get conversationInputPlaceholderWaiting => 'Please wait...';

  @override
  String get conversationStartMessage => 'Start the conversation';

  @override
  String get conversationDevelopmentInProgress => 'Development in progress';

  @override
  String get conversationDevelopmentTimeExpectation =>
      'This process may take a few minutes to complete.';

  @override
  String get conversationDevelopmentBackgroundInfo =>
      'You can close this window and the development will continue in the background.';

  @override
  String get tooltipSendMessage => 'Send message';

  @override
  String get tooltipCloseConversation => 'Close';

  @override
  String get noApplications => 'No Applications Yet';

  @override
  String get createApplicationPrompt =>
      'Create your first application to get started';

  @override
  String get ready => 'Ready';

  @override
  String get queued => 'Queued';

  @override
  String get running => 'Running';

  @override
  String get failed => 'Failed';

  @override
  String get search => 'Search';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get searchApplicationsDialog => 'Search applications dialog';

  @override
  String searchingFor(String query) {
    return 'Searching for: $query';
  }

  @override
  String get openSearchDialogHint => 'Double tap to open search dialog';

  @override
  String sidebarCategoryLabel(String label) {
    return '$label category';
  }

  @override
  String sidebarCategoryHint(int count) {
    return '$count applications. Double tap to filter by this category.';
  }

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get typeMessage => 'Type your message...';

  @override
  String modifyApplication(String title) {
    return 'Modify $title';
  }

  @override
  String get createNewApplication => 'Create New Application';

  @override
  String get applicationCreationDescription =>
      'Describe what you need and I\'ll help you build it';

  @override
  String get close => 'Close';

  @override
  String get startConversation => 'Start the conversation';

  @override
  String get sendMessage => 'Send message';
}
