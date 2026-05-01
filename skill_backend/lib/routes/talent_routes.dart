import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/form_data.dart';

import '../config/database.dart';

import 'package:shelf_router/shelf_router.dart';

class TalentRoutes {
  Router get router {
    final router = Router(notFoundHandler: (Request request) {
      print('🚩 TalentRoutes 404: ${request.method} ${request.url.path}');
      return Response.notFound(
        jsonEncode({'success': false, 'message': 'Route Not Found in TalentRoutes'}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // GET /add-talent/ → get all talents
    router.get('/', _getAllTalents);

    // POST /add-talent/ → add a new talent (multipart)
    router.post('/', _addTalent);

    // GET /add-talent/user/<userId> → get talents by user
    router.get('/user/<userId>', _getTalentsByUser);

    // GET /add-talent/detail/<talentId> → get single talent
    router.get('/detail/<talentId>', _getTalentById);

    // POST /add-talent/like → like a talent
    router.post('/like', _likeTalent);

    // POST /add-talent/unlike → unlike a talent
    router.post('/unlike', _unlikeTalent);

    // POST /add-talent/view → increment view count
    router.post('/view', _incrementView);

    // GET /add-talent/liked/<talentId>/<userId> → check if user liked
    router.get('/liked/<talentId>/<userId>', _checkLiked);

    // DELETE /add-talent/<talentId> → delete post
    router.delete('/<talentId>', _deleteTalent);

    // PUT /add-talent/<talentId> → update post
    router.put('/<talentId>', _updateTalent);

    return router;
  }

  // ================= ADD TALENT =================
  Future<Response> _addTalent(Request request) async {
    try {
      // Read multipart form data
      final parts = await request.multipartFormData.toList();

      Map<String, dynamic> data = {};
      List<String> imageUrls = [];
      List<String> certificateUrls = [];

      for (final part in parts) {

        // ============ IMAGE / CERTIFICATE FILES ============
        if (part.filename != null) {
          final bytes = await part.part.readBytes();

          // Store image as base64 data URI in MongoDB directly
          // (No external service needed)
          final base64Str = base64Encode(bytes);
          final mimeType = _getMimeType(part.filename!);
          final dataUri = 'data:$mimeType;base64,$base64Str';

          if (part.name == 'certificates') {
            certificateUrls.add(dataUri);
          } else {
            imageUrls.add(dataUri);
          }

          print('📷 Stored ${part.name} "${part.filename}" (${bytes.length} bytes) as base64');
        }

        // ============ TEXT FIELDS ============
        else {
          final value = await part.part.readString();

          // Handle JSON arrays sent as strings
          if (part.name == 'tags' || part.name == 'achievements') {
            try {
              data[part.name] = jsonDecode(value);
            } catch (_) {
              data[part.name] = value;
            }
          } else {
            data[part.name] = value;
          }
        }
      }

      // Add file URLs and metadata
      data['images'] = imageUrls;
      data['certificates'] = certificateUrls;
      data['dateAdded'] = DateTime.now().toUtc().toIso8601String();
      data['views'] = 0;
      data['viewedBy'] = [];
      data['likes'] = 0;
      data['isVerified'] = false;
      data['rating'] = 0.0;

      // Save in MongoDB
      final result = await Database.talents.insertOne(data);

      final insertedId = result.document?['_id'];

      print('✅ Talent saved to MongoDB (images: ${imageUrls.length}, certs: ${certificateUrls.length})');

      return Response.ok(
        jsonEncode({
          "success": true,
          "message": "Talent uploaded successfully",
          "talentId": insertedId is ObjectId
              ? insertedId.toHexString()
              : insertedId?.toString() ?? '',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

    } catch (e) {
      print('❌ Add talent error: $e');
      return Response.internalServerError(
        body: jsonEncode({
          "success": false,
          "error": e.toString(),
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );
    }
  }

  // ================= GET ALL TALENTS =================
  Future<Response> _getAllTalents(Request request) async {
    try {
      final talents = await Database.talents.find().toList();

      // Convert ObjectId to string for JSON serialization
      final talentList = talents.map((doc) {
        final map = Map<String, dynamic>.from(doc);
        if (map['_id'] is ObjectId) {
          map['id'] = (map['_id'] as ObjectId).toHexString();
        }
        map.remove('_id');
        return map;
      }).toList();

      return Response.ok(
        jsonEncode({
          'success': true,
          'talents': talentList,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Get talents error: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= GET TALENTS BY USER =================
  Future<Response> _getTalentsByUser(Request request, String userId) async {
    try {
      final talents = await Database.talents
          .find(where.eq('userId', userId))
          .toList();

      final talentList = talents.map((doc) {
        final map = Map<String, dynamic>.from(doc);
        if (map['_id'] is ObjectId) {
          map['id'] = (map['_id'] as ObjectId).toHexString();
        }
        map.remove('_id');
        return map;
      }).toList();

      return Response.ok(
        jsonEncode({
          'success': true,
          'talents': talentList,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Get user talents error: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= MIME TYPE HELPER =================
  String _getMimeType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  // ================= GET SINGLE TALENT =================
  Future<Response> _getTalentById(Request request, String talentId) async {
    try {
      final objectId = ObjectId.fromHexString(talentId);
      final doc = await Database.talents.findOne(where.id(objectId));

      if (doc == null) {
        return Response.notFound(
          jsonEncode({'success': false, 'message': 'Talent not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final map = Map<String, dynamic>.from(doc);
      if (map['_id'] is ObjectId) {
        map['id'] = (map['_id'] as ObjectId).toHexString();
      }
      map.remove('_id');

      return Response.ok(
        jsonEncode({'success': true, 'talent': map}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Get talent by ID error: $e');
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= LIKE TALENT =================
  Future<Response> _likeTalent(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final talentId = body['talentId'];
      final userId = body['userId'];

      if (talentId == null || userId == null) {
        return Response(400,
          body: jsonEncode({'success': false, 'message': 'Missing talentId or userId'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final objectId = ObjectId.fromHexString(talentId);

      // Add userId to likedBy array and increment likes
      await Database.talents.updateOne(
        where.id(objectId),
        modify
            .addToSet('likedBy', userId)
            .inc('likes', 1),
      );

      print('👍 Talent $talentId liked by $userId');

      return Response.ok(
        jsonEncode({'success': true, 'message': 'Talent liked'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Like talent error: $e');
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= UNLIKE TALENT =================
  Future<Response> _unlikeTalent(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final talentId = body['talentId'];
      final userId = body['userId'];

      if (talentId == null || userId == null) {
        return Response(400,
          body: jsonEncode({'success': false, 'message': 'Missing talentId or userId'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final objectId = ObjectId.fromHexString(talentId);

      // Remove userId from likedBy array and decrement likes
      await Database.talents.updateOne(
        where.id(objectId),
        modify
            .pull('likedBy', userId)
            .inc('likes', -1),
      );

      print('👎 Talent $talentId unliked by $userId');

      return Response.ok(
        jsonEncode({'success': true, 'message': 'Talent unliked'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Unlike talent error: $e');
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= INCREMENT VIEW =================
  Future<Response> _incrementView(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final talentId = body['talentId'];
      final userId = body['userId'];

      if (talentId == null || userId == null) {
        return Response(400,
          body: jsonEncode({'success': false, 'message': 'Missing talentId or userId'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final objectId = ObjectId.fromHexString(talentId);

      // Only increment if the userId is not already in the viewedBy array
      await Database.talents.updateOne(
        where.id(objectId).ne('viewedBy', userId),
        modify.addToSet('viewedBy', userId).inc('views', 1),
      );

      return Response.ok(
        jsonEncode({'success': true, 'message': 'View processed'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Increment view error: $e');
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= CHECK IF LIKED =================
  Future<Response> _checkLiked(Request request, String talentId, String userId) async {
    try {
      final objectId = ObjectId.fromHexString(talentId);
      final doc = await Database.talents.findOne(
        where.id(objectId).eq('likedBy', userId),
      );

      return Response.ok(
        jsonEncode({
          'success': true,
          'liked': doc != null,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Check liked error: $e');
      return Response.ok(
        jsonEncode({'success': true, 'liked': false}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= DELETE TALENT =================
  Future<Response> _deleteTalent(Request request, String talentId) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final userId = body['userId'];

      if (userId == null) {
        return Response(400,
            body: jsonEncode({'success': false, 'message': 'User ID required'}),
            headers: {'Content-Type': 'application/json'});
      }

      final objectId = ObjectId.fromHexString(talentId);
      final talent = await Database.talents.findOne(where.id(objectId));

      if (talent == null) {
        return Response(404,
            body: jsonEncode({'success': false, 'message': 'Talent not found'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Check if the user is the owner
      if (talent['userId'] != userId) {
        return Response(403,
            body: jsonEncode({'success': false, 'message': 'Unauthorized'}),
            headers: {'Content-Type': 'application/json'});
      }

      await Database.talents.deleteOne(where.id(objectId));

      return Response.ok(
        jsonEncode({'success': true, 'message': 'Talent deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Delete talent error: $e');
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ================= UPDATE TALENT =================
  Future<Response> _updateTalent(Request request, String talentId) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final userId = body['userId'];
      final updateData = body['updateData'];

      if (userId == null || updateData == null) {
        return Response(400,
            body: jsonEncode({'success': false, 'message': 'User ID and update data required'}),
            headers: {'Content-Type': 'application/json'});
      }

      final objectId = ObjectId.fromHexString(talentId);
      final talent = await Database.talents.findOne(where.id(objectId));

      if (talent == null) {
        return Response(404,
            body: jsonEncode({'success': false, 'message': 'Talent not found'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Check if the user is the owner
      if (talent['userId'] != userId) {
        return Response(403,
            body: jsonEncode({'success': false, 'message': 'Unauthorized'}),
            headers: {'Content-Type': 'application/json'});
      }

      // Predefined fields to update
      final allowedFields = [
        'title',
        'description',
        'category',
        'level',
        'tags',
        'images',
        'certificates'
      ];
      final modifier = modify;
      bool hasUpdate = false;

      for (var field in allowedFields) {
        if (updateData[field] != null) {
          modifier.set(field, updateData[field]);
          hasUpdate = true;
        }
      }

      if (hasUpdate) {
        await Database.talents.updateOne(where.id(objectId), modifier);
      }

      return Response.ok(
        jsonEncode({'success': true, 'message': 'Talent updated successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Update talent error: $e');
      return Response.internalServerError(
        body: jsonEncode({'success': false, 'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
