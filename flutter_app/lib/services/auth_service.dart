import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {

  static const base = "http://127.0.0.1:5000";

  static String? token;

  static Future<bool> login(String email, String pass) async {

    final r = await http.post(
      Uri.parse("$base/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": pass}),
    );

    if (r.statusCode == 200) {
      token = jsonDecode(r.body)["token"];
      return true;
    }

    return false;
  }

  static Future<bool> register(String email, String pass) async {

    final r = await http.post(
      Uri.parse("$base/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": pass}),
    );

    return r.statusCode == 200;
  }

  static Future<Map<String, dynamic>> me() async {

    final r = await http.get(
      Uri.parse("$base/me"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    return jsonDecode(r.body);
  }

  static void logout() {
    token = null;
  }
}
