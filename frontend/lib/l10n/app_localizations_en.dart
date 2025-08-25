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
  String get sidebarTitle => 'Dwellware';

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

  @override
  String get back => 'Back';

  @override
  String get forward => 'Forward';

  @override
  String get refresh => 'Refresh';

  @override
  String get buttonLaunchApplication => 'Launch';

  @override
  String get buttonBringToForeground => 'Bring to Foreground';

  @override
  String get buttonRestartApplication => 'Restart';

  @override
  String get buttonStopApplication => 'Stop';

  @override
  String get buttonModifyApplication => 'Modify';

  @override
  String get buttonViewDetails => 'View Details';

  @override
  String get buttonRetryApplication => 'Retry';

  @override
  String get buttonDeleteApplication => 'Delete';

  @override
  String get buttonAddToFavorites => 'Add to Favorites';

  @override
  String get buttonRemoveFromFavorites => 'Remove from Favorites';

  @override
  String get selectAll => 'Select All';

  @override
  String get selectNone => 'Select None';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get bulkActionsTitle => 'Bulk Actions';

  @override
  String get bulkDeleteConfirmTitle => 'Delete Applications';

  @override
  String bulkDeleteConfirmMessage(int count) {
    return 'Are you sure you want to delete $count applications? This action cannot be undone.';
  }

  @override
  String get deleteConfirmTitle => 'Delete Application';

  @override
  String deleteConfirmMessage(String title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String get buttonDelete => 'Delete';

  @override
  String get applicationStopped => 'Application stopped';

  @override
  String get applicationRestarted => 'Application restarted';

  @override
  String get applicationDeleted => 'Application deleted';

  @override
  String applicationsDeleted(int count) {
    return '$count applications deleted';
  }

  @override
  String get applicationAddedToFavorites => 'Added to favorites';

  @override
  String get applicationRemovedFromFavorites => 'Removed from favorites';

  @override
  String get conversationProcessingMessage => 'Processing your request';

  @override
  String get filters => 'Filters';

  @override
  String get categories => 'Categories';

  @override
  String get status => 'Status';

  @override
  String get dateRange => 'Date Range';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get noDateSelected => 'No date selected';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String get sortBy => 'Sort by';

  @override
  String get newest => 'Newest';

  @override
  String get oldest => 'Oldest';

  @override
  String get recentlyUpdated => 'Recently Updated';

  @override
  String get leastRecentlyUpdated => 'Least Recently Updated';

  @override
  String get titleAZ => 'Title A-Z';

  @override
  String get titleZA => 'Title Z-A';

  @override
  String get statusPriority => 'Status Priority';

  @override
  String get oneResult => '1 result';

  @override
  String multipleResults(int count) {
    return '$count results';
  }

  @override
  String get noSearchResults => 'No applications match your search';

  @override
  String get oneSearchResult => '1 application matches your search';

  @override
  String multipleSearchResults(int count) {
    return '$count applications match your search';
  }

  @override
  String get noFilterResults => 'No applications match the current filters';

  @override
  String allApplicationsShown(int count) {
    return 'All $count applications shown';
  }

  @override
  String filteredApplicationsShown(int filtered, int total) {
    return 'Showing $filtered of $total applications';
  }

  @override
  String applicationCount(int count) {
    return '$count applications';
  }

  @override
  String get setupCheckingKiro => 'Checking for Kiro IDE...';

  @override
  String get setupCheckingKiroDescription =>
      'Please wait while we verify your Kiro installation.';

  @override
  String get setupKiroRequired => 'Kiro IDE Required';

  @override
  String get setupKiroRequiredDescription =>
      'To use Dwellware, you need to have Kiro IDE installed on your system. Please download and install Kiro from the official website.';

  @override
  String get setupDownloadKiro => 'Download Kiro IDE';

  @override
  String get setupContinue => 'Continue';

  @override
  String get setupChecking => 'Checking...';

  @override
  String get setupWelcome => 'Welcome to Dwellware!';

  @override
  String setupKiroDetected(String version) {
    return 'Kiro IDE $version detected';
  }

  @override
  String get setupTutorialDescription =>
      'Let\'s get you started with creating and managing your custom applications.';

  @override
  String get setupTutorialTitle => 'Quick Start Guide';

  @override
  String get setupTutorialStep1Title => 'Create Applications';

  @override
  String get setupTutorialStep1Description =>
      'Describe what you need in natural language and let AI build it for you.';

  @override
  String get setupTutorialStep2Title => 'Monitor Development';

  @override
  String get setupTutorialStep2Description =>
      'Watch real-time progress as your applications are developed and tested.';

  @override
  String get setupTutorialStep3Title => 'Launch and Use';

  @override
  String get setupTutorialStep3Description =>
      'Once ready, launch your applications directly from the dashboard.';

  @override
  String get setupSkipTutorial => 'Skip Tutorial';

  @override
  String get setupGetStarted => 'Get Started';

  @override
  String get splashTitle => 'Dwellware';

  @override
  String get splashSubtitle => 'AI-Powered Home Application Development';

  @override
  String get splashInitializing => 'Initializing application...';

  @override
  String get splashInitializationFailed => 'Initialization Failed';

  @override
  String get splashRetry => 'Retry';

  @override
  String get splashForceSetup => 'Go to Setup';

  @override
  String accessibilityApplicationTile(String title) {
    return 'Application tile for $title';
  }

  @override
  String accessibilityApplicationTileHint(String status, String description) {
    return 'Status: $status. $description. Double tap to launch, long press for options.';
  }

  @override
  String accessibilityApplicationTileHintDeveloping(
    String status,
    String description,
    int progress,
  ) {
    return 'Status: $status. $description. Progress: $progress%. Double tap for details.';
  }

  @override
  String get accessibilityApplicationGrid => 'Application grid';

  @override
  String accessibilityApplicationGridHint(int count) {
    return 'Grid containing $count applications. Use arrow keys to navigate.';
  }

  @override
  String get accessibilityCreateNewAppTile => 'Create new application';

  @override
  String get accessibilityCreateNewAppTileHint =>
      'Double tap to start creating a new application';

  @override
  String get accessibilitySidebar => 'Navigation sidebar';

  @override
  String get accessibilitySidebarHint =>
      'Contains navigation, search, and application categories';

  @override
  String get accessibilitySidebarToggle => 'Toggle sidebar';

  @override
  String accessibilitySidebarToggleHint(String action) {
    return 'Double tap to $action the sidebar';
  }

  @override
  String get accessibilitySearchField => 'Search applications';

  @override
  String get accessibilitySearchFieldHint =>
      'Type to search through your applications';

  @override
  String get accessibilitySearchClear => 'Clear search';

  @override
  String get accessibilitySearchClearHint =>
      'Double tap to clear the current search';

  @override
  String accessibilityNavigationItem(String label) {
    return '$label navigation';
  }

  @override
  String accessibilityNavigationItemHint(String label) {
    return 'Double tap to filter applications by $label';
  }

  @override
  String accessibilityCategoryItem(String category) {
    return '$category category';
  }

  @override
  String accessibilityCategoryItemHint(int count) {
    return '$count applications in this category. Double tap to filter.';
  }

  @override
  String get accessibilityStatusBar => 'System status bar';

  @override
  String get accessibilityStatusBarHint =>
      'Shows connection status and system information';

  @override
  String accessibilityConnectionStatus(String status) {
    return 'Connection status: $status';
  }

  @override
  String get accessibilityConversationModal =>
      'Application creation conversation';

  @override
  String get accessibilityConversationModalHint =>
      'Chat interface for creating or modifying applications';

  @override
  String accessibilityConversationMessage(String sender) {
    return 'Message from $sender';
  }

  @override
  String get accessibilityConversationInput => 'Message input';

  @override
  String get accessibilityConversationInputHint =>
      'Type your message to the assistant';

  @override
  String get accessibilityConversationSend => 'Send message';

  @override
  String get accessibilityConversationSendHint =>
      'Double tap to send your message';

  @override
  String get accessibilityConversationClose => 'Close conversation';

  @override
  String get accessibilityConversationCloseHint =>
      'Double tap to close the conversation and return to dashboard';

  @override
  String get accessibilityProgressIndicator => 'Development progress';

  @override
  String accessibilityProgressIndicatorHint(int percentage, String phase) {
    return '$percentage% complete. Current phase: $phase';
  }

  @override
  String get accessibilityBulkSelectionToolbar => 'Bulk selection toolbar';

  @override
  String accessibilityBulkSelectionToolbarHint(int count) {
    return '$count applications selected. Actions available.';
  }

  @override
  String get accessibilityMainContent => 'Main content area';

  @override
  String get accessibilityMainContentHint =>
      'Contains application grid and primary interface';

  @override
  String get accessibilityEmptyState => 'No applications';

  @override
  String get accessibilityEmptyStateHint =>
      'You haven\'t created any applications yet. Use the create button to get started.';

  @override
  String get expand => 'expand';

  @override
  String get collapse => 'collapse';

  @override
  String get user => 'user';

  @override
  String get assistant => 'assistant';
}
