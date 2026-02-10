import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {

  static const baseUrl = "http://127.0.0.1:5000";
  
  // Helper to get headers with authentication
  static Map<String, String> _getHeaders() {
    final headers = {"Content-Type": "application/json"};
    if (AuthService.token != null) {
      headers["Authorization"] = "Bearer ${AuthService.token}";
    }
    return headers;
  }
  
  static Future<double> predict(Map<String, dynamic> data) async {

    print("📤 SENDING TO API: $data");

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/predict"),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      print("📥 STATUS: ${response.statusCode}");
      print("📥 BODY: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json["predicted_price"].toDouble();
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized - Please login again");
      } else {
        throw Exception("Prediction Failed: ${response.body}");
      }

    } catch (e) {
      print("❌ API ERROR: $e");
      throw Exception("Cannot connect to backend");
    }
  }
  
  static Future<List<dynamic>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/history"),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized - Please login again");
      } else {
        throw Exception("Failed to get history: ${response.body}");
      }
    } catch (e) {
      print("❌ API ERROR: $e");
      throw Exception("Cannot connect to backend");
    }
  }
  
  static Future<void> deleteHistory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/history/$id"),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to delete: ${response.body}");
      }
    } catch (e) {
      print("❌ API ERROR: $e");
      throw Exception("Cannot connect to backend");
    }
  }
  
  static Future<void> toggleFavorite(int id) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/history/$id/favorite"),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to toggle favorite: ${response.body}");
      }
    } catch (e) {
      print("❌ API ERROR: $e");
      throw Exception("Cannot connect to backend");
    }
  }
}
