import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/follow_request_model.dart';

class FollowRequestRepository {
  static const String _baseUrl = 'http://localhost:8080';

  /// Send a follow request from [fromUserId] to [toUserId]
  Future<Map<String, dynamic>> sendFollowRequest({
    required String fromUserId,
    required String toUserId,
    required String fromUserName,
    String fromUserAvatar = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/requests/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'fromUserName': fromUserName,
          'fromUserAvatar': fromUserAvatar,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to send follow request');
      }
    } catch (e) {
      throw Exception('Failed to send follow request: $e');
    }
  }

  /// Get all pending follow requests received by [userId]
  Future<List<FollowRequest>> getReceivedRequests(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/requests/received/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List requestList = data['requests'] ?? [];
        return requestList
            .map((item) =>
                FollowRequest.fromMap(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch received requests');
      }
    } catch (e) {
      throw Exception('Failed to load received requests: $e');
    }
  }

  /// Get all follow requests sent by [userId]
  Future<List<FollowRequest>> getSentRequests(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/requests/sent/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List requestList = data['requests'] ?? [];
        return requestList
            .map((item) =>
                FollowRequest.fromMap(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch sent requests');
      }
    } catch (e) {
      throw Exception('Failed to load sent requests: $e');
    }
  }

  /// Accept a follow request
  Future<void> acceptRequest(String requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/requests/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requestId': requestId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to accept request');
      }
    } catch (e) {
      throw Exception('Failed to accept follow request: $e');
    }
  }

  /// Decline a follow request
  Future<void> declineRequest(String requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/requests/decline'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requestId': requestId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to decline request');
      }
    } catch (e) {
      throw Exception('Failed to decline follow request: $e');
    }
  }

  /// Get connection counts for [userId]
  Future<Map<String, int>> getConnectionCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/requests/connections/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'followers': data['followers'] ?? 0,
          'following': data['following'] ?? 0,
          'connections': data['connections'] ?? 0,
        };
      } else {
        throw Exception(data['error'] ?? 'Failed to get connection count');
      }
    } catch (e) {
      throw Exception('Failed to get connections: $e');
    }
  }

  /// Check follow request status between two users
  Future<String> getRequestStatus(
      String fromUserId, String toUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/requests/status/$fromUserId/$toUserId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['status'] ?? 'none';
      } else {
        return 'none';
      }
    } catch (e) {
      return 'none';
    }
  }
}
