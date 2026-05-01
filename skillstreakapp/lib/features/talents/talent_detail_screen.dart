import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/talent_model.dart';
import '../../data/models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/talent_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/follow_request_provider.dart';
import '../messages/chat_screen.dart';
import 'edit_talent_screen.dart';

class TalentDetailScreen extends ConsumerStatefulWidget {
  final Talent talent;

  const TalentDetailScreen({super.key, required this.talent});

  @override
  ConsumerState<TalentDetailScreen> createState() =>
      _TalentDetailScreenState();
}

class _TalentDetailScreenState extends ConsumerState<TalentDetailScreen> {
  final _commentController = TextEditingController();
  bool _isLiked = false;
  int _likeCount = 0;
  int _viewCount = 0;
  bool _isLiking = false;
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.talent.likes;
    _viewCount = widget.talent.views;
    _incrementView();
    _checkLikeStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _incrementView() {
    final user = ref.read(authProvider).value;
    if (user != null) {
      // Only increment if user hasn't viewed this post before
      if (!widget.talent.viewedBy.contains(user.id)) {
        final repo = ref.read(talentRepositoryProvider);
        repo.incrementView(widget.talent.id, user.id);
        setState(() => _viewCount++);
      }
    }
  }

  void _checkLikeStatus() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    final repo = ref.read(talentRepositoryProvider);
    final liked = await repo.checkLiked(widget.talent.id, user.id);
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    if (_isLiking) return;

    setState(() => _isLiking = true);

