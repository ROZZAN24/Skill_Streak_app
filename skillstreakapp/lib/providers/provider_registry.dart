import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_model.dart'; // Added import for User model

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});


final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Add user provider - changed to ProviderFamily if you need to fetch by ID
final usersProvider = FutureProvider<List<User>>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getUsers();
});

// User Notifier for following/unfollowing
class UserNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final Ref ref;
  late final UserRepository _userRepository;

  UserNotifier(this.ref) : super(const AsyncValue.loading()) {
    _userRepository = ref.read(userRepositoryProvider);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userRepository.getUsers();
      state = AsyncValue.data(users);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> followUser(String userId, String targetUserId) async {
    try {
      await _userRepository.followUser(userId, targetUserId);
      // Refresh users to update follower counts
      await _loadUsers();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> unfollowUser(String userId, String targetUserId) async {
    try {
      await _userRepository.unfollowUser(userId, targetUserId);
      await _loadUsers();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

// Provider for UserNotifier
final userNotifierProvider = StateNotifierProvider<UserNotifier, AsyncValue<List<User>>>(
  (ref) => UserNotifier(ref),
);

// Additional useful providers:

// Provider for current user
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final user = await authRepository.getCurrentUser();
  return user;
});

// Provider for user by ID
final userByIdProvider = FutureProvider.family<User?, String>((ref, userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getUserById(userId);
});

// Provider for user followers
final userFollowersProvider = FutureProvider.family<List<User>, String>((ref, userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getUserFollowers(userId);
});

// Provider for user following
final userFollowingProvider = FutureProvider.family<List<User>, String>((ref, userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getUserFollowing(userId);
});