import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';

final notificationsProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<Notification>>>(
  (ref) => NotificationNotifier(ref),
);

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  
  return notifications.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<Notification>>> {
  final Ref ref;
  late final NotificationRepository _notificationRepository;

  NotificationNotifier(this.ref) : super(const AsyncValue.loading()) {
    _notificationRepository = ref.read(notificationRepositoryProvider);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationRepository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      final currentNotifications = state.value ?? [];
      final index = currentNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = currentNotifications[index];
        final newNotifications = List<Notification>.from(currentNotifications);
        newNotifications[index] = notification.copyWith(isRead: true);
        state = AsyncValue.data(newNotifications);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationRepository.markAllAsRead();
      final currentNotifications = state.value ?? [];
      final newNotifications = currentNotifications.map((n) => n.copyWith(isRead: true)).toList();
      state = AsyncValue.data(newNotifications);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationRepository.deleteNotification(notificationId);
      final currentNotifications = state.value ?? [];
      final newNotifications = currentNotifications.where((n) => n.id != notificationId).toList();
      state = AsyncValue.data(newNotifications);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _notificationRepository.clearAllNotifications();
      state = const AsyncValue.data([]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationRepository {
  Future<List<Notification>> getNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    // In real app, fetch from API
    return [];
  }

  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> deleteNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> clearAllNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}