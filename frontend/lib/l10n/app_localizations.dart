import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// A greeting displayed to the user
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get greeting;

  /// A message welcoming the user to the app
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get welcomeMessage;

  /// Title displayed in the sidebar header
  ///
  /// In en, this message translates to:
  /// **'Dwellware'**
  String get sidebarTitle;

  /// Tooltip for the sidebar collapse button
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get sidebarToggleCollapse;

  /// Tooltip for the sidebar expand button
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get sidebarToggleExpand;

  /// Hint text for the application search field
  ///
  /// In en, this message translates to:
  /// **'Search applications...'**
  String get searchApplicationsHint;

  /// Navigation item for viewing all applications
  ///
  /// In en, this message translates to:
  /// **'All Applications'**
  String get navAllApplications;

  /// Navigation item for viewing recent applications
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get navRecent;

  /// Navigation item for viewing favorite applications
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// Navigation item for viewing applications currently in development
  ///
  /// In en, this message translates to:
  /// **'In Development'**
  String get navInDevelopment;

  /// Title for the categories section in the sidebar
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// Category for home management applications
  ///
  /// In en, this message translates to:
  /// **'Home Management'**
  String get categoryHomeManagement;

  /// Category for finance applications
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get categoryFinance;

  /// Category for planning applications
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get categoryPlanning;

  /// Category for health and fitness applications
  ///
  /// In en, this message translates to:
  /// **'Health & Fitness'**
  String get categoryHealthFitness;

  /// Category for education applications
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// Button text for creating a new application
  ///
  /// In en, this message translates to:
  /// **'Create New App'**
  String get buttonCreateNewApp;

  /// Status indicator showing system is connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// Status indicator showing system performance is degraded
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get statusDegraded;

  /// Status indicator showing system is disconnected
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get statusDisconnected;

  /// Status indicator showing system is attempting to connect
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get statusConnecting;

  /// System status showing number of available and developing applications
  ///
  /// In en, this message translates to:
  /// **'{availableApps} available • {developingApps} developing'**
  String systemStatusAvailableDeveloping(int availableApps, int developingApps);

  /// Tooltip for the settings button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// Tooltip for the notifications button
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tooltipNotifications;

  /// Tooltip for the user profile button
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get tooltipUserProfile;

  /// Text for a cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// Status label for applications that have been requested but not started
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get applicationStatusRequested;

  /// Status label for applications currently being developed
  ///
  /// In en, this message translates to:
  /// **'Developing'**
  String get applicationStatusDeveloping;

  /// Status label for applications currently being tested
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get applicationStatusTesting;

  /// Status label for applications that are ready to launch
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get applicationStatusReady;

  /// Status label for applications that are currently running
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get applicationStatusRunning;

  /// Status label for applications that have failed to build or deploy
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get applicationStatusFailed;

  /// Status label for applications that are being updated
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get applicationStatusUpdating;

  /// Title shown when no applications are available
  ///
  /// In en, this message translates to:
  /// **'No Applications Yet'**
  String get emptyStateTitle;

  /// Message shown when no applications are available
  ///
  /// In en, this message translates to:
  /// **'Create your first application to get started'**
  String get emptyStateMessage;

  /// Format for showing development progress percentage and current phase
  ///
  /// In en, this message translates to:
  /// **'{percentage}% • {phase}'**
  String progressPercentagePhase(int percentage, String phase);

  /// Title for the conversation modal when creating a new application
  ///
  /// In en, this message translates to:
  /// **'Create New Application'**
  String get conversationTitleCreate;

  /// Title for the conversation modal when modifying an application
  ///
  /// In en, this message translates to:
  /// **'Modify {applicationName}'**
  String conversationTitleModify(String applicationName);

  /// Subtitle text for the conversation modal
  ///
  /// In en, this message translates to:
  /// **'Describe what you need and I\'ll help you build it'**
  String get conversationSubtitle;

  /// Placeholder text for the conversation input field
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get conversationInputPlaceholder;

  /// Placeholder text when the system is processing
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get conversationInputPlaceholderWaiting;

  /// Message shown when no conversation messages exist yet
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get conversationStartMessage;

  /// Title shown when application development is ongoing
  ///
  /// In en, this message translates to:
  /// **'Development in progress'**
  String get conversationDevelopmentInProgress;

  /// Message explaining that development takes time
  ///
  /// In en, this message translates to:
  /// **'This process may take a few minutes to complete.'**
  String get conversationDevelopmentTimeExpectation;

  /// Message explaining that development continues in background
  ///
  /// In en, this message translates to:
  /// **'You can close this window and the development will continue in the background.'**
  String get conversationDevelopmentBackgroundInfo;

  /// Tooltip for the send message button
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get tooltipSendMessage;

  /// Tooltip for the close conversation button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tooltipCloseConversation;

  /// A message displayed to the user when they have not yet added an application
  ///
  /// In en, this message translates to:
  /// **'No Applications Yet'**
  String get noApplications;

  /// A message to the user asking that they create an application to get started
  ///
  /// In en, this message translates to:
  /// **'Create your first application to get started'**
  String get createApplicationPrompt;

  /// A generic message indicating that a system is ready
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// Describes the status of an entity that is awaiting further action
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queued;

  /// Describes the status of a system that is currently operational
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// Describes an operation that has not completed successfully
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Indicates functionality related to finding entities
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Text for a button used to clear a search field
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Semantic label for a button associated with the application search functionality
  ///
  /// In en, this message translates to:
  /// **'Search applications dialog'**
  String get searchApplicationsDialog;

  /// An indicator of the query for which a search is being conducted
  ///
  /// In en, this message translates to:
  /// **'Searching for: {query}'**
  String searchingFor(String query);

  /// A hint for how to open the search dialog
  ///
  /// In en, this message translates to:
  /// **'Double tap to open search dialog'**
  String get openSearchDialogHint;

  /// Semantics label for a sidebar category icon when the sidebar is collapsed.
  ///
  /// In en, this message translates to:
  /// **'{label} category'**
  String sidebarCategoryLabel(String label);

  /// Semantics hint for a sidebar category icon in collapsed state. Tells the user how many apps are in the category and the action.
  ///
  /// In en, this message translates to:
  /// **'{count} applications. Double tap to filter by this category.'**
  String sidebarCategoryHint(int count);

  /// A generic message requesting that the user wait for a loading operation to complete
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// Placeholder text for the field used to collect user input in the application creation flow
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// Title shown when modifying an existing application
  ///
  /// In en, this message translates to:
  /// **'Modify {title}'**
  String modifyApplication(String title);

  /// A title for the dialog forming the main part of the application creation flow
  ///
  /// In en, this message translates to:
  /// **'Create New Application'**
  String get createNewApplication;

  /// A description for the application creation dialog
  ///
  /// In en, this message translates to:
  /// **'Describe what you need and I\'ll help you build it'**
  String get applicationCreationDescription;

  /// A generic message for dismissing an interface in the application
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// A prompt nto the user to start the application creation flow
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get startConversation;

  /// A tooltip for the interface allowing the user to send a message to the agent
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// Navigation button to go back in browser history
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Navigation button to go forward in browser history
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// Button to refresh the current page
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Button to launch an application
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get buttonLaunchApplication;

  /// Button to bring a running application to the foreground
  ///
  /// In en, this message translates to:
  /// **'Bring to Foreground'**
  String get buttonBringToForeground;

  /// Button to restart a running application
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get buttonRestartApplication;

  /// Button to stop a running application
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get buttonStopApplication;

  /// Button to modify an existing application
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get buttonModifyApplication;

  /// Button to view application details
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get buttonViewDetails;

  /// Button to retry a failed application
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetryApplication;

  /// Button to delete an application
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buttonDeleteApplication;

  /// Button to add an application to favorites
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get buttonAddToFavorites;

  /// Button to remove an application from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get buttonRemoveFromFavorites;

  /// Button to select all applications
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// Button to deselect all applications
  ///
  /// In en, this message translates to:
  /// **'Select None'**
  String get selectNone;

  /// Shows the number of selected applications
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// Title for bulk actions menu
  ///
  /// In en, this message translates to:
  /// **'Bulk Actions'**
  String get bulkActionsTitle;

  /// Title for bulk delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Applications'**
  String get bulkDeleteConfirmTitle;

  /// Message for bulk delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} applications? This action cannot be undone.'**
  String bulkDeleteConfirmMessage(int count);

  /// Title for single application delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Application'**
  String get deleteConfirmTitle;

  /// Message for single application delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String deleteConfirmMessage(String title);

  /// Generic delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buttonDelete;

  /// Message shown when an application is stopped
  ///
  /// In en, this message translates to:
  /// **'Application stopped'**
  String get applicationStopped;

  /// Message shown when an application is restarted
  ///
  /// In en, this message translates to:
  /// **'Application restarted'**
  String get applicationRestarted;

  /// Message shown when an application is deleted
  ///
  /// In en, this message translates to:
  /// **'Application deleted'**
  String get applicationDeleted;

  /// Message shown when multiple applications are deleted
  ///
  /// In en, this message translates to:
  /// **'{count} applications deleted'**
  String applicationsDeleted(int count);

  /// Message shown when an application is added to favorites
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get applicationAddedToFavorites;

  /// Message shown when an application is removed from favorites
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get applicationRemovedFromFavorites;

  /// Message shown when the system is analyzing user input before specific progress is available
  ///
  /// In en, this message translates to:
  /// **'Processing your request'**
  String get conversationProcessingMessage;

  /// Title for the filters panel
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Title for the categories filter section
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Title for the status filter section
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Title for the date range filter section
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// Label for the start date picker
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// Label for the end date picker
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// Text shown when no date is selected
  ///
  /// In en, this message translates to:
  /// **'No date selected'**
  String get noDateSelected;

  /// Button text to clear all active filters
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// Label for sort controls
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Short label for newest first sort option
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// Short label for oldest first sort option
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// Short label for recently updated sort option
  ///
  /// In en, this message translates to:
  /// **'Recently Updated'**
  String get recentlyUpdated;

  /// Short label for least recently updated sort option
  ///
  /// In en, this message translates to:
  /// **'Least Recently Updated'**
  String get leastRecentlyUpdated;

  /// Short label for alphabetical title sort
  ///
  /// In en, this message translates to:
  /// **'Title A-Z'**
  String get titleAZ;

  /// Short label for reverse alphabetical title sort
  ///
  /// In en, this message translates to:
  /// **'Title Z-A'**
  String get titleZA;

  /// Short label for status priority sort
  ///
  /// In en, this message translates to:
  /// **'Status Priority'**
  String get statusPriority;

  /// Text shown when there is exactly one result
  ///
  /// In en, this message translates to:
  /// **'1 result'**
  String get oneResult;

  /// Text shown when there are multiple results
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String multipleResults(int count);

  /// Message shown when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No applications match your search'**
  String get noSearchResults;

  /// Message shown when search returns exactly one result
  ///
  /// In en, this message translates to:
  /// **'1 application matches your search'**
  String get oneSearchResult;

  /// Message shown when search returns multiple results
  ///
  /// In en, this message translates to:
  /// **'{count} applications match your search'**
  String multipleSearchResults(int count);

  /// Message shown when filters return no results
  ///
  /// In en, this message translates to:
  /// **'No applications match the current filters'**
  String get noFilterResults;

  /// Message shown when all applications are displayed
  ///
  /// In en, this message translates to:
  /// **'All {count} applications shown'**
  String allApplicationsShown(int count);

  /// Message shown when filters are applied
  ///
  /// In en, this message translates to:
  /// **'Showing {filtered} of {total} applications'**
  String filteredApplicationsShown(int filtered, int total);

  /// Shows the count of applications in a category or status
  ///
  /// In en, this message translates to:
  /// **'{count} applications'**
  String applicationCount(int count);

  /// Message shown while checking if Kiro IDE is installed
  ///
  /// In en, this message translates to:
  /// **'Checking for Kiro IDE...'**
  String get setupCheckingKiro;

  /// Description shown during Kiro installation check
  ///
  /// In en, this message translates to:
  /// **'Please wait while we verify your Kiro installation.'**
  String get setupCheckingKiroDescription;

  /// Title shown when Kiro IDE is not installed
  ///
  /// In en, this message translates to:
  /// **'Kiro IDE Required'**
  String get setupKiroRequired;

  /// Description explaining why Kiro IDE is required
  ///
  /// In en, this message translates to:
  /// **'To use Dwellware, you need to have Kiro IDE installed on your system. Please download and install Kiro from the official website.'**
  String get setupKiroRequiredDescription;

  /// Button text to download Kiro IDE
  ///
  /// In en, this message translates to:
  /// **'Download Kiro IDE'**
  String get setupDownloadKiro;

  /// Button text to continue after installing Kiro
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get setupContinue;

  /// Text shown on button while checking for Kiro
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get setupChecking;

  /// Welcome message in the tutorial phase
  ///
  /// In en, this message translates to:
  /// **'Welcome to Dwellware!'**
  String get setupWelcome;

  /// Message confirming Kiro IDE version is detected
  ///
  /// In en, this message translates to:
  /// **'Kiro IDE {version} detected'**
  String setupKiroDetected(String version);

  /// Description for the tutorial phase
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you started with creating and managing your custom applications.'**
  String get setupTutorialDescription;

  /// Title for the tutorial section
  ///
  /// In en, this message translates to:
  /// **'Quick Start Guide'**
  String get setupTutorialTitle;

  /// Title for tutorial step 1
  ///
  /// In en, this message translates to:
  /// **'Create Applications'**
  String get setupTutorialStep1Title;

  /// Description for tutorial step 1
  ///
  /// In en, this message translates to:
  /// **'Describe what you need in natural language and let AI build it for you.'**
  String get setupTutorialStep1Description;

  /// Title for tutorial step 2
  ///
  /// In en, this message translates to:
  /// **'Monitor Development'**
  String get setupTutorialStep2Title;

  /// Description for tutorial step 2
  ///
  /// In en, this message translates to:
  /// **'Watch real-time progress as your applications are developed and tested.'**
  String get setupTutorialStep2Description;

  /// Title for tutorial step 3
  ///
  /// In en, this message translates to:
  /// **'Launch and Use'**
  String get setupTutorialStep3Title;

  /// Description for tutorial step 3
  ///
  /// In en, this message translates to:
  /// **'Once ready, launch your applications directly from the dashboard.'**
  String get setupTutorialStep3Description;

  /// Button text to skip the tutorial
  ///
  /// In en, this message translates to:
  /// **'Skip Tutorial'**
  String get setupSkipTutorial;

  /// Button text to complete setup and enter the main app
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get setupGetStarted;

  /// Application title shown on splash screen
  ///
  /// In en, this message translates to:
  /// **'Dwellware'**
  String get splashTitle;

  /// Application subtitle shown on splash screen
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Home Application Development'**
  String get splashSubtitle;

  /// Message shown while app is initializing
  ///
  /// In en, this message translates to:
  /// **'Initializing application...'**
  String get splashInitializing;

  /// Title shown when app initialization fails
  ///
  /// In en, this message translates to:
  /// **'Initialization Failed'**
  String get splashInitializationFailed;

  /// Button text to retry initialization
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get splashRetry;

  /// Button text to bypass initialization and go to setup
  ///
  /// In en, this message translates to:
  /// **'Go to Setup'**
  String get splashForceSetup;

  /// Semantic label for application tiles
  ///
  /// In en, this message translates to:
  /// **'Application tile for {title}'**
  String accessibilityApplicationTile(String title);

  /// Semantic hint for application tiles
  ///
  /// In en, this message translates to:
  /// **'Status: {status}. {description}. Double tap to launch, long press for options.'**
  String accessibilityApplicationTileHint(String status, String description);

  /// Semantic hint for developing application tiles
  ///
  /// In en, this message translates to:
  /// **'Status: {status}. {description}. Progress: {progress}%. Double tap for details.'**
  String accessibilityApplicationTileHintDeveloping(
    String status,
    String description,
    int progress,
  );

  /// Semantic label for the application grid
  ///
  /// In en, this message translates to:
  /// **'Application grid'**
  String get accessibilityApplicationGrid;

  /// Semantic hint for the application grid
  ///
  /// In en, this message translates to:
  /// **'Grid containing {count} applications. Use arrow keys to navigate.'**
  String accessibilityApplicationGridHint(int count);

  /// Semantic label for the create new app tile
  ///
  /// In en, this message translates to:
  /// **'Create new application'**
  String get accessibilityCreateNewAppTile;

  /// Semantic hint for the create new app tile
  ///
  /// In en, this message translates to:
  /// **'Double tap to start creating a new application'**
  String get accessibilityCreateNewAppTileHint;

  /// Semantic label for the sidebar
  ///
  /// In en, this message translates to:
  /// **'Navigation sidebar'**
  String get accessibilitySidebar;

  /// Semantic hint for the sidebar
  ///
  /// In en, this message translates to:
  /// **'Contains navigation, search, and application categories'**
  String get accessibilitySidebarHint;

  /// Semantic label for the sidebar toggle button
  ///
  /// In en, this message translates to:
  /// **'Toggle sidebar'**
  String get accessibilitySidebarToggle;

  /// Semantic hint for the sidebar toggle button
  ///
  /// In en, this message translates to:
  /// **'Double tap to {action} the sidebar'**
  String accessibilitySidebarToggleHint(String action);

  /// Semantic label for the search field
  ///
  /// In en, this message translates to:
  /// **'Search applications'**
  String get accessibilitySearchField;

  /// Semantic hint for the search field
  ///
  /// In en, this message translates to:
  /// **'Type to search through your applications'**
  String get accessibilitySearchFieldHint;

  /// Semantic label for the search clear button
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get accessibilitySearchClear;

  /// Semantic hint for the search clear button
  ///
  /// In en, this message translates to:
  /// **'Double tap to clear the current search'**
  String get accessibilitySearchClearHint;

  /// Semantic label for navigation items
  ///
  /// In en, this message translates to:
  /// **'{label} navigation'**
  String accessibilityNavigationItem(String label);

  /// Semantic hint for navigation items
  ///
  /// In en, this message translates to:
  /// **'Double tap to filter applications by {label}'**
  String accessibilityNavigationItemHint(String label);

  /// Semantic label for category items
  ///
  /// In en, this message translates to:
  /// **'{category} category'**
  String accessibilityCategoryItem(String category);

  /// Semantic hint for category items
  ///
  /// In en, this message translates to:
  /// **'{count} applications in this category. Double tap to filter.'**
  String accessibilityCategoryItemHint(int count);

  /// Semantic label for the status bar
  ///
  /// In en, this message translates to:
  /// **'System status bar'**
  String get accessibilityStatusBar;

  /// Semantic hint for the status bar
  ///
  /// In en, this message translates to:
  /// **'Shows connection status and system information'**
  String get accessibilityStatusBarHint;

  /// Semantic label for connection status
  ///
  /// In en, this message translates to:
  /// **'Connection status: {status}'**
  String accessibilityConnectionStatus(String status);

  /// Semantic label for the conversation modal
  ///
  /// In en, this message translates to:
  /// **'Application creation conversation'**
  String get accessibilityConversationModal;

  /// Semantic hint for the conversation modal
  ///
  /// In en, this message translates to:
  /// **'Chat interface for creating or modifying applications'**
  String get accessibilityConversationModalHint;

  /// Semantic label for conversation messages
  ///
  /// In en, this message translates to:
  /// **'Message from {sender}'**
  String accessibilityConversationMessage(String sender);

  /// Semantic label for the conversation input field
  ///
  /// In en, this message translates to:
  /// **'Message input'**
  String get accessibilityConversationInput;

  /// Semantic hint for the conversation input field
  ///
  /// In en, this message translates to:
  /// **'Type your message to the assistant'**
  String get accessibilityConversationInputHint;

  /// Semantic label for the send message button
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get accessibilityConversationSend;

  /// Semantic hint for the send message button
  ///
  /// In en, this message translates to:
  /// **'Double tap to send your message'**
  String get accessibilityConversationSendHint;

  /// Semantic label for the close conversation button
  ///
  /// In en, this message translates to:
  /// **'Close conversation'**
  String get accessibilityConversationClose;

  /// Semantic hint for the close conversation button
  ///
  /// In en, this message translates to:
  /// **'Double tap to close the conversation and return to dashboard'**
  String get accessibilityConversationCloseHint;

  /// Semantic label for progress indicators
  ///
  /// In en, this message translates to:
  /// **'Development progress'**
  String get accessibilityProgressIndicator;

  /// Semantic hint for progress indicators
  ///
  /// In en, this message translates to:
  /// **'{percentage}% complete. Current phase: {phase}'**
  String accessibilityProgressIndicatorHint(int percentage, String phase);

  /// Semantic label for the bulk selection toolbar
  ///
  /// In en, this message translates to:
  /// **'Bulk selection toolbar'**
  String get accessibilityBulkSelectionToolbar;

  /// Semantic hint for the bulk selection toolbar
  ///
  /// In en, this message translates to:
  /// **'{count} applications selected. Actions available.'**
  String accessibilityBulkSelectionToolbarHint(int count);

  /// Semantic label for the main content area
  ///
  /// In en, this message translates to:
  /// **'Main content area'**
  String get accessibilityMainContent;

  /// Semantic hint for the main content area
  ///
  /// In en, this message translates to:
  /// **'Contains application grid and primary interface'**
  String get accessibilityMainContentHint;

  /// Semantic label for the empty state
  ///
  /// In en, this message translates to:
  /// **'No applications'**
  String get accessibilityEmptyState;

  /// Semantic hint for the empty state
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any applications yet. Use the create button to get started.'**
  String get accessibilityEmptyStateHint;

  /// Action word for expanding something
  ///
  /// In en, this message translates to:
  /// **'expand'**
  String get expand;

  /// Action word for collapsing something
  ///
  /// In en, this message translates to:
  /// **'collapse'**
  String get collapse;

  /// Label for user messages in conversation
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get user;

  /// Label for assistant messages in conversation
  ///
  /// In en, this message translates to:
  /// **'assistant'**
  String get assistant;

  /// Section title for application description in details dialog
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailsDescription;

  /// Section title for development progress in details dialog
  ///
  /// In en, this message translates to:
  /// **'Development Progress'**
  String get detailsDevelopmentProgress;

  /// Section title for application information in details dialog
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get detailsInformation;

  /// Label for creation date in application details
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get detailsCreated;

  /// Label for last updated date in application details
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get detailsLastUpdated;

  /// Label for application category in details
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get detailsCategory;

  /// Label for application tags in details
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get detailsTags;

  /// Error message when application launcher service is not ready
  ///
  /// In en, this message translates to:
  /// **'Application launcher not ready. Please try again.'**
  String get errorApplicationLauncherNotReady;

  /// Error message when application launch fails
  ///
  /// In en, this message translates to:
  /// **'Failed to launch {title}: {error}'**
  String errorFailedToLaunch(String title, String error);

  /// Error message when application restart fails
  ///
  /// In en, this message translates to:
  /// **'Failed to restart {title}: {error}'**
  String errorFailedToRestart(String title, String error);

  /// Error message when application stop fails
  ///
  /// In en, this message translates to:
  /// **'Failed to stop {title}: {error}'**
  String errorFailedToStop(String title, String error);

  /// Error message when updating favorite status fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorite status for {title}: {error}'**
  String errorFailedToUpdateFavorite(String title, String error);

  /// Error message when application deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete {title}: {error}'**
  String errorFailedToDelete(String title, String error);

  /// Error message when application fails to load in webview
  ///
  /// In en, this message translates to:
  /// **'Error loading application: {message}'**
  String errorLoadingApplication(String message);

  /// Message shown while application is loading in webview
  ///
  /// In en, this message translates to:
  /// **'Loading application...'**
  String get loadingApplication;

  /// Message shown while application window is initializing
  ///
  /// In en, this message translates to:
  /// **'Initializing application window...'**
  String get initializingApplicationWindow;

  /// Label for chore tracker suggestion button
  ///
  /// In en, this message translates to:
  /// **'Chore Tracker'**
  String get suggestionChoreTracker;

  /// Label for budget planner suggestion button
  ///
  /// In en, this message translates to:
  /// **'Budget Planner'**
  String get suggestionBudgetPlanner;

  /// Label for recipe organizer suggestion button
  ///
  /// In en, this message translates to:
  /// **'Recipe Organizer'**
  String get suggestionRecipeOrganizer;

  /// Value for chore tracker suggestion
  ///
  /// In en, this message translates to:
  /// **'I need a chore tracking app for my family'**
  String get suggestionChoreTrackerValue;

  /// Value for budget planner suggestion
  ///
  /// In en, this message translates to:
  /// **'I want to track our household budget'**
  String get suggestionBudgetPlannerValue;

  /// Value for recipe organizer suggestion
  ///
  /// In en, this message translates to:
  /// **'Help me organize family recipes'**
  String get suggestionRecipeOrganizerValue;

  /// Label for add features modification action
  ///
  /// In en, this message translates to:
  /// **'Add Features'**
  String get modifyActionAddFeatures;

  /// Label for change design modification action
  ///
  /// In en, this message translates to:
  /// **'Change Design'**
  String get modifyActionChangeDesign;

  /// Label for fix issues modification action
  ///
  /// In en, this message translates to:
  /// **'Fix Issues'**
  String get modifyActionFixIssues;

  /// Value for add features modification action
  ///
  /// In en, this message translates to:
  /// **'I want to add new features'**
  String get modifyActionAddFeaturesValue;

  /// Value for change design modification action
  ///
  /// In en, this message translates to:
  /// **'I want to change the design or layout'**
  String get modifyActionChangeDesignValue;

  /// Value for fix issues modification action
  ///
  /// In en, this message translates to:
  /// **'There are some issues I want to fix'**
  String get modifyActionFixIssuesValue;

  /// Welcome message for new application creation conversation
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'ll help you create a custom application for your household. What would you like to build?'**
  String get conversationWelcomeNewApp;

  /// Welcome message for application modification conversation
  ///
  /// In en, this message translates to:
  /// **'I can help you modify your {applicationName} application. What changes would you like to make?'**
  String conversationWelcomeModifyApp(String applicationName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
