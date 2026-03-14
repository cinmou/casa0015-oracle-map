class TarotCard {
  final String number;      // 牌号
  final String name;     // 名字
  final String arcana;   // 阿尔卡娜类型 (Major/Minor)
  final String? suit;
  final String img; // 图片文件名 (例如: 00-TheFool.png)
  final List<String> uprightKeywords;
  final String uprightMeaning;
  final List<String> reversedKeywords;
  final String reversedMeaning;

  TarotCard({
    required this.name,
    required this.number,
    required this.arcana,
    this.suit,
    required this.img,
    required this.uprightKeywords,
    required this.uprightMeaning,
    required this.reversedKeywords,
    required this.reversedMeaning,
  });

  // 逻辑：将 JSON 转为 Dart 对象
  factory TarotCard.fromJson(Map<String, dynamic> json) {
    return TarotCard(
      name: json['name'],
      number: json['number'],
      arcana: json['arcana'],
      suit: json['suit'], // 如果 JSON 里是 null，这里也会自动赋值为 null
      img: json['img'],
      // 在这里直接从嵌套的 Map 中取值
      uprightKeywords: List<String>.from(json['upright']['keywords']),
      uprightMeaning: json['upright']['meaning'],
      reversedKeywords: List<String>.from(json['reversed']['keywords']),
      reversedMeaning: json['reversed']['meaning'],
    );
  }

  // 方便获取完整图片路径的方法
  String get fullPath => 'assets/images/tarot/$img';

}