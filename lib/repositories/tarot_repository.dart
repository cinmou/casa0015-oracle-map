import '../models/tarot_card.dart';
import '../services/tarot_service.dart';

class TarotRepository {
  // 用一个 Map 来缓存已经加载过的卡牌，Key 是语言代码（如 'zh'）
  final Map<String, List<TarotCard>> _cache = {};

  Future<List<TarotCard>> fetchCardsByLanguage(String lang) async {
    print('--- [DEBUG] TarotRepository: Fetching cards for lang: $lang ---'); // DEBUG PRINT
    
    // 1. 如果缓存里已经有这个语言的数据了，直接秒传
    if (_cache.containsKey(lang)) {
      print('--- [DEBUG] TarotRepository: Returning cached data for $lang. Count: ${_cache[lang]!.length} ---'); // DEBUG PRINT
      return _cache[lang]!;
    }

    print('--- [DEBUG] TarotRepository: Cache miss for $lang. Calling Service... ---'); // DEBUG PRINT
    // 2. 如果没有，就去叫 Service 工人去读文件
    final cards = await TarotService.loadCards(lang);

    // 3. 存入缓存并返回
    _cache[lang] = cards;
    print('--- [DEBUG] TarotRepository: Data cached for $lang. Count: ${cards.length} ---'); // DEBUG PRINT
    return cards;
  }
  
  // 添加一个清除缓存的方法，以防万一需要强制刷新
  void clearCache() {
    _cache.clear();
    print('--- [DEBUG] TarotRepository: Cache cleared ---'); // DEBUG PRINT
  }
}