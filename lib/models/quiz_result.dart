import 'package:quizistan_academy/models/question.dart';

/// One answered question inside a finished quiz.
class AnsweredQuestion {
  final Question question;
  final int? selectedIndex; // null = skipped
  final int secondsTaken;

  const AnsweredQuestion({
    required this.question,
    required this.selectedIndex,
    required this.secondsTaken,
  });

  bool get isCorrect => selectedIndex == question.correctIndex;
  bool get isSkipped => selectedIndex == null;
}

/// The result of a finished quiz session.
class QuizResult {
  final String board;
  final String classLevel;
  final String subject;
  final String chapter;
  final List<AnsweredQuestion> answers;
  final int durationSecs;
  final DateTime createdAt;

  const QuizResult({
    required this.board,
    required this.classLevel,
    required this.subject,
    required this.chapter,
    required this.answers,
    required this.durationSecs,
    required this.createdAt,
  });

  int get total => answers.length;
  int get correct => answers.where((a) => a.isCorrect).length;
  int get wrong => answers.where((a) => !a.isCorrect && !a.isSkipped).length;
  int get skipped => answers.where((a) => a.isSkipped).length;
  double get scorePercent => total == 0 ? 0 : (correct / total) * 100;

  List<AnsweredQuestion> get mistakes =>
      answers.where((a) => !a.isCorrect).toList();

  Map<String, dynamic> toMap(String uid) {
    return {
      'uid': uid,
      'board': board,
      'classLevel': classLevel,
      'subject': subject,
      'chapter': chapter,
      'totalQuestions': total,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'durationSecs': durationSecs,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
