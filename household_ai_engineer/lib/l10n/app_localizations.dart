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
  /// **'Household Engineer'**
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

  /// System status showing number of running and developing applications
  ///
  /// In en, this message translates to:
  /// **'{activeApps} running • {developingApps} developing'**
  String systemStatusRunningDeveloping(int activeApps, int developingApps);

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
