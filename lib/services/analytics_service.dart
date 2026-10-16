import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:quizistan_academy/services/auth_service.dart';

/// Firebase Analytics wrapper — fully graceful when Firebase is not
/// configured yet (offline mode). Every method is a safe no-op until
/// AuthService.firebaseReady becomes true, so screens can call these
/// freely without null checks.
///
/// Once google-services.json is added, the Firebase console will show:
/// installs, active users, screen views, quiz completions — answering
/// "kis ne install karke check kiya".
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  FirebaseAnalytics? get _safe {
    if (!AuthService.firebaseReady) return null;
    try {
      _analytics ??= FirebaseAnalytics.instance;
      return _analytics;
    } catch (e) {
      debugPrint('AnalyticsService init failed: $e');
      return null;
    }
  }

  /// Call once at app start. Firebase logs app_open automatically,
  /// but this also stamps the first-open for our own funnels.
  Future<void> logAppOpen() async {
    try {
      await _safe?.logAppOpen();
    } catch (e) {
      debugPrint('logAppOpen failed: $e');
    }
  }

  Future<void> logScreen(String name) async {
    try {
      await _safe?.logScreenView(screenName: name);
    } catch (e) {
      debugPrint('logScreen failed: $e');
    }
  }

  Future<void> logQuizStart({
    required String board,
    required String classLevel,
    required String subject,
    required int count,
  }) async {
    try {
      await _safe?.logEvent(
        name: 'quiz_start',
        parameters: {
          'board': board,
          'class_level': classLevel,
          'subject': subject,
          'question_count': count,
        },
      );
    } catch (e) {
      debugPrint('logQuizStart failed: $e');
    }
  }

  Future<void> logQuizComplete({
    required String subject,
    required int total,
    required int correct,
  }) async {
    try {
      await _safe?.logEvent(
        name: 'quiz_complete',
        parameters: {
          'subject': subject,
          'total_questions': total,
          'correct_answers': correct,
        },
      );
    } catch (e) {
      debugPrint('logQuizComplete failed: $e');
    }
  }

  Future<void> logSignUp() async {
    try {
      await _safe?.logSignUp(signUpMethod: 'profile_form');
    } catch (e) {
      debugPrint('logSignUp failed: $e');
    }
  }
}
