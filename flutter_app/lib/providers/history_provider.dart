import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prediction_history_model.dart';

class HistoryProvider extends ChangeNotifier {
  List<PredictionHistory> _items = [];
  bool _loading = false;

  List<PredictionHistory> get items => _items;
  bool get loading => _loading;
  
  List<PredictionHistory> get favorites => 
      _items.where((item) => item.isFavorite).toList();

  HistoryProvider() {
    _loadFromLocalStorage();
  }

  // Load history from local storage
  Future<void> _loadFromLocalStorage() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('prediction_history');
      
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _items = decoded
            .map((item) => PredictionHistory.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint("History load error: $e");
      _items = [];
    }

    _loading = false;
    notifyListeners();
  }

  // Save history to local storage
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = json.encode(
        _items.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('prediction_history', historyJson);
    } catch (e) {
      debugPrint("History save error: $e");
    }
  }

  // Add new prediction to history
  Future<void> addPrediction(Map<String, dynamic> input, double price) async {
    final newItem = PredictionHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      input: input,
      predictedPrice: price,
      timestamp: DateTime.now(),
    );

    _items.insert(0, newItem); // Add to beginning
    await _saveToLocalStorage();
    notifyListeners();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isFavorite: !_items[index].isFavorite,
      );
      await _saveToLocalStorage();
      notifyListeners();
    }
  }

  // Delete single history item
  Future<void> remove(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _saveToLocalStorage();
    notifyListeners();
  }

  // Clear all history
  Future<void> clearAll() async {
    _items = [];
    await _saveToLocalStorage();
    notifyListeners();
  }

  // Reload from storage
  Future<void> reload() async {
    await _loadFromLocalStorage();
  }
}
