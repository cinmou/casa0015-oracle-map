// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'The Oracle';

  @override
  String get bottomNavQuick => 'Quick';

  @override
  String get bottomNavAiDraw => 'AI Draw';

  @override
  String get bottomNavOracle => 'Oracle';

  @override
  String get bottomNavMe => 'Me';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System Default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System Default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageChinese => '简体中文';

  @override
  String get settingsLanguageTraditionalChinese => '繁體中文';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get quickPickTitle => 'Make a Choice';

  @override
  String get quickPickCoinFlip => 'Coin Flip';

  @override
  String get quickPickDiceRoll => 'Dice Roll';

  @override
  String get quickPickDrawCard => 'Draw Card';

  @override
  String get oraclePickTitle => 'Tarot Workshop';

  @override
  String get oraclePickLibrary => 'Library';

  @override
  String get oraclePickDailyDraw => 'Daily Draw';

  @override
  String get oraclePickClassicSpread => 'Classic Spread';

  @override
  String get tarotDisplayTitle => 'Tarot';

  @override
  String get tarotDisplaySelectCard => 'Select Tarot Card';

  @override
  String get tarotDisplayUprightMeaning => 'Upright Meaning';

  @override
  String get tarotDisplayReversedMeaning => 'Reversed Meaning';

  @override
  String tarotDisplayKeywords(Object keywords) {
    return 'Keywords: $keywords';
  }

  @override
  String get singleDrawTitle => 'Reveal Fate';

  @override
  String get singleDrawReversed => 'REVERSED';

  @override
  String get singleDrawTapToReveal => 'TAP CARD TO REVEAL';

  @override
  String get singleDrawShowMeaning => 'SHOW MEANING';

  @override
  String get pastPresentFutureTitle => 'Three Fates';

  @override
  String get pastPresentFuturePast => 'THE PAST';

  @override
  String get pastPresentFuturePresent => 'THE PRESENT';

  @override
  String get pastPresentFutureFuture => 'THE FUTURE';

  @override
  String get pastPresentFuturePastDesc => 'Roots of the matter';

  @override
  String get pastPresentFuturePresentDesc => 'Current energy';

  @override
  String get pastPresentFutureFutureDesc => 'Potential outcome';

  @override
  String get pastPresentFutureReadFullMeaning => 'READ FULL MEANING';

  @override
  String get readingSummaryTitle => 'Reading Summary';

  @override
  String get readingSummaryReversedAbbr => 'REV';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirmation =>
      'This will delete all non-favorited entries. This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get noHistory => 'No history yet.';

  @override
  String get question => 'Question';

  @override
  String get deleteRecord => 'Delete Record?';

  @override
  String deleteRecordConfirmation(Object cardName) {
    return 'Are you sure you want to remove the record for \'$cardName\'? This action cannot be undone.';
  }

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get delete => 'Delete';

  @override
  String get editQuestion => 'Edit Question';

  @override
  String get editQuestionHint => 'What was your question?';

  @override
  String get save => 'Save';

  @override
  String get tripleCardHistoryTitle => 'Three Card Spread History';
}
