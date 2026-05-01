import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/talent_model.dart';
import '../../providers/talent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_request_provider.dart';
import '../../providers/comment_provider.dart';
import '../../features/talents/talent_detail_screen.dart';

class TalentCard extends ConsumerWidget {
  final Talent talent;
  final VoidCallback? onTap;
  final bool showActions;

  const TalentCard({
    super.key,
    required this.talent,
    this.onTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryIcon = _getCategoryIcon(talent.category);
    final categoryColor = _getCategoryColor(talent.category);
    final authState = ref.watch(authProvider);
    final currentUser = authState.value;
    final isOwnTalent = currentUser?.id == talent.userId;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and category
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: talent.userAvatar.isNotEmpty
                        ? NetworkImage(talent.userAvatar)
                        : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          talent.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          talent.institution,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Follow button (only for other users' talents)
                  if (!isOwnTalent && currentUser != null)
                    _FollowButton(
                      currentUserId: currentUser.id,
                      currentUserName: currentUser.name,
                      currentUserAvatar: currentUser.profileImage,
                      targetUserId: talent.userId,
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon, size: 14, color: categoryColor),
                        const SizedBox(width: 4),
                        Text(
                          talent.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Talent title and level
              Text(
                talent.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getLevelColor(talent.level),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      talent.level,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (talent.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                talent.description,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Tags
              if (talent.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: talent.tags
                      .take(3)
                      .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Colors.grey[100],
                            labelStyle: const TextStyle(fontSize: 11),
                            padding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),

              if (talent.tags.isNotEmpty) const SizedBox(height: 12),

              // Stats and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildStatItem(
                        Icons.remove_red_eye,
                        talent.views.toString(),
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.favorite,
                        talent.likes.toString(),
                        color: Colors.red[300],
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.comment_outlined,
                        ref.watch(commentCountProvider(talent.id)).maybeWhen(
                          data: (count) => count.toString(),
                          orElse: () => '0',
                        ),
                      ),
                    ],
                  ),
                  if (showActions)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TalentDetailScreen(talent: talent),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('View Details'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return Icons.sports_soccer;
      case 'music':
        return Icons.music_note;
      case 'arts':
        return Icons.palette;
      case 'debate':
        return Icons.mic;
      case 'dance':
        return Icons.sentiment_very_satisfied;
      case 'science':
        return Icons.science;
      case 'technology':
        return Icons.code;
      case 'leadership':
        return Icons.leaderboard;
      case 'writing':
        return Icons.edit;
      default:
        return Icons.star;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return Colors.orange;
      case 'music':
        return Colors.purple;
      case 'arts':
        return Colors.pink;
      case 'debate':
        return Colors.blue;
      case 'dance':
        return Colors.red;
      case 'science':
        return Colors.green;
      case 'technology':
        return Colors.indigo;
      case 'leadership':
        return Colors.amber;
      case 'writing':
        return Colors.brown;
      default:
        return Colors.teal;
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'international':
        return Colors.red;
      case 'national':
        return Colors.orange;
      case 'state':
        return Colors.green;
      case 'district':
        return Colors.blue;
      case 'school':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// ═══════════════ FOLLOW BUTTON WIDGET ═══════════════
class _FollowButton extends ConsumerStatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;
  final String targetUserId;

  const _FollowButton({
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
    required this.targetUserId,
  });

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _isLoading = false;
  String? _localStatus;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(followStatusProvider((
      fromUserId: widget.currentUserId,
      toUserId: widget.targetUserId,
    )));

    return statusAsync.when(
      data: (status) {
        final displayStatus = _localStatus ?? status;
        return _buildButton(displayStatus);
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => _buildButton('none'),
    );
  }

  Widget _buildButton(String status) {
    String label;
    Color bgColor;
    Color fgColor;
    IconData icon;
    bool enabled = true;

    if (status.contains('accepted')) {
      label = 'Following';
      bgColor = Colors.grey[200]!;
      fgColor = Colors.grey[700]!;
      icon = Icons.check;
      enabled = false;
    } else if (status.startsWith('sent_pending')) {
      label = 'Requested';
      bgColor = Colors.orange[50]!;
      fgColor = Colors.orange[700]!;
      icon = Icons.hourglass_top;
      enabled = false;
    } else {
      label = 'Follow';
      bgColor = Colors.teal;
      fgColor = Colors.white;
      icon = Icons.person_add;
    }

    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: enabled && !_isLoading ? _sendFollowRequest : null,
        icon: _isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _sendFollowRequest() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(followRequestRepositoryProvider);
      await repo.sendFollowRequest(
        fromUserId: widget.currentUserId,
        toUserId: widget.targetUserId,
        fromUserName: widget.currentUserName,
        fromUserAvatar: widget.currentUserAvatar,
      );

      setState(() {
        _localStatus = 'sent_pending';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow request sent!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}