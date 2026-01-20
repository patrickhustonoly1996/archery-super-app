// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Archery Super App';

  @override
  String get archery => 'ARCHERY';

  @override
  String get superApp => 'SUPER APP';

  @override
  String get selectMode => 'SELECT MODE';

  @override
  String get loading => 'LOADING';

  @override
  String get commonSave => 'SAVE';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonNone => 'None';

  @override
  String get commonDefault => 'DEFAULT';

  @override
  String get commonPrimary => 'PRIMARY';

  @override
  String get commonStart => 'Start';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get menuResume => 'RESUME';

  @override
  String get menuResumeRound => 'Continue round';

  @override
  String get menuResumeDrill => 'Resume drill';

  @override
  String get menuResumeBreath => 'Resume breath';

  @override
  String get menuQuickStart => 'QUICK START';

  @override
  String get menuQuickStartSub => 'Fast session';

  @override
  String get menuScore => 'SCORE';

  @override
  String get menuScoreSub => 'New session';

  @override
  String get menuScores => 'SCORES';

  @override
  String get menuScoresSub => 'Score record';

  @override
  String get menuStats => 'STATS';

  @override
  String get menuStatsSub => 'Trends & data';

  @override
  String get menuBowDrills => 'BOW DRILLS';

  @override
  String get menuBowDrillsSub => 'Timed training';

  @override
  String get menuDelayCam => 'DELAY CAM';

  @override
  String get menuDelayCamSub => 'Form review';

  @override
  String get menuBreathe => 'BREATHE';

  @override
  String get menuBreatheSub => 'Focus & calm';

  @override
  String get menuLearn => 'LEARN';

  @override
  String get menuLearnSub => 'Video courses';

  @override
  String get menuGear => 'GEAR';

  @override
  String get menuGearSub => 'Bows & arrows';

  @override
  String get menuProfile => 'PROFILE';

  @override
  String get menuProfileSub => 'Performance radar';

  @override
  String get menuSettings => 'SETTINGS';

  @override
  String get menuSettingsSub => 'Language & more';

  @override
  String get menuSignOut => 'SIGN OUT';

  @override
  String get menuSignOutSub => 'Log out';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settingsLanguage => 'LANGUAGE';

  @override
  String get settingsLanguageDescription => 'Choose your preferred language';

  @override
  String get settingsImport => 'IMPORT DATA';

  @override
  String get settingsImportDescription => 'Import scores from file';

  @override
  String get loginSignIn => 'SIGN IN';

  @override
  String get loginCreateAccount => 'CREATE ACCOUNT';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSignInButton => 'Sign In';

  @override
  String get loginCreateButton => 'Create Account';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginNewToApp => 'New to Archery Super App?';

  @override
  String get loginCreateFreeAccount => 'Create your free account';

  @override
  String get loginErrorGeneric => 'An error occurred. Please try again.';

  @override
  String get loginErrorEmailInUse =>
      'An account already exists with this email.';

  @override
  String get loginErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get loginErrorWeakPassword =>
      'Password must be at least 6 characters.';

  @override
  String get loginErrorUserNotFound => 'No account found with this email.';

  @override
  String get loginErrorWrongPassword => 'Incorrect password.';

  @override
  String get loginErrorInvalidCredential => 'Invalid email or password.';

  @override
  String get loginErrorAuthFailed => 'Authentication failed. Please try again.';

  @override
  String get loginEnterEmailFirst =>
      'Enter your email first, then tap forgot password.';

  @override
  String get loginPasswordResetSent =>
      'Password reset email sent. Check your inbox.';

  @override
  String get sessionNewSession => 'New Session';

  @override
  String get sessionStart => 'Start';

  @override
  String get sessionSessionType => 'Session Type';

  @override
  String get sessionPractice => 'Practice';

  @override
  String get sessionCompetition => 'Competition';

  @override
  String get sessionEquipmentOptional => 'Equipment (Optional)';

  @override
  String get sessionNoEquipment =>
      'No equipment configured. Go to Equipment to add bows and quivers.';

  @override
  String get sessionBow => 'Bow';

  @override
  String get sessionSelectBow => 'Select a bow';

  @override
  String get sessionQuiver => 'Quiver';

  @override
  String get sessionSelectQuiver => 'Select a quiver';

  @override
  String get sessionEnableShaftTagging => 'Enable shaft tagging';

  @override
  String get sessionTrackArrowPerformance =>
      'Track individual arrow performance';

  @override
  String get sessionSelectRound => 'Select Round';

  @override
  String get sessionTriSpot => 'Tri-spot';

  @override
  String get sessionArrowsPerEnd => 'arrows/end';

  @override
  String get sessionEnds => 'ends';

  @override
  String get roundCategoryWaIndoor => 'WA Indoor';

  @override
  String get roundCategoryWaOutdoor => 'WA Outdoor';

  @override
  String get roundCategoryAgbIndoor => 'AGB Indoor';

  @override
  String get roundCategoryAgbImperial => 'AGB Imperial';

  @override
  String get roundCategoryAgbMetric => 'AGB Metric';

  @override
  String get roundCategoryNfaaIndoor => 'NFAA Indoor';

  @override
  String get roundCategoryNfaaField => 'NFAA Field';

  @override
  String get roundCategoryPractice => 'Practice';

  @override
  String get historyTitle => 'Scores Record';

  @override
  String get historyImportScores => 'Import Scores';

  @override
  String get historyNoSessions => 'No sessions yet';

  @override
  String get historyStartTraining => 'Start training to see your history here';

  @override
  String get historyImportHistory => 'Import Score History';

  @override
  String historyScoresCount(int count) {
    return '$count scores';
  }

  @override
  String get historyIndoor => 'Indoor';

  @override
  String get historyOutdoor => 'Outdoor';

  @override
  String get historyComp => 'Comp';

  @override
  String historyHandicap(int value) {
    return 'HC $value';
  }

  @override
  String get equipmentTitle => 'Equipment';

  @override
  String get equipmentBows => 'Bows';

  @override
  String get equipmentQuivers => 'Quivers';

  @override
  String get equipmentTuning => 'Tuning';

  @override
  String get equipmentNoBows => 'No bows added';

  @override
  String get equipmentAddBowToStart => 'Add a bow to get started';

  @override
  String get equipmentAddBow => 'Add Bow';

  @override
  String get equipmentNoQuivers => 'No quivers added';

  @override
  String get equipmentAddQuiverToTrack => 'Add a quiver to track arrows';

  @override
  String get equipmentAddQuiver => 'Add Quiver';

  @override
  String equipmentArrowsCount(int count) {
    return '$count arrows';
  }

  @override
  String get profileTitle => 'PROFILE';

  @override
  String get profileShootingStyle => 'SHOOTING STYLE';

  @override
  String get profileArcherInfo => 'ARCHER INFO';

  @override
  String get profileClassification => 'CLASSIFICATION';

  @override
  String get profileFederations => 'FEDERATION MEMBERSHIPS';

  @override
  String get profileNotes => 'NOTES';

  @override
  String get profilePrimaryBowType => 'Primary Bow Type';

  @override
  String get profileHandedness => 'Handedness';

  @override
  String get profileName => 'Name';

  @override
  String get profileNameHint => 'Your name';

  @override
  String get profileClub => 'Club';

  @override
  String get profileClubHint => 'Your archery club';

  @override
  String get profileYearStarted => 'Year Started Shooting';

  @override
  String get profileSelectYear => 'Select year';

  @override
  String profileYearsExperience(int years) {
    return '$years years experience';
  }

  @override
  String get profileShootingFrequency => 'Shooting Frequency';

  @override
  String profileDaysPerWeek(int days) {
    return '$days days/week';
  }

  @override
  String get profileCompetitionLevels => 'Competition Levels';

  @override
  String get profileGender => 'Gender (for classification)';

  @override
  String get profileGenderNote =>
      'Used to calculate AGB classification thresholds';

  @override
  String get profileDateOfBirth => 'Date of Birth';

  @override
  String get profileDateOfBirthNote =>
      'Used to determine your age category for classifications';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileAgeCategory => 'Age Category';

  @override
  String get profileNoFederations => 'No federation memberships';

  @override
  String get profileAddFederation => 'ADD FEDERATION';

  @override
  String profileMemberNumber(String number) {
    return 'Member #: $number';
  }

  @override
  String profileExpires(String date) {
    return 'Expires: $date';
  }

  @override
  String get profileNotesHint => 'Club access codes, locker number, etc.';

  @override
  String get profileTargetFaceSuggestions => 'Target Face Suggestions';

  @override
  String profileBasedOn(String bowType) {
    return 'Based on $bowType:';
  }

  @override
  String get profileHandicapNote =>
      'Handicap and classification calculations based on archeryutils';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get statsTitle => 'Training Volume';

  @override
  String get statsBulkUpload => 'Bulk Upload';

  @override
  String get statsFilterDays => 'Filter by days';

  @override
  String get stats30Days => '30 Days';

  @override
  String get stats90Days => '90 Days';

  @override
  String get stats180Days => '180 Days';

  @override
  String get stats1Year => '1 Year';

  @override
  String get statsNoData => 'No volume data yet';

  @override
  String get statsTrackArrows =>
      'Track your daily arrow count to monitor training load';

  @override
  String get statsAddEntry => 'Add Volume Entry';

  @override
  String statsNoDataForDays(int days) {
    return 'No data for the last $days days';
  }

  @override
  String get statsLast7Days => 'Last 7 Days';

  @override
  String get stats7DayAvg => '7-Day Avg';

  @override
  String get stats7DayEma => '7-Day EMA';

  @override
  String get stats28DayEma => '28-Day EMA';

  @override
  String get stats90DayEma => '90-Day EMA';

  @override
  String get statsArrows => 'arrows';

  @override
  String get statsPerDay => 'per day';

  @override
  String get statsTrainingVolume => 'Training Volume';

  @override
  String get statsRecentEntries => 'Recent Entries';

  @override
  String statsArrowsCount(int count) {
    return '$count arrows';
  }

  @override
  String get statsDate => 'Date';

  @override
  String get statsArrowCount => 'Arrow Count';

  @override
  String get statsArrowCountHint => 'e.g., 120';

  @override
  String get statsNotesOptional => 'Notes (optional)';

  @override
  String get statsNotesHint => 'e.g., Competition day';

  @override
  String get statsValidArrowCount => 'Please enter a valid arrow count';

  @override
  String get statsEntryAdded => 'Volume entry added';

  @override
  String get quickStartTitle => 'QUICK START';

  @override
  String get quickStartRoundType => 'ROUND TYPE';

  @override
  String get quickStartArrowsPerEnd => 'ARROWS PER END';

  @override
  String get quickStartNoRecent =>
      'No recent sessions found.\nStart a regular session first.';

  @override
  String get quickStartButton => 'START SHOOTING';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'French';

  @override
  String get languageGerman => 'German';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageItalian => 'Italian';

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageNativeEnglish => 'English';

  @override
  String get languageNativeFrench => 'Francais';

  @override
  String get languageNativeGerman => 'Deutsch';

  @override
  String get languageNativeSpanish => 'Espanol';

  @override
  String get languageNativeItalian => 'Italiano';

  @override
  String get languageNativeKorean => 'Korean';

  @override
  String get languageNativeJapanese => 'Japanese';
}
