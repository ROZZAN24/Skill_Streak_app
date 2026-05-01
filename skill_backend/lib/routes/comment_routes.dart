import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config/database.dart';

class CommentRoutes {
  Router get router {
    final router = Router();

    // POST /comments/add → add a comment
    router.post('/add', _addComment);

    // GET /comments/talent/<talentId> → get comments for a talent
    router.get('/talent/<talentId>', _getCommentsByTalent);

    // DELETE /comments/<commentId> → delete a comment
    router.delete('/<commentId>', _deleteComment);

    // GET /comments/count/<talentId> → get comment count
    router.get('/count/<talentId>', _getCommentCount);

    return router;
  }

  // ================= ADD COMMENT =================
  Future<Response> _addComment(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final talentId = body['talentId'];
      final userId = body['userId'];
      final userName = body['userName'];
      final userAvatar = body['userAvatar'] ?? '';
      final text = body['text'];

      if (talentId == null || userId == null || userName == null || text == null) {
        return _json(400, {
          'success': false,
          'message': 'Missing required fields (talentId, userId, userName, text)',
        });
      }

      if (text.toString().trim().isEmpty) {
        return _json(400, {
          'success': false,
          'message': 'Comment text cannot be empty',
        });
      }

      final commentId = ObjectId();
      final now = DateTime.now().toUtc().toIso8601String();

      final doc = {
        '_id': commentId,
        'talentId': talentId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'text': text.toString().trim(),
        'createdAt': now,
      };

      await Database.comments.insertOne(doc);

      print('💬 Comment added by $userName on talent $talentId');

      return _json(201, {
        'success': true,
        'message': 'Comment added',
        'comment': {
          'id': commentId.toHexString(),
          'talentId': talentId,
          'userId': userId,
          'userName': userName,
          'userAvatar': userAvatar,
          'text': text.toString().trim(),
          'createdAt': now,
        },
      });
    } catch (e) {
      print('❌ Add comment error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= GET COMMENTS BY TALENT =================
  Future<Response> _getCommentsByTalent(Request request, String talentId) async {
    try {
      final docs = await Database.comments
          .find(where.eq('talentId', talentId).sortBy('createdAt', descending: true))
          .toList();

      final comments = docs.map((doc) {
        final map = Map<String, dynamic>.from(doc);
        if (map['_id'] is ObjectId) {
          map['id'] = (map['_id'] as ObjectId).toHexString();
        }
        map.remove('_id');
        return map;
      }).toList();

      return _json(200, {
        'success': true,
        'comments': comments,
        'count': comments.length,
      });
    } catch (e) {
      print('❌ Get comments error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= DELETE COMMENT =================
  Future<Response> _deleteComment(Request request, String commentId) async {
    try {
      final objectId = ObjectId.fromHexString(commentId);

      final result = await Database.comments.deleteOne(where.id(objectId));

      if (result.nRemoved == 0) {
        return _json(404, {
          'success': false,
          'message': 'Comment not found',
        });
      }

      print('🗑️ Comment $commentId deleted');

      return _json(200, {
        'success': true,
        'message': 'Comment deleted',
      });
    } catch (e) {
      print('❌ Delete comment error: $e');
      return _json(500, {'success': false, 'error': e.toString()});
    }
  }

  // ================= GET COMMENT COUNT =================
  Future<Response> _getCommentCount(Request request, String talentId) async {
    try {
      final count = await Database.comments
          .count(where.eq('talentId', talentId));

      return _json(200, {
        'success': true,
        'count': count,
      });
    } catch (e) {
      print('❌ Get comment count error: $e');
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
