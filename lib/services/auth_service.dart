import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizistan_academy/models/app_user.dart';

/// Handles authentication (anonymous sign-in) and the user's profile.
///
/// Works in two modes:
/// - Firebase ready: anonymous auth + Firestore profile doc (full features).
/// - Firebase NOT ready (no google-services.json yet): profile is stored
///   locally on the phone via SharedPreferences, so every screen works.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Set by main() after Firebase.initializeApp() attempt.
  static bool firebaseReady = false;

  // Lazy Firebase handles — never touched when firebaseReady is false,
  // so merely creating AuthService.instance can never crash the app.
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  FirebaseAuth get _authSafe {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  FirebaseFirestore get _dbSafe {
    _db ??= FirebaseFirestore.instance;
    return _db!;
  }

  /// Emits the current Firebase user (null when signed out or no Firebase).
  Stream<User?> get authStateChanges {
    if (!firebaseReady) return Stream.value(null);
    try {
      return _authSafe.authStateChanges();
    } catch (e) {
      debugPrint('AuthService.authStateChanges failed: $e');
      return Stream.value(null);
    }
  }

  /// The currently signed-in Firebase user, if any.
  User? get firebaseUser {
    if (!firebaseReady) return null;
    try {
      return _authSafe.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Returns the signed-in user, signing in anonymously when needed.
  /// Throws when Firebase is not ready — callers must check firebaseReady.
  Future<User> ensureSignedIn() async {
    final current = _authSafe.currentUser;
    if (current != null) return current;
    try {
      final cred = await _authSafe.signInAnonymously();
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService.ensureSignedIn failed: ${e.code}');
      rethrow;
    }
  }

  /// Loads the profile: from Firestore when Firebase is ready,
  /// otherwise from local phone storage. Returns null if none saved.
  Future<AppUser?> loadProfile() async {
    if (!firebaseReady) return _loadLocalProfile();
    try {
      final user = await ensureSignedIn();
      final doc = await _dbSafe.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return _loadLocalProfile();
      return AppUser.fromMap(doc.id, doc.data()!);
    } on FirebaseException catch (e) {
      debugPrint('AuthService.loadProfile failed: ${e.code}');
      return _loadLocalProfile();
    } catch (e) {
      debugPrint('AuthService.loadProfile failed: $e');
      return _loadLocalProfile();
    }
  }

  /// Saves the profile: to Firestore when Firebase is ready,
  /// otherwise to local phone storage. Never throws.
  Future<void> saveProfile(AppUser user) async {
    await _saveLocalProfile(user);
    if (!firebaseReady) return;
    try {
      await _dbSafe
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('AuthService.saveProfile cloud failed: $e');
    }
  }

  /// Marks the current user as premium (or not). No-op when signed out.
  Future<void> updatePremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_isPremium', value);
    if (!firebaseReady) return;
    final user = firebaseUser;
    if (user == null) return;
    try {
      await _dbSafe
          .collection('users')
          .doc(user.uid)
          .set({'isPremium': value}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AuthService.updatePremium failed: $e');
    }
  }

  /// Marks the current user as Pro (or not). No-op when signed out.
  Future<void> updatePro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_isPro', value);
    if (!firebaseReady) return;
    final user = firebaseUser;
    if (user == null) return;
    try {
      await _dbSafe
          .collection('users')
          .doc(user.uid)
          .set({'isPro': value}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AuthService.updatePro failed: $e');
    }
  }

  /// Signs the user out. Clears local profile too.
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_data');
    if (!firebaseReady) return;
    try {
      await _authSafe.signOut();
    } catch (e) {
      debugPrint('AuthService.signOut failed: $e');
    }
  }

  // ------------------------------------------------- local storage ----

  static const _kProfileKey = 'profile_data';

  Future<AppUser?> _loadLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('profile_name');
      if (name == null || name.isEmpty) return null;
      return AppUser(
        uid: prefs.getString('profile_uid') ?? 'local-user',
        name: name,
        role: prefs.getString('profile_role') ?? 'student',
        board: prefs.getString('profile_board') ?? '',
        classLevel: prefs.getString('profile_class') ?? '',
        isPremium: prefs.getBool('profile_isPremium') ?? false,
        isPro: prefs.getBool('profile_isPro') ?? false,
        createdAt: DateTime.tryParse(prefs.getString('profile_created') ?? '') ??
            DateTime.now(),
      );
    } catch (e) {
      debugPrint('AuthService._loadLocalProfile failed: $e');
      return null;
    }
  }

  Future<void> _saveLocalProfile(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_uid', user.uid);
      await prefs.setString('profile_name', user.name);
      await prefs.setString('profile_role', user.role);
      await prefs.setString('profile_board', user.board);
      await prefs.setString('profile_class', user.classLevel);
      await prefs.setBool('profile_isPremium', user.isPremium);
      await prefs.setBool('profile_isPro', user.isPro);
      await prefs.setString(
          'profile_created', user.createdAt.toIso8601String());
    } catch (e) {
      debugPrint('AuthService._saveLocalProfile failed: $e');
    }
  }
}
