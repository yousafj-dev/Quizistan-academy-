import 'package:cloud_firestore/cloud_firestore.dart';

/// A single MCQ in the question bank.
class Question {
  final String id;
  final String board;
  final String classLevel;
  final String subject;
  final String chapter;
  final String text;
  final List<String> options; // always 4
  final int correctIndex;
  final String explanation;
  final String createdBy;
  final DateTime createdAt;

  const Question({
    required this.id,
    required this.board,
    required this.classLevel,
    required this.subject,
    required this.chapter,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.createdBy,
    required this.createdAt,
  });

  factory Question.fromMap(String id, Map<String, dynamic> map) {
    return Question(
      id: id,
      board: map['board'] as String? ?? '',
      classLevel: map['classLevel'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      chapter: map['chapter'] as String? ?? '',
      text: map['text'] as String? ?? '',
      options: List<String>.from(map['options'] as List? ?? const []),
      correctIndex: map['correctIndex'] as int? ?? 0,
      explanation: map['explanation'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'board': board,
      'classLevel': classLevel,
      'subject': subject,
      'chapter': chapter,
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isValid =>
      text.isNotEmpty &&
      options.length == 4 &&
      correctIndex >= 0 &&
      correctIndex < 4 &&
      board.isNotEmpty &&
      classLevel.isNotEmpty &&
      subject.isNotEmpty;
}
