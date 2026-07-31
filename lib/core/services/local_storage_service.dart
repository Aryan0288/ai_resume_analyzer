import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

/// Service coordinating local caching database operations (Hive boxes) and Firestore sync.
class LocalStorageService {
  final Box _resumeBox = Hive.box(AppConstants.resumeBox);
  final Box _draftBox = Hive.box(AppConstants.draftBox);
  final Box _prefsBox = Hive.box(AppConstants.userPrefsBox);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Resume Caching
  Future<void> saveResumeText(String text) async {
    await _resumeBox.put(AppConstants.keyResumeText, text);
  }

  String getResumeText() {
    return _resumeBox.get(AppConstants.keyResumeText, defaultValue: '');
  }

  Future<void> clearResumeData() async {
    await _resumeBox.delete(AppConstants.keyResumeText);
  }

  // Interview & Quiz Draft Persistence
  Future<void> saveDraft(String key, String text) async {
    await _draftBox.put(key, text);
  }

  String getDraft(String key) {
    return _draftBox.get(key, defaultValue: '');
  }

  Future<void> clearDraft(String key) async {
    await _draftBox.delete(key);
  }

  // User Preferences / Theme Configuration
  Future<void> saveThemeMode(bool isDark) async {
    await _prefsBox.put(AppConstants.keyThemeMode, isDark);
  }

  bool isDarkMode() {
    return _prefsBox.get(AppConstants.keyThemeMode, defaultValue: false);
  }

  Future<void> saveTargetRole(String role) async {
    await _prefsBox.put(AppConstants.keyTargetRole, role);
  }

  String getTargetRole() {
    return _prefsBox.get(AppConstants.keyTargetRole, defaultValue: '');
  }

  Future<void> saveRecentActivities(List<Map<String, dynamic>> activities, [String? uid]) async {
    final key = uid != null && uid.isNotEmpty ? 'activities_$uid' : 'key_recent_activities';
    await _resumeBox.put(key, activities);
  }

  Future<void> saveScoreTrends(List<Map<String, dynamic>> trends, [String? uid]) async {
    final key = uid != null && uid.isNotEmpty ? 'trends_$uid' : 'key_score_trends';
    await _resumeBox.put(key, trends);
  }

  // -------------------------------------------------------------
  // USER-SCOPED RECENT ACTIVITIES & SCORE TRENDS (Firestore + Hive)
  // -------------------------------------------------------------
  Future<void> addRecentActivity(String uid, Map<String, dynamic> activity) async {
    final key = 'activities_$uid';
    final existing = getRecentActivities(uid);
    final docId = activity['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    activity['id'] = docId;

    // Deduplicate by ID
    existing.removeWhere((item) => item['id'] == docId);
    existing.insert(0, activity);
    await _resumeBox.put(key, existing);

    // Sync to Firestore
    if (uid.isNotEmpty && uid != 'anonymous') {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('activities')
            .doc(docId)
            .set(activity, SetOptions(merge: true));
        debugPrint('[LocalStorageService] ✅ Activity successfully written to Firestore users/$uid/activities/$docId');
      } catch (e) {
        debugPrint('[LocalStorageService] ❌ Firestore write error ($e). Make sure Firestore Database is created in Firebase Console and Security Rules allow write!');
      }
    }
  }

  List<Map<String, dynamic>> getRecentActivities([String? uid]) {
    final key = uid != null && uid.isNotEmpty ? 'activities_$uid' : 'key_recent_activities';
    final raw = _resumeBox.get(key) ?? _resumeBox.get('key_recent_activities');
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> syncUserActivitiesFromFirestore(String uid) async {
    if (uid.isEmpty) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('activities')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final List<Map<String, dynamic>> list = snapshot.docs.map((doc) => doc.data()).toList();
        list.sort((a, b) {
          final dateA = a['date']?.toString() ?? '';
          final dateB = b['date']?.toString() ?? '';
          return dateB.compareTo(dateA);
        });
        await _resumeBox.put('activities_$uid', list);
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Sync Firestore activities error: $e');
    }
  }

  Future<void> addScoreTrend(String uid, Map<String, dynamic> trend) async {
    final key = 'trends_$uid';
    final existing = getScoreTrends(uid);
    existing.add(trend);
    if (existing.length > 7) {
      existing.removeAt(0);
    }
    await _resumeBox.put(key, existing);

    try {
      await _firestore.collection('users').doc(uid).collection('trends').add(trend);
    } catch (e) {
      debugPrint('[LocalStorageService] Firestore trend sync error: $e');
    }
  }

  List<Map<String, dynamic>> getScoreTrends([String? uid]) {
    final key = uid != null && uid.isNotEmpty ? 'trends_$uid' : 'key_score_trends';
    final raw = _resumeBox.get(key) ?? _resumeBox.get('key_score_trends');
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // -------------------------------------------------------------
  // 24-HOUR ROLLING ATTEMPT LIMIT & ADMOB UNLOCKS PER USER UID
  // -------------------------------------------------------------

  /// Returns timestamps of attempts made within the last 48 hours.
  List<DateTime> getRecentAttemptTimestamps([String? uid]) {
    final key = uid != null && uid.isNotEmpty ? 'attempts_$uid' : 'key_attempt_timestamps';
    final raw = _prefsBox.get(key);
    if (raw is List) {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 48));
      final List<DateTime> valid = [];
      for (final item in raw) {
        final dt = DateTime.tryParse(item.toString());
        if (dt != null && dt.isAfter(cutoff)) {
          valid.add(dt);
        }
      }
      return valid;
    }
    return [];
  }

  int getAnalysisCount([String? uid]) {
    return getRecentAttemptTimestamps(uid).length;
  }

  Future<void> recordAnalysisAttempt([String? uid]) async {
    final key = uid != null && uid.isNotEmpty ? 'attempts_$uid' : 'key_attempt_timestamps';
    final timestamps = getRecentAttemptTimestamps(uid);
    timestamps.add(DateTime.now());
    final strList = timestamps.map((dt) => dt.toIso8601String()).toList();
    await _prefsBox.put(key, strList);

    if (uid != null && uid.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).set({
          'lastAttemptAt': FieldValue.serverTimestamp(),
          'recentAttemptsCount': timestamps.length,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[LocalStorageService] Firestore attempt record error: $e');
      }
    }
  }

  int getUnlockedBonusAttempts([String? uid]) {
    final key = uid != null && uid.isNotEmpty ? 'bonus_$uid' : 'key_unlocked_bonus_attempts';
    return _prefsBox.get(key, defaultValue: 0);
  }

  Future<void> incrementUnlockedBonusAttempts([String? uid]) async {
    final current = getUnlockedBonusAttempts(uid);
    final key = uid != null && uid.isNotEmpty ? 'bonus_$uid' : 'key_unlocked_bonus_attempts';
    await _prefsBox.put(key, current + 1);

    if (uid != null && uid.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).set({
          'bonusAttempts': current + 1,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[LocalStorageService] Firestore bonus update error: $e');
      }
    }
  }

  int getRemainingAttempts([String? uid]) {
    final allowed = 4 + getUnlockedBonusAttempts(uid);
    final usedInLast48Hours = getAnalysisCount(uid);
    final remaining = allowed - usedInLast48Hours;
    return remaining < 0 ? 0 : remaining;
  }
}
