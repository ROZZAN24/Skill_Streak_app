import 'package:mongo_dart/mongo_dart.dart';

class Database {
  static late Db db;
  static late DbCollection users;
  static late DbCollection talents;
  static late DbCollection followRequests;
  static late DbCollection comments;
  static late DbCollection messages;

  static Future<void> connect() async {
    db = await Db.create('mongodb://host.docker.internal:27017/skillstreak');
    await db.open();
    users = db.collection('users');
    talents = db.collection('talents');
    followRequests = db.collection('follow_requests');
    comments = db.collection('comments');
    messages = db.collection('messages');
    print('✅ MongoDB Connected');
  }
}
