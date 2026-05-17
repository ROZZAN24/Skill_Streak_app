import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthRepository {
  // 🔹 Use this for Android Emulator
  static const String _baseUrl = 'https://skill-streak-app.onrender.com';

  // 🔹 Use this instead when testing on real mobile (same WiFi)
  // static const String _baseUrl = 'http://192.168.1.100:8080';

  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  /* ================= CURRENT USER ================= */

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson == null) return null;

    return User.fromMap(jsonDecode(userJson));
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /* ================= LOGIN ================= */

  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = User.fromMap(data['user']);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toMap()));
        await prefs.setString(_tokenKey, token);

        return user;
      } else {
        throw Exception(data['message'] ?? 'Invalid email or password');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /* ================= REGISTER ================= */

  Future<User> register(User user, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': user.name,
          'email': user.email,
          'institution': user.institution,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final newUser = User.fromMap(data['user']);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(newUser.toMap()));
        await prefs.setString(_tokenKey, token);

        return newUser;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  /* ================= UPDATE PROFILE ================= */

  Future<User> updateProfile(User user) async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('Unauthorized: Token missing');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(user.toMap()),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final updatedUser = User.fromMap(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(updatedUser.toMap()));

      return updatedUser;
    } else {
      throw Exception(data['message'] ?? 'Profile update failed');
    }
  }

  /* ================= CHANGE PASSWORD ================= */

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('Unauthorized: Token missing');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Password change failed');
    }
  }

  /* ================= UPLOAD PROFILE IMAGE ================= */

  Future<User> uploadProfileImage(List<int> imageBytes, String filename, String userId) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/auth/avatar/upload'),
      );
      
      request.fields['userId'] = userId;
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // We only receive the new URL, so let's patch the local user
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(
            profileImage: data['profileImage'],
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(updatedUser.toMap()));
          return updatedUser;
        } else {
          throw Exception('Local user not found');
        }
      } else {
        throw Exception(data['message'] ?? 'Avatar upload failed');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  /* ================= LOGOUT ================= */

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }
}
