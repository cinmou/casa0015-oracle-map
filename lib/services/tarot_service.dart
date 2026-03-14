import 'dart:convert'; // 用于 JSON 解码
import 'package:flutter/services.dart'; // 核心包：用于读取本地资源文件
import '../models/tarot_card.dart'; // 导入我们的蓝图

class TarotService {

  //卡背的路径
  static const String cardBackPath = 'assets/images/tarot/CardBacks.png';

  // Future<List<TarotCard>> 的意思是：
  // 这是一个“异步”工程。读取硬盘需要时间，它承诺最终会给你一堆生产好的卡牌对象。
  static Future<List<TarotCard>> loadCards(String languageCode) async {
    final String path = 'assets/data/tarot_$languageCode.json';
    print('--- [DEBUG] TarotService: Attempting to load file: $path ---'); // DEBUG PRINT

    try {
      // 第一步：从硬盘读取原始 JSON 文本
      // rootBundle.loadString 会去 assets 路径下找那个文件
      final String jsonContent = await rootBundle.loadString(path);
      print('--- [DEBUG] TarotService: File loaded successfully. Length: ${jsonContent.length} ---'); // DEBUG PRINT

      // 第二步：将文本解码成 Dart 原始数据结构
      // json.decode 把文字变成了 Map<String, dynamic>
      final Map<String, dynamic> rawData = json.decode(jsonContent);

      // 第三步：根据你的 JSON 结构，提取出键名为 "cards" 的列表
      final List<dynamic> cardsList = rawData['cards'];
      print('--- [DEBUG] TarotService: Parsed ${cardsList.length} cards ---'); // DEBUG PRINT

      // 第四步：工程组装。
      // .map() 会遍历列表中每一项数据
      // TarotCard.fromJson(item) 会把每一项原始数据按照蓝图加工成对象
      // .toList() 最终把所有加工好的对象装进一个列表里返回
      return cardsList.map((item) => TarotCard.fromJson(item)).toList();

    } catch (e) {
      // 工程事故处理：如果文件路径写错或格式不对，会跳到这里
      print("--- [DEBUG] TarotService: Error loading tarot data: $e ---"); // DEBUG PRINT
      return []; // 返回空列表，防止 App 彻底崩溃
    }
  }

}