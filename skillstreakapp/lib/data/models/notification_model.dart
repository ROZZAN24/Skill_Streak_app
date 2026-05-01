enum NotificationType {
  talentApproval,
  profileView,
  message,
  achievement,
  connectionRequest,
  system,
  talentUpdate,
  opportunity,
  certificateVerified,
  talentLiked, reminder,
}

class Notification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;
  final String? talentId;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.talentId,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: _parseNotificationType(map['type']),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: map['isRead'] ?? false,
      data: map['data'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      senderAvatar: map['senderAvatar'],
      talentId: map['talentId'],
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'talentApproval':
        return NotificationType.talentApproval;
      case 'profileView':
        return NotificationType.profileView;
      case 'message':
        return NotificationType.message;
      case 'achievement':
        return NotificationType.achievement;
      case 'connectionRequest':
        return NotificationType.connectionRequest;
      case 'system':
        return NotificationType.system;
      case 'talentUpdate':
        return NotificationType.talentUpdate;
      case 'opportunity':
        return NotificationType.opportunity;
      case 'certificateVerified':
        return NotificationType.certificateVerified;
      case 'talentLiked':
        return NotificationType.talentLiked;
      default:
        return NotificationType.system;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'talentId': talentId,
    };
  }

  Notification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? talentId,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      talentId: talentId ?? this.talentId,
    );
  }
}