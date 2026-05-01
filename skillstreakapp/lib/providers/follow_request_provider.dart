import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/follow_request_model.dart';
import '../data/repositories/follow_request_repository.dart';

// ═══════════════════ REPOSITORY PROVIDER ═══════════════════
final followRequestRepositoryProvider =
    Provider<FollowRequestRepository>((ref) {
  return FollowRequestRepository();
});

// ═══════════════════ RECEIVED REQUESTS PROVIDER ═══════════════════
final receivedRequestsProvider = StateNotifierProvider.family<
    ReceivedRequestsNotifier,
    AsyncValue<List<FollowRequest>>,
    String>((ref, userId) {
  return ReceivedRequestsNotifier(ref, userId);
});

class ReceivedRequestsNotifier
    extends StateNotifier<AsyncValue<List<FollowRequest>>> {
  final Ref ref;
  final String userId;
  late final FollowRequestRepository _repo;

  ReceivedRequestsNotifier(this.ref, this.userId)
      : super(const AsyncValue.loading()) {
    _repo = ref.read(followRequestRepositoryProvider);
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      state = const AsyncValue.loading();
      final requests = await _repo.getReceivedRequests(userId);
      state = AsyncValue.data(requests);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _repo.acceptRequest(requestId);
      // Remove from list after accepting
      final current = state.value ?? [];
      state = AsyncValue.data(
          current.where((r) => r.id != requestId).toList());
      // Refresh connection counts
      ref.invalidate(connectionCountProvider(userId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      await _repo.declineRequest(requestId);
      // Remove from list after declining
      final current = state.value ?? [];
      state = AsyncValue.data(
          current.where((r) => r.id != requestId).toList());
    } catch (e) {
      rethrow;
    }
  }
}

// ═══════════════════ SENT REQUESTS PROVIDER ═══════════════════
final sentRequestsProvider = StateNotifierProvider.family<
    SentRequestsNotifier,
    AsyncValue<List<FollowRequest>>,
    String>((ref, userId) {
  return SentRequestsNotifier(ref, userId);
});

class SentRequestsNotifier
    extends StateNotifier<AsyncValue<List<FollowRequest>>> {
  final Ref ref;
  final String userId;
  late final FollowRequestRepository _repo;

  SentRequestsNotifier(this.ref, this.userId)
      : super(const AsyncValue.loading()) {
    _repo = ref.read(followRequestRepositoryProvider);
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      state = const AsyncValue.loading();
      final requests = await _repo.getSentRequests(userId);
      state = AsyncValue.data(requests);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// ═══════════════════ CONNECTION COUNT PROVIDER ═══════════════════
final connectionCountProvider =
    FutureProvider.family<Map<String, int>, String>((ref, userId) async {
  final repo = ref.read(followRequestRepositoryProvider);
  return await repo.getConnectionCount(userId);
});

// ═══════════════════ FOLLOW STATUS PROVIDER ═══════════════════
// Checks the request status between current user and target user
final followStatusProvider =
    FutureProvider.family<String, ({String fromUserId, String toUserId})>(
        (ref, params) async {
  final repo = ref.read(followRequestRepositoryProvider);
  return await repo.getRequestStatus(params.fromUserId, params.toUserId);
});

// ═══════════════════ SEND REQUEST ACTION ═══════════════════
final sendFollowRequestProvider = Provider<FollowRequestRepository>((ref) {
  return ref.read(followRequestRepositoryProvider);
});
