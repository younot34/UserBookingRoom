import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_model.dart';

class AuthService {
  static AuthUser? _currentUser;
  static AuthUser? get currentUser => _currentUser;

  static Future<AuthUser?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/login"),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🚫 Blokir email admin@gmail.com sesuai logika lama
        if (data['user']['email'] == "admin@gmail.com") {
          throw Exception("Email ini tidak diperbolehkan login.");
        }

        _currentUser = AuthUser.fromJson({
          "id": data['user']['id'],
          "name": data['user']['name'],
          "email": data['user']['email'],
          "token": data['token'],
        });

        return _currentUser;
      } else {
        print("Login gagal: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }
  static Future<bool> updatePassword(String newPassword) async {
    if (_currentUser == null) return false;

    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/users/${_currentUser!.id}/password"),
        headers: {
          ...ApiConfig.headers,
          "Authorization": "Bearer ${_currentUser!.token}",
        },
        body: jsonEncode({
          "new_password": newPassword,
          "new_password_confirmation": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Password updated: ${response.body}");
        return true;
      } else {
        print("❌ Failed update: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Update password error: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    if (_currentUser != null) {
      try {
        await http.post(
          Uri.parse("${ApiConfig.baseUrl}/logout"),
          headers: {
            ...ApiConfig.headers,
            "Authorization": "Bearer ${_currentUser!.token}",
          },
        );
      } catch (e) {
        print("Logout error: $e");
      }
    }
    _currentUser = null;
  }
}