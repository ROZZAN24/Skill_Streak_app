import 'dart:convert';
import 'package:flutter/foundation.dart';

class Talent {
  final String id;
  final String title;
  final String description;
  final String category;
  final String level;
  final String userId;
  final String userName;
  final String userAvatar;
  final String institution;
  final DateTime dateAdded;
  final List<String> certificates;
  final List<String> images;
  final int views;
  final int likes;
  final bool isVerified;
  final double rating;
  final List<String> tags;
  final List<Achievement> achievements;
  final List<String> viewedBy;

  Talent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.institution,
    required this.dateAdded,
    this.certificates = const [],
    this.images = const [],
    this.views = 0,
    this.likes = 0,
    this.isVerified = false,
    this.rating = 0.0,
    this.tags = const [],
    this.achievements = const [],
    this.viewedBy = const [],
  });

  // Factory constructor from Map (for Firestore/JSON)
  factory Talent.fromMap(Map<String, dynamic> map) {
    try {
      // Parse achievements
      List<Achievement> achievementsList = [];
      if (map['achievements'] != null) {
        if (map['achievements'] is List) {
          achievementsList = (map['achievements'] as List)
              .whereType<Map<String, dynamic>>()
              .map((achievementMap) => Achievement.fromMap(achievementMap))
              .toList();
        }
      }

      return Talent(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        category: map['category']?.toString() ?? '',
        level: map['level']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        userName: map['userName']?.toString() ?? '',
        userAvatar: map['userAvatar']?.toString() ?? '',
        institution: map['institution']?.toString() ?? '',
        dateAdded: map['dateAdded'] != null
            ? DateTime.tryParse(map['dateAdded'].toString()) ?? DateTime.now()
            : DateTime.now(),
        certificates: map['certificates'] is List
            ? List<String>.from(map['certificates'] as List)
            : [],
        images: map['images'] is List
            ? List<String>.from(map['images'] as List)
            : [],
        views: (map['views'] is int)
            ? map['views'] as int
            : (map['views'] is num)
                ? (map['views'] as num).toInt()
                : 0,
        likes: (map['likes'] is int)
            ? map['likes'] as int
            : (map['likes'] is num)
                ? (map['likes'] as num).toInt()
                : 0,
        isVerified: map['isVerified'] is bool
            ? map['isVerified'] as bool
            : (map['isVerified']?.toString().toLowerCase() == 'true'),
        rating: (map['rating'] is double)
            ? map['rating'] as double
            : (map['rating'] is num)
                ? (map['rating'] as num).toDouble()
                : 0.0,
        tags: map['tags'] is List
            ? List<String>.from(map['tags'] as List)
            : [],
        achievements: achievementsList,
        viewedBy: map['viewedBy'] is List
            ? List<String>.from(map['viewedBy'] as List)
            : [],
      );
    } catch (e, stackTrace) {
      print('Error parsing Talent from Map: $e');
      print('Stack trace: $stackTrace');
      print('Map data: $map');
      rethrow;
    }
  }

  // Convert to Map (for Firestore/JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'level': level,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'institution': institution,
      'dateAdded': dateAdded.toIso8601String(),
      'certificates': certificates,
      'images': images,
      'views': views,
      'likes': likes,
      'isVerified': isVerified,
      'rating': rating,
      'tags': tags,
      'achievements': achievements.map((x) => x.toMap()).toList(),
      'viewedBy': viewedBy,
    };
  }

  // JSON serialization methods
  factory Talent.fromJson(String source) => 
      Talent.fromMap(json.decode(source) as Map<String, dynamic>);
  
  String toJson() => json.encode(toMap());

  // Copy with method
  Talent copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? level,
    String? userId,
    String? userName,
    String? userAvatar,
    String? institution,
    DateTime? dateAdded,
    List<String>? certificates,
    List<String>? images,
    int? views,
    int? likes,
    bool? isVerified,
    double? rating,
    List<String>? tags,
    List<Achievement>? achievements,
    List<String>? viewedBy,
  }) {
    return Talent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      institution: institution ?? this.institution,
      dateAdded: dateAdded ?? this.dateAdded,
      certificates: certificates ?? this.certificates,
      images: images ?? this.images,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      achievements: achievements ?? this.achievements,
      viewedBy: viewedBy ?? this.viewedBy,
    );
  }

  // Utility methods
  bool get hasCertificates => certificates.isNotEmpty;
  bool get hasImages => images.isNotEmpty;
  bool get hasAchievements => achievements.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
  
  String get formattedDate => 
      '${dateAdded.day}/${dateAdded.month}/${dateAdded.year}';
  
  // Calculate average rating if needed
  double get calculatedRating => rating; // You can add calculation logic here

  // Check if talent is new (added within last 7 days)
  bool get isNew => 
      DateTime.now().difference(dateAdded).inDays <= 7;

  // Get first image or placeholder
  String get firstImageOrPlaceholder => 
      images.isNotEmpty ? images.first : '';

  // Add like
  Talent incrementLikes() => copyWith(likes: likes + 1);

  // Remove like
  Talent decrementLikes() => copyWith(likes: likes > 0 ? likes - 1 : 0);

  // Add view
  Talent incrementViews() => copyWith(views: views + 1);

  // Add tag
  Talent addTag(String tag) {
    if (!tags.contains(tag)) {
      return copyWith(tags: [...tags, tag]);
    }
    return this;
  }

  // Remove tag
  Talent removeTag(String tag) {
    if (tags.contains(tag)) {
      return copyWith(tags: tags.where((t) => t != tag).toList());
    }
    return this;
  }

  // Add achievement
  Talent addAchievement(Achievement achievement) {
    return copyWith(achievements: [...achievements, achievement]);
  }

  // Remove achievement
  Talent removeAchievement(String achievementId) {
    return copyWith(
      achievements: achievements.where((a) => a.id != achievementId).toList()
    );
  }

  @override
  String toString() {
    return 'Talent(id: $id, title: $title, category: $category, likes: $likes, views: $views)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Talent &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.level == level &&
        other.userId == userId &&
        other.userName == userName &&
        other.userAvatar == userAvatar &&
        other.institution == institution &&
        other.dateAdded == dateAdded &&
        listEquals(other.certificates, certificates) &&
        listEquals(other.images, images) &&
        other.views == views &&
        other.likes == likes &&
        other.isVerified == isVerified &&
        other.rating == rating &&
        listEquals(other.tags, tags) &&
        listEquals(other.achievements, achievements);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        category.hashCode ^
        level.hashCode ^
        userId.hashCode ^
        userName.hashCode ^
        userAvatar.hashCode ^
        institution.hashCode ^
        dateAdded.hashCode ^
        certificates.hashCode ^
        images.hashCode ^
        views.hashCode ^
        likes.hashCode ^
        isVerified.hashCode ^
        rating.hashCode ^
        tags.hashCode ^
        achievements.hashCode;
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String organization;
  final DateTime date;
  final String certificateUrl;
  final String level;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.organization,
    required this.date,
    required this.certificateUrl,
    required this.level,
  });

  // Factory constructor from Map
  factory Achievement.fromMap(Map<String, dynamic> map) {
    try {
      return Achievement(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        organization: map['organization']?.toString() ?? '',
        date: map['date'] != null
            ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        certificateUrl: map['certificateUrl']?.toString() ?? '',
        level: map['level']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing Achievement from Map: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organization': organization,
      'date': date.toIso8601String(),
      'certificateUrl': certificateUrl,
      'level': level,
    };
  }

  // JSON serialization methods
  factory Achievement.fromJson(String source) => 
      Achievement.fromMap(json.decode(source) as Map<String, dynamic>);
  
  String toJson() => json.encode(toMap());

  // Copy with method
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? organization,
    DateTime? date,
    String? certificateUrl,
    String? level,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organization: organization ?? this.organization,
      date: date ?? this.date,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      level: level ?? this.level,
    );
  }

  // Create empty achievement
  factory Achievement.empty() {
    return Achievement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      description: '',
      organization: '',
      date: DateTime.now(),
      certificateUrl: '',
      level: '',
    );
  }

  // Check if achievement is empty
  bool get isEmpty => 
      title.isEmpty && description.isEmpty && organization.isEmpty;

  // Check if achievement is not empty
  bool get isNotEmpty => !isEmpty;

  // Format date
  String get formattedDate => 
      '${date.day}/${date.month}/${date.year}';

  // Get year only
  int get year => date.year;

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, organization: $organization, date: $formattedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Achievement &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.organization == organization &&
        other.date == date &&
        other.certificateUrl == certificateUrl &&
        other.level == level;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        organization.hashCode ^
        date.hashCode ^
        certificateUrl.hashCode ^
        level.hashCode;
  }
}

