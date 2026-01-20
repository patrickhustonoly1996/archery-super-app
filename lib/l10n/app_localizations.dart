import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Archery Super App'**
  String get appTitle;

  /// No description provided for @archery.
  ///
  /// In en, this message translates to:
  /// **'ARCHERY'**
  String get archery;

  /// No description provided for @superApp.
  ///
  /// In en, this message translates to:
  /// **'SUPER APP'**
  String get superApp;

  /// No description provided for @selectMode.
  ///
  /// In en, this message translates to:
  /// **'SELECT MODE'**
  String get selectMode;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'LOADING'**
  String get loading;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonDefault.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get commonDefault;

  /// No description provided for @commonPrimary.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get commonPrimary;

  /// No description provided for @commonStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get commonStart;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @menuResume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get menuResume;

  /// No description provided for @menuResumeRound.
  ///
  /// In en, this message translates to:
  /// **'Continue round'**
  String get menuResumeRound;

  /// No description provided for @menuResumeDrill.
  ///
  /// In en, this message translates to:
  /// **'Resume drill'**
  String get menuResumeDrill;

  /// No description provided for @menuResumeBreath.
  ///
  /// In en, this message translates to:
  /// **'Resume breath'**
  String get menuResumeBreath;

  /// No description provided for @menuQuickStart.
  ///
  /// In en, this message translates to:
  /// **'QUICK START'**
  String get menuQuickStart;

  /// No description provided for @menuQuickStartSub.
  ///
  /// In en, this message translates to:
  /// **'Fast session'**
  String get menuQuickStartSub;

  /// No description provided for @menuScore.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get menuScore;

  /// No description provided for @menuScoreSub.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get menuScoreSub;

  /// No description provided for @menuScores.
  ///
  /// In en, this message translates to:
  /// **'SCORES'**
  String get menuScores;

  /// No description provided for @menuScoresSub.
  ///
  /// In en, this message translates to:
  /// **'Score record'**
  String get menuScoresSub;

  /// No description provided for @menuStats.
  ///
  /// In en, this message translates to:
  /// **'STATS'**
  String get menuStats;

  /// No description provided for @menuStatsSub.
  ///
  /// In en, this message translates to:
  /// **'Trends & data'**
  String get menuStatsSub;

  /// No description provided for @menuBowDrills.
  ///
  /// In en, this message translates to:
  /// **'BOW DRILLS'**
  String get menuBowDrills;

  /// No description provided for @menuBowDrillsSub.
  ///
  /// In en, this message translates to:
  /// **'Timed training'**
  String get menuBowDrillsSub;

  /// No description provided for @menuDelayCam.
  ///
  /// In en, this message translates to:
  /// **'DELAY CAM'**
  String get menuDelayCam;

  /// No description provided for @menuDelayCamSub.
  ///
  /// In en, this message translates to:
  /// **'Form review'**
  String get menuDelayCamSub;

  /// No description provided for @menuBreathe.
  ///
  /// In en, this message translates to:
  /// **'BREATHE'**
  String get menuBreathe;

  /// No description provided for @menuBreatheSub.
  ///
  /// In en, this message translates to:
  /// **'Focus & calm'**
  String get menuBreatheSub;

  /// No description provided for @menuLearn.
  ///
  /// In en, this message translates to:
  /// **'LEARN'**
  String get menuLearn;

  /// No description provided for @menuLearnSub.
  ///
  /// In en, this message translates to:
  /// **'Video courses'**
  String get menuLearnSub;

  /// No description provided for @menuGear.
  ///
  /// In en, this message translates to:
  /// **'GEAR'**
  String get menuGear;

  /// No description provided for @menuGearSub.
  ///
  /// In en, this message translates to:
  /// **'Bows & arrows'**
  String get menuGearSub;

  /// No description provided for @menuProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get menuProfile;

  /// No description provided for @menuProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Performance radar'**
  String get menuProfileSub;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get menuSettings;

  /// No description provided for @menuSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Language & more'**
  String get menuSettingsSub;

  /// No description provided for @menuSignOut.
  ///
  /// In en, this message translates to:
  /// **'SIGN OUT'**
  String get menuSignOut;

  /// No description provided for @menuSignOutSub.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get menuSignOutSub;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get settingsLanguageDescription;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'IMPORT DATA'**
  String get settingsImport;

  /// No description provided for @settingsImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Import scores from file'**
  String get settingsImportDescription;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get loginSignIn;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get loginCreateAccount;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignInButton;

  /// No description provided for @loginCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateButton;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginNewToApp.
  ///
  /// In en, this message translates to:
  /// **'New to Archery Super App?'**
  String get loginNewToApp;

  /// No description provided for @loginCreateFreeAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your free account'**
  String get loginCreateFreeAccount;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get loginErrorGeneric;

  /// No description provided for @loginErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get loginErrorEmailInUse;

  /// No description provided for @loginErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get loginErrorInvalidEmail;

  /// No description provided for @loginErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get loginErrorWeakPassword;

  /// No description provided for @loginErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get loginErrorUserNotFound;

  /// No description provided for @loginErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get loginErrorWrongPassword;

  /// No description provided for @loginErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginErrorInvalidCredential;

  /// No description provided for @loginErrorAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get loginErrorAuthFailed;

  /// No description provided for @loginEnterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first, then tap forgot password.'**
  String get loginEnterEmailFirst;

  /// No description provided for @loginPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get loginPasswordResetSent;

  /// No description provided for @sessionNewSession.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get sessionNewSession;

  /// No description provided for @sessionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get sessionStart;

  /// No description provided for @sessionSessionType.
  ///
  /// In en, this message translates to:
  /// **'Session Type'**
  String get sessionSessionType;

  /// No description provided for @sessionPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get sessionPractice;

  /// No description provided for @sessionCompetition.
  ///
  /// In en, this message translates to:
  /// **'Competition'**
  String get sessionCompetition;

  /// No description provided for @sessionEquipmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Equipment (Optional)'**
  String get sessionEquipmentOptional;

  /// No description provided for @sessionNoEquipment.
  ///
  /// In en, this message translates to:
  /// **'No equipment configured. Go to Equipment to add bows and quivers.'**
  String get sessionNoEquipment;

  /// No description provided for @sessionBow.
  ///
  /// In en, this message translates to:
  /// **'Bow'**
  String get sessionBow;

  /// No description provided for @sessionSelectBow.
  ///
  /// In en, this message translates to:
  /// **'Select a bow'**
  String get sessionSelectBow;

  /// No description provided for @sessionQuiver.
  ///
  /// In en, this message translates to:
  /// **'Quiver'**
  String get sessionQuiver;

  /// No description provided for @sessionSelectQuiver.
  ///
  /// In en, this message translates to:
  /// **'Select a quiver'**
  String get sessionSelectQuiver;

  /// No description provided for @sessionEnableShaftTagging.
  ///
  /// In en, this message translates to:
  /// **'Enable shaft tagging'**
  String get sessionEnableShaftTagging;

  /// No description provided for @sessionTrackArrowPerformance.
  ///
  /// In en, this message translates to:
  /// **'Track individual arrow performance'**
  String get sessionTrackArrowPerformance;

  /// No description provided for @sessionSelectRound.
  ///
  /// In en, this message translates to:
  /// **'Select Round'**
  String get sessionSelectRound;

  /// No description provided for @sessionTriSpot.
  ///
  /// In en, this message translates to:
  /// **'Tri-spot'**
  String get sessionTriSpot;

  /// No description provided for @sessionArrowsPerEnd.
  ///
  /// In en, this message translates to:
  /// **'arrows/end'**
  String get sessionArrowsPerEnd;

  /// No description provided for @sessionEnds.
  ///
  /// In en, this message translates to:
  /// **'ends'**
  String get sessionEnds;

  /// No description provided for @roundCategoryWaIndoor.
  ///
  /// In en, this message translates to:
  /// **'WA Indoor'**
  String get roundCategoryWaIndoor;

  /// No description provided for @roundCategoryWaOutdoor.
  ///
  /// In en, this message translates to:
  /// **'WA Outdoor'**
  String get roundCategoryWaOutdoor;

  /// No description provided for @roundCategoryAgbIndoor.
  ///
  /// In en, this message translates to:
  /// **'AGB Indoor'**
  String get roundCategoryAgbIndoor;

  /// No description provided for @roundCategoryAgbImperial.
  ///
  /// In en, this message translates to:
  /// **'AGB Imperial'**
  String get roundCategoryAgbImperial;

  /// No description provided for @roundCategoryAgbMetric.
  ///
  /// In en, this message translates to:
  /// **'AGB Metric'**
  String get roundCategoryAgbMetric;

  /// No description provided for @roundCategoryNfaaIndoor.
  ///
  /// In en, this message translates to:
  /// **'NFAA Indoor'**
  String get roundCategoryNfaaIndoor;

  /// No description provided for @roundCategoryNfaaField.
  ///
  /// In en, this message translates to:
  /// **'NFAA Field'**
  String get roundCategoryNfaaField;

  /// No description provided for @roundCategoryPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get roundCategoryPractice;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Scores Record'**
  String get historyTitle;

  /// No description provided for @historyImportScores.
  ///
  /// In en, this message translates to:
  /// **'Import Scores'**
  String get historyImportScores;

  /// No description provided for @historyNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get historyNoSessions;

  /// No description provided for @historyStartTraining.
  ///
  /// In en, this message translates to:
  /// **'Start training to see your history here'**
  String get historyStartTraining;

  /// No description provided for @historyImportHistory.
  ///
  /// In en, this message translates to:
  /// **'Import Score History'**
  String get historyImportHistory;

  /// No description provided for @historyScoresCount.
  ///
  /// In en, this message translates to:
  /// **'{count} scores'**
  String historyScoresCount(int count);

  /// No description provided for @historyIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get historyIndoor;

  /// No description provided for @historyOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get historyOutdoor;

  /// No description provided for @historyComp.
  ///
  /// In en, this message translates to:
  /// **'Comp'**
  String get historyComp;

  /// No description provided for @historyHandicap.
  ///
  /// In en, this message translates to:
  /// **'HC {value}'**
  String historyHandicap(int value);

  /// No description provided for @equipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipmentTitle;

  /// No description provided for @equipmentBows.
  ///
  /// In en, this message translates to:
  /// **'Bows'**
  String get equipmentBows;

  /// No description provided for @equipmentQuivers.
  ///
  /// In en, this message translates to:
  /// **'Quivers'**
  String get equipmentQuivers;

  /// No description provided for @equipmentTuning.
  ///
  /// In en, this message translates to:
  /// **'Tuning'**
  String get equipmentTuning;

  /// No description provided for @equipmentNoBows.
  ///
  /// In en, this message translates to:
  /// **'No bows added'**
  String get equipmentNoBows;

  /// No description provided for @equipmentAddBowToStart.
  ///
  /// In en, this message translates to:
  /// **'Add a bow to get started'**
  String get equipmentAddBowToStart;

  /// No description provided for @equipmentAddBow.
  ///
  /// In en, this message translates to:
  /// **'Add Bow'**
  String get equipmentAddBow;

  /// No description provided for @equipmentNoQuivers.
  ///
  /// In en, this message translates to:
  /// **'No quivers added'**
  String get equipmentNoQuivers;

  /// No description provided for @equipmentAddQuiverToTrack.
  ///
  /// In en, this message translates to:
  /// **'Add a quiver to track arrows'**
  String get equipmentAddQuiverToTrack;

  /// No description provided for @equipmentAddQuiver.
  ///
  /// In en, this message translates to:
  /// **'Add Quiver'**
  String get equipmentAddQuiver;

  /// No description provided for @equipmentArrowsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} arrows'**
  String equipmentArrowsCount(int count);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profileTitle;

  /// No description provided for @profileShootingStyle.
  ///
  /// In en, this message translates to:
  /// **'SHOOTING STYLE'**
  String get profileShootingStyle;

  /// No description provided for @profileArcherInfo.
  ///
  /// In en, this message translates to:
  /// **'ARCHER INFO'**
  String get profileArcherInfo;

  /// No description provided for @profileClassification.
  ///
  /// In en, this message translates to:
  /// **'CLASSIFICATION'**
  String get profileClassification;

  /// No description provided for @profileFederations.
  ///
  /// In en, this message translates to:
  /// **'FEDERATION MEMBERSHIPS'**
  String get profileFederations;

  /// No description provided for @profileNotes.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get profileNotes;

  /// No description provided for @profilePrimaryBowType.
  ///
  /// In en, this message translates to:
  /// **'Primary Bow Type'**
  String get profilePrimaryBowType;

  /// No description provided for @profileHandedness.
  ///
  /// In en, this message translates to:
  /// **'Handedness'**
  String get profileHandedness;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileNameHint;

  /// No description provided for @profileClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get profileClub;

  /// No description provided for @profileClubHint.
  ///
  /// In en, this message translates to:
  /// **'Your archery club'**
  String get profileClubHint;

  /// No description provided for @profileYearStarted.
  ///
  /// In en, this message translates to:
  /// **'Year Started Shooting'**
  String get profileYearStarted;

  /// No description provided for @profileSelectYear.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get profileSelectYear;

  /// No description provided for @profileYearsExperience.
  ///
  /// In en, this message translates to:
  /// **'{years} years experience'**
  String profileYearsExperience(int years);

  /// No description provided for @profileShootingFrequency.
  ///
  /// In en, this message translates to:
  /// **'Shooting Frequency'**
  String get profileShootingFrequency;

  /// No description provided for @profileDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{days} days/week'**
  String profileDaysPerWeek(int days);

  /// No description provided for @profileCompetitionLevels.
  ///
  /// In en, this message translates to:
  /// **'Competition Levels'**
  String get profileCompetitionLevels;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender (for classification)'**
  String get profileGender;

  /// No description provided for @profileGenderNote.
  ///
  /// In en, this message translates to:
  /// **'Used to calculate AGB classification thresholds'**
  String get profileGenderNote;

  /// No description provided for @profileDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get profileDateOfBirth;

  /// No description provided for @profileDateOfBirthNote.
  ///
  /// In en, this message translates to:
  /// **'Used to determine your age category for classifications'**
  String get profileDateOfBirthNote;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileAgeCategory.
  ///
  /// In en, this message translates to:
  /// **'Age Category'**
  String get profileAgeCategory;

  /// No description provided for @profileNoFederations.
  ///
  /// In en, this message translates to:
  /// **'No federation memberships'**
  String get profileNoFederations;

  /// No description provided for @profileAddFederation.
  ///
  /// In en, this message translates to:
  /// **'ADD FEDERATION'**
  String get profileAddFederation;

  /// No description provided for @profileMemberNumber.
  ///
  /// In en, this message translates to:
  /// **'Member #: {number}'**
  String profileMemberNumber(String number);

  /// No description provided for @profileExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String profileExpires(String date);

  /// No description provided for @profileNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Club access codes, locker number, etc.'**
  String get profileNotesHint;

  /// No description provided for @profileTargetFaceSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Target Face Suggestions'**
  String get profileTargetFaceSuggestions;

  /// No description provided for @profileBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Based on {bowType}:'**
  String profileBasedOn(String bowType);

  /// No description provided for @profileHandicapNote.
  ///
  /// In en, this message translates to:
  /// **'Handicap and classification calculations based on archeryutils'**
  String get profileHandicapNote;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Volume'**
  String get statsTitle;

  /// No description provided for @statsBulkUpload.
  ///
  /// In en, this message translates to:
  /// **'Bulk Upload'**
  String get statsBulkUpload;

  /// No description provided for @statsFilterDays.
  ///
  /// In en, this message translates to:
  /// **'Filter by days'**
  String get statsFilterDays;

  /// No description provided for @stats30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get stats30Days;

  /// No description provided for @stats90Days.
  ///
  /// In en, this message translates to:
  /// **'90 Days'**
  String get stats90Days;

  /// No description provided for @stats180Days.
  ///
  /// In en, this message translates to:
  /// **'180 Days'**
  String get stats180Days;

  /// No description provided for @stats1Year.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get stats1Year;

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'No volume data yet'**
  String get statsNoData;

  /// No description provided for @statsTrackArrows.
  ///
  /// In en, this message translates to:
  /// **'Track your daily arrow count to monitor training load'**
  String get statsTrackArrows;

  /// No description provided for @statsAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Volume Entry'**
  String get statsAddEntry;

  /// No description provided for @statsNoDataForDays.
  ///
  /// In en, this message translates to:
  /// **'No data for the last {days} days'**
  String statsNoDataForDays(int days);

  /// No description provided for @statsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get statsLast7Days;

  /// No description provided for @stats7DayAvg.
  ///
  /// In en, this message translates to:
  /// **'7-Day Avg'**
  String get stats7DayAvg;

  /// No description provided for @stats7DayEma.
  ///
  /// In en, this message translates to:
  /// **'7-Day EMA'**
  String get stats7DayEma;

  /// No description provided for @stats28DayEma.
  ///
  /// In en, this message translates to:
  /// **'28-Day EMA'**
  String get stats28DayEma;

  /// No description provided for @stats90DayEma.
  ///
  /// In en, this message translates to:
  /// **'90-Day EMA'**
  String get stats90DayEma;

  /// No description provided for @statsArrows.
  ///
  /// In en, this message translates to:
  /// **'arrows'**
  String get statsArrows;

  /// No description provided for @statsPerDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get statsPerDay;

  /// No description provided for @statsTrainingVolume.
  ///
  /// In en, this message translates to:
  /// **'Training Volume'**
  String get statsTrainingVolume;

  /// No description provided for @statsRecentEntries.
  ///
  /// In en, this message translates to:
  /// **'Recent Entries'**
  String get statsRecentEntries;

  /// No description provided for @statsArrowsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} arrows'**
  String statsArrowsCount(int count);

  /// No description provided for @statsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get statsDate;

  /// No description provided for @statsArrowCount.
  ///
  /// In en, this message translates to:
  /// **'Arrow Count'**
  String get statsArrowCount;

  /// No description provided for @statsArrowCountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 120'**
  String get statsArrowCountHint;

  /// No description provided for @statsNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get statsNotesOptional;

  /// No description provided for @statsNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Competition day'**
  String get statsNotesHint;

  /// No description provided for @statsValidArrowCount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid arrow count'**
  String get statsValidArrowCount;

  /// No description provided for @statsEntryAdded.
  ///
  /// In en, this message translates to:
  /// **'Volume entry added'**
  String get statsEntryAdded;

  /// No description provided for @quickStartTitle.
  ///
  /// In en, this message translates to:
  /// **'QUICK START'**
  String get quickStartTitle;

  /// No description provided for @quickStartRoundType.
  ///
  /// In en, this message translates to:
  /// **'ROUND TYPE'**
  String get quickStartRoundType;

  /// No description provided for @quickStartArrowsPerEnd.
  ///
  /// In en, this message translates to:
  /// **'ARROWS PER END'**
  String get quickStartArrowsPerEnd;

  /// No description provided for @quickStartNoRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent sessions found.\nStart a regular session first.'**
  String get quickStartNoRecent;

  /// No description provided for @quickStartButton.
  ///
  /// In en, this message translates to:
  /// **'START SHOOTING'**
  String get quickStartButton;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageItalian;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageKorean;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @languageNativeEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNativeEnglish;

  /// No description provided for @languageNativeFrench.
  ///
  /// In en, this message translates to:
  /// **'Francais'**
  String get languageNativeFrench;

  /// No description provided for @languageNativeGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageNativeGerman;

  /// No description provided for @languageNativeSpanish.
  ///
  /// In en, this message translates to:
  /// **'Espanol'**
  String get languageNativeSpanish;

  /// No description provided for @languageNativeItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageNativeItalian;

  /// No description provided for @languageNativeKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageNativeKorean;

  /// No description provided for @languageNativeJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageNativeJapanese;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
