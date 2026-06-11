import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Freelancer Platform'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @findWork.
  ///
  /// In en, this message translates to:
  /// **'Find Work'**
  String get findWork;

  /// No description provided for @myProposals.
  ///
  /// In en, this message translates to:
  /// **'My Proposals'**
  String get myProposals;

  /// No description provided for @myProjects.
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get myProjects;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// No description provided for @disputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get disputes;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @financial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get financial;

  /// No description provided for @advancedSearch.
  ///
  /// In en, this message translates to:
  /// **'Advanced Search'**
  String get advancedSearch;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @freelancer.
  ///
  /// In en, this message translates to:
  /// **'Freelancer'**
  String get freelancer;

  /// No description provided for @jobSuccessScore.
  ///
  /// In en, this message translates to:
  /// **'JSS'**
  String get jobSuccessScore;

  /// No description provided for @activeProjects.
  ///
  /// In en, this message translates to:
  /// **'Active Projects'**
  String get activeProjects;

  /// No description provided for @proposals.
  ///
  /// In en, this message translates to:
  /// **'Proposals'**
  String get proposals;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @trendingSkills.
  ///
  /// In en, this message translates to:
  /// **'Trending Skills'**
  String get trendingSkills;

  /// No description provided for @myPortfolio.
  ///
  /// In en, this message translates to:
  /// **'My Portfolio'**
  String get myPortfolio;

  /// No description provided for @skillTests.
  ///
  /// In en, this message translates to:
  /// **'Skill Tests'**
  String get skillTests;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @fullCalendar.
  ///
  /// In en, this message translates to:
  /// **'Full Calendar'**
  String get fullCalendar;

  /// No description provided for @bestMatches.
  ///
  /// In en, this message translates to:
  /// **'Best Matches'**
  String get bestMatches;

  /// No description provided for @mostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get mostRecent;

  /// No description provided for @savedJobs.
  ///
  /// In en, this message translates to:
  /// **'Saved Jobs'**
  String get savedJobs;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @switchTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark theme'**
  String get switchTheme;

  /// No description provided for @useSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'Use System Theme'**
  String get useSystemTheme;

  /// No description provided for @followSystemTheme.
  ///
  /// In en, this message translates to:
  /// **'Follow system theme settings'**
  String get followSystemTheme;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @updatePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get updatePassword;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @manageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get manageNotifications;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currency;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @getHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get getHelpSupport;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @readTerms.
  ///
  /// In en, this message translates to:
  /// **'Read our terms and conditions'**
  String get readTerms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @readPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacy;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate this app on the store'**
  String get rateApp;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get noImage;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviews;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @reviewsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Reviews will appear here once completed projects are rated'**
  String get reviewsWillAppearHere;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @foundThisHelpful.
  ///
  /// In en, this message translates to:
  /// **'found this helpful'**
  String get foundThisHelpful;

  /// No description provided for @responseFromSeller.
  ///
  /// In en, this message translates to:
  /// **'Response from seller:'**
  String get responseFromSeller;

  /// No description provided for @ratingDistribution.
  ///
  /// In en, this message translates to:
  /// **'Rating Distribution'**
  String get ratingDistribution;

  /// No description provided for @ratingSummary.
  ///
  /// In en, this message translates to:
  /// **'Rating Summary'**
  String get ratingSummary;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @withComments.
  ///
  /// In en, this message translates to:
  /// **'With Comments'**
  String get withComments;

  /// No description provided for @withReplies.
  ///
  /// In en, this message translates to:
  /// **'With Replies'**
  String get withReplies;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @reviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Review Details'**
  String get reviewDetails;

  /// No description provided for @replyToReview.
  ///
  /// In en, this message translates to:
  /// **'Reply to Review'**
  String get replyToReview;

  /// No description provided for @alreadyMarkedHelpful.
  ///
  /// In en, this message translates to:
  /// **'You already marked this as helpful'**
  String get alreadyMarkedHelpful;

  /// No description provided for @thanksForFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get thanksForFeedback;

  /// No description provided for @replyAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reply added successfully'**
  String get replyAddedSuccess;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @sellerResponse.
  ///
  /// In en, this message translates to:
  /// **'Seller Response'**
  String get sellerResponse;

  /// Text showing rating out of 5
  ///
  /// In en, this message translates to:
  /// **'out of 5'**
  String get outOf5;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// Metric name for communication
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @youFoundThisHelpful.
  ///
  /// In en, this message translates to:
  /// **'You found this helpful'**
  String get youFoundThisHelpful;

  /// No description provided for @wasThisReviewHelpful.
  ///
  /// In en, this message translates to:
  /// **'Was this review helpful?'**
  String get wasThisReviewHelpful;

  /// No description provided for @errorLoadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Error loading projects'**
  String get errorLoadingProjects;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @budgetLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Budget: Low to High'**
  String get budgetLowToHigh;

  /// No description provided for @budgetHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Budget: High to Low'**
  String get budgetHighToLow;

  /// No description provided for @durationShortestFirst.
  ///
  /// In en, this message translates to:
  /// **'Duration: Shortest First'**
  String get durationShortestFirst;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @unknownClient.
  ///
  /// In en, this message translates to:
  /// **'Unknown Client'**
  String get unknownClient;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @remote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'d ago'**
  String get daysAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get hoursAgo;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @searchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects...'**
  String get searchProjects;

  /// No description provided for @projectsFound.
  ///
  /// In en, this message translates to:
  /// **'projects found'**
  String get projectsFound;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get noProjectsFound;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @mobileDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Mobile Development'**
  String get mobileDevelopment;

  /// No description provided for @webDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Web Development'**
  String get webDevelopment;

  /// No description provided for @backendDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Backend Development'**
  String get backendDevelopment;

  /// No description provided for @uiUxDesign.
  ///
  /// In en, this message translates to:
  /// **'UI/UX Design'**
  String get uiUxDesign;

  /// No description provided for @graphicDesign.
  ///
  /// In en, this message translates to:
  /// **'Graphic Design'**
  String get graphicDesign;

  /// No description provided for @contentWriting.
  ///
  /// In en, this message translates to:
  /// **'Content Writing'**
  String get contentWriting;

  /// No description provided for @digitalMarketing.
  ///
  /// In en, this message translates to:
  /// **'Digital Marketing'**
  String get digitalMarketing;

  /// No description provided for @devOps.
  ///
  /// In en, this message translates to:
  /// **'DevOps'**
  String get devOps;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @durationLongestFirst.
  ///
  /// In en, this message translates to:
  /// **'Duration: Longest First'**
  String get durationLongestFirst;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search error'**
  String get searchError;

  /// No description provided for @saveSearchFilter.
  ///
  /// In en, this message translates to:
  /// **'Save Search Filter'**
  String get saveSearchFilter;

  /// No description provided for @filterName.
  ///
  /// In en, this message translates to:
  /// **'Filter Name'**
  String get filterName;

  /// No description provided for @filterHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., High Budget Flutter Jobs'**
  String get filterHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @filterSaved.
  ///
  /// In en, this message translates to:
  /// **'Filter saved successfully'**
  String get filterSaved;

  /// No description provided for @errorSavingFilter.
  ///
  /// In en, this message translates to:
  /// **'Error saving filter'**
  String get errorSavingFilter;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @saveThisSearch.
  ///
  /// In en, this message translates to:
  /// **'Save this search'**
  String get saveThisSearch;

  /// No description provided for @adjustYourFilters.
  ///
  /// In en, this message translates to:
  /// **'Adjust your search filters'**
  String get adjustYourFilters;

  /// No description provided for @savedSearches.
  ///
  /// In en, this message translates to:
  /// **'Saved Searches'**
  String get savedSearches;

  /// No description provided for @projectAlerts.
  ///
  /// In en, this message translates to:
  /// **'Project Alerts'**
  String get projectAlerts;

  /// No description provided for @createNewAlert.
  ///
  /// In en, this message translates to:
  /// **'Create New Alert'**
  String get createNewAlert;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// Label for budget
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @deleteFilter.
  ///
  /// In en, this message translates to:
  /// **'Delete Filter'**
  String get deleteFilter;

  /// No description provided for @deleteFilterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteFilterQuestion;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @filterDeleted.
  ///
  /// In en, this message translates to:
  /// **'Filter deleted'**
  String get filterDeleted;

  /// No description provided for @alertDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alert deleted'**
  String get alertDeleted;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @createProjectAlert.
  ///
  /// In en, this message translates to:
  /// **'Create Project Alert'**
  String get createProjectAlert;

  /// No description provided for @alertName.
  ///
  /// In en, this message translates to:
  /// **'Alert Name'**
  String get alertName;

  /// No description provided for @keywordsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Keywords (comma separated)'**
  String get keywordsCommaSeparated;

  /// No description provided for @keywordsHint.
  ///
  /// In en, this message translates to:
  /// **'flutter, mobile, app'**
  String get keywordsHint;

  /// No description provided for @skillsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Skills (comma separated)'**
  String get skillsCommaSeparated;

  /// No description provided for @alertCreated.
  ///
  /// In en, this message translates to:
  /// **'Alert created successfully'**
  String get alertCreated;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites!'**
  String get addedToFavorites;

  /// No description provided for @anyKeywords.
  ///
  /// In en, this message translates to:
  /// **'Any keywords'**
  String get anyKeywords;

  /// No description provided for @avatarUploaded.
  ///
  /// In en, this message translates to:
  /// **'Avatar uploaded successfully'**
  String get avatarUploaded;

  /// No description provided for @errorUploadingAvatar.
  ///
  /// In en, this message translates to:
  /// **'Error uploading avatar'**
  String get errorUploadingAvatar;

  /// No description provided for @uploadCV.
  ///
  /// In en, this message translates to:
  /// **'Upload CV'**
  String get uploadCV;

  /// No description provided for @updateCV.
  ///
  /// In en, this message translates to:
  /// **'Update CV'**
  String get updateCV;

  /// No description provided for @errorUploadingCV.
  ///
  /// In en, this message translates to:
  /// **'Error uploading CV'**
  String get errorUploadingCV;

  /// No description provided for @cvAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'✅ CV analyzed! {count} skills found'**
  String cvAnalyzed(Object count);

  /// No description provided for @cvAnalyzed_plural.
  ///
  /// In en, this message translates to:
  /// **'✅ CV analyzed! {count} skills found'**
  String cvAnalyzed_plural(Object count);

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied'**
  String get locationPermissionsDenied;

  /// No description provided for @locationPermissionsDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied'**
  String get locationPermissionsDeniedForever;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully'**
  String get locationUpdated;

  /// No description provided for @errorGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location'**
  String get errorGettingLocation;

  /// No description provided for @errorSavingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile'**
  String get errorSavingProfile;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Tagline'**
  String get tagline;

  /// No description provided for @taglineHint.
  ///
  /// In en, this message translates to:
  /// **'Short headline (shown to clients)'**
  String get taglineHint;

  /// No description provided for @professionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Title'**
  String get professionalTitle;

  /// No description provided for @professionalTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Senior Flutter Developer'**
  String get professionalTitleHint;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get bioHint;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @mapPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map preview unavailable'**
  String get mapPreviewUnavailable;

  /// Metric name for skills
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @addSkill.
  ///
  /// In en, this message translates to:
  /// **'Add a skill'**
  String get addSkill;

  /// No description provided for @noSkillsAdded.
  ///
  /// In en, this message translates to:
  /// **'No skills added yet'**
  String get noSkillsAdded;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @addLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add a language'**
  String get addLanguage;

  /// No description provided for @noLanguagesAdded.
  ///
  /// In en, this message translates to:
  /// **'No languages added yet'**
  String get noLanguagesAdded;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @degree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get degree;

  /// No description provided for @institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @noEducationAdded.
  ///
  /// In en, this message translates to:
  /// **'No education added yet'**
  String get noEducationAdded;

  /// No description provided for @certifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @certificationName.
  ///
  /// In en, this message translates to:
  /// **'Certification name'**
  String get certificationName;

  /// No description provided for @issuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get issuer;

  /// No description provided for @noCertificationsAdded.
  ///
  /// In en, this message translates to:
  /// **'No certifications added yet'**
  String get noCertificationsAdded;

  /// No description provided for @socialLinks.
  ///
  /// In en, this message translates to:
  /// **'Social & Professional Links'**
  String get socialLinks;

  /// No description provided for @portfolioWebsite.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Website'**
  String get portfolioWebsite;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @linkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedin;

  /// No description provided for @behance.
  ///
  /// In en, this message translates to:
  /// **'Behance'**
  String get behance;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get fullTime;

  /// No description provided for @partTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get partTime;

  /// No description provided for @asNeeded.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get asNeeded;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @weeklyHours.
  ///
  /// In en, this message translates to:
  /// **'Weekly hours'**
  String get weeklyHours;

  /// No description provided for @yearsOfExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get yearsOfExperience;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'yrs'**
  String get years;

  /// Label for hourly rate
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @aiAnalysisComplete.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis Complete!'**
  String get aiAnalysisComplete;

  /// No description provided for @extractedFromCV.
  ///
  /// In en, this message translates to:
  /// **'Extracted from your CV'**
  String get extractedFromCV;

  /// No description provided for @skillsCount.
  ///
  /// In en, this message translates to:
  /// **'skills'**
  String get skillsCount;

  /// No description provided for @languagesCount.
  ///
  /// In en, this message translates to:
  /// **'languages'**
  String get languagesCount;

  /// No description provided for @educationCount.
  ///
  /// In en, this message translates to:
  /// **'education'**
  String get educationCount;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error loading favorites'**
  String get errorLoadingFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @removeFromFavoritesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{projectTitle}\" from favorites?'**
  String removeFromFavoritesConfirmation(String projectTitle);

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @saveProjectsByTappingHeart.
  ///
  /// In en, this message translates to:
  /// **'Save projects you like by tapping the heart icon'**
  String get saveProjectsByTappingHeart;

  /// No description provided for @browseProjects.
  ///
  /// In en, this message translates to:
  /// **'Browse Projects'**
  String get browseProjects;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @financialDashboard.
  ///
  /// In en, this message translates to:
  /// **'Financial Dashboard'**
  String get financialDashboard;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get downloadReport;

  /// No description provided for @errorLoadingFinancialData.
  ///
  /// In en, this message translates to:
  /// **'Error loading financial data'**
  String get errorLoadingFinancialData;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully'**
  String get reportGenerated;

  /// No description provided for @errorGeneratingReport.
  ///
  /// In en, this message translates to:
  /// **'Error generating report'**
  String get errorGeneratingReport;

  /// No description provided for @withdrawFunds.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdrawFunds;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @withdrawalMethod.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Method'**
  String get withdrawalMethod;

  /// No description provided for @paypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get paypal;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @stripe.
  ///
  /// In en, this message translates to:
  /// **'Stripe'**
  String get stripe;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @withdrawalRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'✅ Withdrawal request submitted'**
  String get withdrawalRequestSubmitted;

  /// No description provided for @noFinancialData.
  ///
  /// In en, this message translates to:
  /// **'No financial data available'**
  String get noFinancialData;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @platformFees.
  ///
  /// In en, this message translates to:
  /// **'Platform Fees'**
  String get platformFees;

  /// No description provided for @withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get withdrawn;

  /// No description provided for @totalWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Total withdrawn'**
  String get totalWithdrawn;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get netEarnings;

  /// No description provided for @availableToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Available to withdraw'**
  String get availableToWithdraw;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data available for this period'**
  String get noDataForPeriod;

  /// No description provided for @earningsOverview.
  ///
  /// In en, this message translates to:
  /// **'Earnings Overview'**
  String get earningsOverview;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceived;

  /// No description provided for @paymentSent.
  ///
  /// In en, this message translates to:
  /// **'Payment Sent'**
  String get paymentSent;

  /// No description provided for @withdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get withdrawal;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get platformFee;

  /// No description provided for @bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @noAnalyticsData.
  ///
  /// In en, this message translates to:
  /// **'No analytics data available'**
  String get noAnalyticsData;

  /// No description provided for @topProjects.
  ///
  /// In en, this message translates to:
  /// **'Top Projects'**
  String get topProjects;

  /// No description provided for @earningsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Earnings by Category'**
  String get earningsByCategory;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @projectedEarnings.
  ///
  /// In en, this message translates to:
  /// **'Projected Earnings'**
  String get projectedEarnings;

  /// No description provided for @projectedEarningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Next 3 months based on your history'**
  String get projectedEarningsSubtitle;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @submitWork.
  ///
  /// In en, this message translates to:
  /// **'Submit Work'**
  String get submitWork;

  /// No description provided for @submitWorkConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit this work for review?'**
  String get submitWorkConfirmation;

  /// No description provided for @workSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Work submitted successfully!'**
  String get workSubmittedSuccess;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent!'**
  String get messageSent;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @untitledProject.
  ///
  /// In en, this message translates to:
  /// **'Untitled Project'**
  String get untitledProject;

  /// No description provided for @projectProgress.
  ///
  /// In en, this message translates to:
  /// **'Project Progress'**
  String get projectProgress;

  /// No description provided for @openWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open Workspace'**
  String get openWorkspace;

  /// No description provided for @openContract.
  ///
  /// In en, this message translates to:
  /// **'Open Contract'**
  String get openContract;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// Tooltip for refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Loading your projects...'**
  String get loadingProjects;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No Projects Yet'**
  String get noProjectsYet;

  /// No description provided for @acceptedProposalsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your accepted proposals will appear here'**
  String get acceptedProposalsWillAppear;

  /// No description provided for @viewMyProposals.
  ///
  /// In en, this message translates to:
  /// **'View My Proposals'**
  String get viewMyProposals;

  /// No description provided for @errorLoadingProposals.
  ///
  /// In en, this message translates to:
  /// **'Error loading proposals'**
  String get errorLoadingProposals;

  /// No description provided for @proposalsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Proposals This Month'**
  String get proposalsThisMonth;

  /// No description provided for @proposalLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Proposal Limit Reached'**
  String get proposalLimitReached;

  /// No description provided for @proposalsRemaining.
  ///
  /// In en, this message translates to:
  /// **'✨ You have {count} proposal remaining this month.'**
  String proposalsRemaining(int count);

  /// No description provided for @proposalsRemaining_plural.
  ///
  /// In en, this message translates to:
  /// **'✨ You have {count} proposals remaining this month.'**
  String proposalsRemaining_plural(Object count);

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get rejected;

  /// No description provided for @unknownProject.
  ///
  /// In en, this message translates to:
  /// **'Unknown Project'**
  String get unknownProject;

  /// No description provided for @noMessageProvided.
  ///
  /// In en, this message translates to:
  /// **'No message provided'**
  String get noMessageProvided;

  /// No description provided for @startWorking.
  ///
  /// In en, this message translates to:
  /// **'Start Working'**
  String get startWorking;

  /// No description provided for @noProposalsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No proposals in this category'**
  String get noProposalsInCategory;

  /// No description provided for @loadingProposals.
  ///
  /// In en, this message translates to:
  /// **'Loading proposals...'**
  String get loadingProposals;

  /// No description provided for @noProposalsYet.
  ///
  /// In en, this message translates to:
  /// **'No Proposals Yet'**
  String get noProposalsYet;

  /// No description provided for @browseProjectsAndSubmitProposal.
  ///
  /// In en, this message translates to:
  /// **'Browse projects and submit your first proposal'**
  String get browseProjectsAndSubmitProposal;

  /// No description provided for @findProjects.
  ///
  /// In en, this message translates to:
  /// **'Find Projects'**
  String get findProjects;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @errorLoadingProjectDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading project details'**
  String get errorLoadingProjectDetails;

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found'**
  String get projectNotFound;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @aiSmartPricingAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Smart Pricing Analysis'**
  String get aiSmartPricingAnalysis;

  /// No description provided for @recommendedPrice.
  ///
  /// In en, this message translates to:
  /// **'Recommended Price'**
  String get recommendedPrice;

  /// No description provided for @estHours.
  ///
  /// In en, this message translates to:
  /// **'Est. Hours'**
  String get estHours;

  /// Plural form of hours
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hours;

  /// No description provided for @baseRate.
  ///
  /// In en, this message translates to:
  /// **'Base Rate'**
  String get baseRate;

  /// No description provided for @complexity.
  ///
  /// In en, this message translates to:
  /// **'Complexity'**
  String get complexity;

  /// Metric name for experience
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @requiredSkills.
  ///
  /// In en, this message translates to:
  /// **'Required Skills'**
  String get requiredSkills;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @proposalsRemainingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Proposals remaining this month: {count}'**
  String proposalsRemainingThisMonth(int count);

  /// No description provided for @upgradeToSendMoreProposals.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to send more proposals'**
  String get upgradeToSendMoreProposals;

  /// No description provided for @submitProposal.
  ///
  /// In en, this message translates to:
  /// **'Submit Proposal'**
  String get submitProposal;

  /// No description provided for @proposalSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Proposal submitted successfully!'**
  String get proposalSubmittedSuccess;

  /// No description provided for @alreadySubmittedProposal.
  ///
  /// In en, this message translates to:
  /// **'You have already submitted a proposal for this project'**
  String get alreadySubmittedProposal;

  /// No description provided for @projectStatus.
  ///
  /// In en, this message translates to:
  /// **'This project is {status}'**
  String projectStatus(String status);

  /// No description provided for @projectStatusWithContract.
  ///
  /// In en, this message translates to:
  /// **'This project is {status}. Your workspace is in the contract.'**
  String projectStatusWithContract(String status);

  /// No description provided for @restoredProposalDraft.
  ///
  /// In en, this message translates to:
  /// **'Restored your saved proposal draft'**
  String get restoredProposalDraft;

  /// No description provided for @aiPriceApplied.
  ///
  /// In en, this message translates to:
  /// **'AI recommended price applied!'**
  String get aiPriceApplied;

  /// No description provided for @aiSuggestedMilestones.
  ///
  /// In en, this message translates to:
  /// **'AI Suggested Milestones'**
  String get aiSuggestedMilestones;

  /// No description provided for @aiMilestonesDescription.
  ///
  /// In en, this message translates to:
  /// **'Based on your project analysis, here are recommended milestones:'**
  String get aiMilestonesDescription;

  /// No description provided for @applyMilestones.
  ///
  /// In en, this message translates to:
  /// **'Apply Milestones'**
  String get applyMilestones;

  /// No description provided for @aiMilestonesApplied.
  ///
  /// In en, this message translates to:
  /// **'AI milestones applied! You can edit them below.'**
  String get aiMilestonesApplied;

  /// No description provided for @milestoneAmountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Total milestone amounts (\${total}) does not match your price (\${price})'**
  String milestoneAmountMismatch(Object price, Object total);

  /// No description provided for @milestoneAmountMismatch_plural.
  ///
  /// In en, this message translates to:
  /// **'Total milestone amounts (\${total}) does not match your price (\${price})'**
  String milestoneAmountMismatch_plural(Object price, Object total);

  /// No description provided for @proposalLimitReachedUpgrade.
  ///
  /// In en, this message translates to:
  /// **'You have reached your proposal limit. Please upgrade to submit more proposals.'**
  String get proposalLimitReachedUpgrade;

  /// No description provided for @errorSubmittingProposal.
  ///
  /// In en, this message translates to:
  /// **'Error submitting proposal'**
  String get errorSubmittingProposal;

  /// No description provided for @fillProposalFieldsFirst.
  ///
  /// In en, this message translates to:
  /// **'Fill price, delivery time, and a meaningful cover letter first'**
  String get fillProposalFieldsFirst;

  /// No description provided for @couldNotAnalyzeProposal.
  ///
  /// In en, this message translates to:
  /// **'Could not analyze proposal'**
  String get couldNotAnalyzeProposal;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed'**
  String get analysisFailed;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get draftSaved;

  /// No description provided for @proposalAutosaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Proposal autosaves on this device while you edit.'**
  String get proposalAutosaveMessage;

  /// No description provided for @youAreApplyingFor.
  ///
  /// In en, this message translates to:
  /// **'You\'re applying for:'**
  String get youAreApplyingFor;

  /// No description provided for @yourProposal.
  ///
  /// In en, this message translates to:
  /// **'Your Proposal'**
  String get yourProposal;

  /// No description provided for @fillProposalDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below to submit your proposal'**
  String get fillProposalDetails;

  /// No description provided for @yourPrice.
  ///
  /// In en, this message translates to:
  /// **'Your Price (\$)'**
  String get yourPrice;

  /// No description provided for @enterYourPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter your proposed price'**
  String get enterYourPrice;

  /// No description provided for @pleaseEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter your price'**
  String get pleaseEnterPrice;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @priceGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than 0'**
  String get priceGreaterThanZero;

  /// No description provided for @deliveryTimeDays.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time (days)'**
  String get deliveryTimeDays;

  /// No description provided for @howManyDays.
  ///
  /// In en, this message translates to:
  /// **'How many days you need?'**
  String get howManyDays;

  /// No description provided for @pleaseEnterDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Please enter delivery time'**
  String get pleaseEnterDeliveryTime;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @deliveryTimeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Delivery time must be greater than 0'**
  String get deliveryTimeGreaterThanZero;

  /// No description provided for @paymentMilestones.
  ///
  /// In en, this message translates to:
  /// **'Payment Milestones'**
  String get paymentMilestones;

  /// No description provided for @aiGenerated.
  ///
  /// In en, this message translates to:
  /// **'AI Generated'**
  String get aiGenerated;

  /// No description provided for @defineMilestones.
  ///
  /// In en, this message translates to:
  /// **'Define the project phases and payment schedule'**
  String get defineMilestones;

  /// No description provided for @coverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// No description provided for @coverLetterHint.
  ///
  /// In en, this message translates to:
  /// **'Explain why you\'re the best candidate for this project...\n- Your relevant experience\n- How you\'ll approach the project\n- Any questions you have'**
  String get coverLetterHint;

  /// No description provided for @pleaseWriteCoverLetter.
  ///
  /// In en, this message translates to:
  /// **'Please write a cover letter'**
  String get pleaseWriteCoverLetter;

  /// No description provided for @coverLetterMinLength.
  ///
  /// In en, this message translates to:
  /// **'Cover letter should be at least 50 characters'**
  String get coverLetterMinLength;

  /// No description provided for @analyzingProposal.
  ///
  /// In en, this message translates to:
  /// **'Analyzing proposal...'**
  String get analyzingProposal;

  /// No description provided for @analyzeProposalQuality.
  ///
  /// In en, this message translates to:
  /// **'Analyze Proposal Quality (AI)'**
  String get analyzeProposalQuality;

  /// No description provided for @proposalScore.
  ///
  /// In en, this message translates to:
  /// **'Proposal Score'**
  String get proposalScore;

  /// No description provided for @strengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get strengths;

  /// No description provided for @improve.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get improve;

  /// No description provided for @priceWithinBudget.
  ///
  /// In en, this message translates to:
  /// **'Your price is within the project budget'**
  String get priceWithinBudget;

  /// No description provided for @priceAboveBudget.
  ///
  /// In en, this message translates to:
  /// **'Your price is above the project budget. Make sure to justify this in your cover letter.'**
  String get priceAboveBudget;

  /// No description provided for @paymentScheduleSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Schedule Summary'**
  String get paymentScheduleSummary;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'By submitting, you agree to our Terms of Service'**
  String get agreeToTerms;

  /// No description provided for @aiSmartPricing.
  ///
  /// In en, this message translates to:
  /// **'AI Smart Pricing'**
  String get aiSmartPricing;

  /// No description provided for @useRecommendedPrice.
  ///
  /// In en, this message translates to:
  /// **'Use Recommended Price'**
  String get useRecommendedPrice;

  /// No description provided for @aiMilestoneSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Milestone Suggestions'**
  String get aiMilestoneSuggestions;

  /// No description provided for @viewAndApplyMilestones.
  ///
  /// In en, this message translates to:
  /// **'View & Apply AI Milestones'**
  String get viewAndApplyMilestones;

  /// No description provided for @plusMoreMilestones.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more milestones'**
  String plusMoreMilestones(int count);

  /// No description provided for @submittingWorkFor.
  ///
  /// In en, this message translates to:
  /// **'Submitting work for: {projectTitle}'**
  String submittingWorkFor(String projectTitle);

  /// No description provided for @submissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission Title'**
  String get submissionTitle;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @describeYourWork.
  ///
  /// In en, this message translates to:
  /// **'Describe what you have completed...'**
  String get describeYourWork;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get addFiles;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @pleaseAddAtLeastOneFileOrLink.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one file or link'**
  String get pleaseAddAtLeastOneFileOrLink;

  /// No description provided for @errorSubmittingWork.
  ///
  /// In en, this message translates to:
  /// **'Error submitting work'**
  String get errorSubmittingWork;

  /// No description provided for @boostYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Boost Your Profile'**
  String get boostYourProfile;

  /// No description provided for @errorLoadingPrices.
  ///
  /// In en, this message translates to:
  /// **'Error loading prices'**
  String get errorLoadingPrices;

  /// No description provided for @featurePurchasedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Feature purchased successfully!'**
  String get featurePurchasedSuccess;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get purchaseFailed;

  /// No description provided for @noProjectsToHighlight.
  ///
  /// In en, this message translates to:
  /// **'You have no projects to highlight'**
  String get noProjectsToHighlight;

  /// No description provided for @selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select a project'**
  String get selectProject;

  /// No description provided for @featureYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Feature Your Profile'**
  String get featureYourProfile;

  /// No description provided for @featureYourProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Get featured at the top of search results for 7 days'**
  String get featureYourProfileDesc;

  /// No description provided for @highlightYourProject.
  ///
  /// In en, this message translates to:
  /// **'Highlight Your Project'**
  String get highlightYourProject;

  /// No description provided for @highlightYourProjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Make your project stand out with a highlight badge'**
  String get highlightYourProjectDesc;

  /// No description provided for @skillCertificate.
  ///
  /// In en, this message translates to:
  /// **'Skill Certificate'**
  String get skillCertificate;

  /// No description provided for @skillCertificateDesc.
  ///
  /// In en, this message translates to:
  /// **'Get certified and earn a verified badge'**
  String get skillCertificateDesc;

  /// No description provided for @aiResumeReview.
  ///
  /// In en, this message translates to:
  /// **'AI Resume Review'**
  String get aiResumeReview;

  /// No description provided for @aiResumeReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Get professional feedback on your resume'**
  String get aiResumeReviewDesc;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @contractProgress.
  ///
  /// In en, this message translates to:
  /// **'Contract progress'**
  String get contractProgress;

  /// No description provided for @couldNotLoadProgress.
  ///
  /// In en, this message translates to:
  /// **'Could not load progress'**
  String get couldNotLoadProgress;

  /// No description provided for @milestoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Milestone updated'**
  String get milestoneUpdated;

  /// No description provided for @couldNotApproveMilestone.
  ///
  /// In en, this message translates to:
  /// **'Could not approve milestone'**
  String get couldNotApproveMilestone;

  /// No description provided for @workApproved.
  ///
  /// In en, this message translates to:
  /// **'Work approved'**
  String get workApproved;

  /// No description provided for @approvalFailed.
  ///
  /// In en, this message translates to:
  /// **'Approval failed'**
  String get approvalFailed;

  /// No description provided for @requestRevision.
  ///
  /// In en, this message translates to:
  /// **'Request revision'**
  String get requestRevision;

  /// No description provided for @whatShouldBeChanged.
  ///
  /// In en, this message translates to:
  /// **'What should be changed?'**
  String get whatShouldBeChanged;

  /// No description provided for @revisionRequested.
  ///
  /// In en, this message translates to:
  /// **'Revision Requested'**
  String get revisionRequested;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed'**
  String get requestFailed;

  /// No description provided for @addedToPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Added to portfolio'**
  String get addedToPortfolio;

  /// No description provided for @couldNotAddToPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Could not add to portfolio'**
  String get couldNotAddToPortfolio;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @contractNumber.
  ///
  /// In en, this message translates to:
  /// **'Contract #{id}'**
  String contractNumber(int id);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @escrow.
  ///
  /// In en, this message translates to:
  /// **'Escrow'**
  String get escrow;

  /// No description provided for @pool.
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get pool;

  /// No description provided for @coupon.
  ///
  /// In en, this message translates to:
  /// **'coupon'**
  String get coupon;

  /// No description provided for @dollar.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get dollar;

  /// No description provided for @commissionPreview.
  ///
  /// In en, this message translates to:
  /// **'Commission preview'**
  String get commissionPreview;

  /// No description provided for @planRateIndicative.
  ///
  /// In en, this message translates to:
  /// **'Plan rate (indicative)'**
  String get planRateIndicative;

  /// No description provided for @estPlatformFeeOnRelease.
  ///
  /// In en, this message translates to:
  /// **'Est. platform fee on release'**
  String get estPlatformFeeOnRelease;

  /// No description provided for @noPendingSteps.
  ///
  /// In en, this message translates to:
  /// **'No pending steps'**
  String get noPendingSteps;

  /// No description provided for @upToDateOnMilestones.
  ///
  /// In en, this message translates to:
  /// **'You are up to date on milestones and deliverables.'**
  String get upToDateOnMilestones;

  /// No description provided for @yourNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Your next steps'**
  String get yourNextSteps;

  /// No description provided for @approveMilestone.
  ///
  /// In en, this message translates to:
  /// **'Approve Milestone'**
  String get approveMilestone;

  /// No description provided for @reviewSubmission.
  ///
  /// In en, this message translates to:
  /// **'Review submission'**
  String get reviewSubmission;

  /// No description provided for @submitDeliverable.
  ///
  /// In en, this message translates to:
  /// **'Submit deliverable'**
  String get submitDeliverable;

  /// No description provided for @approveAndRelease.
  ///
  /// In en, this message translates to:
  /// **'Approve & Release'**
  String get approveAndRelease;

  /// No description provided for @approveWork.
  ///
  /// In en, this message translates to:
  /// **'Approve work'**
  String get approveWork;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @milestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get milestone;

  /// No description provided for @deliverables.
  ///
  /// In en, this message translates to:
  /// **'Deliverables'**
  String get deliverables;

  /// No description provided for @submission.
  ///
  /// In en, this message translates to:
  /// **'Submission'**
  String get submission;

  /// No description provided for @addToPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Add to Portfolio'**
  String get addToPortfolio;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @contractAgreement.
  ///
  /// In en, this message translates to:
  /// **'Contract Agreement'**
  String get contractAgreement;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @contractNotFound.
  ///
  /// In en, this message translates to:
  /// **'Contract not found'**
  String get contractNotFound;

  /// No description provided for @signedOn.
  ///
  /// In en, this message translates to:
  /// **'Signed on'**
  String get signedOn;

  /// No description provided for @contractAmount.
  ///
  /// In en, this message translates to:
  /// **'Contract Amount'**
  String get contractAmount;

  /// No description provided for @aiOptimized.
  ///
  /// In en, this message translates to:
  /// **'AI Optimized'**
  String get aiOptimized;

  /// No description provided for @noMilestonesFound.
  ///
  /// In en, this message translates to:
  /// **'No milestones found for this contract'**
  String get noMilestonesFound;

  /// No description provided for @githubIntegration.
  ///
  /// In en, this message translates to:
  /// **'GitHub Integration'**
  String get githubIntegration;

  /// No description provided for @connectGithubRepository.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub Repository'**
  String get connectGithubRepository;

  /// No description provided for @trackProgressAndShowWork.
  ///
  /// In en, this message translates to:
  /// **'Track your progress and show your work'**
  String get trackProgressAndShowWork;

  /// No description provided for @connectRepository.
  ///
  /// In en, this message translates to:
  /// **'Connect Repository'**
  String get connectRepository;

  /// No description provided for @recentCommits.
  ///
  /// In en, this message translates to:
  /// **'Recent Commits'**
  String get recentCommits;

  /// No description provided for @commits.
  ///
  /// In en, this message translates to:
  /// **'commits'**
  String get commits;

  /// No description provided for @contractDocument.
  ///
  /// In en, this message translates to:
  /// **'Contract Document'**
  String get contractDocument;

  /// No description provided for @contractDocumentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Contract document not available'**
  String get contractDocumentNotAvailable;

  /// No description provided for @clientSignature.
  ///
  /// In en, this message translates to:
  /// **'Client Signature'**
  String get clientSignature;

  /// No description provided for @freelancerSignature.
  ///
  /// In en, this message translates to:
  /// **'Freelancer Signature'**
  String get freelancerSignature;

  /// No description provided for @enterCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a coupon code'**
  String get enterCouponCode;

  /// No description provided for @couponApplied.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied'**
  String get couponApplied;

  /// No description provided for @couldNotApplyCoupon.
  ///
  /// In en, this message translates to:
  /// **'Could not apply coupon'**
  String get couldNotApplyCoupon;

  /// No description provided for @couponRemoved.
  ///
  /// In en, this message translates to:
  /// **'Coupon removed'**
  String get couponRemoved;

  /// No description provided for @couldNotRemoveCoupon.
  ///
  /// In en, this message translates to:
  /// **'Could not remove coupon'**
  String get couldNotRemoveCoupon;

  /// No description provided for @errorLoadingContract.
  ///
  /// In en, this message translates to:
  /// **'Error loading contract'**
  String get errorLoadingContract;

  /// No description provided for @errorCreatingPayment.
  ///
  /// In en, this message translates to:
  /// **'Error creating payment'**
  String get errorCreatingPayment;

  /// No description provided for @contractSignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Contract signed successfully'**
  String get contractSignedSuccess;

  /// No description provided for @errorSigningContract.
  ///
  /// In en, this message translates to:
  /// **'Error signing contract'**
  String get errorSigningContract;

  /// No description provided for @awaitingSignatures.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Signatures'**
  String get awaitingSignatures;

  /// No description provided for @waitingForClientSignature.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Client Signature'**
  String get waitingForClientSignature;

  /// No description provided for @waitingForFreelancerSignature.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Freelancer Signature'**
  String get waitingForFreelancerSignature;

  /// No description provided for @contractActive.
  ///
  /// In en, this message translates to:
  /// **'Contract Active'**
  String get contractActive;

  /// No description provided for @contractCompleted.
  ///
  /// In en, this message translates to:
  /// **'Contract Completed'**
  String get contractCompleted;

  /// No description provided for @contractCancelled.
  ///
  /// In en, this message translates to:
  /// **'Contract Cancelled'**
  String get contractCancelled;

  /// No description provided for @connectGithub.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub'**
  String get connectGithub;

  /// No description provided for @connectGithubDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect your GitHub repository to track commits and show your progress to the client.'**
  String get connectGithubDescription;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @escrowFunded.
  ///
  /// In en, this message translates to:
  /// **'✅ Escrow Funded'**
  String get escrowFunded;

  /// No description provided for @paymentRequired.
  ///
  /// In en, this message translates to:
  /// **'💰 Payment Required'**
  String get paymentRequired;

  /// No description provided for @escrowFundedDescription.
  ///
  /// In en, this message translates to:
  /// **'The payment is secured in escrow. Milestone payments will be released upon approval.'**
  String get escrowFundedDescription;

  /// No description provided for @paymentRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'To activate this contract and start working, please deposit the contract amount into escrow.'**
  String get paymentRequiredDescription;

  /// No description provided for @contractCouponEscrow.
  ///
  /// In en, this message translates to:
  /// **'Contract coupon (escrow)'**
  String get contractCouponEscrow;

  /// No description provided for @contractCoupon.
  ///
  /// In en, this message translates to:
  /// **'Contract coupon'**
  String get contractCoupon;

  /// No description provided for @paymentHeldSecurely.
  ///
  /// In en, this message translates to:
  /// **'Your payment is secured and will be released when the milestone is approved.'**
  String get paymentHeldSecurely;

  /// No description provided for @chargedNow.
  ///
  /// In en, this message translates to:
  /// **'Charged now'**
  String get chargedNow;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatus;

  /// No description provided for @pendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// No description provided for @applyBeforePaying.
  ///
  /// In en, this message translates to:
  /// **'Apply before paying'**
  String get applyBeforePaying;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @amountDueNow.
  ///
  /// In en, this message translates to:
  /// **'Amount due now'**
  String get amountDueNow;

  /// No description provided for @afterCoupon.
  ///
  /// In en, this message translates to:
  /// **'after coupon'**
  String get afterCoupon;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @paymentSecured.
  ///
  /// In en, this message translates to:
  /// **'Payment secured'**
  String get paymentSecured;

  /// No description provided for @inEscrow.
  ///
  /// In en, this message translates to:
  /// **'in escrow'**
  String get inEscrow;

  /// No description provided for @thankYouForRating.
  ///
  /// In en, this message translates to:
  /// **'✅ Thank you for your rating!'**
  String get thankYouForRating;

  /// No description provided for @rateThisExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate this experience'**
  String get rateThisExperience;

  /// No description provided for @waitingForOtherParty.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Other Party'**
  String get waitingForOtherParty;

  /// No description provided for @signContract.
  ///
  /// In en, this message translates to:
  /// **'Sign Contract'**
  String get signContract;

  /// No description provided for @contractActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Contract is active. You can now start working!'**
  String get contractActiveMessage;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid ✓'**
  String get paid;

  /// No description provided for @completedAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Completed - Awaiting Approval'**
  String get completedAwaitingApproval;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @updateProgress.
  ///
  /// In en, this message translates to:
  /// **'Update Progress'**
  String get updateProgress;

  /// No description provided for @requestChanges.
  ///
  /// In en, this message translates to:
  /// **'Request Changes'**
  String get requestChanges;

  /// No description provided for @paymentReleasedOn.
  ///
  /// In en, this message translates to:
  /// **'Payment released on'**
  String get paymentReleasedOn;

  /// No description provided for @milestoneMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'✅ Milestone marked as completed'**
  String get milestoneMarkedCompleted;

  /// No description provided for @errorCompletingMilestone.
  ///
  /// In en, this message translates to:
  /// **'Error completing milestone'**
  String get errorCompletingMilestone;

  /// No description provided for @approveMilestoneConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve \"{title}\"?'**
  String approveMilestoneConfirmation(String title);

  /// No description provided for @amountWillBeReleased.
  ///
  /// In en, this message translates to:
  /// **'\${amount} will be released to the freelancer'**
  String amountWillBeReleased(String amount);

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @milestoneApprovedPaymentReleased.
  ///
  /// In en, this message translates to:
  /// **'✅ Milestone approved and payment released'**
  String get milestoneApprovedPaymentReleased;

  /// No description provided for @errorApprovingMilestone.
  ///
  /// In en, this message translates to:
  /// **'Error approving milestone'**
  String get errorApprovingMilestone;

  /// No description provided for @explainWhatNeedsToBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Please explain what needs to be changed:'**
  String get explainWhatNeedsToBeChanged;

  /// No description provided for @describeChangesNeeded.
  ///
  /// In en, this message translates to:
  /// **'Describe the changes needed...'**
  String get describeChangesNeeded;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @revisionRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Revision request sent to freelancer'**
  String get revisionRequestSent;

  /// No description provided for @notSigned.
  ///
  /// In en, this message translates to:
  /// **'Not signed'**
  String get notSigned;

  /// No description provided for @previewSOW.
  ///
  /// In en, this message translates to:
  /// **'Preview SOW'**
  String get previewSOW;

  /// No description provided for @verificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'✅ Verification code sent'**
  String get verificationCodeSent;

  /// No description provided for @codeMustBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'❌ Code must be 6 digits'**
  String get codeMustBe6Digits;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'❌ Invalid code'**
  String get invalidCode;

  /// No description provided for @maxAttemptsReached.
  ///
  /// In en, this message translates to:
  /// **'❌ Max attempts. Request new code'**
  String get maxAttemptsReached;

  /// No description provided for @errorGeneratingPDF.
  ///
  /// In en, this message translates to:
  /// **'Error generating PDF'**
  String get errorGeneratingPDF;

  /// No description provided for @viewPDF.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get viewPDF;

  /// No description provided for @downloadPDF.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPDF;

  /// No description provided for @sharePDF.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePDF;

  /// No description provided for @downloadingPDF.
  ///
  /// In en, this message translates to:
  /// **'Downloading PDF...'**
  String get downloadingPDF;

  /// No description provided for @errorDownloadingPDF.
  ///
  /// In en, this message translates to:
  /// **'Error downloading PDF'**
  String get errorDownloadingPDF;

  /// No description provided for @errorSharing.
  ///
  /// In en, this message translates to:
  /// **'Error sharing'**
  String get errorSharing;

  /// No description provided for @contractSignedSuccessViewSOW.
  ///
  /// In en, this message translates to:
  /// **'Contract signed successfully! View the SOW document:'**
  String get contractSignedSuccessViewSOW;

  /// No description provided for @contractSOWDocument.
  ///
  /// In en, this message translates to:
  /// **'Contract SOW Document'**
  String get contractSOWDocument;

  /// No description provided for @electronicContractSigning.
  ///
  /// In en, this message translates to:
  /// **'Electronic Contract Signing'**
  String get electronicContractSigning;

  /// No description provided for @verificationCodeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'A verification code has been sent to your email'**
  String get verificationCodeSentToEmail;

  /// No description provided for @codeValidFor.
  ///
  /// In en, this message translates to:
  /// **'Code valid for'**
  String get codeValidFor;

  /// No description provided for @generatingPDFDocument.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF document...'**
  String get generatingPDFDocument;

  /// No description provided for @confirmSignature.
  ///
  /// In en, this message translates to:
  /// **'Confirm Signature'**
  String get confirmSignature;

  /// No description provided for @waitSecondsToResend.
  ///
  /// In en, this message translates to:
  /// **'Wait {seconds}s to resend'**
  String waitSecondsToResend(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @aiGeneratedSOW.
  ///
  /// In en, this message translates to:
  /// **'AI-Generated SOW'**
  String get aiGeneratedSOW;

  /// No description provided for @aiGeneratedSOWDescription.
  ///
  /// In en, this message translates to:
  /// **'This document was generated by AI and is legally binding'**
  String get aiGeneratedSOWDescription;

  /// No description provided for @statementOfWorkPreview.
  ///
  /// In en, this message translates to:
  /// **'Statement of Work Preview'**
  String get statementOfWorkPreview;

  /// No description provided for @reviewBeforeSigning.
  ///
  /// In en, this message translates to:
  /// **'Please review the document before signing'**
  String get reviewBeforeSigning;

  /// No description provided for @sowContentWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'SOW content will appear here\n(HTML rendering)'**
  String get sowContentWillAppearHere;

  /// No description provided for @myContracts.
  ///
  /// In en, this message translates to:
  /// **'My Contracts'**
  String get myContracts;

  /// No description provided for @noContractsYet.
  ///
  /// In en, this message translates to:
  /// **'No contracts yet'**
  String get noContractsYet;

  /// No description provided for @submitFinalWork.
  ///
  /// In en, this message translates to:
  /// **'Submit Final Work'**
  String get submitFinalWork;

  /// No description provided for @submitWorkForMilestones.
  ///
  /// In en, this message translates to:
  /// **'Submit Work for Milestones:'**
  String get submitWorkForMilestones;

  /// No description provided for @signed.
  ///
  /// In en, this message translates to:
  /// **'Signed ✓'**
  String get signed;

  /// No description provided for @waitingForFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Freelancer'**
  String get waitingForFreelancer;

  /// No description provided for @waitingForClient.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Client'**
  String get waitingForClient;

  /// No description provided for @signNow.
  ///
  /// In en, this message translates to:
  /// **'Sign Now'**
  String get signNow;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Title'**
  String get reminderTitle;

  /// No description provided for @reminderTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Submit milestone 1'**
  String get reminderTitleHint;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional details...'**
  String get additionalDetails;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'✅ Reminder set'**
  String get reminderSet;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @calendarAndDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Calendar & Deadlines'**
  String get calendarAndDeadlines;

  /// No description provided for @noActiveContractsToAddReminder.
  ///
  /// In en, this message translates to:
  /// **'No active contracts to add reminder'**
  String get noActiveContractsToAddReminder;

  /// No description provided for @weekDays.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get weekDays;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get months;

  /// No description provided for @responseTimeRanges.
  ///
  /// In en, this message translates to:
  /// **'<1h,1-6h,6-12h,12-24h,>24h'**
  String get responseTimeRanges;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'events'**
  String get events;

  /// No description provided for @noEventsForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No events for this day'**
  String get noEventsForThisDay;

  /// No description provided for @upcomingNext7Days.
  ///
  /// In en, this message translates to:
  /// **'Upcoming (Next 7 Days)'**
  String get upcomingNext7Days;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysLeft(int count);

  /// No description provided for @repositoryUrl.
  ///
  /// In en, this message translates to:
  /// **'Repository URL'**
  String get repositoryUrl;

  /// No description provided for @repositoryUrlExample.
  ///
  /// In en, this message translates to:
  /// **'Example: https://github.com/flutter/flutter'**
  String get repositoryUrlExample;

  /// No description provided for @branchOptional.
  ///
  /// In en, this message translates to:
  /// **'Branch (Optional)'**
  String get branchOptional;

  /// No description provided for @pleaseEnterRepositoryUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter repository URL'**
  String get pleaseEnterRepositoryUrl;

  /// No description provided for @pleaseEnterValidGithubUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid GitHub URL'**
  String get pleaseEnterValidGithubUrl;

  /// No description provided for @repositoryConnected.
  ///
  /// In en, this message translates to:
  /// **'✅ Repository connected'**
  String get repositoryConnected;

  /// No description provided for @projectWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Project Workspace'**
  String get projectWorkspace;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @filesSectionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Files section coming soon...'**
  String get filesSectionComingSoon;

  /// No description provided for @chatSectionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Chat section coming soon...'**
  String get chatSectionComingSoon;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWallet;

  /// No description provided for @errorLoadingWallet.
  ///
  /// In en, this message translates to:
  /// **'Error loading wallet'**
  String get errorLoadingWallet;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get pleaseEnterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get insufficientBalance;

  /// No description provided for @completeStripeAccountSetup.
  ///
  /// In en, this message translates to:
  /// **'Please complete Stripe account setup'**
  String get completeStripeAccountSetup;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'m ago'**
  String get minutesAgo;

  /// No description provided for @noWalletFound.
  ///
  /// In en, this message translates to:
  /// **'No wallet found'**
  String get noWalletFound;

  /// No description provided for @boost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boost;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get errorLoadingNotifications;

  /// No description provided for @allNotificationsMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsMarkedAsRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'When you receive notifications, they will appear here'**
  String get notificationsWillAppearHere;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @clearChatConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear chat history?'**
  String get clearChatConfirmation;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @chatHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Chat history cleared'**
  String get chatHistoryCleared;

  /// No description provided for @askMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get askMeAnything;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get opening;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referAndEarn;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @shareReferralMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on Freelancer Platform and get benefits! Use my code:'**
  String get shareReferralMessage;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get yourReferralCode;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share Code'**
  String get shareCode;

  /// No description provided for @referredFriends.
  ///
  /// In en, this message translates to:
  /// **'Referred Friends'**
  String get referredFriends;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Experience'**
  String get rateYourExperience;

  /// No description provided for @youAreRating.
  ///
  /// In en, this message translates to:
  /// **'You are rating'**
  String get youAreRating;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get yourRating;

  /// No description provided for @yourReviewOptional.
  ///
  /// In en, this message translates to:
  /// **'Your Review (Optional)'**
  String get yourReviewOptional;

  /// No description provided for @shareYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Share Your Experience'**
  String get shareYourExperience;

  /// No description provided for @pleaseSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating'**
  String get pleaseSelectRating;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRating;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @errorSubmittingRating.
  ///
  /// In en, this message translates to:
  /// **'Error submitting rating'**
  String get errorSubmittingRating;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @replyVisibilityMessage.
  ///
  /// In en, this message translates to:
  /// **'Your reply will be visible to everyone. Be professional and courteous.'**
  String get replyVisibilityMessage;

  /// No description provided for @yourReply.
  ///
  /// In en, this message translates to:
  /// **'Your Reply'**
  String get yourReply;

  /// No description provided for @replyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your response to this review...\n\nExample: \"Thank you for your feedback! We appreciate your business and will work on improving.\"'**
  String get replyHint;

  /// No description provided for @tipsForGoodReply.
  ///
  /// In en, this message translates to:
  /// **'Tips for a good reply'**
  String get tipsForGoodReply;

  /// No description provided for @beProfessionalAndPolite.
  ///
  /// In en, this message translates to:
  /// **'• Be professional and polite'**
  String get beProfessionalAndPolite;

  /// No description provided for @addressSpecificConcerns.
  ///
  /// In en, this message translates to:
  /// **'• Address specific concerns'**
  String get addressSpecificConcerns;

  /// No description provided for @thankReviewerForFeedback.
  ///
  /// In en, this message translates to:
  /// **'• Thank the reviewer for feedback'**
  String get thankReviewerForFeedback;

  /// No description provided for @showWillingnessToImprove.
  ///
  /// In en, this message translates to:
  /// **'• Show willingness to improve'**
  String get showWillingnessToImprove;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @pleaseEnterReply.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reply'**
  String get pleaseEnterReply;

  /// No description provided for @replyMinLength.
  ///
  /// In en, this message translates to:
  /// **'Reply should be at least 10 characters'**
  String get replyMinLength;

  /// No description provided for @replyPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Reply posted successfully'**
  String get replyPostedSuccess;

  /// No description provided for @errorPostingReply.
  ///
  /// In en, this message translates to:
  /// **'Error posting reply'**
  String get errorPostingReply;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// No description provided for @totalReviews.
  ///
  /// In en, this message translates to:
  /// **'Total Reviews'**
  String get totalReviews;

  /// No description provided for @positiveRate.
  ///
  /// In en, this message translates to:
  /// **'Positive Rate'**
  String get positiveRate;

  /// No description provided for @categoryAverages.
  ///
  /// In en, this message translates to:
  /// **'Category Averages'**
  String get categoryAverages;

  /// No description provided for @interviewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Interview Calendar'**
  String get interviewCalendar;

  /// No description provided for @addInterview.
  ///
  /// In en, this message translates to:
  /// **'Add Interview'**
  String get addInterview;

  /// No description provided for @selectDayToViewInterviews.
  ///
  /// In en, this message translates to:
  /// **'Select a day to view interviews'**
  String get selectDayToViewInterviews;

  /// No description provided for @noInterviewsScheduledForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No interviews scheduled for this day'**
  String get noInterviewsScheduledForThisDay;

  /// No description provided for @noLink.
  ///
  /// In en, this message translates to:
  /// **'No link'**
  String get noLink;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @interviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Interview Details'**
  String get interviewDetails;

  /// No description provided for @googleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get googleCalendar;

  /// No description provided for @downloadIcsFile.
  ///
  /// In en, this message translates to:
  /// **'Download .ics file'**
  String get downloadIcsFile;

  /// No description provided for @sendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get sendReminder;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @addFeedback.
  ///
  /// In en, this message translates to:
  /// **'Add Feedback'**
  String get addFeedback;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @invitationExpired.
  ///
  /// In en, this message translates to:
  /// **'This invitation has expired'**
  String get invitationExpired;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get scheduledFor;

  /// No description provided for @waitingForResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for response'**
  String get waitingForResponse;

  /// No description provided for @interviewCompleted.
  ///
  /// In en, this message translates to:
  /// **'Interview completed'**
  String get interviewCompleted;

  /// No description provided for @interviewDeclined.
  ///
  /// In en, this message translates to:
  /// **'Interview declined'**
  String get interviewDeclined;

  /// No description provided for @messageFrom.
  ///
  /// In en, this message translates to:
  /// **'Message from'**
  String get messageFrom;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// Message when invitation is sent
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to'**
  String get invitationSent;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @interviewScheduled.
  ///
  /// In en, this message translates to:
  /// **'Interview Scheduled'**
  String get interviewScheduled;

  /// No description provided for @rescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get rescheduled;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @joinInterview.
  ///
  /// In en, this message translates to:
  /// **'Join Interview'**
  String get joinInterview;

  /// No description provided for @joinInterviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Click the button below to join the video interview.'**
  String get joinInterviewDescription;

  /// No description provided for @joinMeeting.
  ///
  /// In en, this message translates to:
  /// **'Join Meeting'**
  String get joinMeeting;

  /// No description provided for @interviewInvitation.
  ///
  /// In en, this message translates to:
  /// **'Interview Invitation'**
  String get interviewInvitation;

  /// No description provided for @proposedTime.
  ///
  /// In en, this message translates to:
  /// **'Proposed Time:'**
  String get proposedTime;

  /// No description provided for @availableTimes.
  ///
  /// In en, this message translates to:
  /// **'Available Times:'**
  String get availableTimes;

  /// No description provided for @addMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a message (optional)'**
  String get addMessageOptional;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @acceptAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept & Confirm'**
  String get acceptAndConfirm;

  /// No description provided for @acceptSelectedTime.
  ///
  /// In en, this message translates to:
  /// **'Accept Selected Time'**
  String get acceptSelectedTime;

  /// No description provided for @pleaseSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a time'**
  String get pleaseSelectTime;

  /// No description provided for @completeInterview.
  ///
  /// In en, this message translates to:
  /// **'Complete Interview'**
  String get completeInterview;

  /// No description provided for @completeInterviewDescription.
  ///
  /// In en, this message translates to:
  /// **'After the interview, add your notes and feedback.'**
  String get completeInterviewDescription;

  /// No description provided for @meetingNotes.
  ///
  /// In en, this message translates to:
  /// **'Meeting Notes'**
  String get meetingNotes;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @declineInterview.
  ///
  /// In en, this message translates to:
  /// **'Decline Interview'**
  String get declineInterview;

  /// No description provided for @declineInterviewConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this interview invitation?'**
  String get declineInterviewConfirmation;

  /// No description provided for @interviewAccepted.
  ///
  /// In en, this message translates to:
  /// **'Interview accepted!'**
  String get interviewAccepted;

  /// No description provided for @errorAcceptingInterview.
  ///
  /// In en, this message translates to:
  /// **'Error accepting interview'**
  String get errorAcceptingInterview;

  /// No description provided for @interviewDeclinedMsg.
  ///
  /// In en, this message translates to:
  /// **'Interview declined'**
  String get interviewDeclinedMsg;

  /// No description provided for @errorDecliningInterview.
  ///
  /// In en, this message translates to:
  /// **'Error declining interview'**
  String get errorDecliningInterview;

  /// No description provided for @reasonForRescheduling.
  ///
  /// In en, this message translates to:
  /// **'Reason for rescheduling?'**
  String get reasonForRescheduling;

  /// No description provided for @interviewRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Interview rescheduled'**
  String get interviewRescheduled;

  /// No description provided for @errorRescheduling.
  ///
  /// In en, this message translates to:
  /// **'Error rescheduling'**
  String get errorRescheduling;

  /// No description provided for @reasonForCancellation.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation?'**
  String get reasonForCancellation;

  /// No description provided for @interviewCancelled.
  ///
  /// In en, this message translates to:
  /// **'Interview cancelled'**
  String get interviewCancelled;

  /// No description provided for @errorCancelling.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling'**
  String get errorCancelling;

  /// No description provided for @pleaseProvideReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason...'**
  String get pleaseProvideReason;

  /// No description provided for @addNotesAboutInterview.
  ///
  /// In en, this message translates to:
  /// **'Add notes about the interview:'**
  String get addNotesAboutInterview;

  /// No description provided for @meetingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting notes...'**
  String get meetingNotesHint;

  /// No description provided for @feedbackOptional.
  ///
  /// In en, this message translates to:
  /// **'Feedback (optional):'**
  String get feedbackOptional;

  /// No description provided for @additionalFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional feedback...'**
  String get additionalFeedbackHint;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @errorCompletingInterview.
  ///
  /// In en, this message translates to:
  /// **'Error completing interview'**
  String get errorCompletingInterview;

  /// No description provided for @calendarFileDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Calendar file downloaded'**
  String get calendarFileDownloaded;

  /// No description provided for @addedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Added to calendar successfully!'**
  String get addedToCalendar;

  /// No description provided for @errorAddingToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Error adding to calendar'**
  String get errorAddingToCalendar;

  /// No description provided for @reminderSent.
  ///
  /// In en, this message translates to:
  /// **'Reminder sent successfully!'**
  String get reminderSent;

  /// No description provided for @errorSendingReminder.
  ///
  /// In en, this message translates to:
  /// **'Error sending reminder'**
  String get errorSendingReminder;

  /// No description provided for @interviewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Interview Analytics'**
  String get interviewAnalytics;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @totalInterviews.
  ///
  /// In en, this message translates to:
  /// **'Total Interviews'**
  String get totalInterviews;

  /// No description provided for @acceptanceRate.
  ///
  /// In en, this message translates to:
  /// **'Acceptance Rate'**
  String get acceptanceRate;

  /// Label for completion rate statistic
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @avgResponse.
  ///
  /// In en, this message translates to:
  /// **'Avg Response'**
  String get avgResponse;

  /// No description provided for @interviewStatusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Interview Status Distribution'**
  String get interviewStatusDistribution;

  /// No description provided for @avgResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Response Time'**
  String get avgResponseTime;

  /// No description provided for @fromInvitationSent.
  ///
  /// In en, this message translates to:
  /// **'from invitation sent'**
  String get fromInvitationSent;

  /// No description provided for @monthlyTrends.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trends'**
  String get monthlyTrends;

  /// No description provided for @upcomingInterviews.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Interviews'**
  String get upcomingInterviews;

  /// No description provided for @noUpcomingInterviews.
  ///
  /// In en, this message translates to:
  /// **'No upcoming interviews scheduled'**
  String get noUpcomingInterviews;

  /// No description provided for @interviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get interviews;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String inDays(int count);

  /// No description provided for @onTimeRate.
  ///
  /// In en, this message translates to:
  /// **'On-Time Rate'**
  String get onTimeRate;

  /// No description provided for @ofCompleted.
  ///
  /// In en, this message translates to:
  /// **'of completed'**
  String get ofCompleted;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg Rating'**
  String get avgRating;

  /// No description provided for @successRate.
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get successRate;

  /// No description provided for @acceptedToCompleted.
  ///
  /// In en, this message translates to:
  /// **'accepted → completed'**
  String get acceptedToCompleted;

  /// No description provided for @responseTimeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Response Time Distribution'**
  String get responseTimeDistribution;

  /// No description provided for @interviewRatings.
  ///
  /// In en, this message translates to:
  /// **'Interview Ratings'**
  String get interviewRatings;

  /// No description provided for @topPerformers.
  ///
  /// In en, this message translates to:
  /// **'Top Performers'**
  String get topPerformers;

  /// No description provided for @interviewsCompleted.
  ///
  /// In en, this message translates to:
  /// **'interviews completed'**
  String get interviewsCompleted;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI insights'**
  String get aiInsights;

  /// No description provided for @bestTimeToInterview.
  ///
  /// In en, this message translates to:
  /// **'Best Time to Interview'**
  String get bestTimeToInterview;

  /// No description provided for @bestTimeToInterviewClient.
  ///
  /// In en, this message translates to:
  /// **'Based on your history, freelancers are most responsive between 10 AM - 2 PM on weekdays.'**
  String get bestTimeToInterviewClient;

  /// No description provided for @bestTimeToInterviewFreelancer.
  ///
  /// In en, this message translates to:
  /// **'You respond fastest to interview invitations within 2 hours of receiving them.'**
  String get bestTimeToInterviewFreelancer;

  /// No description provided for @successRateClient.
  ///
  /// In en, this message translates to:
  /// **'Your interview to hire conversion rate is {rate}%. Keep up the good work!'**
  String successRateClient(int rate);

  /// No description provided for @successRateFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Your interview acceptance rate is {rate}%. Try responding faster to improve.'**
  String successRateFreelancer(int rate);

  /// No description provided for @optimalSchedule.
  ///
  /// In en, this message translates to:
  /// **'Optimal Schedule'**
  String get optimalSchedule;

  /// No description provided for @optimalScheduleClient.
  ///
  /// In en, this message translates to:
  /// **'Tuesday and Wednesday have the highest acceptance rates for interview invitations.'**
  String get optimalScheduleClient;

  /// No description provided for @optimalScheduleFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Interviews scheduled on Thursday have the highest completion rate.'**
  String get optimalScheduleFreelancer;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @recommendationClient1.
  ///
  /// In en, this message translates to:
  /// **'Your response rate is 85%. Try to respond within 24 hours for better results.'**
  String get recommendationClient1;

  /// No description provided for @recommendationClient2.
  ///
  /// In en, this message translates to:
  /// **'Schedule interviews between 10 AM - 2 PM for higher acceptance rates.'**
  String get recommendationClient2;

  /// No description provided for @recommendationClient3.
  ///
  /// In en, this message translates to:
  /// **'Send a reminder 1 hour before the interview to reduce no-shows.'**
  String get recommendationClient3;

  /// No description provided for @recommendationFreelancer1.
  ///
  /// In en, this message translates to:
  /// **'You respond within 4 hours on average. Keep up the good work!'**
  String get recommendationFreelancer1;

  /// No description provided for @recommendationFreelancer2.
  ///
  /// In en, this message translates to:
  /// **'Your acceptance rate is 75%. Try to respond to all invitations.'**
  String get recommendationFreelancer2;

  /// No description provided for @recommendationFreelancer3.
  ///
  /// In en, this message translates to:
  /// **'Prepare questions before the interview to make a better impression.'**
  String get recommendationFreelancer3;

  /// No description provided for @proTips.
  ///
  /// In en, this message translates to:
  /// **'Pro Tips'**
  String get proTips;

  /// No description provided for @proTipsContent.
  ///
  /// In en, this message translates to:
  /// **'• Send interview invitations within 24 hours of receiving a proposal\n• Always confirm the interview time 1 day in advance\n• Prepare specific questions before the interview\n• Take notes during the interview for better evaluation\n• Follow up within 48 hours after the interview'**
  String get proTipsContent;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at'**
  String get todayAt;

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at'**
  String get yesterdayAt;

  /// Preposition for time (e.g., at 10:00 AM)
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @errorLoadingInterviews.
  ///
  /// In en, this message translates to:
  /// **'Error loading interviews'**
  String get errorLoadingInterviews;

  /// No description provided for @noInterviewInvitationsSent.
  ///
  /// In en, this message translates to:
  /// **'No interview invitations sent'**
  String get noInterviewInvitationsSent;

  /// No description provided for @noInterviewInvitationsReceived.
  ///
  /// In en, this message translates to:
  /// **'No interview invitations received'**
  String get noInterviewInvitationsReceived;

  /// No description provided for @inviteFreelancersToInterview.
  ///
  /// In en, this message translates to:
  /// **'Invite freelancers to interview before hiring'**
  String get inviteFreelancersToInterview;

  /// No description provided for @interviewsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'When clients invite you for interviews, they will appear here'**
  String get interviewsWillAppearHere;

  /// No description provided for @browseYourProjects.
  ///
  /// In en, this message translates to:
  /// **'Browse Your Projects'**
  String get browseYourProjects;

  /// No description provided for @with_.
  ///
  /// In en, this message translates to:
  /// **'with'**
  String get with_;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @interviewFeedback.
  ///
  /// In en, this message translates to:
  /// **'Interview Feedback'**
  String get interviewFeedback;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps {name} improve and helps other clients make informed decisions.'**
  String feedbackDescription(String name);

  /// Label for overall rating statistic
  ///
  /// In en, this message translates to:
  /// **'Overall Rating'**
  String get overallRating;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent! 🌟'**
  String get excellent;

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good! 👍'**
  String get veryGood;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good 👌'**
  String get good;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair 😐'**
  String get fair;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor 😞'**
  String get poor;

  /// No description provided for @detailedRatings.
  ///
  /// In en, this message translates to:
  /// **'Detailed Ratings'**
  String get detailedRatings;

  /// No description provided for @professionalism.
  ///
  /// In en, this message translates to:
  /// **'Professionalism'**
  String get professionalism;

  /// No description provided for @technicalSkills.
  ///
  /// In en, this message translates to:
  /// **'Technical Skills'**
  String get technicalSkills;

  /// No description provided for @punctuality.
  ///
  /// In en, this message translates to:
  /// **'Punctuality'**
  String get punctuality;

  /// No description provided for @ratingLabelProfessionalism.
  ///
  /// In en, this message translates to:
  /// **'Professionalism'**
  String get ratingLabelProfessionalism;

  /// No description provided for @ratingLabelCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get ratingLabelCommunication;

  /// No description provided for @ratingLabelTechnicalSkills.
  ///
  /// In en, this message translates to:
  /// **'Technical Skills'**
  String get ratingLabelTechnicalSkills;

  /// No description provided for @ratingLabelPunctuality.
  ///
  /// In en, this message translates to:
  /// **'Punctuality'**
  String get ratingLabelPunctuality;

  /// No description provided for @whatWentWell.
  ///
  /// In en, this message translates to:
  /// **'What went well?'**
  String get whatWentWell;

  /// No description provided for @whatWentWellHint.
  ///
  /// In en, this message translates to:
  /// **'Share what you liked about the interview...'**
  String get whatWentWellHint;

  /// No description provided for @whatCouldBeImproved.
  ///
  /// In en, this message translates to:
  /// **'What could be improved?'**
  String get whatCouldBeImproved;

  /// No description provided for @whatCouldBeImprovedHint.
  ///
  /// In en, this message translates to:
  /// **'Constructive feedback for improvement...'**
  String get whatCouldBeImprovedHint;

  /// No description provided for @wouldYouHireAgain.
  ///
  /// In en, this message translates to:
  /// **'Would you hire this freelancer again?'**
  String get wouldYouHireAgain;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @thankYouForFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouForFeedback;

  /// No description provided for @errorSubmittingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Error submitting feedback'**
  String get errorSubmittingFeedback;

  /// No description provided for @interviewQuestionLibrary.
  ///
  /// In en, this message translates to:
  /// **'Interview Question Library'**
  String get interviewQuestionLibrary;

  /// No description provided for @technicalQuestions.
  ///
  /// In en, this message translates to:
  /// **'Technical Questions'**
  String get technicalQuestions;

  /// No description provided for @portfolioReview.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Review'**
  String get portfolioReview;

  /// No description provided for @softSkills.
  ///
  /// In en, this message translates to:
  /// **'Soft Skills'**
  String get softSkills;

  /// No description provided for @culturalFit.
  ///
  /// In en, this message translates to:
  /// **'Cultural Fit'**
  String get culturalFit;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @tipStarMethod.
  ///
  /// In en, this message translates to:
  /// **'Use the STAR method (Situation, Task, Action, Result) to structure your answer.'**
  String get tipStarMethod;

  /// No description provided for @tipChallenge.
  ///
  /// In en, this message translates to:
  /// **'Focus on the problem-solving process and what you learned.'**
  String get tipChallenge;

  /// No description provided for @tipDeadline.
  ///
  /// In en, this message translates to:
  /// **'Show your time management skills and ability to prioritize.'**
  String get tipDeadline;

  /// No description provided for @tipGeneral.
  ///
  /// In en, this message translates to:
  /// **'Be honest and provide specific examples from your experience.'**
  String get tipGeneral;

  /// No description provided for @questionCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Question copied to clipboard!'**
  String get questionCopiedToClipboard;

  /// No description provided for @shareFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share feature coming soon!'**
  String get shareFeatureComingSoon;

  /// No description provided for @searchQuestions.
  ///
  /// In en, this message translates to:
  /// **'Search Questions'**
  String get searchQuestions;

  /// No description provided for @searchByKeyword.
  ///
  /// In en, this message translates to:
  /// **'Search by keyword...'**
  String get searchByKeyword;

  /// No description provided for @randomQuestionForYou.
  ///
  /// In en, this message translates to:
  /// **'Random Question for You'**
  String get randomQuestionForYou;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @randomQuestion.
  ///
  /// In en, this message translates to:
  /// **'Random Question'**
  String get randomQuestion;

  /// No description provided for @noQuestionsFound.
  ///
  /// In en, this message translates to:
  /// **'No questions found'**
  String get noQuestionsFound;

  /// No description provided for @tipsForAnswering.
  ///
  /// In en, this message translates to:
  /// **'💡 Tips for answering:'**
  String get tipsForAnswering;

  /// No description provided for @copyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Copy question'**
  String get copyQuestion;

  /// No description provided for @saveToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Save to favorites'**
  String get saveToFavorites;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// No description provided for @securePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure Payment'**
  String get securePayment;

  /// No description provided for @paymentHeldInEscrow.
  ///
  /// In en, this message translates to:
  /// **'Your payment will be held in escrow until the project is completed.'**
  String get paymentHeldInEscrow;

  /// No description provided for @contractTotal.
  ///
  /// In en, this message translates to:
  /// **'Contract total'**
  String get contractTotal;

  /// No description provided for @couponDiscount.
  ///
  /// In en, this message translates to:
  /// **'Coupon discount'**
  String get couponDiscount;

  /// No description provided for @chargedNowEscrow.
  ///
  /// In en, this message translates to:
  /// **'Charged now (escrow)'**
  String get chargedNowEscrow;

  /// No description provided for @commissionOnRelease.
  ///
  /// In en, this message translates to:
  /// **'Commission (on release)'**
  String get commissionOnRelease;

  /// No description provided for @estFee.
  ///
  /// In en, this message translates to:
  /// **'est. fee'**
  String get estFee;

  /// No description provided for @paymentSecureDescription.
  ///
  /// In en, this message translates to:
  /// **'Your payment is secure and will only be released when you approve each milestone.'**
  String get paymentSecureDescription;

  /// No description provided for @stripeWebRedirect.
  ///
  /// In en, this message translates to:
  /// **'You will be redirected to Stripe secure checkout page.'**
  String get stripeWebRedirect;

  /// No description provided for @stripeInAppPayment.
  ///
  /// In en, this message translates to:
  /// **'Secure in-app payment with Stripe.'**
  String get stripeInAppPayment;

  /// No description provided for @payWithStripe.
  ///
  /// In en, this message translates to:
  /// **'Pay with Stripe'**
  String get payWithStripe;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @confirmPaymentManual.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment (Manual)'**
  String get confirmPaymentManual;

  /// No description provided for @agreeToTermsByPaying.
  ///
  /// In en, this message translates to:
  /// **'By paying, you agree to our Terms of Service'**
  String get agreeToTermsByPaying;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'✅ Payment confirmed!'**
  String get paymentConfirmed;

  /// No description provided for @failedToConfirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to confirm payment'**
  String get failedToConfirmPayment;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'✅ Payment successful!'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @completePaymentInNewTab.
  ///
  /// In en, this message translates to:
  /// **'Complete payment in the new tab'**
  String get completePaymentInNewTab;

  /// No description provided for @completeSubscriptionPayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Subscription Payment'**
  String get completeSubscriptionPayment;

  /// No description provided for @subscriptionPayment.
  ///
  /// In en, this message translates to:
  /// **'Subscription Payment'**
  String get subscriptionPayment;

  /// No description provided for @subscriptionActivatedImmediately.
  ///
  /// In en, this message translates to:
  /// **'Your subscription will be activated immediately after payment.'**
  String get subscriptionActivatedImmediately;

  /// No description provided for @subscriptionPrice.
  ///
  /// In en, this message translates to:
  /// **'Subscription Price'**
  String get subscriptionPrice;

  /// No description provided for @subscriptionSecureDescription.
  ///
  /// In en, this message translates to:
  /// **'Your payment is secure and will grant you immediate access to all premium features.'**
  String get subscriptionSecureDescription;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @subscriptionPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'✅ Subscription payment confirmed!'**
  String get subscriptionPaymentConfirmed;

  /// No description provided for @failedToConfirmSubscriptionPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to confirm subscription payment'**
  String get failedToConfirmSubscriptionPayment;

  /// No description provided for @subscriptionPaymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'✅ Subscription payment successful!'**
  String get subscriptionPaymentSuccessful;

  /// No description provided for @subscriptionPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Subscription payment failed'**
  String get subscriptionPaymentFailed;

  /// No description provided for @agreeToTermsBySubscribing.
  ///
  /// In en, this message translates to:
  /// **'By subscribing, you agree to our Terms of Service and Privacy Policy'**
  String get agreeToTermsBySubscribing;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @minBudget.
  ///
  /// In en, this message translates to:
  /// **'Min Budget'**
  String get minBudget;

  /// No description provided for @maxBudget.
  ///
  /// In en, this message translates to:
  /// **'Max Budget'**
  String get maxBudget;

  /// No description provided for @minDuration.
  ///
  /// In en, this message translates to:
  /// **'Min Duration'**
  String get minDuration;

  /// No description provided for @maxDuration.
  ///
  /// In en, this message translates to:
  /// **'Max Duration'**
  String get maxDuration;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @postNewProject.
  ///
  /// In en, this message translates to:
  /// **'Post New Project'**
  String get postNewProject;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'template'**
  String get templates;

  /// No description provided for @projectDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below. AI will analyze and suggest improvements.'**
  String get projectDetailsHint;

  /// No description provided for @autoSaveHint.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved automatically on this device.'**
  String get autoSaveHint;

  /// No description provided for @draftRestored.
  ///
  /// In en, this message translates to:
  /// **'Continued from your saved draft'**
  String get draftRestored;

  /// No description provided for @templateApplied.
  ///
  /// In en, this message translates to:
  /// **'Template applied — edit and post when ready'**
  String get templateApplied;

  /// No description provided for @clearDraft.
  ///
  /// In en, this message translates to:
  /// **'Clear draft?'**
  String get clearDraft;

  /// No description provided for @clearDraftConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove the saved project draft from this device?'**
  String get clearDraftConfirmation;

  /// No description provided for @draftCleared.
  ///
  /// In en, this message translates to:
  /// **'Draft cleared'**
  String get draftCleared;

  /// No description provided for @projectTemplates.
  ///
  /// In en, this message translates to:
  /// **'Project templates'**
  String get projectTemplates;

  /// No description provided for @templateHint.
  ///
  /// In en, this message translates to:
  /// **'Prefill fields — still edit before posting.'**
  String get templateHint;

  /// No description provided for @clearSavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Clear saved draft'**
  String get clearSavedDraft;

  /// No description provided for @projectCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Project created successfully'**
  String get projectCreatedSuccess;

  /// No description provided for @errorCreatingProject.
  ///
  /// In en, this message translates to:
  /// **'Error creating project'**
  String get errorCreatingProject;

  /// No description provided for @projectTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Title'**
  String get projectTitle;

  /// No description provided for @projectTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Build an E-commerce App'**
  String get projectTitleHint;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get requiredField;

  /// No description provided for @projectDescription.
  ///
  /// In en, this message translates to:
  /// **'Project Description'**
  String get projectDescription;

  /// No description provided for @projectDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your project in detail...\n- What do you need?\n- What are your expectations?\n- Any specific requirements?'**
  String get projectDescriptionHint;

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'Duration (days)'**
  String get durationDays;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @postProject.
  ///
  /// In en, this message translates to:
  /// **'Post Project'**
  String get postProject;

  /// No description provided for @milestonesAddedHint.
  ///
  /// In en, this message translates to:
  /// **'Suggested milestones added to proposal'**
  String get milestonesAddedHint;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @aiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Ai Recommendations'**
  String get aiRecommendations;

  /// Hint shown above AI recommended freelancers explaining the recommendations are project-specific
  ///
  /// In en, this message translates to:
  /// **'These AI recommendations are tailored for this project only, using the project requirements and freelancer match score.'**
  String get aiRecommendationsProjectHint;

  /// Empty state message shown when no AI freelancer suggestions exist for this project
  ///
  /// In en, this message translates to:
  /// **'No AI freelancer suggestions are available yet for this project. You can still review submitted proposals below.'**
  String get noAiFreelancerSuggestions;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// Title for compare freelancers screen
  ///
  /// In en, this message translates to:
  /// **'Compare Freelancers'**
  String get compareFreelancers;

  /// Button tooltip to switch to card view
  ///
  /// In en, this message translates to:
  /// **'Switch to Card View'**
  String get switchToCardView;

  /// Button tooltip to switch to detailed table view
  ///
  /// In en, this message translates to:
  /// **'Switch to Detailed View'**
  String get switchToDetailedView;

  /// Loading message when analyzing freelancers
  ///
  /// In en, this message translates to:
  /// **'Analyzing freelancers...'**
  String get analyzingFreelancers;

  /// Subtitle while loading comparison data
  ///
  /// In en, this message translates to:
  /// **'Comparing skills, experience, and performance'**
  String get comparingFreelancersDesc;

  /// Empty state message when no freelancers available
  ///
  /// In en, this message translates to:
  /// **'No freelancers to compare'**
  String get noFreelancersToCompare;

  /// Instruction when no freelancers selected
  ///
  /// In en, this message translates to:
  /// **'Select at least 2 freelancers to start comparing'**
  String get selectAtLeastTwoFreelancers;

  /// Button text to go back
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// Label for AI recommendation banner
  ///
  /// In en, this message translates to:
  /// **'AI Recommendation'**
  String get aiRecommendation;

  /// Text showing match percentage with project
  ///
  /// In en, this message translates to:
  /// **'match with your project'**
  String get matchWithProject;

  /// Badge label for AI recommended freelancer
  ///
  /// In en, this message translates to:
  /// **'AI Pick'**
  String get aiPick;

  /// Description for overall rating metric
  ///
  /// In en, this message translates to:
  /// **'Overall rating and performance'**
  String get overallRatingDescription;

  /// Description for skills match metric
  ///
  /// In en, this message translates to:
  /// **'Skills match with your project'**
  String get skillsMatchDescription;

  /// Description for experience metric
  ///
  /// In en, this message translates to:
  /// **'Years of experience & project count'**
  String get experienceDescription;

  /// Description for reliability metric
  ///
  /// In en, this message translates to:
  /// **'Completion rate & on-time delivery'**
  String get reliabilityDescription;

  /// Description for communication metric
  ///
  /// In en, this message translates to:
  /// **'Response time & feedback'**
  String get communicationDescription;

  /// Description for value metric
  ///
  /// In en, this message translates to:
  /// **'Price vs quality ratio'**
  String get valueDescription;

  /// Label for skills match statistic
  ///
  /// In en, this message translates to:
  /// **'Skills Match'**
  String get skillsMatch;

  /// Subtitle for skills match
  ///
  /// In en, this message translates to:
  /// **'with your project'**
  String get withYourProject;

  /// Subtitle for completion rate
  ///
  /// In en, this message translates to:
  /// **'of projects completed'**
  String get ofProjectsCompleted;

  /// Label for on-time delivery statistic
  ///
  /// In en, this message translates to:
  /// **'On-Time Delivery'**
  String get onTimeDelivery;

  /// Subtitle for on-time delivery
  ///
  /// In en, this message translates to:
  /// **'of deadlines met'**
  String get ofDeadlinesMet;

  /// Label for response time statistic
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get responseTime;

  /// Subtitle for response time
  ///
  /// In en, this message translates to:
  /// **'average response'**
  String get averageResponse;

  /// Label for completed projects statistic
  ///
  /// In en, this message translates to:
  /// **'Projects Completed'**
  String get projectsCompleted;

  /// Subtitle for completed projects
  ///
  /// In en, this message translates to:
  /// **'Total Projects'**
  String get totalProjects;

  /// Subtitle for experience years
  ///
  /// In en, this message translates to:
  /// **'in the field'**
  String get inTheField;

  /// Abbreviation for hour
  ///
  /// In en, this message translates to:
  /// **'hr'**
  String get hr;

  /// Section title for top skills
  ///
  /// In en, this message translates to:
  /// **'Top Skills'**
  String get topSkills;

  /// Button text to view freelancer profile
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// Button text to hire freelancer
  ///
  /// In en, this message translates to:
  /// **'Hire'**
  String get hire;

  /// Singular form of hour
  ///
  /// In en, this message translates to:
  /// **'hr'**
  String get hour;

  /// Abbreviation for project(s)
  ///
  /// In en, this message translates to:
  /// **'prj'**
  String get prj;

  /// Title for performance comparison chart
  ///
  /// In en, this message translates to:
  /// **'Performance Comparison'**
  String get performanceComparison;

  /// Title for ratings comparison chart
  ///
  /// In en, this message translates to:
  /// **'Ratings Comparison'**
  String get ratingsComparison;

  /// Title for comprehensive analysis section
  ///
  /// In en, this message translates to:
  /// **'Comprehensive Analysis'**
  String get comprehensiveAnalysis;

  /// Metric name for overall rating
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// Metric name for reliability
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get reliability;

  /// Metric name for value for money
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// FAB text to view comparison charts
  ///
  /// In en, this message translates to:
  /// **'View Charts'**
  String get viewCharts;

  /// Title for delete project dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// Confirmation message for deleting a project
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this project?'**
  String get deleteProjectConfirmation;

  /// Label for project status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectStatusLabel;

  /// Status text when project is accepting proposals
  ///
  /// In en, this message translates to:
  /// **'Accepting proposals'**
  String get acceptingProposals;

  /// Status text when project is in progress
  ///
  /// In en, this message translates to:
  /// **'Project in progress'**
  String get projectInProgress;

  /// Button text to complete a project
  ///
  /// In en, this message translates to:
  /// **'Complete Project'**
  String get completeProject;

  /// Label for project posted date
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get posted;

  /// Label for view count
  ///
  /// In en, this message translates to:
  /// **'views'**
  String get views;

  /// Title for contract details section
  ///
  /// In en, this message translates to:
  /// **'Contract Details'**
  String get contractDetails;

  /// Message when interview limit is reached
  ///
  /// In en, this message translates to:
  /// **'Monthly interview invitation limit reached'**
  String get interviewLimitReached;

  /// Message when no interview invitations left
  ///
  /// In en, this message translates to:
  /// **'No interview invitations left this month ({lim}/mo). Upgrade your plan to invite more.'**
  String noInterviewInvitationsLeft(int lim);

  /// Message showing remaining interview invitations
  ///
  /// In en, this message translates to:
  /// **'{rem} of {lim} interview invitations left this month'**
  String interviewInvitationsLeft(int rem, int lim);

  /// Message when proposal status is updated
  ///
  /// In en, this message translates to:
  /// **'Proposal {status} updated successfully'**
  String proposalStatusUpdated(String status);

  /// Error message when updating proposal fails
  ///
  /// In en, this message translates to:
  /// **'Error updating proposal'**
  String get errorUpdatingProposal;

  /// Error message when proposal data is not found
  ///
  /// In en, this message translates to:
  /// **'Proposal data not found'**
  String get proposalDataNotFound;

  /// Error message when project or freelancer data is missing
  ///
  /// In en, this message translates to:
  /// **'Missing project or freelancer data'**
  String get missingProjectOrFreelancerData;

  /// Title for project proposals screen
  ///
  /// In en, this message translates to:
  /// **'Project Proposals'**
  String get projectProposals;

  /// Title for AI recommended freelancers section
  ///
  /// In en, this message translates to:
  /// **'AI Recommended Freelancers'**
  String get aiRecommendedFreelancers;

  /// Label for match percentage
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get match;

  /// Button text to invite freelancer to project
  ///
  /// In en, this message translates to:
  /// **'Invite to Project'**
  String get inviteToProject;

  /// Empty state message for proposals
  ///
  /// In en, this message translates to:
  /// **'When freelancers submit proposals, they will appear here'**
  String get whenFreelancersSubmitProposals;

  /// Button text to negotiate with freelancer
  ///
  /// In en, this message translates to:
  /// **'Negotiate'**
  String get negotiate;

  /// Label for interview feature
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get interview;

  /// Option for manual time selection
  ///
  /// In en, this message translates to:
  /// **'Manual (Choose Times)'**
  String get manualChooseTimes;

  /// Option for AI optimized time selection
  ///
  /// In en, this message translates to:
  /// **'Smart (AI Optimized)'**
  String get smartAIOptimized;

  /// Message when no description is provided
  ///
  /// In en, this message translates to:
  /// **'No description provided'**
  String get noDescriptionProvided;

  /// Label for delivery time
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// Loading message when generating SOW
  ///
  /// In en, this message translates to:
  /// **'Generating SOW...'**
  String get generatingSOW;

  /// Button text to generate SOW
  ///
  /// In en, this message translates to:
  /// **'Generate SOW'**
  String get generateSOW;

  /// Loading message when creating something
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// Button text to view contract
  ///
  /// In en, this message translates to:
  /// **'View Contract'**
  String get viewContract;

  /// Message for coming soon feature
  ///
  /// In en, this message translates to:
  /// **'View Contract - Coming Soon'**
  String get viewContractComingSoon;

  /// Title when proposal is accepted
  ///
  /// In en, this message translates to:
  /// **'Proposal Accepted'**
  String get proposalAccepted;

  /// Message when contract is created
  ///
  /// In en, this message translates to:
  /// **'A contract has been created. You can now communicate with the freelancer.'**
  String get contractCreatedMessage;

  /// Title when proposal is rejected
  ///
  /// In en, this message translates to:
  /// **'Proposal Rejected'**
  String get proposalRejected;

  /// Message when proposal is rejected
  ///
  /// In en, this message translates to:
  /// **'This proposal has been rejected. You can still contact the freelancer if needed.'**
  String get proposalRejectedMessage;

  /// Error message when contract creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create contract'**
  String get failedToCreateContract;

  /// Message for AI interview invitation
  ///
  /// In en, this message translates to:
  /// **'AI has analyzed availability and suggested optimal times. Please select the time that works best for you.'**
  String get aiInterviewInvitationMessage;

  /// Success message when smart interview invitation is sent
  ///
  /// In en, this message translates to:
  /// **'✅ Smart interview invitation sent to freelancer!'**
  String get smartInterviewInvitationSent;

  /// Title for AI suggested times dialog
  ///
  /// In en, this message translates to:
  /// **'AI Suggested Times Sent'**
  String get aiSuggestedTimesSent;

  /// Description for AI times sent dialog
  ///
  /// In en, this message translates to:
  /// **'The following AI-optimized times have been sent to the freelancer. They will select one that works for them.'**
  String get aiTimesSentDescription;

  /// Title for schedule interview dialog
  ///
  /// In en, this message translates to:
  /// **'Schedule Interview'**
  String get scheduleInterview;

  /// Instruction for selecting interview times
  ///
  /// In en, this message translates to:
  /// **'Select 1-3 preferred times for the interview'**
  String get selectPreferredTimes;

  /// Button to add interview time
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get addTime;

  /// Hint for optional message field
  ///
  /// In en, this message translates to:
  /// **'Add a message for the freelancer (optional)'**
  String get optionalMessageHint;

  /// Button to send interview invitation
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitation;

  /// Default message for interview invitation
  ///
  /// In en, this message translates to:
  /// **'I would like to interview you for this project. Please select a time that works for you.'**
  String get interviewInvitationMessage;

  /// Success message when interview invitation is sent
  ///
  /// In en, this message translates to:
  /// **'✅ Interview invitation sent!'**
  String get interviewInvitationSent;

  /// Error message when sending invitation fails
  ///
  /// In en, this message translates to:
  /// **'Error sending invitation'**
  String get errorSendingInvitation;

  /// Button text to acknowledge
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter '**
  String get clearFilter;

  /// No description provided for @showAllContracts.
  ///
  /// In en, this message translates to:
  /// **' Show All Contracts '**
  String get showAllContracts;

  /// No description provided for @noActiveContracts.
  ///
  /// In en, this message translates to:
  /// **'No Active Contracts'**
  String get noActiveContracts;

  /// No description provided for @noDraftContracts.
  ///
  /// In en, this message translates to:
  /// **'No Draft Contracts'**
  String get noDraftContracts;

  /// No description provided for @noCompletedContracts.
  ///
  /// In en, this message translates to:
  /// **'No Completed Contracts'**
  String get noCompletedContracts;

  /// No description provided for @noSignedContracts.
  ///
  /// In en, this message translates to:
  /// **'No Signed Contracts'**
  String get noSignedContracts;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @ratingsAndReviews.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get ratingsAndReviews;

  /// No description provided for @viewAllReviews.
  ///
  /// In en, this message translates to:
  /// **'View All Reviews'**
  String get viewAllReviews;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get seeMore;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get topRated;

  /// No description provided for @risingTalent.
  ///
  /// In en, this message translates to:
  /// **'Rising talent'**
  String get risingTalent;

  /// No description provided for @acceptingWork.
  ///
  /// In en, this message translates to:
  /// **'Accepting work'**
  String get acceptingWork;

  /// No description provided for @limited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get limited;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get done;

  /// No description provided for @hireForProject.
  ///
  /// In en, this message translates to:
  /// **'Hire for this project'**
  String get hireForProject;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @atAGlance.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get atAGlance;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get response;

  /// No description provided for @hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get hourly;

  /// No description provided for @commitment.
  ///
  /// In en, this message translates to:
  /// **'Commitment'**
  String get commitment;

  /// No description provided for @skillsAndExpertise.
  ///
  /// In en, this message translates to:
  /// **'Skills & expertise'**
  String get skillsAndExpertise;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @profileViews.
  ///
  /// In en, this message translates to:
  /// **'Profile views'**
  String get profileViews;

  /// No description provided for @workExperience.
  ///
  /// In en, this message translates to:
  /// **'Work experience'**
  String get workExperience;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @gitHub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get gitHub;

  /// No description provided for @linkedIn.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedIn;

  /// No description provided for @dribbble.
  ///
  /// In en, this message translates to:
  /// **'Dribbble'**
  String get dribbble;

  /// No description provided for @twitter.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get twitter;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @recentlyDelivered.
  ///
  /// In en, this message translates to:
  /// **'Recently delivered projects'**
  String get recentlyDelivered;

  /// No description provided for @deliveredProject.
  ///
  /// In en, this message translates to:
  /// **'Delivered project'**
  String get deliveredProject;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @clientReviews.
  ///
  /// In en, this message translates to:
  /// **'Client reviews'**
  String get clientReviews;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load this profile.'**
  String get couldNotLoadProfile;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @failedToStartChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to start chat'**
  String get failedToStartChat;

  /// No description provided for @freelancerProfile.
  ///
  /// In en, this message translates to:
  /// **'Freelancer profile'**
  String get freelancerProfile;

  /// No description provided for @professionalFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Professional Freelancer'**
  String get professionalFreelancer;

  /// No description provided for @findFreelancers.
  ///
  /// In en, this message translates to:
  /// **'Find Freelancers'**
  String get findFreelancers;

  /// No description provided for @searchFreelancers.
  ///
  /// In en, this message translates to:
  /// **'Search freelancers...'**
  String get searchFreelancers;

  /// No description provided for @noFreelancersFound.
  ///
  /// In en, this message translates to:
  /// **'No freelancers found'**
  String get noFreelancersFound;

  /// No description provided for @tryDifferentFilters.
  ///
  /// In en, this message translates to:
  /// **'Try different filters'**
  String get tryDifferentFilters;

  /// No description provided for @freelancersFound.
  ///
  /// In en, this message translates to:
  /// **'freelancers found'**
  String get freelancersFound;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Active filters'**
  String get activeFilters;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @allSkills.
  ///
  /// In en, this message translates to:
  /// **'All skills'**
  String get allSkills;

  /// No description provided for @minRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum rating'**
  String get minRating;

  /// No description provided for @minExperience.
  ///
  /// In en, this message translates to:
  /// **'Minimum experience'**
  String get minExperience;

  /// No description provided for @maxHourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Maximum hourly rate'**
  String get maxHourlyRate;

  /// No description provided for @lowestFirst.
  ///
  /// In en, this message translates to:
  /// **'Lowest first'**
  String get lowestFirst;

  /// No description provided for @highestFirst.
  ///
  /// In en, this message translates to:
  /// **'Highest first'**
  String get highestFirst;

  /// No description provided for @mostFirst.
  ///
  /// In en, this message translates to:
  /// **'Most first'**
  String get mostFirst;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @hireRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Hire request sent!'**
  String get hireRequestSent;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @skill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get skill;

  /// No description provided for @sendOfferTo.
  ///
  /// In en, this message translates to:
  /// **'Send Offer to'**
  String get sendOfferTo;

  /// No description provided for @offerAmountOptional.
  ///
  /// In en, this message translates to:
  /// **'Offer Amount (Optional)'**
  String get offerAmountOptional;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @messageOptional.
  ///
  /// In en, this message translates to:
  /// **'Message (Optional)'**
  String get messageOptional;

  /// No description provided for @writeMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Write your message here...'**
  String get writeMessageHere;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send Offer'**
  String get sendOffer;

  /// No description provided for @offerSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Offer sent successfully!'**
  String get offerSentSuccessfully;

  /// No description provided for @noOpenProjects.
  ///
  /// In en, this message translates to:
  /// **'No open projects'**
  String get noOpenProjects;

  /// No description provided for @createProjectNow.
  ///
  /// In en, this message translates to:
  /// **'Create Project Now'**
  String get createProjectNow;

  /// No description provided for @hireFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Hire Freelancer'**
  String get hireFreelancer;

  /// No description provided for @sendCustomOfferToFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Send a custom job offer to this freelancer'**
  String get sendCustomOfferToFreelancer;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @discussBeforeHiring.
  ///
  /// In en, this message translates to:
  /// **'Discuss details before hiring'**
  String get discussBeforeHiring;

  /// No description provided for @scheduleVideoCallInterview.
  ///
  /// In en, this message translates to:
  /// **'Schedule a video call interview'**
  String get scheduleVideoCallInterview;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @noOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No offers yet'**
  String get noOffersYet;

  /// No description provided for @whenYouReceiveOffers.
  ///
  /// In en, this message translates to:
  /// **'When you receive job offers, they will appear here'**
  String get whenYouReceiveOffers;

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted'**
  String get offerAccepted;

  /// No description provided for @offerDeclined.
  ///
  /// In en, this message translates to:
  /// **'Offer declined'**
  String get offerDeclined;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @createProjectFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a project first to hire freelancers'**
  String get createProjectFirst;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProject;

  /// No description provided for @mySubscription.
  ///
  /// In en, this message translates to:
  /// **'My Subscription'**
  String get mySubscription;

  /// No description provided for @ads.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get ads;

  /// No description provided for @myCampaigns.
  ///
  /// In en, this message translates to:
  /// **'My Campaigns'**
  String get myCampaigns;

  /// No description provided for @createCampaign.
  ///
  /// In en, this message translates to:
  /// **'Create Campaign'**
  String get createCampaign;

  /// No description provided for @createDispute.
  ///
  /// In en, this message translates to:
  /// **'Create Dispute'**
  String get createDispute;

  /// No description provided for @disputeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please provide clear details about the dispute'**
  String get disputeInstruction;

  /// No description provided for @disputeTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Dispute title'**
  String get disputeTitleHint;

  /// No description provided for @disputeDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Please explain the issue in detail'**
  String get disputeDescriptionHint;

  /// No description provided for @evidenceAttachments.
  ///
  /// In en, this message translates to:
  /// **'Evidence Attachments'**
  String get evidenceAttachments;

  /// No description provided for @uploadEvidenceHint.
  ///
  /// In en, this message translates to:
  /// **'Upload images, documents or screenshots (coming soon)'**
  String get uploadEvidenceHint;

  /// No description provided for @importantNotes.
  ///
  /// In en, this message translates to:
  /// **'Important Notes'**
  String get importantNotes;

  /// No description provided for @submitDispute.
  ///
  /// In en, this message translates to:
  /// **'Submit Dispute'**
  String get submitDispute;

  /// No description provided for @disputeSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dispute submitted successfully. It will be reviewed by admin.'**
  String get disputeSubmittedSuccess;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter dispute title'**
  String get titleRequired;

  /// No description provided for @titleTooShort.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 5 characters'**
  String get titleTooShort;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter dispute description'**
  String get descriptionRequired;

  /// No description provided for @descriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 20 characters'**
  String get descriptionTooShort;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please try again'**
  String get connectionError;

  /// No description provided for @disputeNote1.
  ///
  /// In en, this message translates to:
  /// **'Dispute will be reviewed by admin team'**
  String get disputeNote1;

  /// No description provided for @disputeNote2.
  ///
  /// In en, this message translates to:
  /// **'Please provide clear and reliable evidence'**
  String get disputeNote2;

  /// No description provided for @disputeNote3.
  ///
  /// In en, this message translates to:
  /// **'Dispute resolution may take several days'**
  String get disputeNote3;

  /// No description provided for @disputeNote4.
  ///
  /// In en, this message translates to:
  /// **'All parties will be notified of final decision'**
  String get disputeNote4;

  /// No description provided for @disputeDetails.
  ///
  /// In en, this message translates to:
  /// **'Dispute Details'**
  String get disputeDetails;

  /// No description provided for @disputeInfo.
  ///
  /// In en, this message translates to:
  /// **'Dispute Information'**
  String get disputeInfo;

  /// No description provided for @disputeId.
  ///
  /// In en, this message translates to:
  /// **'Dispute ID'**
  String get disputeId;

  /// No description provided for @disputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get disputeTitle;

  /// No description provided for @disputeDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get disputeDescription;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @disputeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Dispute not found'**
  String get disputeNotFound;

  /// No description provided for @errorLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading details'**
  String get errorLoadingDetails;

  /// No description provided for @contractInfo.
  ///
  /// In en, this message translates to:
  /// **'Contract Information'**
  String get contractInfo;

  /// No description provided for @contractId.
  ///
  /// In en, this message translates to:
  /// **'Contract ID'**
  String get contractId;

  /// No description provided for @viewContractDetails.
  ///
  /// In en, this message translates to:
  /// **'View Contract Details'**
  String get viewContractDetails;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @evidenceFiles.
  ///
  /// In en, this message translates to:
  /// **'Evidence Files'**
  String get evidenceFiles;

  /// No description provided for @disputeStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get disputeStatusPending;

  /// No description provided for @disputeStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get disputeStatusUnderReview;

  /// No description provided for @disputeStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get disputeStatusResolved;

  /// No description provided for @disputeStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get disputeStatusRejected;

  /// No description provided for @disputeStatusPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Dispute is pending admin review'**
  String get disputeStatusPendingDesc;

  /// No description provided for @disputeStatusUnderReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Dispute is under review and investigation'**
  String get disputeStatusUnderReviewDesc;

  /// No description provided for @disputeStatusResolvedDesc.
  ///
  /// In en, this message translates to:
  /// **'Dispute has been resolved with appropriate decision'**
  String get disputeStatusResolvedDesc;

  /// No description provided for @disputeStatusRejectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Dispute has been rejected after review'**
  String get disputeStatusRejectedDesc;

  /// No description provided for @disputeResolved.
  ///
  /// In en, this message translates to:
  /// **'Dispute resolved'**
  String get disputeResolved;

  /// No description provided for @disputeRejected.
  ///
  /// In en, this message translates to:
  /// **'Dispute Rejected'**
  String get disputeRejected;

  /// No description provided for @refundAmount.
  ///
  /// In en, this message translates to:
  /// **'Refund Amount'**
  String get refundAmount;

  /// No description provided for @myDisputes.
  ///
  /// In en, this message translates to:
  /// **'My Disputes'**
  String get myDisputes;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// No description provided for @allDisputes.
  ///
  /// In en, this message translates to:
  /// **'All Disputes'**
  String get allDisputes;

  /// No description provided for @noDisputes.
  ///
  /// In en, this message translates to:
  /// **'No disputes found'**
  String get noDisputes;

  /// No description provided for @noDisputesDesc.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t raised any disputes yet'**
  String get noDisputesDesc;

  /// No description provided for @errorLoadingDisputes.
  ///
  /// In en, this message translates to:
  /// **'Error loading disputes'**
  String get errorLoadingDisputes;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @searchByNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get searchByNameOrEmail;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allUsers;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @usersCount.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get usersCount;

  /// No description provided for @usersCount_plural.
  ///
  /// In en, this message translates to:
  /// **'users'**
  String get usersCount_plural;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filter'**
  String get tryAdjustingFilters;

  /// No description provided for @createNewUser.
  ///
  /// In en, this message translates to:
  /// **'Create new user'**
  String get createNewUser;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @nationalIdOptional.
  ///
  /// In en, this message translates to:
  /// **'National ID (optional)'**
  String get nationalIdOptional;

  /// No description provided for @clientTypeOptional.
  ///
  /// In en, this message translates to:
  /// **'Client Type (optional)'**
  String get clientTypeOptional;

  /// No description provided for @companyNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Company Name (optional)'**
  String get companyNameOptional;

  /// No description provided for @commercialRegisterOptional.
  ///
  /// In en, this message translates to:
  /// **'Commercial Register Number (optional)'**
  String get commercialRegisterOptional;

  /// No description provided for @taxNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Tax Number (optional)'**
  String get taxNumberOptional;

  /// No description provided for @hourlyRateOptional.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (optional)'**
  String get hourlyRateOptional;

  /// No description provided for @skillsOptional.
  ///
  /// In en, this message translates to:
  /// **'Skills (optional, comma separated)'**
  String get skillsOptional;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @userCreated.
  ///
  /// In en, this message translates to:
  /// **'✅ User created. Password sent by email.'**
  String get userCreated;

  /// No description provided for @failedToCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to create user'**
  String get failedToCreateUser;

  /// No description provided for @userActivated.
  ///
  /// In en, this message translates to:
  /// **'✅ User activated successfully'**
  String get userActivated;

  /// No description provided for @userSuspended.
  ///
  /// In en, this message translates to:
  /// **'✅ User suspended successfully'**
  String get userSuspended;

  /// No description provided for @userVerified.
  ///
  /// In en, this message translates to:
  /// **'✅ User verified successfully'**
  String get userVerified;

  /// No description provided for @verificationRemoved.
  ///
  /// In en, this message translates to:
  /// **'✅ Verification removed'**
  String get verificationRemoved;

  /// No description provided for @accountEmailResent.
  ///
  /// In en, this message translates to:
  /// **'✅ Account email resent successfully'**
  String get accountEmailResent;

  /// No description provided for @failedToResendEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend email'**
  String get failedToResendEmail;

  /// No description provided for @resendAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Account Email'**
  String get resendAccountEmail;

  /// No description provided for @verifyUser.
  ///
  /// In en, this message translates to:
  /// **'Verify User'**
  String get verifyUser;

  /// No description provided for @removeVerification.
  ///
  /// In en, this message translates to:
  /// **'Remove Verification'**
  String get removeVerification;

  /// No description provided for @suspendUser.
  ///
  /// In en, this message translates to:
  /// **'Suspend User'**
  String get suspendUser;

  /// No description provided for @activateUser.
  ///
  /// In en, this message translates to:
  /// **'Activate User'**
  String get activateUser;

  /// No description provided for @userDetails.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get userDetails;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @ofWord.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofWord;

  /// No description provided for @monthlyRecurring.
  ///
  /// In en, this message translates to:
  /// **'Monthly Recurring Revenue'**
  String get monthlyRecurring;

  /// No description provided for @yearlyRecurring.
  ///
  /// In en, this message translates to:
  /// **'Yearly Recurring Revenue'**
  String get yearlyRecurring;

  /// No description provided for @subscriptionMetrics.
  ///
  /// In en, this message translates to:
  /// **'Subscription Metrics'**
  String get subscriptionMetrics;

  /// No description provided for @trialing.
  ///
  /// In en, this message translates to:
  /// **'Trialing'**
  String get trialing;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get canceled;

  /// No description provided for @upgradeRate.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Rate'**
  String get upgradeRate;

  /// No description provided for @churnRate.
  ///
  /// In en, this message translates to:
  /// **'Churn Rate'**
  String get churnRate;

  /// No description provided for @mostPopularPlan.
  ///
  /// In en, this message translates to:
  /// **'Most Popular Plan'**
  String get mostPopularPlan;

  /// No description provided for @revenueByPlan.
  ///
  /// In en, this message translates to:
  /// **'Revenue by Plan'**
  String get revenueByPlan;

  /// No description provided for @failedToLoadStats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics'**
  String get failedToLoadStats;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @mrr.
  ///
  /// In en, this message translates to:
  /// **'MRR'**
  String get mrr;

  /// No description provided for @mostSubscribedPlan.
  ///
  /// In en, this message translates to:
  /// **'Most subscribed plan'**
  String get mostSubscribedPlan;

  /// No description provided for @subs.
  ///
  /// In en, this message translates to:
  /// **'subs'**
  String get subs;

  /// No description provided for @subs_plural.
  ///
  /// In en, this message translates to:
  /// **'subs'**
  String get subs_plural;

  /// No description provided for @subscriptionManagement.
  ///
  /// In en, this message translates to:
  /// **'Subscription Management'**
  String get subscriptionManagement;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// No description provided for @coupons.
  ///
  /// In en, this message translates to:
  /// **'coupons'**
  String get coupons;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Admin Settings'**
  String get adminSettings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @platformControls.
  ///
  /// In en, this message translates to:
  /// **'Platform Controls'**
  String get platformControls;

  /// No description provided for @maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get maintenanceMode;

  /// No description provided for @maintenanceModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Temporarily disable user access to the platform'**
  String get maintenanceModeDesc;

  /// No description provided for @allowNewRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Allow New Registrations'**
  String get allowNewRegistrations;

  /// No description provided for @allowNewRegistrationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable signup for new users on the platform'**
  String get allowNewRegistrationsDesc;

  /// No description provided for @defaultConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Default Configuration'**
  String get defaultConfiguration;

  /// No description provided for @defaultClientPlan.
  ///
  /// In en, this message translates to:
  /// **'Default Client Plan'**
  String get defaultClientPlan;

  /// No description provided for @defaultFreelancerVisibility.
  ///
  /// In en, this message translates to:
  /// **'Default Freelancer Visibility'**
  String get defaultFreelancerVisibility;

  /// No description provided for @platformCommissionRate.
  ///
  /// In en, this message translates to:
  /// **'Platform Commission Rate'**
  String get platformCommissionRate;

  /// No description provided for @platformTheme.
  ///
  /// In en, this message translates to:
  /// **'Platform Theme'**
  String get platformTheme;

  /// No description provided for @defaultTheme.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultTheme;

  /// No description provided for @logoBranding.
  ///
  /// In en, this message translates to:
  /// **'Logo & Branding'**
  String get logoBranding;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @autoVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Auto Verify Email Domains'**
  String get autoVerifyEmail;

  /// No description provided for @autoVerifyEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically verify trusted business email domains'**
  String get autoVerifyEmailDesc;

  /// No description provided for @flagHighRiskPayments.
  ///
  /// In en, this message translates to:
  /// **'Flag High-Risk Payments'**
  String get flagHighRiskPayments;

  /// No description provided for @flagHighRiskPaymentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Detect and mark suspicious payment activity'**
  String get flagHighRiskPaymentsDesc;

  /// No description provided for @accessRules.
  ///
  /// In en, this message translates to:
  /// **'Access Rules'**
  String get accessRules;

  /// No description provided for @adminSessionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Admin Session Timeout'**
  String get adminSessionTimeout;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'2FA Requirement'**
  String get twoFactorAuth;

  /// No description provided for @requiredForAdmins.
  ///
  /// In en, this message translates to:
  /// **'Required for admins'**
  String get requiredForAdmins;

  /// No description provided for @ipWhitelist.
  ///
  /// In en, this message translates to:
  /// **'IP Whitelist'**
  String get ipWhitelist;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @securityStatusGood.
  ///
  /// In en, this message translates to:
  /// **'Security Status: Good'**
  String get securityStatusGood;

  /// No description provided for @securityStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'All critical security features are configured properly'**
  String get securityStatusDesc;

  /// No description provided for @adminAlerts.
  ///
  /// In en, this message translates to:
  /// **'Admin Alerts'**
  String get adminAlerts;

  /// No description provided for @weeklyPerformanceReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Performance Report'**
  String get weeklyPerformanceReport;

  /// No description provided for @weeklyPerformanceReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive a comprehensive summary every Monday morning'**
  String get weeklyPerformanceReportDesc;

  /// No description provided for @criticalIncidentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Critical Incident Alerts'**
  String get criticalIncidentAlerts;

  /// No description provided for @emailInApp.
  ///
  /// In en, this message translates to:
  /// **'Email + in-app'**
  String get emailInApp;

  /// No description provided for @disputeEscalationAlerts.
  ///
  /// In en, this message translates to:
  /// **'Dispute Escalation Alerts'**
  String get disputeEscalationAlerts;

  /// No description provided for @instantPush.
  ///
  /// In en, this message translates to:
  /// **'Instant push'**
  String get instantPush;

  /// No description provided for @newUserRegistrations.
  ///
  /// In en, this message translates to:
  /// **'New User Registrations'**
  String get newUserRegistrations;

  /// No description provided for @dailyDigest.
  ///
  /// In en, this message translates to:
  /// **'Daily digest'**
  String get dailyDigest;

  /// No description provided for @emailConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Email Configuration'**
  String get emailConfiguration;

  /// No description provided for @smtpSettings.
  ///
  /// In en, this message translates to:
  /// **'SMTP Settings'**
  String get smtpSettings;

  /// No description provided for @emailTemplates.
  ///
  /// In en, this message translates to:
  /// **'Email Templates'**
  String get emailTemplates;

  /// No description provided for @templates_plural.
  ///
  /// In en, this message translates to:
  /// **'templates'**
  String get templates_plural;

  /// No description provided for @senderNameAddress.
  ///
  /// In en, this message translates to:
  /// **'Sender Name & Address'**
  String get senderNameAddress;

  /// No description provided for @platformAdmin.
  ///
  /// In en, this message translates to:
  /// **'Platform Admin'**
  String get platformAdmin;

  /// No description provided for @projectsManagement.
  ///
  /// In en, this message translates to:
  /// **'Projects Management'**
  String get projectsManagement;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @projects_plural.
  ///
  /// In en, this message translates to:
  /// **'projects'**
  String get projects_plural;

  /// No description provided for @projectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Project deleted'**
  String get projectDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @failedToLoadProjects.
  ///
  /// In en, this message translates to:
  /// **'Failed to load projects'**
  String get failedToLoadProjects;

  /// No description provided for @plansConfigured.
  ///
  /// In en, this message translates to:
  /// **'plan configured'**
  String get plansConfigured;

  /// No description provided for @plansConfigured_plural.
  ///
  /// In en, this message translates to:
  /// **'plans configured'**
  String get plansConfigured_plural;

  /// No description provided for @newPlan.
  ///
  /// In en, this message translates to:
  /// **'New Plan'**
  String get newPlan;

  /// No description provided for @deletePlan.
  ///
  /// In en, this message translates to:
  /// **'Delete Plan'**
  String get deletePlan;

  /// No description provided for @deletePlanConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String deletePlanConfirmation(Object name);

  /// No description provided for @planDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plan deleted successfully'**
  String get planDeletedSuccess;

  /// No description provided for @failedToDeletePlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete plan'**
  String get failedToDeletePlan;

  /// No description provided for @failedToLoadPlans.
  ///
  /// In en, this message translates to:
  /// **'Failed to load plans'**
  String get failedToLoadPlans;

  /// No description provided for @noPlansConfigured.
  ///
  /// In en, this message translates to:
  /// **'No plans configured'**
  String get noPlansConfigured;

  /// No description provided for @addFirstPlan.
  ///
  /// In en, this message translates to:
  /// **'Add First Plan'**
  String get addFirstPlan;

  /// No description provided for @editPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit Plan'**
  String get editPlan;

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'Save Plan'**
  String get savePlan;

  /// No description provided for @planName.
  ///
  /// In en, this message translates to:
  /// **'Plan Name *'**
  String get planName;

  /// No description provided for @slugExample.
  ///
  /// In en, this message translates to:
  /// **'Slug * (e.g. pro)'**
  String get slugExample;

  /// No description provided for @billingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Billing Period'**
  String get billingPeriod;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @proposalLimitEmpty.
  ///
  /// In en, this message translates to:
  /// **'Proposal Limit (empty=∞)'**
  String get proposalLimitEmpty;

  /// No description provided for @projectLimitEmpty.
  ///
  /// In en, this message translates to:
  /// **'Project Limit (empty=∞)'**
  String get projectLimitEmpty;

  /// No description provided for @trialDays.
  ///
  /// In en, this message translates to:
  /// **'Trial Days'**
  String get trialDays;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @customFeatures.
  ///
  /// In en, this message translates to:
  /// **'Custom Features'**
  String get customFeatures;

  /// No description provided for @addFeature.
  ///
  /// In en, this message translates to:
  /// **'Add feature...'**
  String get addFeature;

  /// No description provided for @planCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plan created successfully'**
  String get planCreatedSuccess;

  /// No description provided for @planUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plan updated successfully'**
  String get planUpdatedSuccess;

  /// No description provided for @failedToSavePlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to save plan'**
  String get failedToSavePlan;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @trial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trial;

  /// No description provided for @proposals_plural.
  ///
  /// In en, this message translates to:
  /// **'proposals'**
  String get proposals_plural;

  /// No description provided for @customBranding.
  ///
  /// In en, this message translates to:
  /// **'Custom branding'**
  String get customBranding;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get prioritySupport;

  /// No description provided for @apiAccess.
  ///
  /// In en, this message translates to:
  /// **'API access'**
  String get apiAccess;

  /// No description provided for @disputesManagement.
  ///
  /// In en, this message translates to:
  /// **'Disputes Management'**
  String get disputesManagement;

  /// No description provided for @resolveDispute.
  ///
  /// In en, this message translates to:
  /// **'Resolve Dispute'**
  String get resolveDispute;

  /// No description provided for @rejectDispute.
  ///
  /// In en, this message translates to:
  /// **'Reject Dispute'**
  String get rejectDispute;

  /// No description provided for @rejectDisputeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this dispute?'**
  String get rejectDisputeConfirmation;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get rejectionReason;

  /// No description provided for @disputeStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get disputeStatusOpen;

  /// No description provided for @disputeResolvedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dispute resolved successfully'**
  String get disputeResolvedSuccess;

  /// No description provided for @failedToResolveDispute.
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve dispute'**
  String get failedToResolveDispute;

  /// No description provided for @disputeRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dispute rejected successfully'**
  String get disputeRejectedSuccess;

  /// No description provided for @failedToRejectDispute.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject dispute'**
  String get failedToRejectDispute;

  /// No description provided for @initiatedBy.
  ///
  /// In en, this message translates to:
  /// **'Initiated by'**
  String get initiatedBy;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @fullRefundToClient.
  ///
  /// In en, this message translates to:
  /// **'Full Refund to Client'**
  String get fullRefundToClient;

  /// No description provided for @partialRefundToClient.
  ///
  /// In en, this message translates to:
  /// **'Partial Refund to Client'**
  String get partialRefundToClient;

  /// No description provided for @noRefund.
  ///
  /// In en, this message translates to:
  /// **'No Refund'**
  String get noRefund;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @adminNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Admin Notes (optional)'**
  String get adminNotesOptional;

  /// No description provided for @noDisputesFound.
  ///
  /// In en, this message translates to:
  /// **'No disputes found'**
  String get noDisputesFound;

  /// No description provided for @adminNotes.
  ///
  /// In en, this message translates to:
  /// **'Admin Notes'**
  String get adminNotes;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @newCoupon.
  ///
  /// In en, this message translates to:
  /// **'New Coupon'**
  String get newCoupon;

  /// No description provided for @deleteCoupon.
  ///
  /// In en, this message translates to:
  /// **'Delete Coupon'**
  String get deleteCoupon;

  /// No description provided for @deleteCouponConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete coupon \"{code}\"?'**
  String deleteCouponConfirmation(Object code);

  /// No description provided for @couponDeleted.
  ///
  /// In en, this message translates to:
  /// **'Coupon deleted'**
  String get couponDeleted;

  /// No description provided for @failedToDeleteCoupon.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete coupon'**
  String get failedToDeleteCoupon;

  /// No description provided for @failedToLoadCoupons.
  ///
  /// In en, this message translates to:
  /// **'Failed to load coupons'**
  String get failedToLoadCoupons;

  /// No description provided for @noCouponsYet.
  ///
  /// In en, this message translates to:
  /// **'No coupons yet'**
  String get noCouponsYet;

  /// No description provided for @createFirstCoupon.
  ///
  /// In en, this message translates to:
  /// **'Create First Coupon'**
  String get createFirstCoupon;

  /// No description provided for @editCoupon.
  ///
  /// In en, this message translates to:
  /// **'Edit Coupon'**
  String get editCoupon;

  /// No description provided for @saveCoupon.
  ///
  /// In en, this message translates to:
  /// **'Save Coupon'**
  String get saveCoupon;

  /// No description provided for @couponCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code *'**
  String get couponCodeRequired;

  /// No description provided for @discountType.
  ///
  /// In en, this message translates to:
  /// **'Discount Type'**
  String get discountType;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @fixedAmount.
  ///
  /// In en, this message translates to:
  /// **'Fixed Amount'**
  String get fixedAmount;

  /// No description provided for @appliesTo.
  ///
  /// In en, this message translates to:
  /// **'Applies To'**
  String get appliesTo;

  /// No description provided for @subscriptionOnly.
  ///
  /// In en, this message translates to:
  /// **'Subscription only'**
  String get subscriptionOnly;

  /// No description provided for @contractEscrow.
  ///
  /// In en, this message translates to:
  /// **'Contract escrow'**
  String get contractEscrow;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get both;

  /// No description provided for @validFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid From'**
  String get validFrom;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid Until'**
  String get validUntil;

  /// No description provided for @maxUsesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Max Uses (empty = unlimited)'**
  String get maxUsesEmpty;

  /// No description provided for @applicablePlansOptional.
  ///
  /// In en, this message translates to:
  /// **'Applicable Plans (optional)'**
  String get applicablePlansOptional;

  /// No description provided for @planSlugExample.
  ///
  /// In en, this message translates to:
  /// **'Plan slug (e.g. pro)'**
  String get planSlugExample;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get used;

  /// No description provided for @percentageDiscount.
  ///
  /// In en, this message translates to:
  /// **'Percentage discount'**
  String get percentageDiscount;

  /// No description provided for @fixedAmountOff.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount off'**
  String get fixedAmountOff;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @couponCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Coupon created successfully'**
  String get couponCreatedSuccess;

  /// No description provided for @couponUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Coupon updated successfully'**
  String get couponUpdatedSuccess;

  /// No description provided for @failedToSaveCoupon.
  ///
  /// In en, this message translates to:
  /// **'Failed to save coupon'**
  String get failedToSaveCoupon;

  /// No description provided for @contractsManagement.
  ///
  /// In en, this message translates to:
  /// **'Contracts Management'**
  String get contractsManagement;

  /// No description provided for @pendingClient.
  ///
  /// In en, this message translates to:
  /// **'Pending Client'**
  String get pendingClient;

  /// No description provided for @pendingFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Pending Freelancer'**
  String get pendingFreelancer;

  /// No description provided for @disputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get disputed;

  /// No description provided for @failedToLoadContracts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contracts'**
  String get failedToLoadContracts;

  /// No description provided for @resolutionNotes.
  ///
  /// In en, this message translates to:
  /// **'Resolution notes'**
  String get resolutionNotes;

  /// No description provided for @resolutionHint.
  ///
  /// In en, this message translates to:
  /// **'Write your resolution details here...'**
  String get resolutionHint;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get actionFailed;

  /// No description provided for @noContractsFound.
  ///
  /// In en, this message translates to:
  /// **'No contracts found'**
  String get noContractsFound;

  /// No description provided for @errorLoadingCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Error loading campaigns'**
  String get errorLoadingCampaigns;

  /// No description provided for @adRevenueStats.
  ///
  /// In en, this message translates to:
  /// **'Ad Revenue Stats'**
  String get adRevenueStats;

  /// No description provided for @totalAdRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Ad Revenue'**
  String get totalAdRevenue;

  /// No description provided for @totalAdSpend.
  ///
  /// In en, this message translates to:
  /// **'Total Ad Spend'**
  String get totalAdSpend;

  /// No description provided for @recentCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Recent Campaigns'**
  String get recentCampaigns;

  /// No description provided for @noCampaignsYet.
  ///
  /// In en, this message translates to:
  /// **'No campaigns yet'**
  String get noCampaignsYet;

  /// No description provided for @failedToChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to change status'**
  String get failedToChangeStatus;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete campaign'**
  String get failedToDelete;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @deleteCampaign.
  ///
  /// In en, this message translates to:
  /// **'Delete Campaign'**
  String get deleteCampaign;

  /// No description provided for @editCampaign.
  ///
  /// In en, this message translates to:
  /// **'Edit Campaign'**
  String get editCampaign;

  /// No description provided for @campaignName.
  ///
  /// In en, this message translates to:
  /// **'Campaign Name'**
  String get campaignName;

  /// No description provided for @totalBudget.
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get totalBudget;

  /// No description provided for @dailyBudget.
  ///
  /// In en, this message translates to:
  /// **'Daily Budget'**
  String get dailyBudget;

  /// No description provided for @costPerClick.
  ///
  /// In en, this message translates to:
  /// **'Cost per Click'**
  String get costPerClick;

  /// No description provided for @costPerImpression.
  ///
  /// In en, this message translates to:
  /// **'Cost Per Impression'**
  String get costPerImpression;

  /// No description provided for @campaignUpdated.
  ///
  /// In en, this message translates to:
  /// **'Campaign updated successfully'**
  String get campaignUpdated;

  /// No description provided for @campaignDeleted.
  ///
  /// In en, this message translates to:
  /// **'Campaign deleted successfully'**
  String get campaignDeleted;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

  /// No description provided for @adsManagement.
  ///
  /// In en, this message translates to:
  /// **'Ads Management'**
  String get adsManagement;

  /// No description provided for @campaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get campaigns;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApproval;

  /// No description provided for @searchCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Search campaigns...'**
  String get searchCampaigns;

  /// No description provided for @activeCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeCampaigns;

  /// No description provided for @noCampaignsFound.
  ///
  /// In en, this message translates to:
  /// **'No campaigns found'**
  String get noCampaignsFound;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @platformCommission.
  ///
  /// In en, this message translates to:
  /// **'Platform Commission'**
  String get platformCommission;

  /// No description provided for @activeCampaignsCount.
  ///
  /// In en, this message translates to:
  /// **'Active Campaigns'**
  String get activeCampaignsCount;

  /// No description provided for @ctrAverage.
  ///
  /// In en, this message translates to:
  /// **'Average CTR'**
  String get ctrAverage;

  /// No description provided for @keyPerformanceIndicators.
  ///
  /// In en, this message translates to:
  /// **'Key Performance Indicators'**
  String get keyPerformanceIndicators;

  /// No description provided for @dailyPerformanceTrends.
  ///
  /// In en, this message translates to:
  /// **'Daily Performance Trends'**
  String get dailyPerformanceTrends;

  /// No description provided for @performanceByAdType.
  ///
  /// In en, this message translates to:
  /// **'Performance by Ad Type'**
  String get performanceByAdType;

  /// No description provided for @topAdvertisers.
  ///
  /// In en, this message translates to:
  /// **'Top Advertisers'**
  String get topAdvertisers;

  /// No description provided for @additionalMetrics.
  ///
  /// In en, this message translates to:
  /// **'Additional Metrics'**
  String get additionalMetrics;

  /// No description provided for @avgCtr.
  ///
  /// In en, this message translates to:
  /// **'Avg CTR'**
  String get avgCtr;

  /// No description provided for @estRoi.
  ///
  /// In en, this message translates to:
  /// **'Est. ROI'**
  String get estRoi;

  /// No description provided for @conversionRate.
  ///
  /// In en, this message translates to:
  /// **'Conversion Rate'**
  String get conversionRate;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @impressions.
  ///
  /// In en, this message translates to:
  /// **'Impressions'**
  String get impressions;

  /// No description provided for @clicks.
  ///
  /// In en, this message translates to:
  /// **'Clicks'**
  String get clicks;

  /// No description provided for @ctr.
  ///
  /// In en, this message translates to:
  /// **'CTR'**
  String get ctr;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @advertiser.
  ///
  /// In en, this message translates to:
  /// **'Advertiser'**
  String get advertiser;

  /// No description provided for @campaignsCount.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get campaignsCount;

  /// No description provided for @totalSpentCap.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpentCap;

  /// No description provided for @commission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commission;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @campaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get campaign;

  /// No description provided for @totalCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Total Campaigns'**
  String get totalCampaigns;

  /// No description provided for @pausedCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Paused Campaigns'**
  String get pausedCampaigns;

  /// No description provided for @completedCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Completed Campaigns'**
  String get completedCampaigns;

  /// No description provided for @draftCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Draft Campaigns'**
  String get draftCampaigns;

  /// No description provided for @totalImpressions.
  ///
  /// In en, this message translates to:
  /// **'Total Impressions'**
  String get totalImpressions;

  /// No description provided for @totalClicks.
  ///
  /// In en, this message translates to:
  /// **'Total Clicks'**
  String get totalClicks;

  /// No description provided for @clickThroughRate.
  ///
  /// In en, this message translates to:
  /// **'Click-Through Rate'**
  String get clickThroughRate;

  /// No description provided for @totalSpend.
  ///
  /// In en, this message translates to:
  /// **'Total Spend'**
  String get totalSpend;

  /// No description provided for @totalBudgetSum.
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get totalBudgetSum;

  /// No description provided for @campaignsWaitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'campaigns waiting for payment'**
  String get campaignsWaitingForPayment;

  /// Status changed message
  ///
  /// In en, this message translates to:
  /// **'Status changed to {status}'**
  String statusChangedTo(String status);

  /// Delete campaign confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{campaignName}\"? This action cannot be undone.'**
  String deleteCampaignConfirmation(String campaignName);

  /// No description provided for @errorLoadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Users'**
  String get errorLoadingUsers;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @freelancers.
  ///
  /// In en, this message translates to:
  /// **'Freelancers'**
  String get freelancers;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @totalContracts.
  ///
  /// In en, this message translates to:
  /// **'Total Contracts'**
  String get totalContracts;

  /// No description provided for @adRevenue.
  ///
  /// In en, this message translates to:
  /// **'Ad Revenue'**
  String get adRevenue;

  /// No description provided for @pendingProjects.
  ///
  /// In en, this message translates to:
  /// **'Pending Projects'**
  String get pendingProjects;

  /// No description provided for @activeContracts.
  ///
  /// In en, this message translates to:
  /// **'Active Contracts'**
  String get activeContracts;

  /// No description provided for @completedContracts.
  ///
  /// In en, this message translates to:
  /// **'Completed Contracts'**
  String get completedContracts;

  /// No description provided for @pendingDisputes.
  ///
  /// In en, this message translates to:
  /// **'Pending Disputes'**
  String get pendingDisputes;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdmin;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @heresWhatsHappening.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what\'s happening on your platform today'**
  String get heresWhatsHappening;

  /// No description provided for @userGrowthAnalytics.
  ///
  /// In en, this message translates to:
  /// **'User Growth Analytics'**
  String get userGrowthAnalytics;

  /// No description provided for @totalUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsersLabel;

  /// No description provided for @userDistribution.
  ///
  /// In en, this message translates to:
  /// **'User Distribution'**
  String get userDistribution;

  /// No description provided for @balancedMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Balanced marketplace with {total} total accounts'**
  String balancedMarketplace(Object total);

  /// No description provided for @operationalPerformance.
  ///
  /// In en, this message translates to:
  /// **'Operational Performance'**
  String get operationalPerformance;

  /// No description provided for @lastMonthUsers.
  ///
  /// In en, this message translates to:
  /// **'Last Month Users'**
  String get lastMonthUsers;

  /// No description provided for @lastMonthRevenue.
  ///
  /// In en, this message translates to:
  /// **'Last Month Revenue'**
  String get lastMonthRevenue;

  /// No description provided for @healthScore.
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get healthScore;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get loadingDashboard;

  /// No description provided for @noChartDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No chart data available'**
  String get noChartDataAvailable;

  /// No description provided for @failedToLoadDashboardData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard data'**
  String get failedToLoadDashboardData;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @totalUsersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} user'**
  String totalUsersCount(Object count);

  /// No description provided for @totalUsersCount_plural.
  ///
  /// In en, this message translates to:
  /// **'{count} users'**
  String totalUsersCount_plural(Object count);

  /// No description provided for @activeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeCount(Object count);

  /// No description provided for @freelancersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} freelancer'**
  String freelancersCount(Object count);

  /// No description provided for @freelancersCount_plural.
  ///
  /// In en, this message translates to:
  /// **'{count} freelancers'**
  String freelancersCount_plural(Object count);

  /// No description provided for @clientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} client'**
  String clientsCount(Object count);

  /// No description provided for @clientsCount_plural.
  ///
  /// In en, this message translates to:
  /// **'{count} clients'**
  String clientsCount_plural(Object count);

  /// No description provided for @exportStarted.
  ///
  /// In en, this message translates to:
  /// **'Export started successfully'**
  String get exportStarted;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @searchContracts.
  ///
  /// In en, this message translates to:
  /// **'Search contracts...'**
  String get searchContracts;

  /// No description provided for @campaignsManagement.
  ///
  /// In en, this message translates to:
  /// **'campaigns Management'**
  String get campaignsManagement;

  /// No description provided for @usersManagement.
  ///
  /// In en, this message translates to:
  /// **'Users Management'**
  String get usersManagement;

  /// No description provided for @advancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get advancedFilters;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'more Options'**
  String get moreOptions;

  /// No description provided for @joinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined date'**
  String get joinedDate;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @raiseDispute.
  ///
  /// In en, this message translates to:
  /// **'Raise Dispute'**
  String get raiseDispute;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'LIMIT'**
  String get limitReached;

  /// No description provided for @projectLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum of {limit} active projects on your current plan.\n\nUpgrade your plan to create more projects or wait for existing projects to complete.'**
  String projectLimitMessage(Object limit);

  /// No description provided for @noContract.
  ///
  /// In en, this message translates to:
  /// **'No Contract'**
  String get noContract;

  /// No description provided for @createContractFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create a contract first before submitting work.'**
  String get createContractFirst;

  /// No description provided for @milestoneAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'This milestone has already been completed.'**
  String get milestoneAlreadyCompleted;

  /// No description provided for @workSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Work Submissions'**
  String get workSubmissions;

  /// No description provided for @viewAllSubmissions.
  ///
  /// In en, this message translates to:
  /// **'View All Submissions'**
  String get viewAllSubmissions;

  /// No description provided for @escrowSecuredForFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Escrow Secured'**
  String get escrowSecuredForFreelancer;

  /// No description provided for @waitingForClientPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Client Payment'**
  String get waitingForClientPayment;

  /// No description provided for @fundsAreProtected.
  ///
  /// In en, this message translates to:
  /// **'Funds are protected:'**
  String get fundsAreProtected;

  /// No description provided for @clientWillFundEscrowBeforeWork.
  ///
  /// In en, this message translates to:
  /// **'Client will fund escrow before work begins'**
  String get clientWillFundEscrowBeforeWork;

  /// No description provided for @errorSendingRevision.
  ///
  /// In en, this message translates to:
  /// **'Error sending revision request'**
  String get errorSendingRevision;

  /// No description provided for @cannotSubmitWorkEscrowNotFunded.
  ///
  /// In en, this message translates to:
  /// **'Cannot submit work before client funds the escrow'**
  String get cannotSubmitWorkEscrowNotFunded;

  /// No description provided for @waitingForClientPaymentBeforeWork.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client payment before starting work'**
  String get waitingForClientPaymentBeforeWork;

  /// No description provided for @submissionDetails.
  ///
  /// In en, this message translates to:
  /// **'Submission Details'**
  String get submissionDetails;

  /// No description provided for @noSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet'**
  String get noSubmissionsYet;

  /// No description provided for @waitingForFreelancerToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Waiting for freelancer to submit work'**
  String get waitingForFreelancerToSubmit;

  /// No description provided for @youHaventSubmittedAnyWorkYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t submitted any work yet'**
  String get youHaventSubmittedAnyWorkYet;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on'**
  String get submittedOn;

  /// No description provided for @untitledSubmission.
  ///
  /// In en, this message translates to:
  /// **'Untitled Submission'**
  String get untitledSubmission;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingReview;

  /// No description provided for @revisionFeedback.
  ///
  /// In en, this message translates to:
  /// **'Revision Feedback'**
  String get revisionFeedback;

  /// No description provided for @resubmitWork.
  ///
  /// In en, this message translates to:
  /// **'Resubmit Work'**
  String get resubmitWork;

  /// No description provided for @workApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Work approved successfully'**
  String get workApprovedSuccess;

  /// No description provided for @errorApprovingWork.
  ///
  /// In en, this message translates to:
  /// **'Error approving work'**
  String get errorApprovingWork;

  /// No description provided for @viewMySubmissions.
  ///
  /// In en, this message translates to:
  /// **'View My Submissions'**
  String get viewMySubmissions;

  /// No description provided for @tapToSeeAllReviews.
  ///
  /// In en, this message translates to:
  /// **'Tap to see all reviews'**
  String get tapToSeeAllReviews;

  /// No description provided for @proposalsRunningLow.
  ///
  /// In en, this message translates to:
  /// **'Proposals running low'**
  String get proposalsRunningLow;

  /// No description provided for @proposalsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Proposals per month'**
  String get proposalsPerMonth;

  /// No description provided for @proposalsLeftThisMonth.
  ///
  /// In en, this message translates to:
  /// **'proposals left this month.'**
  String get proposalsLeftThisMonth;

  /// No description provided for @activeProjectsFire.
  ///
  /// In en, this message translates to:
  /// **'Active Projects 🔥'**
  String get activeProjectsFire;

  /// No description provided for @pendingYourSignature.
  ///
  /// In en, this message translates to:
  /// **'Pending Your Signature'**
  String get pendingYourSignature;

  /// No description provided for @recentlyDeliveredProjects.
  ///
  /// In en, this message translates to:
  /// **'Recently Delivered Projects'**
  String get recentlyDeliveredProjects;

  /// No description provided for @individualSubscription.
  ///
  /// In en, this message translates to:
  /// **'Individual subscription'**
  String get individualSubscription;

  /// No description provided for @oneMonthFree.
  ///
  /// In en, this message translates to:
  /// **'1 month Premium free'**
  String get oneMonthFree;

  /// No description provided for @twoMonthsStudentDiscount.
  ///
  /// In en, this message translates to:
  /// **'2 months for students discount'**
  String get twoMonthsStudentDiscount;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime'**
  String get cancelAnytime;

  /// No description provided for @bestDealsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Best deals & offers monthly'**
  String get bestDealsMonthly;

  /// No description provided for @noSavedJobsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved jobs yet'**
  String get noSavedJobsYet;

  /// No description provided for @noAISuggestionsYet.
  ///
  /// In en, this message translates to:
  /// **'No AI suggestions yet'**
  String get noAISuggestionsYet;

  /// No description provided for @refreshSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Refresh suggestions'**
  String get refreshSuggestions;

  /// No description provided for @viewAllTests.
  ///
  /// In en, this message translates to:
  /// **'View All Tests'**
  String get viewAllTests;

  /// No description provided for @nothingOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get nothingOnThisDay;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get more;

  /// No description provided for @milestonesRemindersInterviews.
  ///
  /// In en, this message translates to:
  /// **'Milestones, reminders & interviews'**
  String get milestonesRemindersInterviews;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfile;

  /// No description provided for @shareProfileText.
  ///
  /// In en, this message translates to:
  /// **'Check out my profile: '**
  String get shareProfileText;

  /// No description provided for @loadingSubscription.
  ///
  /// In en, this message translates to:
  /// **'Loading your subscription...'**
  String get loadingSubscription;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @cancelSubscriptionConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel your subscription? You will continue to have access until the end of your billing period.'**
  String get cancelSubscriptionConfirmation;

  /// No description provided for @noKeepIt.
  ///
  /// In en, this message translates to:
  /// **'No, Keep It'**
  String get noKeepIt;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @subscriptionCanceledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subscription canceled successfully'**
  String get subscriptionCanceledSuccess;

  /// No description provided for @errorCanceling.
  ///
  /// In en, this message translates to:
  /// **'Error canceling'**
  String get errorCanceling;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No Active Subscription'**
  String get noActiveSubscription;

  /// No description provided for @freePlanMessage.
  ///
  /// In en, this message translates to:
  /// **'You are currently on the Free plan'**
  String get freePlanMessage;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get viewPlans;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'days remaining'**
  String get daysRemaining;

  /// No description provided for @billingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing Cycle'**
  String get billingCycle;

  /// No description provided for @usageOverview.
  ///
  /// In en, this message translates to:
  /// **'Usage Overview'**
  String get usageOverview;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @includedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Included Features'**
  String get includedFeatures;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @billingInformation.
  ///
  /// In en, this message translates to:
  /// **'Billing Information'**
  String get billingInformation;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'✨ Current Plan'**
  String get currentPlan;

  /// No description provided for @nextBillingDate.
  ///
  /// In en, this message translates to:
  /// **'Next Billing Date'**
  String get nextBillingDate;

  /// No description provided for @subscriptionEndNotice.
  ///
  /// In en, this message translates to:
  /// **'Your subscription will end on the next billing date.'**
  String get subscriptionEndNotice;

  /// No description provided for @readyForMore.
  ///
  /// In en, this message translates to:
  /// **'Ready for more?'**
  String get readyForMore;

  /// No description provided for @upgradeMessage.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock unlimited proposals, AI insights, and priority support!'**
  String get upgradeMessage;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to get'**
  String get upgradeToPro;

  /// No description provided for @businessPlanUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Business plan gives you unlimited proposals'**
  String get businessPlanUnlimited;

  /// No description provided for @yearlyBillingSave.
  ///
  /// In en, this message translates to:
  /// **'Save 20% with yearly billing'**
  String get yearlyBillingSave;

  /// No description provided for @contactSales.
  ///
  /// In en, this message translates to:
  /// **'Contact sales for custom enterprise plans'**
  String get contactSales;

  /// No description provided for @viewUpgradeOptions.
  ///
  /// In en, this message translates to:
  /// **'View Upgrade Options'**
  String get viewUpgradeOptions;

  /// No description provided for @noUsageData.
  ///
  /// In en, this message translates to:
  /// **'No usage data available yet'**
  String get noUsageData;

  /// No description provided for @noUsageDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start using the platform to see your statistics'**
  String get noUsageDataSubtitle;

  /// No description provided for @monthlyActivity.
  ///
  /// In en, this message translates to:
  /// **'Monthly Activity'**
  String get monthlyActivity;

  /// No description provided for @quickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// No description provided for @proposalsUsed.
  ///
  /// In en, this message translates to:
  /// **'Proposals Used'**
  String get proposalsUsed;

  /// No description provided for @activeProjectsUsed.
  ///
  /// In en, this message translates to:
  /// **'Active Projects Used'**
  String get activeProjectsUsed;

  /// No description provided for @remainingProposals.
  ///
  /// In en, this message translates to:
  /// **'Remaining Proposals'**
  String get remainingProposals;

  /// No description provided for @remainingProjects.
  ///
  /// In en, this message translates to:
  /// **'Remaining Projects'**
  String get remainingProjects;

  /// No description provided for @interviewsUsed.
  ///
  /// In en, this message translates to:
  /// **'Interviews Used'**
  String get interviewsUsed;

  /// No description provided for @interviewsLeft.
  ///
  /// In en, this message translates to:
  /// **'Interviews Left'**
  String get interviewsLeft;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get off;

  /// No description provided for @leftThisMonth.
  ///
  /// In en, this message translates to:
  /// **'left this month'**
  String get leftThisMonth;

  /// No description provided for @canStart.
  ///
  /// In en, this message translates to:
  /// **'can start'**
  String get canStart;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get thisMonth;

  /// No description provided for @basicFeatures.
  ///
  /// In en, this message translates to:
  /// **'Basic features'**
  String get basicFeatures;

  /// No description provided for @limitedProposals.
  ///
  /// In en, this message translates to:
  /// **'Limited proposals'**
  String get limitedProposals;

  /// No description provided for @oneActiveProject.
  ///
  /// In en, this message translates to:
  /// **'1 active project'**
  String get oneActiveProject;

  /// No description provided for @unlimitedProposals.
  ///
  /// In en, this message translates to:
  /// **'Unlimited proposals'**
  String get unlimitedProposals;

  /// No description provided for @tenActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'10 active projects'**
  String get tenActiveProjects;

  /// No description provided for @advancedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics'**
  String get advancedAnalytics;

  /// No description provided for @teamManagement.
  ///
  /// In en, this message translates to:
  /// **'Team management'**
  String get teamManagement;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @errorLoadingPlans.
  ///
  /// In en, this message translates to:
  /// **'Error loading plans'**
  String get errorLoadingPlans;

  /// No description provided for @couponAppliedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied!'**
  String get couponAppliedSuccess;

  /// No description provided for @offf.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get offf;

  /// No description provided for @invalidCoupon.
  ///
  /// In en, this message translates to:
  /// **'Invalid coupon'**
  String get invalidCoupon;

  /// No description provided for @errorValidatingCoupon.
  ///
  /// In en, this message translates to:
  /// **'Error validating coupon'**
  String get errorValidatingCoupon;

  /// No description provided for @alreadyOnFreePlan.
  ///
  /// In en, this message translates to:
  /// **'You are already on the Free plan'**
  String get alreadyOnFreePlan;

  /// No description provided for @couldNotLaunchCheckout.
  ///
  /// In en, this message translates to:
  /// **'Could not launch checkout URL'**
  String get couldNotLaunchCheckout;

  /// No description provided for @subscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Subscription failed'**
  String get subscriptionFailed;

  /// No description provided for @errorActivating.
  ///
  /// In en, this message translates to:
  /// **'Error activating'**
  String get errorActivating;

  /// No description provided for @yourPlanYourChoice.
  ///
  /// In en, this message translates to:
  /// **'✨ Your Plan, Your Choice ✨'**
  String get yourPlanYourChoice;

  /// No description provided for @chooseWhatFitsYou.
  ///
  /// In en, this message translates to:
  /// **'Choose what fits you best • Cancel anytime'**
  String get chooseWhatFitsYou;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get mostPopular;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'FREE PLAN'**
  String get freePlan;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// No description provided for @whatsIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s included:'**
  String get whatsIncluded;

  /// No description provided for @freeTrialMessage.
  ///
  /// In en, this message translates to:
  /// **'14-day free trial! Cancel anytime.'**
  String get freeTrialMessage;

  /// No description provided for @couponCodeHint.
  ///
  /// In en, this message translates to:
  /// **'🎟️ Coupon code'**
  String get couponCodeHint;

  /// No description provided for @couponAppliedLabel.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied:'**
  String get couponAppliedLabel;

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'🚀 Start Free Trial'**
  String get startFreeTrial;

  /// No description provided for @devActivateManually.
  ///
  /// In en, this message translates to:
  /// **'DEV: Activate Manually'**
  String get devActivateManually;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @comparePlans.
  ///
  /// In en, this message translates to:
  /// **'Compare Plans'**
  String get comparePlans;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @pleaseEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get pleaseEnterCurrentPassword;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your new password'**
  String get pleaseEnterNewPassword;

  /// No description provided for @pleaseConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get pleaseConfirmNewPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @errorChangingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error changing password'**
  String get errorChangingPassword;

  /// No description provided for @completePaymentInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Complete payment in the browser to activate your subscription.'**
  String get completePaymentInBrowser;

  /// No description provided for @failedToCreateCheckout.
  ///
  /// In en, this message translates to:
  /// **'Failed to create checkout session'**
  String get failedToCreateCheckout;

  /// No description provided for @noContractFound.
  ///
  /// In en, this message translates to:
  /// **'No contract found for this project'**
  String get noContractFound;

  /// No description provided for @viewActiveContract.
  ///
  /// In en, this message translates to:
  /// **'View Active Contract'**
  String get viewActiveContract;

  /// No description provided for @trackProgress.
  ///
  /// In en, this message translates to:
  /// **'Track Progress'**
  String get trackProgress;

  /// No description provided for @generateSOWToCreateContract.
  ///
  /// In en, this message translates to:
  /// **'Generate SOW to create contract'**
  String get generateSOWToCreateContract;

  /// No description provided for @contractWaitingSignature.
  ///
  /// In en, this message translates to:
  /// **'Contract waiting for signature'**
  String get contractWaitingSignature;

  /// No description provided for @pleaseGenerateSOWFirst.
  ///
  /// In en, this message translates to:
  /// **'Please generate SOW first'**
  String get pleaseGenerateSOWFirst;

  /// No description provided for @reviewAndSign.
  ///
  /// In en, this message translates to:
  /// **'Review and Sign'**
  String get reviewAndSign;

  /// No description provided for @askGenerateSOW.
  ///
  /// In en, this message translates to:
  /// **'Would you like to generate a professional SOW (Statement of Work) or proceed directly to the contract?'**
  String get askGenerateSOW;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @contractCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Contract created successfully!'**
  String get contractCreatedSuccess;

  /// No description provided for @errorAcceptingProposal.
  ///
  /// In en, this message translates to:
  /// **'Error accepting proposal'**
  String get errorAcceptingProposal;

  /// No description provided for @errorRejectingProposal.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting proposal'**
  String get errorRejectingProposal;

  /// No description provided for @freelancerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Freelancer not found'**
  String get freelancerNotFound;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'generate'**
  String get generate;

  /// No description provided for @proposalLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You cannot submit any more proposals this month. Upgrade your plan to send unlimited proposals.'**
  String get proposalLimitMessage;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @proposalLimitReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'You cannot submit any more proposals this month. Upgrade your plan to send unlimited proposals.'**
  String get proposalLimitReachedMessage;

  /// No description provided for @noActiveProjectForHiring.
  ///
  /// In en, this message translates to:
  /// **'No active project available for hiring. Please create a project first.'**
  String get noActiveProjectForHiring;

  /// No description provided for @cannotSendOffer.
  ///
  /// In en, this message translates to:
  /// **'Cannot send offer'**
  String get cannotSendOffer;

  /// No description provided for @projectNotOpenForOffers.
  ///
  /// In en, this message translates to:
  /// **'is not open for offers. Only projects with \'Open\' status can receive offers.'**
  String get projectNotOpenForOffers;

  /// No description provided for @createAdCampaign.
  ///
  /// In en, this message translates to:
  /// **'Create Ad Campaign'**
  String get createAdCampaign;

  /// No description provided for @campaignInfo.
  ///
  /// In en, this message translates to:
  /// **'Campaign Info'**
  String get campaignInfo;

  /// No description provided for @adContent.
  ///
  /// In en, this message translates to:
  /// **'Ad Content'**
  String get adContent;

  /// No description provided for @adSettings.
  ///
  /// In en, this message translates to:
  /// **'Ad Settings'**
  String get adSettings;

  /// No description provided for @cpcSettings.
  ///
  /// In en, this message translates to:
  /// **'CPC Settings'**
  String get cpcSettings;

  /// No description provided for @cpmSettings.
  ///
  /// In en, this message translates to:
  /// **'CPM Settings'**
  String get cpmSettings;

  /// No description provided for @budgetAndDates.
  ///
  /// In en, this message translates to:
  /// **'Budget & Dates'**
  String get budgetAndDates;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @targetUrl.
  ///
  /// In en, this message translates to:
  /// **'Target URL'**
  String get targetUrl;

  /// No description provided for @buttonText.
  ///
  /// In en, this message translates to:
  /// **'Button Text'**
  String get buttonText;

  /// No description provided for @adType.
  ///
  /// In en, this message translates to:
  /// **'Ad Type'**
  String get adType;

  /// No description provided for @placement.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get placement;

  /// No description provided for @pricingModel.
  ///
  /// In en, this message translates to:
  /// **'Pricing Model'**
  String get pricingModel;

  /// No description provided for @costPerThousand.
  ///
  /// In en, this message translates to:
  /// **'Cost per 1000 Impressions'**
  String get costPerThousand;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @paymentInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'After creating the campaign, you will need to complete payment to activate it.'**
  String get paymentInfoMessage;

  /// No description provided for @campaignCreated.
  ///
  /// In en, this message translates to:
  /// **'Campaign created! Go to payment to activate'**
  String get campaignCreated;

  /// No description provided for @failedToCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create campaign'**
  String get failedToCreate;

  /// No description provided for @selectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get selectStartDate;

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get selectEndDate;

  /// No description provided for @banner.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get banner;

  /// No description provided for @sidebar.
  ///
  /// In en, this message translates to:
  /// **'Sidebar'**
  String get sidebar;

  /// No description provided for @popup.
  ///
  /// In en, this message translates to:
  /// **'Popup'**
  String get popup;

  /// No description provided for @native.
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get native;

  /// No description provided for @homeTop.
  ///
  /// In en, this message translates to:
  /// **'Home Top'**
  String get homeTop;

  /// No description provided for @homeBottom.
  ///
  /// In en, this message translates to:
  /// **'Home Bottom'**
  String get homeBottom;

  /// No description provided for @sidebarTop.
  ///
  /// In en, this message translates to:
  /// **'Sidebar Top'**
  String get sidebarTop;

  /// No description provided for @sidebarBottom.
  ///
  /// In en, this message translates to:
  /// **'Sidebar Bottom'**
  String get sidebarBottom;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @projectPage.
  ///
  /// In en, this message translates to:
  /// **'Project Page'**
  String get projectPage;

  /// No description provided for @cpc.
  ///
  /// In en, this message translates to:
  /// **'CPC (Cost per click)'**
  String get cpc;

  /// No description provided for @cpm.
  ///
  /// In en, this message translates to:
  /// **'CPM (Cost per 1000 impressions)'**
  String get cpm;

  /// No description provided for @flat.
  ///
  /// In en, this message translates to:
  /// **'Flat Rate'**
  String get flat;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @adCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Ad Campaigns'**
  String get adCampaigns;

  /// No description provided for @newCampaign.
  ///
  /// In en, this message translates to:
  /// **'New Campaign'**
  String get newCampaign;

  /// No description provided for @noAdCampaigns.
  ///
  /// In en, this message translates to:
  /// **'No ad campaigns yet'**
  String get noAdCampaigns;

  /// No description provided for @createFirstCampaign.
  ///
  /// In en, this message translates to:
  /// **'Create your first campaign to reach more clients'**
  String get createFirstCampaign;

  /// No description provided for @campaignPaused.
  ///
  /// In en, this message translates to:
  /// **'Campaign paused'**
  String get campaignPaused;

  /// No description provided for @campaignActivated.
  ///
  /// In en, this message translates to:
  /// **'Campaign activated'**
  String get campaignActivated;

  /// No description provided for @failedToActivate.
  ///
  /// In en, this message translates to:
  /// **'Failed to activate campaign'**
  String get failedToActivate;

  /// No description provided for @cpcShort.
  ///
  /// In en, this message translates to:
  /// **'CPC'**
  String get cpcShort;

  /// No description provided for @cpmShort.
  ///
  /// In en, this message translates to:
  /// **'CPM'**
  String get cpmShort;

  /// No description provided for @flatShort.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get flatShort;

  /// No description provided for @activateAndPay.
  ///
  /// In en, this message translates to:
  /// **'Activate & Pay'**
  String get activateAndPay;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @avgCpc.
  ///
  /// In en, this message translates to:
  /// **'Avg CPC'**
  String get avgCpc;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
