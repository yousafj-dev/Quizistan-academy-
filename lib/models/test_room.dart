import 'package:cloud_firestore/cloud_firestore.dart';

/// A live test room hosted by a teacher.
class TestRoom {
  final String code;
  final String hostUid;
  final String board;
  final String classLevel;
  final String subject;
  final int questionCount;
  final String status; // waiting | live | ended
  final DateTime createdAt;

  const TestRoom({
    required this.code,
    required this.hostUid,
    required this.board,
    required this.classLevel,
    required this.subject,
    required this.questionCount,
    required this.status,
    required this.createdAt,
  });

  factory TestRoom.fromMap(String code, Map<String, dynamic> map) {
    return TestRoom(
      code: code,
      hostUid: map['hostUid'] as String? ?? '',
      board: map['board'] as String? ?? '',
      classLevel: map['classLevel'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      questionCount: map['questionCount'] as int? ?? 10,
      status: map['status'] as String? ?? 'waiting',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostUid': hostUid,
      'board': board,
      'classLevel': classLevel,
      'subject': subject,
      'questionCount': questionCount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// One student's live participation in a room.
class RoomParticipant {
  final String uid;
  final String name;
  final int score;
  final Map<String, int> answers; // questionId -> selectedIndex
  final DateTime joinedAt;

  const RoomParticipant({
    required this.uid,
    required this.name,
    required this.score,
    required this.answers,
    required this.joinedAt,
  });

  factory RoomParticipant.fromMap(String uid, Map<String, dynamic> map) {
    return RoomParticipant(
      uid: uid,
      name: map['name'] as String? ?? '',
      score: map['score'] as int? ?? 0,
      answers: Map<String, int>.from(map['answers'] as Map? ?? const {}),
      joinedAt:
          (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'score': score,
      'answers': answers,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
