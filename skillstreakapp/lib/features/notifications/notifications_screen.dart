import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_request_provider.dart';
import '../../data/models/notification_model.dart' as model;
import '../../data/models/follow_request_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState.value;
    final userId = currentUser?.id ?? '';

    final receivedAsync = userId.isNotEmpty
        ? ref.watch(receivedRequestsProvider(userId))
        : const AsyncValue<List<FollowRequest>>.data([]);

    // Count pending follow requests
    final pendingCount = receivedAsync.maybeWhen(
      data: (requests) => requests.length,
      orElse: () => 0,
    );

    // Count unread notifications
    int unreadCount = notificationsAsync.maybeWhen(
      data: (notifications) => notifications.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: Badge(
                label: Text(unreadCount.toString()),
                child: const Icon(Icons.mark_email_read),
              ),
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read') {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              } else if (value == 'clear_all') {
                _showClearAllDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear all notifications'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            const Tab(text: 'Notifications'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Follow Requests'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Regular Notifications ──
          _buildNotificationsTab(notificationsAsync),

          // ── Tab 2: Follow Requests ──
          _buildFollowRequestsTab(receivedAsync, userId),
        ],
      ),
    );
  }

  // ═══════════════ NOTIFICATIONS TAB ═══════════════
  Widget _buildNotificationsTab(
      AsyncValue<List<model.Notification>> notificationsAsync) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(notificationsProvider);
      },
      child: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text('No Notifications',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600])),
                  const SizedBox(height: 10),
                  Text("You're all caught up!",
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref
                      .read(notificationsProvider.notifier)
                      .deleteNotification(notification.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification removed')),
                  );
                },
                child: _buildNotificationItem(notification),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error loading notifications',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(notificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════ FOLLOW REQUESTS TAB ═══════════════
  Widget _buildFollowRequestsTab(
      AsyncValue<List<FollowRequest>> receivedAsync, String userId) {
    return RefreshIndicator(
      onRefresh: () async {
        if (userId.isNotEmpty) {
          ref.read(receivedRequestsProvider(userId).notifier).loadRequests();
        }
      },
      child: receivedAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text('No Follow Requests',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600])),
                  const SizedBox(height: 10),
                  Text('When someone sends you a follow request,\nit will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return _buildFollowRequestCard(req, userId);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error loading requests',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (userId.isNotEmpty) {
                    ref
                        .read(receivedRequestsProvider(userId).notifier)
                        .loadRequests();
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════ FOLLOW REQUEST CARD ═══════════════
  Widget _buildFollowRequestCard(FollowRequest req, String userId) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.teal[100],
              backgroundImage: req.fromUserAvatar.isNotEmpty
                  ? NetworkImage(req.fromUserAvatar)
                  : null,
              child: req.fromUserAvatar.isEmpty
                  ? Text(
                      req.fromUserName.isNotEmpty
                          ? req.fromUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Name + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.fromUserName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'wants to follow you • ${_formatTime(req.createdAt)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Accept / Decline buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accept
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(receivedRequestsProvider(userId).notifier)
                          .acceptRequest(req.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${req.fromUserName} is now following you!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child:
                      const Text('Accept', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),

                // Decline
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(receivedRequestsProvider(userId).notifier)
                          .declineRequest(req.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Follow request declined')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  child:
                      const Text('Decline', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════ EXISTING HELPERS ═══════════════

  Widget _buildNotificationItem(model.Notification notification) {
    return ListTile(
      leading: _buildNotificationIcon(notification),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight:
              notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message),
          const SizedBox(height: 4),
          Text(
            _formatTime(notification.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Colors.blue, shape: BoxShape.circle),
            ),
      onTap: () {
        ref
            .read(notificationsProvider.notifier)
            .markAsRead(notification.id);
        _handleNotificationTap(notification);
      },
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildNotificationIcon(model.Notification notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case model.NotificationType.talentApproval:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case model.NotificationType.profileView:
        icon = Icons.visibility;
        color = Colors.blue;
        break;
      case model.NotificationType.message:
        icon = Icons.message;
        color = Colors.purple;
        break;
      case model.NotificationType.achievement:
        icon = Icons.emoji_events;
        color = Colors.orange;
        break;
      case model.NotificationType.connectionRequest:
        icon = Icons.person_add;
        color = Colors.indigo;
        break;
      case model.NotificationType.talentUpdate:
        icon = Icons.update;
        color = Colors.teal;
        break;
      case model.NotificationType.opportunity:
        icon = Icons.work;
        color = Colors.amber;
        break;
      case model.NotificationType.certificateVerified:
        icon = Icons.verified;
        color = Colors.green;
        break;
      case model.NotificationType.talentLiked:
        icon = Icons.thumb_up;
        color = Colors.pink;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(model.Notification notification) {
    switch (notification.type) {
      case model.NotificationType.talentApproval:
      case model.NotificationType.talentUpdate:
      case model.NotificationType.talentLiked:
        if (notification.talentId != null) {
          // Navigate to talent details
        }
        break;
      case model.NotificationType.connectionRequest:
        // Switch to Follow Requests tab
        _tabController.animateTo(1);
        break;
      case model.NotificationType.message:
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(model.Notification notification) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildNotificationIcon(notification),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(notification.message),
              const SizedBox(height: 20),
              Text(_formatTime(notification.timestamp),
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content:
            const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(notificationsProvider.notifier)
                  .clearAllNotifications();
            },
            child:
                const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}