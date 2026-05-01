class User {
  final String id;
  final String name;
  final String email;
  final String institution;
  final String profileImage;
  final String bio;
  final List<String> skills;
  final List<String> interests;
  final DateTime joinDate;
  final int totalTalents;
  final int totalViews;
  final int totalLikes;
  final int followers;
  final int following;
  final double rating;
  final bool isVerified;
  final List<SocialLink> socialLinks;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.institution,
    this.profileImage = '',
    this.bio = '',
    this.skills = const [],
    this.interests = const [],
    required this.joinDate,
    this.totalTalents = 0,
    this.totalViews = 0,
    this.totalLikes = 0,
    this.followers = 0,
    this.following = 0,
    this.rating = 0.0,
    this.isVerified = false,
    this.socialLinks = const [],
  });

  double get profileCompletion {
    double completion = 0.0;
    if (name.isNotEmpty) completion += 20;
    if (email.isNotEmpty) completion += 20;
    if (institution.isNotEmpty) completion += 20;
    if (bio.isNotEmpty) completion += 10;
    if (profileImage.isNotEmpty) completion += 10;
    if (skills.isNotEmpty) completion += 10;
    if (interests.isNotEmpty) completion += 10;
    return completion;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      institution: map['institution'] ?? '',
      profileImage: map['profileImage'] ?? '',
      bio: map['bio'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      joinDate: DateTime.parse(map['joinDate'] ?? DateTime.now().toIso8601String()),
      totalTalents: map['totalTalents'] ?? 0,
      totalViews: map['totalViews'] ?? 0,
      totalLikes: map['totalLikes'] ?? 0,
      followers: map['followers'] ?? 0,
      following: map['following'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      isVerified: map['isVerified'] ?? false,
      socialLinks: List<SocialLink>.from(
        (map['socialLinks'] ?? []).map((x) => SocialLink.fromMap(x)),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'institution': institution,
      'profileImage': profileImage,
      'bio': bio,
      'skills': skills,
      'interests': interests,
      'joinDate': joinDate.toIso8601String(),
      'totalTalents': totalTalents,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'followers': followers,
      'following': following,
      'rating': rating,
      'isVerified': isVerified,
      'socialLinks': socialLinks.map((x) => x.toMap()).toList(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? institution,
    String? profileImage,
    String? bio,
    List<String>? skills,
    List<String>? interests,
    DateTime? joinDate,
    int? totalTalents,
    int? totalViews,
    int? totalLikes,
    int? followers,
    int? following,
    double? rating,
    bool? isVerified,
    List<SocialLink>? socialLinks,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      institution: institution ?? this.institution,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      joinDate: joinDate ?? this.joinDate,
      totalTalents: totalTalents ?? this.totalTalents,
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}

class SocialLink {
  final String platform;
  final String url;
  final String username;

  SocialLink({
    required this.platform,
    required this.url,
    required this.username,
  });

  factory SocialLink.fromMap(Map<String, dynamic> map) {
    return SocialLink(
      platform: map['platform'] ?? '',
      url: map['url'] ?? '',
      username: map['username'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'url': url,
      'username': username,
    };
  }
}