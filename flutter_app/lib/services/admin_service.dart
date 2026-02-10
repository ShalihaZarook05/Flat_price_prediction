import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  static const base = "http://127.0.0.1:5000";
  static String? token;

  // Authentication
  static Future<bool> login(String email, String pass) async {
    final r = await http.post(
      Uri.parse("$base/admin/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": pass}),
    );

    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      token = data["token"];
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> me() async {
    final r = await http.get(
      Uri.parse("$base/admin/me"),
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(r.body);
  }

  static void logout() {
    token = null;
  }

  // Helper to get headers with authentication
  static Map<String, String> _getHeaders() {
    final headers = {"Content-Type": "application/json"};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  // User Management
  static Future<List<dynamic>> getAllUsers() async {
    final r = await http.get(
      Uri.parse("$base/admin/users"),
      headers: _getHeaders(),
    );
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as List<dynamic>;
    }
    throw Exception("Failed to get users");
  }

  static Future<void> deleteUser(int userId) async {
    final r = await http.delete(
      Uri.parse("$base/admin/users/$userId"),
      headers: _getHeaders(),
    );
    if (r.statusCode != 200) {
      throw Exception("Failed to delete user");
    }
  }

  static Future<void> toggleBlockUser(int userId) async {
    final r = await http.put(
      Uri.parse("$base/admin/users/$userId/block"),
      headers: _getHeaders(),
    );
    if (r.statusCode != 200) {
      throw Exception("Failed to block/unblock user");
    }
  }

  // Prediction Management
  static Future<List<dynamic>> getAllPredictions() async {
    final r = await http.get(
      Uri.parse("$base/admin/predictions"),
      headers: _getHeaders(),
    );
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as List<dynamic>;
    }
    throw Exception("Failed to get predictions");
  }

  static Future<void> deletePrediction(int predictionId) async {
    final r = await http.delete(
      Uri.parse("$base/admin/predictions/$predictionId"),
      headers: _getHeaders(),
    );
    if (r.statusCode != 200) {
      throw Exception("Failed to delete prediction");
    }
  }

  // Statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final r = await http.get(
      Uri.parse("$base/admin/stats"),
      headers: _getHeaders(),
    );
    if (r.statusCode == 200) {
      return jsonDecode(r.body);
    }
    throw Exception("Failed to get statistics");
  }

  // Model Info
  static Future<Map<String, dynamic>> getModelInfo() async {
    final r = await http.get(
      Uri.parse("$base/admin/model-info"),
      headers: _getHeaders(),
    );
    if (r.statusCode == 200) {
      return jsonDecode(r.body);
    }
    throw Exception("Failed to get model info");
  }
}
