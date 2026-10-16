import 'package:cloud_firestore/cloud_firestore.dart';

/// App user profile stored in Firestore.
class AppUser {
  final String uid;
  final String name;
  final String role; // student | teacher
  final String board;
  final String classLevel;
  final bool isPremium;
  final bool isPro;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.role,
    required this.board,
    required this.classLevel,
    required this.isPremium,
    this.isPro = false,
    required this.createdAt,
  });

  bool get isTeacher => role == 'teacher';

  /// Koi bhi paid plan (Pro ya Premium).
  bool get isPaid => isPremium || isPro;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      board: map['board'] as String? ?? '',
      classLevel: map['classLevel'] as String? ?? '',
      isPremium: map['isPremium'] as bool? ?? false,
      isPro: map['isPro'] as bool? ?? false,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'board': board,
      'classLevel': classLevel,
      'isPremium': isPremium,
      'isPro': isPro,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