    final repo = ref.read(talentRepositoryProvider);
    try {
      if (_isLiked) {
        await repo.unlikeTalent(widget.talent.id, user.id);
        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        await repo.likeTalent(widget.talent.id, user.id);
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProvider).value;
    if (user == null) return;

    setState(() => _isSendingComment = true);
    try {
      await ref.read(commentsProvider(widget.talent.id).notifier).addComment(
            userId: user.id,
            userName: user.name,
            userAvatar: user.profileImage,
            text: text,
          );
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final user = ref.read(authProvider).value;
              if (user != null) {
                try {
                  await ref.read(talentsProvider.notifier).deletePost(widget.talent.id, user.id);
                  if (mounted) {
                    Navigator.pop(context); // Go back to Home/Explore
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTalentScreen(talent: widget.talent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final talent = widget.talent;
    final commentsAsync = ref.watch(commentsProvider(talent.id));
    final authState = ref.watch(authProvider);
    final currentUser = authState.value;
    final connectionAsync = currentUser != null
        ? ref.watch(connectionCountProvider(talent.userId))
        : null;

    final isOwner = currentUser?.id == talent.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(talent.title),
        elevation: 0,
        actions: isOwner ? [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToEdit();
              } else if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Post'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Post', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ] : null,
      ),
      body: Column(
        children: [
          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Images carousel ──
                  if (talent.images.isNotEmpty)
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        itemCount: talent.images.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            talent.images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                  child: Icon(Icons.broken_image, size: 48)),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(talent.category).withOpacity(0.7),
                            _getCategoryColor(talent.category),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(talent.category),
                          size: 80,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),

                  // ── Like / Views / Comment count bar ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Like button
                        _ActionButton(
                          icon: _isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: _likeCount.toString(),
                          color: _isLiked ? Colors.red : Colors.grey[700]!,
                          onTap: _toggleLike,
                        ),
                        const SizedBox(width: 24),
                        // Views
                        _ActionButton(
                          icon: Icons.remove_red_eye_outlined,
                          label: _viewCount.toString(),
                          color: Colors.blue[600]!,
                          onTap: null,
                        ),
                        const SizedBox(width: 24),
                        // Comments count
                        _ActionButton(
                          icon: Icons.comment_outlined,
                          label: commentsAsync.maybeWhen(
                            data: (comments) => comments.length.toString(),
                            orElse: () => '...',
                          ),
                          color: Colors.teal,
                          onTap: null,
                        ),
                        const Spacer(),
                        // Share button
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          color: Colors.grey[600],
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Share feature coming soon!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── User info card ──
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.teal[100],
                              backgroundImage: talent.userAvatar.isNotEmpty
                                  ? NetworkImage(talent.userAvatar)
                                  : null,
                              child: talent.userAvatar.isEmpty
                                  ? Text(
                                      talent.userName.isNotEmpty
                                          ? talent.userName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal),
                                    )
                                  : null,
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
                                        fontSize: 16),
                                  ),
                                  if (talent.institution.isNotEmpty)
                                    Text(
                                      talent.institution,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            // Connections count of talent owner
                            if (connectionAsync != null)
                              connectionAsync.when(
                                data: (counts) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${counts['connections']} connections',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.teal,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            if (currentUser != null && currentUser.id != talent.userId) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.mail_outline, color: Colors.blueAccent),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        partnerId: talent.userId,
                                        partnerName: talent.userName,
                                        partnerImage: talent.userAvatar,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Title + Level + Category ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          talent.title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getLevelColor(talent.level),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                talent.level,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(talent.category)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      _getCategoryIcon(talent.category),
                                      size: 14,
                                      color: _getCategoryColor(
                                          talent.category)),
                                  const SizedBox(width: 4),
                                  Text(
                                    talent.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getCategoryColor(
                                          talent.category),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (talent.isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified,
                                  size: 18, color: Colors.green),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Description ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      talent.description,
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Tags ──
                  if (talent.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: talent.tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor:
                                      Colors.teal.withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                      fontSize: 12, color: Colors.teal),
                                ))
                            .toList(),
                      ),
                    ),

                  // ── Achievements ──
                  if (talent.achievements.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Achievements',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...talent.achievements.map((a) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Card(
                            child: ListTile(
                              leading: const Icon(Icons.emoji_events,
                                  color: Colors.amber),
                              title: Text(a.title),
                              subtitle: Text(
                                  '${a.organization} • ${a.level}'),
                            ),
                          ),
                        )),
                  ],

                  // ── Certificates ──
                  if (talent.certificates.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'Certificates',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: talent.certificates.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                talent.certificates[index],
                                height: 140,
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 140,
                                  width: 200,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Comments Section ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.comment, color: Colors.teal),
                        const SizedBox(width: 8),
                        const Text(
                          'Comments',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        commentsAsync.maybeWhen(
                          data: (comments) => Text(
                            '${comments.length}',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Comments list
                  commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'No comments yet. Be the first!',
                                  style: TextStyle(
                                      color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentTile(
                              comments[index], currentUser?.id);
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.error,
                                color: Colors.red, size: 36),
                            const SizedBox(height: 8),
                            Text('Failed to load comments',
                                style:
                                    TextStyle(color: Colors.grey[600])),
                            TextButton(
                              onPressed: () => ref
                                  .read(commentsProvider(talent.id)
                                      .notifier)
                                  .loadComments(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // space for input bar
                ],
              ),
            ),
          ),

          // ── Comment input bar ──
          if (currentUser != null) _buildCommentInput(currentUser.id),
        ],
      ),
    );
  }

  // ═══════════════ Comment Tile ═══════════════
  Widget _buildCommentTile(Comment comment, String? currentUserId) {
    final isOwn = comment.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.teal[100],
            backgroundImage: comment.userAvatar.isNotEmpty
                ? NetworkImage(comment.userAvatar)
                : null,
            child: comment.userAvatar.isEmpty
                ? Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOwn
                    ? Colors.teal.withOpacity(0.06)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(comment.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          if (isOwn)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Colors.red[300]),
              onPressed: () async {
                try {
                  await ref
                      .read(
                          commentsProvider(widget.talent.id).notifier)
                      .deleteComment(comment.id);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  // ═══════════════ Comment Input ═══════════════
  Widget _buildCommentInput(String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: Colors.teal, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            backgroundColor: Colors.teal,
            onPressed: _isSendingComment ? null : _sendComment,
            child: _isSendingComment
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send, size: 18),
          ),
        ],
      ),
    );
  }

  // ═══════════════ Helpers ═══════════════
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
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

// ═══════════════ Small action button widget ═══════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