// Optional: Create a helper class for Talent operations
class TalentHelper {
  // Sort talents by date (newest first)
  static List<Talent> sortByDate(List<Talent> talents, {bool ascending = false}) {
    talents.sort((a, b) => ascending
        ? a.dateAdded.compareTo(b.dateAdded)
        : b.dateAdded.compareTo(a.dateAdded));
    return talents;
  }

  // Sort talents by likes (most liked first)
  static List<Talent> sortByLikes(List<Talent> talents, {bool ascending = false}) {
    talents.sort((a, b) => ascending
        ? a.likes.compareTo(b.likes)
        : b.likes.compareTo(a.likes));
    return talents;
  }

  // Filter talents by category
  static List<Talent> filterByCategory(List<Talent> talents, String category) {
    return talents.where((talent) => talent.category == category).toList();
  }

  // Filter talents by level
  static List<Talent> filterByLevel(List<Talent> talents, String level) {
    return talents.where((talent) => talent.level == level).toList();
  }

  // Search talents by title or description
  static List<Talent> search(List<Talent> talents, String query) {
    if (query.isEmpty) return talents;
    
    final lowerQuery = query.toLowerCase();
    return talents.where((talent) =>
        talent.title.toLowerCase().contains(lowerQuery) ||
        talent.description.toLowerCase().contains(lowerQuery) ||
        talent.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))).toList();
  }

  // Get unique categories from talents
  static List<String> getUniqueCategories(List<Talent> talents) {
    return talents.map((t) => t.category).toSet().toList();
  }

  // Get unique levels from talents
  static List<String> getUniqueLevels(List<Talent> talents) {
    return talents.map((t) => t.level).toSet().toList();
  }

  // Calculate total views
  static int getTotalViews(List<Talent> talents) {
    return talents.fold(0, (sum, talent) => sum + talent.views);
  }

  // Calculate total likes
  static int getTotalLikes(List<Talent> talents) {
    return talents.fold(0, (sum, talent) => sum + talent.likes);
  }
}