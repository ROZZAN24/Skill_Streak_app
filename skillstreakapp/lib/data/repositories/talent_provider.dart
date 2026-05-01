import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/talent_model.dart';
import '../models/user_model.dart';

class TalentRepository {
  static const String _talentsKey = 'talents_cache';
  static const String _likedTalentsKey = 'liked_talents';

  final List<Talent> _mockTalents = [];

  TalentRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final mockUsers = [
      User(
        id: 'user_1',
        name: 'Alex Johnson',
        email: 'alex.johnson@university.edu',
        institution: 'University of Technology',
        profileImage: 'https://ui-avatars.com/api/?name=Alex+Johnson&background=0D8ABC&color=fff&size=200',
        joinDate: DateTime.now().subtract(const Duration(days: 365)),
      ),
      User(
        id: 'user_2',
        name: 'Samantha Lee',
        email: 'samantha.lee@college.edu',
        institution: 'Arts College',
        profileImage: 'https://ui-avatars.com/api/?name=Samantha+Lee&background=FF6B6B&color=fff&size=200',
        joinDate: DateTime.now().subtract(const Duration(days: 200)),
      ),
      User(
        id: 'user_3',
        name: 'Michael Chen',
        email: 'michael.chen@institute.edu',
        institution: 'Engineering Institute',
        profileImage: 'https://ui-avatars.com/api/?name=Michael+Chen&background=4ECDC4&color=fff&size=200',
        joinDate: DateTime.now().subtract(const Duration(days: 150)),
      ),
      User(
        id: 'user_4',
        name: 'Priya Sharma',
        email: 'priya.sharma@university.edu',
        institution: 'National University',
        profileImage: 'https://ui-avatars.com/api/?name=Priya+Sharma&background=FFD93D&color=000&size=200',
        joinDate: DateTime.now().subtract(const Duration(days: 300)),
      ),
    ];

