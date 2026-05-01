class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['_id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class InboxSummary {
  final String partnerId;
  final String partnerName;
  final String partnerImage;
  final String latestMessage;
  final DateTime timestamp;
  final int unreadCount;

  InboxSummary({
    required this.partnerId,
    required this.partnerName,
    required this.partnerImage,
    required this.latestMessage,
    required this.timestamp,
    required this.unreadCount,
  });

  factory InboxSummary.fromMap(Map<String, dynamic> map) {
    return InboxSummary(
      partnerId: map['partnerId'] ?? '',
      partnerName: map['partnerName'] ?? 'Unknown User',
      partnerImage: map['partnerImage'] ?? '',
      latestMessage: map['latestMessage'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      unreadCount: map['unreadCount'] ?? 0,
    );
  }
}
