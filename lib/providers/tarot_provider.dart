import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/tarot_card.dart';
import '../repositories/tarot_repository.dart';

class TarotProvider extends ChangeNotifier {
  final TarotRepository _repository = TarotRepository();

  List<TarotCard> _cards = [];
  String _currentLang = 'en';
  bool _isLoading = false;

  // 外部读取接口
  List<TarotCard> get cards => _cards;
  String get currentLang => _currentLang;
  bool get isLoading => _isLoading;

  // 接收启动时的全局语言设置，默认为英文
  Future<void> init([String initialLang = 'en']) async {
    await loadTarotData(initialLang);
  }

  // 初始化或切换语言的方法
  Future<void> loadTarotData([String lang = 'en']) async {
    print('--- [DEBUG] TarotProvider: loadTarotData called with lang: $lang ---'); // DEBUG PRINT
    _isLoading = true;
    notifyListeners(); // 通知 UI 显示加载状态

    // 解析系统语言
    String actualLang = lang;
    if (lang == 'system') {
      // 获取手机系统的当前语言代码 (如 'en', 'zh')
      String systemLocale = ui.PlatformDispatcher.instance.locale.languageCode;
      print('--- [DEBUG] TarotProvider: System locale detected: $systemLocale ---'); // DEBUG PRINT

      // 检查你的 JSON 是否支持这个系统语言，如果不支持就默认回退到 'en'
      // 假设你目前只有 'en', 'zh', 'ja'
      if (['en', 'zh', 'ja'].contains(systemLocale)) {
        actualLang = systemLocale;
      } else {
        actualLang = 'en';
      }
    }
    
    print('--- [DEBUG] TarotProvider: Final resolved language: $actualLang ---'); // DEBUG PRINT

    _currentLang = actualLang;
    // 传入解析后的实际语言给 Repository (如 fetchCardsByLanguage('zh'))
    _cards = await _repository.fetchCardsByLanguage(actualLang);
    print('--- [DEBUG] TarotProvider: Cards loaded. Count: ${_cards.length} ---'); // DEBUG PRINT

    _isLoading = false;
    notifyListeners(); // 数据加载完毕，UI 自动刷新为新语言的塔罗牌
  }
}
