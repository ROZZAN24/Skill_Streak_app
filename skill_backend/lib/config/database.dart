import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

class Database {
  static late Db db;

  static late DbCollection users;
  static late DbCollection talents;
  static late DbCollection followRequests;
  static late DbCollection comments;
  static late DbCollection messages;

  static Future<void> connect() async {
    try {

      // Force security context initialization
      SecurityContext.defaultContext;

      final uri ='mongodb://roshan:roshandb@ac-njembsk-shard-00-00.l6aj7pa.mongodb.net:27017,ac-njembsk-shard-00-01.l6aj7pa.mongodb.net:27017,ac-njembsk-shard-00-02.l6aj7pa.mongodb.net:27017/?ssl=true&replicaSet=atlas-6qrvfk-shard-0&authSource=admin&appName=Cluster0';

      db = await Db.create(uri);

      await db.open();

      users = db.collection('users');
      talents = db.collection('talents');
      followRequests = db.collection('follow_requests');
      comments = db.collection('comments');
      messages = db.collection('messages');

      print('✅ MongoDB Connected Successfully');
    } catch (e) {
      print('❌ MongoDB Connection Error: $e');
    }
  }
}