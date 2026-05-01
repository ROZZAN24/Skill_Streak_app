class AppConstants {
  static const String appName = 'Beyond Academics';
  static const String appVersion = '2.0.1';
  static const String appBuildNumber = '2024.12';

  // API Endpoints (to be replaced with actual URLs)
  static const String baseUrl = 'https://api.beyond-academics.com';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String talentsEndpoint = '/talents';
  static const String usersEndpoint = '/users';
  static const String notificationsEndpoint = '/notifications';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String currentUserKey = 'current_user';
  static const String fcmTokenKey = 'fcm_token';

  // Default values
  static const int defaultPageSize = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> supportedDocumentFormats = ['pdf', 'doc', 'docx'];

  // Categories
  static const List<String> talentCategories = [
    'Sports',
    'Music',
    'Arts',
    'Debate',
    'Dance',
    'Science',
    'Technology',
    'Leadership',
    'Writing',
    'Other',
  ];

  // Levels
  static const List<String> talentLevels = [
    'School',
    'District',
    'State',
    'National',
    'International',
  ];

  // Validation
  static const int minPasswordLength = 6;
  static const int maxBioLength = 500;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 1000;
}