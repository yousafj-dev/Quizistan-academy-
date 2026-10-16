import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quizistan_academy/models/app_user.dart';

/// Handles authentication (anonymous sign-in) and the user's profile doc.
///
/// All Quizistan users sign in anonymously; role (student/teacher), board and
/// class are stored on the `users/{uid}` document.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Emits the current Firebase user (null when signed out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase user, if any.
  User? get firebaseUser => _auth.currentUser;

  /// Returns the signed-in user, signing in anonymously when needed.
  Future<User> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current;
    try {
      final cred = await _auth.signInAnonymously();
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService.ensureSignedIn failed: ${e.code}');
      rethrow;
    }
  }

  /// Loads the profile document for the current user, or null if none exists.
  Future<AppUser?> loadProfile() async {
    try {
      final user = await ensureSignedIn();
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    } on FirebaseException catch (e) {
      debugPrint('AuthService.loadProfile failed: ${e.code}');
      rethrow;
    }
  }

  /// Creates/updates the profile document (merge so nothing is lost).
  Future<void> saveProfile(AppUser user) async {
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('AuthService.saveProfile failed: ${e.code}');
      rethrow;
    }
  }

  /// Marks the current user as premium (or not). No-op when signed out.
  Future<void> updatePremium(bool value) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('AuthService.updatePremium: no signed-in user, skipping');
      return;
    }
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set({'isPremium': value}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('AuthService.updatePremium failed: ${e.code}');
      rethrow;
    }
  }

  /// Signs the user out of Firebase Auth.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService.signOut failed: ${e.code}');
      rethrow;
    }
  }
}
