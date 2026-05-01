import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../config/database.dart';

class MessageRoutes {
  Router get router {
    final router = Router();

    // POST /messages/send -> send a message
    router.post('/send', _sendMessage);

    // GET /messages/history/<userId>/<otherUserId> -> get chat history
    router.get('/history/<userId>/<otherUserId>', _getHistory);

    // GET /messages/inbox/<userId> -> get latest message for all active chats
    router.get('/inbox/<userId>', _getInbox);

    return router;
  }

  // ================= SEND MESSAGE =================
  Future<Response> _sendMessage(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      
      final senderId = body['senderId'];
      final receiverId = body['receiverId'];
      final content = body['content'];

      if (senderId == null || receiverId == null || content == null || content.isEmpty) {
        return Response(400,
          body: jsonEncode({'success': false, 'message': 'Missing data'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final message = {
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'isRead': false,
      };

      final result = await Database.messages.insertOne(message);
      
      message['_id'] = (result.document?['_id'] as ObjectId?)?.toHexString() ?? '';

      return Response.ok(
        jsonEncode({'success': true, 'messageData': message}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Send message error: $e');
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= GET CHAT HISTORY =================
  Future<Response> _getHistory(Request request, String userId, String otherUserId) async {
    try {
      // Find all messages between userId and otherUserId
      final query = where
        .eq('senderId', userId).eq('receiverId', otherUserId)
        .or(where.eq('senderId', otherUserId).eq('receiverId', userId))
        .sortBy('timestamp'); // Sort ascending (oldest first)

      final messages = await Database.messages.find(query).toList();

      // Convert ObjectIds to hex strings
      final serialized = messages.map((m) {
        m['_id'] = (m['_id'] as ObjectId).toHexString();
        return m;
      }).toList();

      // Mark messages received by 'userId' from 'otherUserId' as read
      await Database.messages.updateMany(
        where.eq('senderId', otherUserId).eq('receiverId', userId).eq('isRead', false),
        modify.set('isRead', true),
      );

      return Response.ok(
        jsonEncode({'success': true, 'messages': serialized}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Get chat history error: $e');
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= GET INBOX (LATEST MESSAGES) =================
  Future<Response> _getInbox(Request request, String userId) async {
    try {
      // Find all messages involving this user
      final query = where
        .eq('senderId', userId)
        .or(where.eq('receiverId', userId))
        .sortBy('timestamp', descending: true);

      final allMessages = await Database.messages.find(query).toList();

      // We need to group messages by conversation partner
      // Map of partnerId -> ChatSummary
      Map<String, Map<String, dynamic>> inbox = {};

      for (var m in allMessages) {
        final isSender = m['senderId'] == userId;
        final partnerId = isSender ? m['receiverId'] as String : m['senderId'] as String;

        // If we haven't seen this partner yet, this is the newest message between them!
        if (!inbox.containsKey(partnerId)) {
          
          // Grab partner's basic profile details
          final partnerObjectId = ObjectId.fromHexString(partnerId);
          final partnerDoc = await Database.users.findOne(where.id(partnerObjectId));
          
          inbox[partnerId] = {
            'partnerId': partnerId,
            'partnerName': partnerDoc?['name'] ?? 'Unknown User',
            'partnerImage': partnerDoc?['profileImage'] ?? '',
            'latestMessage': m['content'],
            'timestamp': m['timestamp'],
            'unreadCount': (!isSender && m['isRead'] == false) ? 1 : 0,
          };
        } else {
          // If we already logged the latest message, we just aggregate unread counts
          if (!isSender && m['isRead'] == false) {
            inbox[partnerId]!['unreadCount'] = (inbox[partnerId]!['unreadCount'] as int) + 1;
          }
        }
      }

      // Convert map to list and sort by timestamp
      final inboxList = inbox.values.toList();
      inboxList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      return Response.ok(
        jsonEncode({'success': true, 'inbox': inboxList}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Get inbox error: $e');
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
