import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserRepository {
  static const String _usersKey = 'users_cache';
  static const String _followersKey = 'followers_cache';

  final List<User> _mockUsers = [];

  UserRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    _mockUsers.addAll([
      User(
        id: 'user_1',
        name: 'Alex Johnson',
        email: 'alex.johnson@university.edu',
        institution: 'University of Technology',
        profileImage: 'https://ui-avatars.com/api/?name=Alex+Johnson&background=0D8ABC&color=fff&size=200',
        bio: 'Sports enthusiast and team leader. Passionate about football and technology.',
        skills: ['Football', 'Leadership', 'Team Management', 'Strategy'],
        interests: ['Sports', 'Technology', 'Entrepreneurship'],
        joinDate: DateTime.now().subtract(const Duration(days: 365)),
        totalTalents: 3,
        totalViews: 1250,
        totalLikes: 320,
        followers: 150,
        following: 85,
        rating: 4.8,
        isVerified: true,
        socialLinks: [
          SocialLink(
            platform: 'LinkedIn',
            url: 'https://linkedin.com/in/alexjohnson',
            username: 'alexjohnson',
          ),
          SocialLink(
            platform: 'Twitter',
            url: 'https://twitter.com/alexjohnson',
            username: 'alexjohnson',
          ),
        ],
      ),
      User(
        id: 'user_2',
        name: 'Samantha Lee',
        email: 'samantha.lee@college.edu',
        institution: 'Arts College',
        profileImage: 'https://ui-avatars.com/api/?name=Samantha+Lee&background=FF6B6B&color=fff&size=200',
        bio: 'Classical guitarist and music composer. Passionate about bringing music to everyone.',
        skills: ['Guitar', 'Music Composition', 'Performance', 'Teaching'],
        interests: ['Music', 'Arts', 'Culture', 'Education'],
        joinDate: DateTime.now().subtract(const Duration(days: 200)),
        totalTalents: 2,
        totalViews: 890,
        totalLikes: 210,
        followers: 120,
        following: 95,
        rating: 4.9,
        isVerified: true,
        socialLinks: [
          SocialLink(
            platform: 'Instagram',
            url: 'https://instagram.com/samanthalee',
            username: 'samanthalee',
          ),
          SocialLink(
            platform: 'YouTube',
            url: 'https://youtube.com/samanthalee',
            username: 'Samantha Lee Music',
          ),
        ],
      ),
      User(
        id: 'user_3',
        name: 'Michael Chen',
        email: 'michael.chen@institute.edu',
        institution: 'Engineering Institute',
        profileImage: 'https://ui-avatars.com/api/?name=Michael+Chen&background=4ECDC4&color=fff&size=200',
        bio: 'Debate champion and public speaker. Interested in politics and social issues.',
        skills: ['Debate', 'Public Speaking', 'Research', 'Critical Thinking'],
        interests: ['Politics', 'Social Issues', 'Law', 'Education'],
        joinDate: DateTime.now().subtract(const Duration(days: 150)),
        totalTalents: 1,
        totalViews: 450,
        totalLikes: 120,
        followers: 80,
        following: 110,
        rating: 4.5,
        isVerified: false,
        socialLinks: [
          SocialLink(
            platform: 'LinkedIn',
            url: 'https://linkedin.com/in/michaelchen',
            username: 'michaelchen',
          ),
        ],
      ),
      User(
        id: 'user_4',
        name: 'Priya Sharma',
        email: 'priya.sharma@university.edu',
        institution: 'National University',
        profileImage: 'https://ui-avatars.com/api/?name=Priya+Sharma&background=FFD93D&color=000&size=200',
        bio: 'AI researcher and classical dancer. Combining technology with traditional arts.',
        skills: ['AI/ML', 'Python', 'Bharatanatyam', 'Research'],
        interests: ['Technology', 'Dance', 'Research', 'Innovation'],
        joinDate: DateTime.now().subtract(const Duration(days: 300)),
        totalTalents: 2,
        totalViews: 1880,
        totalLikes: 530,
        followers: 200,
        following: 125,
        rating: 4.7,
        isVerified: true,
        socialLinks: [
          SocialLink(
            platform: 'GitHub',
            url: 'https://github.com/priyasharma',
            username: 'priyasharma',
          ),
          SocialLink(
            platform: 'Instagram',
            url: 'https://instagram.com/priyasharma',
            username: 'priyasharma',
          ),
        ],
      ),
    ]);
  }

  Future<List<User>> getUsers() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_usersKey);
      
      if (cachedJson != null) {
        final cachedList = jsonDecode(cachedJson) as List;
        return cachedList.map((item) => User.fromMap(item)).toList();
      }

      return List<User>.from(_mockUsers);
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<User> getUserById(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final users = await getUsers();
      return users.firstWhere((user) => user.id == userId);
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final users = await getUsers();
      final lowerQuery = query.toLowerCase();

      return users.where((user) {
        return user.name.toLowerCase().contains(lowerQuery) ||
               user.email.toLowerCase().contains(lowerQuery) ||
               user.institution.toLowerCase().contains(lowerQuery) ||
               user.skills.any((skill) => skill.toLowerCase().contains(lowerQuery)) ||
               user.interests.any((interest) => interest.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<void> followUser(String userId, String targetUserId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      final followersKey = '${_followersKey}_$targetUserId';
      
      final followersJson = prefs.getString(followersKey) ?? '[]';
      final followers = List<String>.from(jsonDecode(followersJson));
      
      if (!followers.contains(userId)) {
        followers.add(userId);
        await prefs.setString(followersKey, jsonEncode(followers));
      }
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  Future<void> unfollowUser(String userId, String targetUserId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      final followersKey = '${_followersKey}_$targetUserId';
      
      final followersJson = prefs.getString(followersKey) ?? '[]';
      final followers = List<String>.from(jsonDecode(followersJson));
      
      followers.remove(userId);
      await prefs.setString(followersKey, jsonEncode(followers));
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  Future<bool> isFollowing(String userId, String targetUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followersKey = '${_followersKey}_$targetUserId';
      
      final followersJson = prefs.getString(followersKey) ?? '[]';
      final followers = List<String>.from(jsonDecode(followersJson));
      
      return followers.contains(userId);
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getFollowers(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followersKey = '${_followersKey}_$userId';
      
      final followersJson = prefs.getString(followersKey) ?? '[]';
      return List<String>.from(jsonDecode(followersJson));
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> getFollowersList(String userId) async {
    try {
      final followerIds = await getFollowers(userId);
      final allUsers = await getUsers();
      
      return allUsers.where((user) => followerIds.contains(user.id)).toList();
    } catch (e) {
      throw Exception('Failed to get followers list: $e');
    }
  }

  Future<List<String>> getFollowing(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followingKey = 'following_$userId';
      
      final followingJson = prefs.getString(followingKey) ?? '[]';
      return List<String>.from(jsonDecode(followingJson));
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> getFollowingList(String userId) async {
    try {
      final followingIds = await getFollowing(userId);
      final allUsers = await getUsers();
      
      return allUsers.where((user) => followingIds.contains(user.id)).toList();
    } catch (e) {
      throw Exception('Failed to get following list: $e');
    }
  }

  Future<void> saveUser(User user) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_usersKey);
      List<User> currentUsers = [];

      if (cachedJson != null) {
        final cachedList = jsonDecode(cachedJson) as List;
        currentUsers = cachedList.map((item) => User.fromMap(item)).toList();
      }

      final index = currentUsers.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        currentUsers[index] = user;
      } else {
        currentUsers.add(user);
      }

      await prefs.setString(_usersKey,
        jsonEncode(currentUsers.map((u) => u.toMap()).toList()));
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  Future<void> updateUserStats({
    required String userId,
    int? views,
    int? likes,
    int? followers,
  }) async {
    try {
      final user = await getUserById(userId);
      var updatedUser = user;

      if (views != null) {
        updatedUser = updatedUser.copyWith(totalViews: updatedUser.totalViews + views);
      }
      
      if (likes != null) {
        updatedUser = updatedUser.copyWith(totalLikes: updatedUser.totalLikes + likes);
      }
      
      if (followers != null) {
        updatedUser = updatedUser.copyWith(followers: updatedUser.followers + followers);
      }

      await saveUser(updatedUser);
    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usersKey);
      
      // Clear all follower keys
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_followersKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      throw Exception('Failed to clear user cache: $e');
    }
  }

  Future<FutureOr<List<User>>> getUserFollowers(String userId) async {
    return await getFollowersList(userId);
  }

  FutureOr<List<User>> getUserFollowing(String userId) {
    return getFollowingList(userId);
  }
}