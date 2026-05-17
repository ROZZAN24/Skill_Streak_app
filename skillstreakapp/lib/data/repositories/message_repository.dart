import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class MessageRepository {
  // 🔹 Use this for Android Emulator
  static const String _baseUrl = 'https://skill-streak-app.onrender.com/messages';

  // ================= GET INBOX =================
  Future<List<InboxSummary>> getInbox(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/inbox/$userId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List inboxLogs = data['inbox'];
          return inboxLogs.map((e) => InboxSummary.fromMap(e)).toList();
        }
      }
      throw Exception('Failed to load inbox');
    } catch (e) {
      throw Exception('Inbox Error: $e');
    }
  }

  // ================= GET CHAT HISTORY =================
  Future<List<Message>> getChatHistory(String userId, String otherUserId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/history/$userId/$otherUserId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List history = data['messages'];
          return history.map((e) => Message.fromMap(e)).toList();
        }
      }
      throw Exception('Failed to load chat history');
    } catch (e) {
      throw Exception('History Error: $e');
    }
  }

  // ================= SEND MESSAGE =================
  Future<Message> sendMessage(String senderId, String receiverId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Message.fromMap(data['messageData']);
      } else {
        throw Exception(data['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception('Send Error: $e');
    }
  }
}
