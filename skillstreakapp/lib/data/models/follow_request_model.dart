class FollowRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String fromUserAvatar;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  final DateTime updatedAt;

  FollowRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    this.fromUserAvatar = '',
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FollowRequest.fromMap(Map<String, dynamic> map) {
    return FollowRequest(
      id: map['id'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      fromUserAvatar: map['fromUserAvatar'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'fromUserAvatar': fromUserAvatar,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FollowRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? fromUserName,
    String? fromUserAvatar,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FollowRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserAvatar: fromUserAvatar ?? this.fromUserAvatar,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
}
