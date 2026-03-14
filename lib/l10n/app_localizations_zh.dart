// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '神谕';

  @override
  String get bottomNavQuick => '速选';

  @override
  String get bottomNavAiDraw => 'AI 绘图';

  @override
  String get bottomNavOracle => '神谕';

  @override
  String get bottomNavMe => '我';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色模式';

  @override
  String get settingsThemeDark => '深色模式';

  @override
  String get settingsPreferences => '偏好';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageChinese => '简体中文';

  @override
  String get settingsLanguageTraditionalChinese => '繁體中文';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get quickPickTitle => '做出选择';

  @override
  String get quickPickCoinFlip => '抛硬币';

  @override
  String get quickPickDiceRoll => '掷骰子';

  @override
  String get quickPickDrawCard => '抽张卡';

  @override
  String get oraclePickTitle => '塔罗工坊';

  @override
  String get oraclePickLibrary => '牌库';

  @override
  String get oraclePickDailyDraw => '每日一抽';

  @override
  String get oraclePickClassicSpread => '经典牌阵';

  @override
  String get tarotDisplayTitle => '塔罗牌';

  @override
  String get tarotDisplaySelectCard => '选择塔罗牌';

  @override
  String get tarotDisplayUprightMeaning => '正位释义';

  @override
  String get tarotDisplayReversedMeaning => '逆位释义';

  @override
  String tarotDisplayKeywords(Object keywords) {
    return '关键词: $keywords';
  }

  @override
  String get singleDrawTitle => '揭示命运';

  @override
  String get singleDrawReversed => '逆位';

  @override
  String get singleDrawTapToReveal => '点击卡牌以揭示';

  @override
  String get singleDrawShowMeaning => '查看解读';

  @override
  String get pastPresentFutureTitle => '三圣命运';

  @override
  String get pastPresentFuturePast => '过去';

  @override
  String get pastPresentFuturePresent => '现在';

  @override
  String get pastPresentFutureFuture => '未来';

  @override
  String get pastPresentFuturePastDesc => '问题的根源';

  @override
  String get pastPresentFuturePresentDesc => '当前的能量';

  @override
  String get pastPresentFutureFutureDesc => '可能的结果';

  @override
  String get pastPresentFutureReadFullMeaning => '查看完整解读';

  @override
  String get readingSummaryTitle => '解读概要';

  @override
  String get readingSummaryReversedAbbr => '逆';

  @override
  String get clearHistory => '清空历史';

  @override
  String get clearHistoryConfirmation => '此操作将删除所有未收藏的条目。此操作无法撤销。';

  @override
  String get cancel => '取消';

  @override
  String get clear => '清空';

  @override
  String get noHistory => '暂无历史记录。';

  @override
  String get question => '问题';

  @override
  String get deleteRecord => '删除记录?';

  @override
  String deleteRecordConfirmation(Object cardName) {
    return '您确定要移除关于“$cardName”的记录吗？此操作无法撤销。';
  }

  @override
  String get recordDeleted => '记录已删除';

  @override
  String get delete => '删除';

  @override
  String get editQuestion => '编辑问题';

  @override
  String get editQuestionHint => '你当时的问题是什么？';

  @override
  String get save => '保存';

  @override
  String get tripleCardHistoryTitle => '三牌牌阵历史';
}
