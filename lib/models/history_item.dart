enum HistoryType { singleTarot, threeSpread, coinToss }

class HistoryItem {
  final String id;
  final HistoryType type;
  final DateTime timestamp;
  final Map<String, dynamic> payload; // 存放具体的占卜数据

  String question;   // 用户询问的问题
  bool isFavorite;   // 是否收藏

  HistoryItem({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.payload,
    this.question = "Revealing the truth", // 默认问题
    this.isFavorite = false,
  });

  // 将对象转为 Map (存入 Hive)
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.index,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'payload': payload,
    'question': question,
    'isFavorite': isFavorite,
  };

  // 从 Map 转回对象 (从 Hive 读取)
  factory HistoryItem.fromMap(Map<dynamic, dynamic> map) => HistoryItem(
    id: map['id'],
    type: HistoryType.values[map['type']],
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    payload: Map<String, dynamic>.from(map['payload']),
    question: map['question'] ?? "Current Status Reflection",
    isFavorite: map['isFavorite'] ?? false,
  );
}