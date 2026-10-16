import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quizistan_academy/core/constants/app_constants.dart';
import 'package:quizistan_academy/models/question.dart';
import 'package:quizistan_academy/models/quiz_result.dart';
import 'package:quizistan_academy/models/test_room.dart';

/// Central access point for all Firestore reads/writes.
/// No composite indexes: question filters use AT MOST ONE `where` clause
/// (prefer `subject`, else `board`); `orderBy('createdAt')` only with no
/// where-clause; everything else is filtered client-side in Dart.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int _roomCodeLength = 6;
  static const int _maxRoomCodeTries = 5;

  CollectionReference<Map<String, dynamic>> get _questions => _db.collection('questions');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _results => _db.collection('results');
  CollectionReference<Map<String, dynamic>> get _tests => _db.collection('tests');

  /// Base questions query following the single-where rule (no composite index).
  Query<Map<String, dynamic>> _questionsBaseQuery({
    String? board,
    String? subject,
  }) {
    if (subject != null && subject.isNotEmpty) {
      return _questions.where('subject', isEqualTo: subject);
    }
    if (board != null && board.isNotEmpty) {
      return _questions.where('board', isEqualTo: board);
    }
    return _questions.orderBy('createdAt', descending: true);
  }

  /// Remaining filters applied client-side in Dart (no composite index).
  List<Question> _filterQuestions(
    List<Question> questions, {
    String? board,
    String? classLevel,
    String? subject,
    String? chapter,
    String? search,
  }) {
    final s = search?.trim().toLowerCase();
    return questions.where((q) {
      if (board != null && board.isNotEmpty && q.board != board) return false;
      if (classLevel != null &&
          classLevel.isNotEmpty &&
          q.classLevel != classLevel) {
        return false;
      }
      if (subject != null && subject.isNotEmpty && q.subject != subject) {
        return false;
      }
      if (chapter != null && chapter.isNotEmpty && q.chapter != chapter) {
        return false;
      }
      if (s != null && s.isNotEmpty) {
        final haystack = '${q.text} ${q.chapter}'.toLowerCase();
        if (!haystack.contains(s)) return false;
      }
      return true;
    }).toList();
  }

  /// Live stream of questions with optional filters (client-side refined).
  Stream<List<Question>> watchQuestions({
    String? board,
    String? classLevel,
    String? subject,
    String? chapter,
    String? search,
  }) {
    try {
      return _questionsBaseQuery(board: board, subject: subject)
          .snapshots()
          .map((snap) => _filterQuestions(
              snap.docs.map((doc) => Question.fromMap(doc.id, doc.data())).toList(),
              board: board,
              classLevel: classLevel,
              subject: subject,
              chapter: chapter,
              search: search));
    } catch (e) {
      debugPrint('FirestoreService.watchQuestions failed: $e');
      rethrow;
    }
  }

  /// One-shot fetch of questions with the same filtering rules.
  Future<List<Question>> fetchQuestions({
    String? board,
    String? classLevel,
    String? subject,
    String? chapter,
    int limit = 60,
  }) async {
    try {
      final snap = await _questionsBaseQuery(board: board, subject: subject)
          .limit(limit)
          .get();
      return _filterQuestions(
        snap.docs.map((doc) => Question.fromMap(doc.id, doc.data())).toList(),
        board: board,
        classLevel: classLevel,
        subject: subject,
        chapter: chapter,
      );
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.fetchQuestions failed: ${e.code}');
      rethrow;
    }
  }

  /// Adds a new question document. Returns the generated document id.
  Future<String> addQuestion(Question q) async {
    try {
      final data = Map<String, dynamic>.from(q.toMap())..remove('id');
      final doc = await _questions.add(data);
      return doc.id;
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.addQuestion failed: ${e.code}');
      rethrow;
    }
  }

  /// Updates an existing question (merge so nothing else is lost).
  Future<void> updateQuestion(Question q) async {
    try {
      await _questions.doc(q.id).set(q.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.updateQuestion failed: ${e.code}');
      rethrow;
    }
  }

  /// Deletes a question permanently.
  Future<void> deleteQuestion(String id) async {
    try {
      await _questions.doc(id).delete();
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.deleteQuestion failed: ${e.code}');
      rethrow;
    }
  }

  /// Saves a finished quiz attempt for [uid] into `results`.
  Future<void> saveResult(String uid, QuizResult result) async {
    try {
      await _results.add(result.toMap(uid));
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.saveResult failed: ${e.code}');
      rethrow;
    }
  }

  /// Creates a live-test room with a unique 6-char code. Returns the code.
  Future<String> createRoom({
    required String hostUid,
    required String board,
    required String classLevel,
    required String subject,
    required int questionCount,
  }) async {
    try {
      final random = Random();
      const alphabet = AppConstants.roomCodeAlphabet;
      String code = '';
      var unique = false;
      for (var i = 0; i < _maxRoomCodeTries && !unique; i++) {
        code = List.generate(
          _roomCodeLength,
          (_) => alphabet[random.nextInt(alphabet.length)],
        ).join();
        unique = !(await _rooms.doc(code).get()).exists;
      }
      if (!unique) {
        throw StateError('Could not generate a unique room code');
      }
      await _rooms.doc(code).set({
        'hostUid': hostUid,
        'board': board,
        'classLevel': classLevel,
        'subject': subject,
        'questionCount': questionCount,
        'status': 'waiting',
        'createdAt': Timestamp.now(),
      });
      return code;
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.createRoom failed: ${e.code}');
      rethrow;
    }
  }

  /// Live stream of a room document; emits null when the room does not exist.
  Stream<TestRoom?> watchRoom(String code) {
    try {
      return _rooms.doc(code).snapshots().map((doc) => (!doc.exists || doc.data() == null)
          ? null
          : TestRoom.fromMap(doc.id, doc.data()!));
    } catch (e) {
      debugPrint('FirestoreService.watchRoom failed: $e');
      rethrow;
    }
  }

  /// Updates a room's status ('waiting' | 'live' | 'ended').
  Future<void> setRoomStatus(String code, String status) async {
    try {
      await _rooms.doc(code).update({'status': status});
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.setRoomStatus failed: ${e.code}');
      rethrow;
    }
  }

  /// Adds [uid] as a participant of room [code] (merge: re-join keeps answers).
  Future<void> joinRoom({
    required String code,
    required String uid,
    required String name,
  }) async {
    try {
      await _rooms.doc(code).collection('participants').doc(uid).set(
        {
          'name': name,
          'score': 0,
          'answers': <String, dynamic>{},
          'joinedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.joinRoom failed: ${e.code}');
      rethrow;
    }
  }

  /// Live stream of room participants, highest score first.
  Stream<List<RoomParticipant>> watchParticipants(String code) {
    try {
      return _rooms
          .doc(code)
          .collection('participants')
          .orderBy('score', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => RoomParticipant.fromMap(doc.id, doc.data()))
              .toList());
    } catch (e) {
      debugPrint('FirestoreService.watchParticipants failed: $e');
      rethrow;
    }
  }

  /// Records one answer (read-modify-write on the answers map) and the score.
  Future<void> submitRoomAnswer({
    required String code,
    required String uid,
    required String questionId,
    required int? selectedIndex,
    required int score,
  }) async {
    try {
      final ref = _rooms.doc(code).collection('participants').doc(uid);
      final answers = Map<String, dynamic>.from(
          (await ref.get()).data()?['answers'] as Map? ?? {});
      if (selectedIndex == null) {
        answers.remove(questionId);
      } else {
        answers[questionId] = selectedIndex;
      }
      await ref.set({'answers': answers, 'score': score}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.submitRoomAnswer failed: ${e.code}');
      rethrow;
    }
  }

  /// Saves a teacher-made test document into `tests`. Returns the doc id.
  Future<String> saveTest(Map<String, dynamic> data) async {
    try {
      final doc = await _tests.add(data);
      return doc.id;
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.saveTest failed: ${e.code}');
      rethrow;
    }
  }

  /// Leaderboard: latest results filtered client-side, with score percentage.
  Stream<List<Map<String, dynamic>>> watchLeaderboard({
    String? board,
    String? classLevel,
    int limit = 20,
  }) {
    try {
      return _results
          .orderBy('createdAt', descending: true)
          .limit(40)
          .snapshots()
          .map((snap) {
        final entries = <Map<String, dynamic>>[];
        for (final doc in snap.docs) {
          final data = doc.data();
          if (board != null && board.isNotEmpty && data['board'] != board) {
            continue;
          }
          if (classLevel != null &&
              classLevel.isNotEmpty &&
              data['classLevel'] != classLevel) {
            continue;
          }
          final total = (data['totalQuestions'] as num?)?.toInt() ?? 0;
          final correct = (data['correct'] as num?)?.toInt() ?? 0;
          final scorePercent = total == 0 ? 0.0 : correct / total * 100;
          entries.add({
            'id': doc.id,
            'uid': data['uid'],
            'board': data['board'],
            'classLevel': data['classLevel'],
            'subject': data['subject'],
            'totalQuestions': total,
            'correct': correct,
            'scorePercent': scorePercent,
            'createdAt': data['createdAt'],
          });
          if (entries.length >= limit) break;
        }
        return entries;
      });
    } catch (e) {
      debugPrint('FirestoreService.watchLeaderboard failed: $e');
      rethrow;
    }
  }

  /// Returns the display name for [uid], falling back to 'Student'.
  Future<String> userName(String uid) async {
    try {
      final name = (await _users.doc(uid).get()).data()?['name'] as String?;
      return (name != null && name.isNotEmpty) ? name : 'Student';
    } on FirebaseException catch (e) {
      debugPrint('FirestoreService.userName failed: ${e.code}');
      rethrow;
    }
  }
}
