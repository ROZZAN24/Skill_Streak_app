import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/models/talent_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/talent_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/follow_request_provider.dart';
import '../talents/add_talent_screen.dart';
import '../talents/talent_detail_screen.dart';
import '../explore/explore_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../messages/inbox_screen.dart';
import '../../core/widgets/talent_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    
    final notificationsState = ref.watch(notificationsProvider);
    final unreadCount = notificationsState.maybeWhen(
      data: (notifications) => notifications.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    final List<Widget> _screens = [
      _HomeContent(user: user),
      const ExploreScreen(),
      AddTalentScreen(
        onSuccess: () {
          // After successful submission, switch to Home tab
          setState(() => _currentIndex = 0);
        },
      ),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(unreadCount),
      floatingActionButton: _currentIndex == 2
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() => _currentIndex = 2);
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, size: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(int unreadCount) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      showUnselectedLabels: true,
      elevation: 10,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'Explore',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.add, color: Colors.transparent),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: unreadCount > 0
              ? Badge(
                  label: Text(unreadCount.toString()),
                  child: const Icon(Icons.notifications_outlined),
                )
              : const Icon(Icons.notifications_outlined),
          activeIcon: unreadCount > 0
              ? Badge(
                  label: Text(unreadCount.toString()),
                  child: const Icon(Icons.notifications),
                )
              : const Icon(Icons.notifications),
          label: 'Notifications',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final User? user;

  const _HomeContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talentsState = ref.watch(talentsProvider);
    final userTalentsState = ref.watch(userTalentsProvider(user?.id ?? ''));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline, color: Colors.blueAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InboxScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(talentsProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Centered Profile Header
                _buildCenteredHeader(user),
                const SizedBox(height: 20),

                // Stats
                _buildStats(user, ref),
                const SizedBox(height: 30),

                // User's Talents
                _buildUserTalentsSection(context, userTalentsState),
                const SizedBox(height: 30),

                // All Talents
                _buildAllTalentsSection(context, talentsState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Centered Profile Header
  Widget _buildCenteredHeader(User? user) {
    final String greetingName = user?.name.split(' ').first ?? 'Guest';
    
    return Column(
      children: [
        Center(
          child: CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey[200],
            backgroundImage: (user?.profileImage != null && user!.profileImage.isNotEmpty)
                ? NetworkImage(user.profileImage)
                : null,
            child: (user?.profileImage == null || user!.profileImage.isEmpty)
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Hello, $greetingName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (user?.institution != null && user!.institution.isNotEmpty)
          Center(
            child: Text(
              user!.institution,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStats(User? user, WidgetRef ref) {
    if (user == null) return const SizedBox.shrink();

    final connectionCountAsync = ref.watch(connectionCountProvider(user.id));
    final userTalentsAsync = ref.watch(userTalentsProvider(user.id));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Dynamic Talents, Views, Likes from userTalentsAsync
              ...userTalentsAsync.when(
                data: (talents) {
                  final totalTalents = talents.length;
                  final totalViews = talents.fold<int>(0, (sum, t) => sum + t.views);
                  final totalLikes = talents.fold<int>(0, (sum, t) => sum + t.likes);

                  return [
                    _buildStatItem('Talents', totalTalents.toString(), Icons.star),
                    _buildStatItem('Views', totalViews.toString(), Icons.remove_red_eye),
                    _buildStatItem('Likes', totalLikes.toString(), Icons.thumb_up),
                  ];
                },
                loading: () => [
                  _buildStatItem('Talents', '...', Icons.star),
                  _buildStatItem('Views', '...', Icons.remove_red_eye),
                  _buildStatItem('Likes', '...', Icons.thumb_up),
                ],
                error: (_, __) => [
                  _buildStatItem('Talents', '0', Icons.star),
                  _buildStatItem('Views', '0', Icons.remove_red_eye),
                  _buildStatItem('Likes', '0', Icons.thumb_up),
                ],
              ),
              
              // Dynamic Connections from connectionCountAsync
              connectionCountAsync.when(
                data: (counts) => _buildStatItem('Connections', counts['connections'].toString(), Icons.connect_without_contact),
                loading: () => _buildStatItem('Connections', '...', Icons.connect_without_contact),
                error: (_, __) => _buildStatItem('Connections', '0', Icons.connect_without_contact),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserTalentsSection(BuildContext context, AsyncValue<List<Talent>> userTalentsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Talents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if ((userTalentsState.value?.isNotEmpty ?? false))
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navigate to user talents screen'),
                    ),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        userTalentsState.when(
          data: (talents) {
            if (talents.isEmpty) {
              return _buildEmptyState(
                'No talents yet',
                'Add your first talent to get started',
                Icons.add_circle_outline,
              );
            }
            return Column(
              children: talents
                  .take(3)
                  .map((talent) => TalentCard(
                        talent: talent,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Viewing ${talent.title}'),
                            ),
                          );
                        },
                      ))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Error loading talents',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllTalentsSection(BuildContext context, AsyncValue<List<Talent>> talentsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Featured Talents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        talentsState.when(
          data: (talents) {
            if (talents.isEmpty) {
              return _buildEmptyState(
                'No talents found',
                'Be the first to add a talent',
                Icons.emoji_events,
              );
            }
            return Column(
              children: talents
                  .take(3)
                  .map((talent) => TalentCard(
                        talent: talent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TalentDetailScreen(talent: talent),
                            ),
                          );
                        },
                      ))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Error loading featured talents',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}