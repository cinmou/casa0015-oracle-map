import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/history_item.dart';

class HistoryProvider extends ChangeNotifier {
  static const String _boxName = "historyBox";
  List<HistoryItem> _records = [];

  List<HistoryItem> get records => _records;

  Future<void> init() async {
    await Hive.initFlutter();
    var box = await Hive.openBox(_boxName);
    _records = box.values.map((item) => HistoryItem.fromMap(item)).toList();
    await _cleanOldRecords();
    _sortByTime();
    notifyListeners();
  }

  Future<void> addRecord(HistoryItem item) async {
    var box = Hive.box(_boxName);
    await box.put(item.id, item.toMap());
    _records.insert(0, item);
    await _cleanOldRecords();
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    var box = Hive.box(_boxName);
    await box.delete(id);
    _records.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> updateRecord(HistoryItem updatedItem) async {
    var box = Hive.box(_boxName);
    await box.put(updatedItem.id, updatedItem.toMap());
    int index = _records.indexWhere((element) => element.id == updatedItem.id);
    if (index != -1) {
      _records[index] = updatedItem;
      notifyListeners();
    }
  }

  Future<void> clearNonFavorites() async {
    var box = Hive.box(_boxName);
    List<String> keysToDelete = [];
    
    // Find all non-favorite records
    for (var item in _records) {
      if (!item.isFavorite) {
        keysToDelete.add(item.id);
      }
    }

    if (keysToDelete.isNotEmpty) {
      // Delete from Hive
      await box.deleteAll(keysToDelete);
      // Delete from memory
      _records.removeWhere((item) => !item.isFavorite);
      notifyListeners();
    }
  }

  Future<void> _cleanOldRecords() async {
    var box = Hive.box(_boxName);
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    List<String> keysToDelete = [];

    for (var item in _records) {
      if (item.timestamp.isBefore(thirtyDaysAgo) && !item.isFavorite) {
        keysToDelete.add(item.id);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
      _records.removeWhere((item) => keysToDelete.contains(item.id));
    }
  }

  void _sortByTime() => _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
}
