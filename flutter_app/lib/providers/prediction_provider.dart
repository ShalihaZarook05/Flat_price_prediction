import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PredictionProvider extends ChangeNotifier {

  bool loading = false;
  double price = 0;

  // 🔥 ADD THIS LINE
  String errorMessage = "";

  Future<void> predict(Map<String, dynamic> data) async {
    try {
      loading = true;
      errorMessage = "";   // reset old error
      notifyListeners();

      price = await ApiService.predict(data);

      loading = false;
      notifyListeners();

    } catch (e) {
      loading = false;

      // 🔥 SAVE ERROR TO SHOW IN UI
      errorMessage = e.toString();

      notifyListeners();
    }
  }
}
