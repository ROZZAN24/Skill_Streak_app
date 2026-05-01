import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message_model.dart';
import '../data/repositories/message_repository.dart';

final messageRepositoryProvider = Provider((ref) => MessageRepository());

// ================= INBOX PROVIDER =================
final inboxProvider = FutureProvider.family<List<InboxSummary>, String>((ref, userId) async {
  final repo = ref.read(messageRepositoryProvider);
  return repo.getInbox(userId);
});

// ================= CHAT HISTORY PROVIDER =================
final chatHistoryProvider = StateNotifierProvider.family<ChatNotifier, AsyncValue<List<Message>>, ChatParams>((ref, params) {
  return ChatNotifier(ref.read(messageRepositoryProvider), params);
});

class ChatParams {
  final String userId;
  final String otherUserId;

  ChatParams({required this.userId, required this.otherUserId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatParams &&
        other.userId == userId &&
        other.otherUserId == otherUserId;
  }

  @override
  int get hashCode => userId.hashCode ^ otherUserId.hashCode;
}

class ChatNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final MessageRepository _repo;
  final ChatParams _params;

  ChatNotifier(this._repo, this._params) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final messages = await _repo.getChatHistory(_params.userId, _params.otherUserId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(String content) async {
    try {
      // Optimistic update
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _params.userId,
        receiverId: _params.otherUserId,
        content: content,
        timestamp: DateTime.now().toUtc(),
        isRead: false,
      );

      final currentMessages = state.asData?.value ?? [];
      state = AsyncValue.data([...currentMessages, tempMessage]);

      // Call API
      final actualMessage = await _repo.sendMessage(_params.userId, _params.otherUserId, content);
      
      // Update with actual message to fix ID
      state = AsyncValue.data([
        ...currentMessages,
        actualMessage,
      ]);
    } catch (e) {
      // Revert optimism if failed
      refresh();
      rethrow;
    }
  }
}