    _mockTalents.addAll([
      Talent(
        id: 'talent_1',
        title: 'Football Captain',
        description: 'Led university football team to national championship victory. Specialized in strategy and team coordination.',
        category: 'Sports',
        level: 'National',
        userId: mockUsers[0].id,
        userName: mockUsers[0].name,
        userAvatar: mockUsers[0].profileImage,
        institution: mockUsers[0].institution,
        dateAdded: DateTime.now().subtract(const Duration(days: 30)),
        certificates: ['certificate_1.jpg', 'certificate_2.jpg'],
        images: ['football_1.jpg', 'football_2.jpg'],
        views: 1250,
        likes: 320,
        isVerified: true,
        rating: 4.8,
        tags: ['football', 'leadership', 'sports', 'teamwork'],
        achievements: [
          Achievement(
            id: 'ach_1',
            title: 'National Championship Winner',
            description: 'Won national inter-university football championship',
            organization: 'National Sports Association',
            date: DateTime.now().subtract(const Duration(days: 60)),
            certificateUrl: 'certificate_1.jpg',
            level: 'National',
          ),
        ],
      ),
      Talent(
        id: 'talent_2',
        title: 'Classical Guitarist',
        description: 'Expert in classical guitar with 8 years of experience. Performed at international music festivals.',
        category: 'Music',
        level: 'International',
        userId: mockUsers[1].id,
        userName: mockUsers[1].name,
        userAvatar: mockUsers[1].profileImage,
        institution: mockUsers[1].institution,
        dateAdded: DateTime.now().subtract(const Duration(days: 45)),
        certificates: ['music_cert_1.jpg', 'music_cert_2.jpg'],
        images: ['guitar_1.jpg', 'guitar_2.jpg'],
        views: 890,
        likes: 210,
        isVerified: true,
        rating: 4.9,
        tags: ['guitar', 'music', 'classical', 'performance'],
        achievements: [
          Achievement(
            id: 'ach_2',
            title: 'International Music Festival',
            description: 'Featured performer at International Classical Music Festival',
            organization: 'World Music Association',
            date: DateTime.now().subtract(const Duration(days: 90)),
            certificateUrl: 'music_cert_1.jpg',
            level: 'International',
          ),
        ],
      ),
      Talent(
        id: 'talent_3',
        title: 'Debate Champion',
        description: 'State-level debate champion with expertise in parliamentary and MUN formats.',
        category: 'Debate',
        level: 'State',
        userId: mockUsers[2].id,
        userName: mockUsers[2].name,
        userAvatar: mockUsers[2].profileImage,
        institution: mockUsers[2].institution,
        dateAdded: DateTime.now().subtract(const Duration(days: 25)),
        certificates: ['debate_cert_1.jpg'],
        images: ['debate_1.jpg'],
        views: 450,
        likes: 120,
        isVerified: false,
        rating: 4.5,
        tags: ['debate', 'public-speaking', 'mun', 'leadership'],
        achievements: [
          Achievement(
            id: 'ach_3',
            title: 'State Debate Competition Winner',
            description: 'First prize in state-level debate competition',
            organization: 'Youth Parliament',
            date: DateTime.now().subtract(const Duration(days: 30)),
            certificateUrl: 'debate_cert_1.jpg',
            level: 'State',
          ),
        ],
      ),
      Talent(
        id: 'talent_4',
        title: 'AI Research Project',
        description: 'Developed machine learning model for medical diagnosis with 95% accuracy.',
        category: 'Technology',
        level: 'National',
        userId: mockUsers[3].id,
        userName: mockUsers[3].name,
        userAvatar: mockUsers[3].profileImage,
        institution: mockUsers[3].institution,
        dateAdded: DateTime.now().subtract(const Duration(days: 15)),
        certificates: ['tech_cert_1.pdf'],
        images: ['ai_project.jpg'],
        views: 1200,
        likes: 350,
        isVerified: true,
        rating: 4.7,
        tags: ['ai', 'machine-learning', 'research', 'technology'],
        achievements: [
          Achievement(
            id: 'ach_4',
            title: 'National Tech Innovation Award',
            description: 'Awarded for innovative AI solution in healthcare',
            organization: 'National Technology Board',
            date: DateTime.now().subtract(const Duration(days: 20)),
            certificateUrl: 'tech_cert_1.pdf',
            level: 'National',
          ),
        ],
      ),
      Talent(
        id: 'talent_5',
        title: 'Bharatanatyam Dancer',
        description: 'Classical Indian dancer with 10 years of training. Specialized in Bharatanatyam.',
        category: 'Dance',
        level: 'National',
        userId: mockUsers[3].id,
        userName: mockUsers[3].name,
        userAvatar: mockUsers[3].profileImage,
        institution: mockUsers[3].institution,
        dateAdded: DateTime.now().subtract(const Duration(days: 10)),
        certificates: ['dance_cert_1.jpg', 'dance_cert_2.jpg'],
        images: ['dance_1.jpg', 'dance_2.jpg'],
        views: 680,
        likes: 180,
        isVerified: true,
        rating: 4.6,
        tags: ['dance', 'bharatanatyam', 'classical', 'performance'],
        achievements: [
          Achievement(
            id: 'ach_5',
            title: 'National Dance Competition',
            description: 'Second prize in national classical dance competition',
            organization: 'Cultural Ministry',
            date: DateTime.now().subtract(const Duration(days: 40)),
            certificateUrl: 'dance_cert_1.jpg',
            level: 'National',
          ),
        ],
      ),
    ]);
  }

  Future<List<Talent>> getTalents() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_talentsKey);
      
      if (cachedJson != null) {
        final cachedList = jsonDecode(cachedJson) as List;
        final cachedTalents = cachedList.map((item) => Talent.fromMap(item)).toList();
        return cachedTalents;
      }

      // Return mock data if no cache
      return List<Talent>.from(_mockTalents);
    } catch (e) {
      throw Exception('Failed to load talents: $e');
    }
  }

  Future<Talent> getTalentById(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final talents = await getTalents();
      final talent = talents.firstWhere((t) => t.id == id);
      return talent;
    } catch (e) {
      throw Exception('Failed to load talent: $e');
    }
  }

  Future<List<Talent>> getTalentsByUserId(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      final talents = await getTalents();
      return talents.where((talent) => talent.userId == userId).toList();
    } catch (e) {
      throw Exception('Failed to load user talents: $e');
    }
  }

  Future<Talent> addTalent(Talent talent) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate unique ID
      final newTalent = talent.copyWith(
        id: 'talent_${DateTime.now().millisecondsSinceEpoch}',
        dateAdded: DateTime.now(),
        views: 0,
        likes: 0,
      );

      // Add to cache
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_talentsKey);
      List<Talent> currentTalents = [];

      if (cachedJson != null) {
        final cachedList = jsonDecode(cachedJson) as List;
        currentTalents = cachedList.map((item) => Talent.fromMap(item)).toList();
      }

      currentTalents.add(newTalent);
      await prefs.setString(_talentsKey, 
        jsonEncode(currentTalents.map((t) => t.toMap()).toList()));

      return newTalent;
    } catch (e) {
      throw Exception('Failed to add talent: $e');
    }
  }

  Future<Talent> updateTalent(Talent talent) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_talentsKey);
      
      if (cachedJson != null) {
        final cachedList = jsonDecode(cachedJson) as List;
        final currentTalents = cachedList.map((item) => Talent.fromMap(item)).toList();
        
        final index = currentTalents.indexWhere((t) => t.id == talent.id);
        if (index != -1) {
          currentTalents[index] = talent;
          await prefs.setString(_talentsKey,
            jsonEncode(currentTalents.map((t) => t.toMap()).toList()));
        }
      }

      return talent;
    } catch (e) {
      throw Exception('Failed to update talent: $e');
    }
  }

  Future<void> deleteTalent(String talentId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_talentsKey);
      
      if (cachedJson != null) {
        final cachedList = jsonDecode(cachedJson) as List;
        final currentTalents = cachedList.map((item) => Talent.fromMap(item)).toList();
        
        final newTalents = currentTalents.where((t) => t.id != talentId).toList();
        await prefs.setString(_talentsKey,
          jsonEncode(newTalents.map((t) => t.toMap()).toList()));
      }
    } catch (e) {
      throw Exception('Failed to delete talent: $e');
    }
  }

  Future<void> likeTalent(String talentId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Track liked talents
      final prefs = await SharedPreferences.getInstance();
      final likedJson = prefs.getString(_likedTalentsKey) ?? '[]';
      final likedTalents = List<String>.from(jsonDecode(likedJson));
      
      if (!likedTalents.contains(talentId)) {
        likedTalents.add(talentId);
        await prefs.setString(_likedTalentsKey, jsonEncode(likedTalents));

        // Update talent likes in cache
        final cachedJson = prefs.getString(_talentsKey);
        if (cachedJson != null) {
          final cachedList = jsonDecode(cachedJson) as List;
          final currentTalents = cachedList.map((item) => Talent.fromMap(item)).toList();
          
          final index = currentTalents.indexWhere((t) => t.id == talentId);
          if (index != -1) {
            final talent = currentTalents[index];
            currentTalents[index] = talent.copyWith(likes: talent.likes + 1);
            await prefs.setString(_talentsKey,
              jsonEncode(currentTalents.map((t) => t.toMap()).toList()));
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to like talent: $e');
    }
  }

  Future<void> unlikeTalent(String talentId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      final likedJson = prefs.getString(_likedTalentsKey) ?? '[]';
      final likedTalents = List<String>.from(jsonDecode(likedJson));
      
      if (likedTalents.contains(talentId)) {
        likedTalents.remove(talentId);
        await prefs.setString(_likedTalentsKey, jsonEncode(likedTalents));

        // Update talent likes in cache
        final cachedJson = prefs.getString(_talentsKey);
        if (cachedJson != null) {
          final cachedList = jsonDecode(cachedJson) as List;
          final currentTalents = cachedList.map((item) => Talent.fromMap(item)).toList();
          
          final index = currentTalents.indexWhere((t) => t.id == talentId);
          if (index != -1) {
            final talent = currentTalents[index];
            currentTalents[index] = talent.copyWith(likes: talent.likes - 1);
            await prefs.setString(_talentsKey,
              jsonEncode(currentTalents.map((t) => t.toMap()).toList()));
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to unlike talent: $e');
    }
  }

  Future<bool> isTalentLiked(String talentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedJson = prefs.getString(_likedTalentsKey) ?? '[]';
      final likedTalents = List<String>.from(jsonDecode(likedJson));
      return likedTalents.contains(talentId);
    } catch (e) {
      return false;
    }
  }

  Future<List<Talent>> searchTalents(String query) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final talents = await getTalents();
      final lowerQuery = query.toLowerCase();

      return talents.where((talent) {
        return talent.title.toLowerCase().contains(lowerQuery) ||
               talent.description.toLowerCase().contains(lowerQuery) ||
               talent.category.toLowerCase().contains(lowerQuery) ||
               talent.userName.toLowerCase().contains(lowerQuery) ||
               talent.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      throw Exception('Failed to search talents: $e');
    }
  }

  Future<List<Talent>> filterTalents({
    String? category,
    String? level,
    bool? verifiedOnly,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final talents = await getTalents();
      var filteredTalents = List<Talent>.from(talents);

      if (category != null && category.isNotEmpty && category != 'All') {
        filteredTalents = filteredTalents
            .where((talent) => talent.category == category)
            .toList();
      }

      if (level != null && level.isNotEmpty && level != 'All') {
        filteredTalents = filteredTalents
            .where((talent) => talent.level == level)
            .toList();
      }

      if (verifiedOnly == true) {
        filteredTalents = filteredTalents
            .where((talent) => talent.isVerified)
            .toList();
      }

      return filteredTalents;
    } catch (e) {
      throw Exception('Failed to filter talents: $e');
    }
  }

  Future<void> incrementViews(String talentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_talentsKey);
      
      if (cachedJson != null) {
        final cachedList = jsonDecode(cachedJson) as List;
        final currentTalents = cachedList.map((item) => Talent.fromMap(item)).toList();
        
        final index = currentTalents.indexWhere((t) => t.id == talentId);
        if (index != -1) {
          final talent = currentTalents[index];
          currentTalents[index] = talent.copyWith(views: talent.views + 1);
          await prefs.setString(_talentsKey,
            jsonEncode(currentTalents.map((t) => t.toMap()).toList()));
        }
      }
    } catch (e) {
      // Silently fail for view increments
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_talentsKey);
      await prefs.remove(_likedTalentsKey);
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }
}