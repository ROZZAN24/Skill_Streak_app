import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config/database.dart';

class FollowRequestRoutes {
  Router get router {
    final router = Router();

    // POST /requests/send → send a follow request
    router.post('/send', _sendRequest);

    // GET /requests/received/<userId> → get pending incoming requests
    router.get('/received/<userId>', _getReceivedRequests);

    // GET /requests/sent/<userId> → get requests sent by user
    router.get('/sent/<userId>', _getSentRequests);

    // POST /requests/accept → accept a follow request
    router.post('/accept', _acceptRequest);

    // POST /requests/decline → decline a follow request
    router.post('/decline', _declineRequest);

    // GET /requests/connections/<userId> → get connection count
    router.get('/connections/<userId>', _getConnectionCount);

    // GET /requests/status/<fromUserId>/<toUserId> → check request status
    router.get('/status/<fromUserId>/<toUserId>', _getRequestStatus);

    return router;
  }

  // ================= SEND FOLLOW REQUEST =================
  Future<Response> _sendRequest(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final fromUserId = body['fromUserId'];
      final toUserId = body['toUserId'];
      final fromUserName = body['fromUserName'];
      final fromUserAvatar = body['fromUserAvatar'] ?? '';

      if (fromUserId == null || toUserId == null || fromUserName == null) {
        return _json(400, {
          'success': false,
          'message': 'Missing required fields (fromUserId, toUserId, fromUserName)',
        });
      }

      // Can't follow yourself
      if (fromUserId == toUserId) {
        return _json(400, {
          'success': false,
          'message': 'Cannot send follow request to yourself',
        });
      }

      // Check for existing pending request
      final existing = await Database.followRequests.findOne(
        where
            .eq('fromUserId', fromUserId)
            .eq('toUserId', toUserId)
            .eq('status', 'pending'),
      );

      if (existing != null) {
        return _json(409, {
          'success': false,
          'message': 'Follow request already sent',
        });
      }

      // Check if already connected (accepted request exists)
      final alreadyConnected = await Database.followRequests.findOne(
        where
            .eq('fromUserId', fromUserId)
            .eq('toUserId', toUserId)
            .eq('status', 'accepted'),
      );

      if (alreadyConnected != null) {
        return _json(409, {
          'success': false,
          'message': 'Already connected',
        });
      }

      final requestId = ObjectId();
      final now = DateTime.now().toUtc().toIso8601String();

      final doc = {
        '_id': requestId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromUserName,
        'fromUserAvatar': fromUserAvatar,
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      };

      await Database.followRequests.insertOne(doc);

      print('✅ Follow request sent: $fromUserName → $toUserId');

      return _json(201, {
        'success': true,
        'message': 'Follow request sent',
        'requestId': requestId.toHexString(),
      });
    } catch (e) {
      print('❌ Send follow request error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= GET RECEIVED REQUESTS =================
  Future<Response> _getReceivedRequests(Request request, String userId) async {
    try {
      final docs = await Database.followRequests
          .find(where.eq('toUserId', userId).eq('status', 'pending'))
          .toList();

      final requests = docs.map((doc) {
        final map = Map<String, dynamic>.from(doc);
        if (map['_id'] is ObjectId) {
          map['id'] = (map['_id'] as ObjectId).toHexString();
        }
        map.remove('_id');
        return map;
      }).toList();

      return _json(200, {
        'success': true,
        'requests': requests,
      });
    } catch (e) {
      print('❌ Get received requests error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= GET SENT REQUESTS =================
  Future<Response> _getSentRequests(Request request, String userId) async {
    try {
      final docs = await Database.followRequests
          .find(where.eq('fromUserId', userId))
          .toList();

      final requests = docs.map((doc) {
        final map = Map<String, dynamic>.from(doc);
        if (map['_id'] is ObjectId) {
          map['id'] = (map['_id'] as ObjectId).toHexString();
        }
        map.remove('_id');
        return map;
      }).toList();

      return _json(200, {
        'success': true,
        'requests': requests,
      });
    } catch (e) {
      print('❌ Get sent requests error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= ACCEPT REQUEST =================
  Future<Response> _acceptRequest(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final requestId = body['requestId'];

      if (requestId == null) {
        return _json(400, {
          'success': false,
          'message': 'Missing requestId',
        });
      }

      final objectId = ObjectId.fromHexString(requestId);
      final now = DateTime.now().toUtc().toIso8601String();

      final result = await Database.followRequests.updateOne(
        where.id(objectId).eq('status', 'pending'),
        modify.set('status', 'accepted').set('updatedAt', now),
      );

      if (result.nModified == 0) {
        return _json(404, {
          'success': false,
          'message': 'Request not found or already processed',
        });
      }

      // Get the request to know fromUserId → now follows toUserId
      final doc = await Database.followRequests.findOne(where.id(objectId));
      if (doc != null) {
        final fromUserId = doc['fromUserId'];
        final toUserId = doc['toUserId'];
        print('✅ Follow request accepted: $fromUserId now follows $toUserId');
      }

      return _json(200, {
        'success': true,
        'message': 'Follow request accepted',
      });
    } catch (e) {
      print('❌ Accept request error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= DECLINE REQUEST =================
  Future<Response> _declineRequest(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final requestId = body['requestId'];

      if (requestId == null) {
        return _json(400, {
          'success': false,
          'message': 'Missing requestId',
        });
      }

      final objectId = ObjectId.fromHexString(requestId);
      final now = DateTime.now().toUtc().toIso8601String();

      final result = await Database.followRequests.updateOne(
        where.id(objectId).eq('status', 'pending'),
        modify.set('status', 'declined').set('updatedAt', now),
      );

      if (result.nModified == 0) {
        return _json(404, {
          'success': false,
          'message': 'Request not found or already processed',
        });
      }

      print('✅ Follow request declined');

      return _json(200, {
        'success': true,
        'message': 'Follow request declined',
      });
    } catch (e) {
      print('❌ Decline request error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= GET CONNECTION COUNT =================
  // Connections = people who follow you (accepted requests TO you)
  //             + people you follow (accepted requests FROM you)
  Future<Response> _getConnectionCount(Request request, String userId) async {
    try {
      // People following this user (accepted requests TO this user)
      final followers = await Database.followRequests
          .find(where.eq('toUserId', userId).eq('status', 'accepted'))
          .toList();

      // People this user follows (accepted requests FROM this user)
      final following = await Database.followRequests
          .find(where.eq('fromUserId', userId).eq('status', 'accepted'))
          .toList();

      return _json(200, {
        'success': true,
        'followers': followers.length,
        'following': following.length,
        'connections': followers.length + following.length,
      });
    } catch (e) {
      print('❌ Get connection count error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= CHECK REQUEST STATUS =================
  Future<Response> _getRequestStatus(
      Request request, String fromUserId, String toUserId) async {
    try {
      // Check if fromUser sent a request to toUser
      final sent = await Database.followRequests.findOne(
        where.eq('fromUserId', fromUserId).eq('toUserId', toUserId),
      );

      // Check if toUser sent a request to fromUser
      final received = await Database.followRequests.findOne(
        where.eq('fromUserId', toUserId).eq('toUserId', fromUserId),
      );

      String status = 'none'; // no request exists
      if (sent != null) {
        status = 'sent_${sent['status']}'; // e.g. sent_pending, sent_accepted
      } else if (received != null) {
        status = 'received_${received['status']}';
      }

      return _json(200, {
        'success': true,
        'status': status,
      });
    } catch (e) {
      print('❌ Get request status error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= JSON HELPER =================
  Response _json(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
