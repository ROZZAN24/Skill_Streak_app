import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/comment_model.dart';
import '../data/repositories/talent_repository.dart';
import 'talent_provider.dart';

// ═══════════════ COMMENTS PROVIDER (per talent) ═══════════════
final commentsProvider = StateNotifierProvider.family<
    CommentsNotifier, AsyncValue<List<Comment>>, String>((ref, talentId) {
  return CommentsNotifier(ref, talentId);
});

class CommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  final Ref ref;
  final String talentId;
  late final TalentRepository _repo;

  CommentsNotifier(this.ref, this.talentId)
      : super(const AsyncValue.loading()) {
    _repo = ref.read(talentRepositoryProvider);
    loadComments();
  }

  Future<void> loadComments() async {
    try {
      state = const AsyncValue.loading();
      final rawComments = await _repo.getCommentsByTalent(talentId);
      final comments =
          rawComments.map((map) => Comment.fromMap(map)).toList();
      state = AsyncValue.data(comments);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addComment({
    required String userId,
    required String userName,
    required String userAvatar,
    required String text,
  }) async {
    try {
      final rawComment = await _repo.addComment(
        talentId: talentId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        text: text,
      );

      final comment = Comment.fromMap(rawComment);
      final current = state.value ?? [];
      state = AsyncValue.data([comment, ...current]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _repo.deleteComment(commentId);
      final current = state.value ?? [];
      state =
          AsyncValue.data(current.where((c) => c.id != commentId).toList());
    } catch (e) {
      rethrow;
    }
  }
}

// ═══════════════ LIKE STATUS PROVIDER ═══════════════
final likeStatusProvider = FutureProvider.family<bool,
    ({String talentId, String userId})>((ref, params) async {
  final repo = ref.read(talentRepositoryProvider);
  return await repo.checkLiked(params.talentId, params.userId);
});

// ═══════════════ COMMENT COUNT PROVIDER ═══════════════
final commentCountProvider =
    FutureProvider.family<int, String>((ref, talentId) async {
  final repo = ref.read(talentRepositoryProvider);
  return await repo.getCommentCount(talentId);
});
