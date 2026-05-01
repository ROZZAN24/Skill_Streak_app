import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/config/database.dart';
import '../lib/routes/auth_routes.dart';
import '../lib/routes/talent_routes.dart';
import '../lib/routes/follow_request_routes.dart';
import '../lib/routes/comment_routes.dart';
import '../lib/routes/message_routes.dart';

void main() async {
  await Database.connect();

  final authRouter = AuthRoutes().router;
  final talentRouter = TalentRoutes().router;
  final followRequestRouter = FollowRequestRoutes().router;
  final commentRouter = CommentRoutes().router;
  final messageRouter = MessageRoutes().router;

  final router = Router();

  // Mount routers
  router.mount('/auth', authRouter);
  router.mount('/add-talent', talentRouter);
  router.mount('/requests', followRequestRouter);
  router.mount('/comments', commentRouter);
  router.mount('/messages', messageRouter);

  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 8080);

  print('🚀 Backend running on http://localhost:8080');
}

