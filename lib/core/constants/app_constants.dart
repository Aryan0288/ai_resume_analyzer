/// Centralized repository for static strings, asset paths, and configuration limits.
class AppConstants {
  static const String appName = 'ResuMatch AI';
  
  // Asset Paths
  static const String logoSvg = 'assets/logo.svg';
  static const String profilePlaceholder = 'assets/profile_placeholder.png';

  // Limits
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxResumeWordsCount = 1000;

  // Local DB Box Names (Hive)
  static const String resumeBox = 'resume_box';
  static const String draftBox = 'draft_box';
  static const String userPrefsBox = 'user_preferences_box';

  // Local Storage Keys
  static const String keyResumeText = 'resume_text';
  static const String keyTargetRole = 'target_role';
  static const String keyThemeMode = 'theme_mode';
}
