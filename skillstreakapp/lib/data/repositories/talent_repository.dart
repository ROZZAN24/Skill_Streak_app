import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/talent_model.dart';

class TalentRepository {
  // 🔹 Use this for Android Emulator
  static const String _baseUrl = 'https://skill-streak-app.onrender.com/';

  // 🔹 Use this instead when testing on real mobile (same WiFi)
  // static const String _baseUrl = 'http://192.168.1.100:8080';

  /* ================= ADD TALENT (Multipart) ================= */

  Future<Map<String, dynamic>> addTalent({
    required String title,
    required String description,
    required String category,
    required String level,
    required String userId,
    required String userName,
    required String userAvatar,
    required String institution,
    required List<String> tags,
    required List<Achievement> achievements,
    List<File> images = const [],
    List<Uint8List> imagesBytes = const [],
    List<File> certificates = const [],
    List<Uint8List> certificatesBytes = const [],
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/add-talent/');
      final request = http.MultipartRequest('POST', uri);

      // ── Text fields ──
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['category'] = category;
      request.fields['level'] = level;
      request.fields['userId'] = userId;
      request.fields['userName'] = userName;
      request.fields['userAvatar'] = userAvatar;
      request.fields['institution'] = institution;
      request.fields['tags'] = jsonEncode(tags);
      request.fields['achievements'] =
          jsonEncode(achievements.map((a) => a.toMap()).toList());

      // ── Image files ──
      if (kIsWeb) {
        for (int i = 0; i < imagesBytes.length; i++) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              imagesBytes[i],
              filename: 'image_$i.jpg',
            ),
          );
        }
        for (int i = 0; i < certificatesBytes.length; i++) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'certificates',
              certificatesBytes[i],
              filename: 'cert_$i.jpg',
            ),
          );
        }
      } else {
        for (int i = 0; i < images.length; i++) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              images[i].path,
              filename: 'image_$i.jpg',
            ),
          );
        }
        for (int i = 0; i < certificates.length; i++) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'certificates',
              certificates[i].path,
              filename: 'cert_$i.jpg',
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['error'] ?? data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Failed to add talent: $e');
    }
  }

  /* ================= GET ALL TALENTS ================= */

  Future<List<Talent>> getTalents() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/add-talent/'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List talentList = data['talents'] ?? [];
        return talentList
            .map((item) => Talent.fromMap(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch talents');
      }
    } catch (e) {
      throw Exception('Failed to load talents: $e');
    }
  }

  /* ================= GET TALENTS BY USER ================= */

  Future<List<Talent>> getTalentsByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/add-talent/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List talentList = data['talents'] ?? [];
        return talentList
            .map((item) => Talent.fromMap(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch user talents');
      }
    } catch (e) {
      throw Exception('Failed to load user talents: $e');
    }
  }

  /* ================= LIKE TALENT ================= */

  Future<void> likeTalent(String talentId, String userId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/add-talent/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'talentId': talentId, 'userId': userId}),
      );
    } catch (e) {
      throw Exception('Failed to like talent: $e');
    }
  }

  /* ================= UNLIKE TALENT ================= */

  Future<void> unlikeTalent(String talentId, String userId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/add-talent/unlike'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'talentId': talentId, 'userId': userId}),
      );
    } catch (e) {
      throw Exception('Failed to unlike talent: $e');
    }
  }

  /* ================= INCREMENT VIEW ================= */

  Future<void> incrementView(String talentId, String userId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/add-talent/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'talentId': talentId, 'userId': userId}),
      );
    } catch (e) {
      // silently fail — views are not critical
    }
  }

  /* ================= CHECK IF LIKED ================= */

  Future<bool> checkLiked(String talentId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/add-talent/liked/$talentId/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      return data['liked'] == true;
    } catch (e) {
      return false;
    }
  }

  /* ================= ADD COMMENT ================= */

  Future<Map<String, dynamic>> addComment({
    required String talentId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/comments/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'talentId': talentId,
          'userId': userId,
          'userName': userName,
          'userAvatar': userAvatar,
          'text': text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data['comment'];
      } else {
        throw Exception(data['message'] ?? 'Failed to add comment');
      }
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /* ================= GET COMMENTS BY TALENT ================= */

  Future<List<Map<String, dynamic>>> getCommentsByTalent(String talentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/comments/talent/$talentId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['comments'] ?? []);
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch comments');
      }
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  /* ================= DELETE COMMENT ================= */

  Future<void> deleteComment(String commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete comment');
      }
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /* ================= GET COMMENT COUNT ================= */

  Future<int> getCommentCount(String talentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/comments/count/$talentId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /* ================= DELETE TALENT ================= */

  Future<void> deleteTalent(String talentId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/add-talent/$talentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete talent');
      }
    } catch (e) {
      throw Exception('Failed to delete talent: $e');
    }
  }

  /* ================= UPDATE TALENT ================= */

  Future<void> updateTalent(
      String talentId, String userId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/add-talent/$talentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'updateData': updateData,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update talent');
      }
    } catch (e) {
      throw Exception('Failed to update talent: $e');
    }
  }
}