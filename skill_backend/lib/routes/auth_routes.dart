import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_multipart/multipart.dart';

import '../config/database.dart';
import '../utils/password.dart';
import '../utils/jwt_util.dart';

class AuthRoutes {
  Router get router {
    final router = Router();

    /* ================= REGISTER ================= */

    router.post('/register', (Request request) async {
      final body = jsonDecode(await request.readAsString());

      final name = body['name'];
      final email = body['email'];
      final institution = body['institution'];
      final password = body['password'];

      if (name == null ||
          email == null ||
          institution == null ||
          password == null) {
        return _json(
          400,
          {'success': false, 'message': 'Missing fields'},
        );
      }

      final existing =
          await Database.users.findOne({'email': email});
      if (existing != null) {
        return _json(
          409,
          {'success': false, 'message': 'User already exists'},
        );
      }

      final userId = ObjectId();

      final user = {
        '_id': userId,
        'name': name,
        'email': email,
        'institution': institution,
        'password': PasswordUtil.hash(password),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

      await Database.users.insertOne(user);

      final token = JwtUtil.generate(userId.toHexString());

      return _json(
        201,
        {
          'success': true,
          'user': {
            'id': userId.toHexString(),
            'name': name,
            'email': email,
            'institution': institution,
            'joinDate': user['createdAt'],
            'profileImage': '',
          },
          'token': token,
        },
      );
    });

    /* ================= LOGIN ================= */

    router.post('/login', (Request request) async {
      final body = jsonDecode(await request.readAsString());

      final email = body['email'];
      final password = body['password'];

      if (email == null || password == null) {
        return _json(
          400,
          {'success': false, 'message': 'Missing credentials'},
        );
      }

      final user =
          await Database.users.findOne({'email': email});

      if (user == null ||
          !PasswordUtil.verify(password, user['password'])) {
        return _json(
          403,
          {'success': false, 'message': 'Invalid credentials'},
        );
      }

      final token =
          JwtUtil.generate((user['_id'] as ObjectId).toHexString());

      return _json(
        200,
        {
          'success': true,
          'user': {
            'id': (user['_id'] as ObjectId).toHexString(),
            'name': user['name'],
            'email': user['email'],
            'institution': user['institution'],
            'joinDate': user['createdAt'],
            'profileImage': user['profileImage'] ?? '',
          },
          'token': token,
        },
      );
    });

    /* ================= GET AVATAR ================= */

    router.get('/avatar/<userId>', (Request request, String userId) async {
      try {
        final objectId = ObjectId.fromHexString(userId);
        final user = await Database.users.findOne(where.id(objectId));

        if (user == null || user['avatarBytes'] == null) {
          return Response.notFound('No avatar found');
        }

        final BsonBinary binaryData = user['avatarBytes'];

        return Response.ok(
          binaryData.byteList,
          headers: {'Content-Type': 'image/jpeg'}, // Can be general image type
        );
      } catch (e) {
        return Response.internalServerError(body: 'Failed to load avatar');
      }
    });

    /* ================= UPLOAD AVATAR ================= */
    router.post('/avatar/upload', (Request request) async {
      try {
        if (!request.isMultipart) {
          return _json(400, {'success': false, 'message': 'Not a multipart request'});
        }

        final parts = await request.multipartFormData.toList();
        String? userId;
        List<int>? fileBytes;

        for (final part in parts) {
          if (part.name == 'userId') {
            userId = await part.part.readString();
          } else if (part.name == 'image') {
            fileBytes = await part.part.readBytes();
          }
        }

        if (userId == null || fileBytes == null || fileBytes.isEmpty) {
          return _json(400, {'success': false, 'message': 'Missing userId or image data'});
        }

        final objectId = ObjectId.fromHexString(userId);
        final bsonBinary = BsonBinary.from(fileBytes);
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final avatarUrl = '${request.requestedUri.scheme}://${request.requestedUri.authority}/auth/avatar/$userId?t=$timestamp';

        await Database.users.updateOne(
          where.id(objectId),
          modify
              .set('avatarBytes', bsonBinary)
              .set('profileImage', avatarUrl),
        );

        return _json(200, {
          'success': true,
          'message': 'Avatar uploaded successfully',
          'profileImage': avatarUrl,
        });
      } catch (e) {
        print('Avatar upload error: $e');
        return _json(500, {'success': false, 'message': 'Upload failed: $e'});
      }
    });

    /* ================= UPDATE PROFILE ================= */

    router.put('/profile', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString());
        final userId = body['id'];

        if (userId == null) {
          return _json(400, {'success': false, 'message': 'User ID missing'});
        }

        final objectId = ObjectId.fromHexString(userId);
        
        // Fields that are allowed to be updated via this route
        final allowedFields = ['name', 'institution', 'bio', 'skills', 'interests'];
        final modifier = modify;
        bool hasUpdate = false;

        for (var field in allowedFields) {
          if (body[field] != null) {
            modifier.set(field, body[field]);
            hasUpdate = true;
          }
        }

        if (!hasUpdate) {
          return _json(400, {'success': false, 'message': 'No fields to update'});
        }

        await Database.users.updateOne(
          where.id(objectId),
          modifier,
        );

        final updatedUser = await Database.users.findOne(where.id(objectId));

        return _json(200, {
          'success': true,
          'message': 'Profile updated successfully',
          'user': {
            'id': (updatedUser!['_id'] as ObjectId).toHexString(),
            'name': updatedUser['name'],
            'email': updatedUser['email'],
            'institution': updatedUser['institution'],
            'bio': updatedUser['bio'] ?? '',
            'skills': updatedUser['skills'] ?? [],
            'interests': updatedUser['interests'] ?? [],
            'joinDate': updatedUser['createdAt'],
            'profileImage': updatedUser['profileImage'] ?? '',
          },
        });
      } catch (e) {
        print('Profile update error: $e');
        return _json(500, {'success': false, 'message': 'Failed to update profile: $e'});
      }
    });

    return router;
  }

  /* ================= JSON HELPER ================= */

  Response _json(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
