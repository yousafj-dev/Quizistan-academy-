import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quizistan_academy/models/question.dart';
import 'package:quizistan_academy/models/quiz_result.dart';

/// Quizistan ka quiz engine: per-question countdown, answer lock,
/// skip/timeout tracking aur final QuizResult banata hai.
///
/// Main.dart `ChangeNotifierProvider(create: (_) => QuizEngine())` use karta
/// hai, is liye default constructor zaroori hai.
class QuizEngine extends ChangeNotifier {
  List<Question> _questions = const [];
  final List<AnsweredQuestion> _answers = [];

  int _index = 0;
  int? _selectedIndex;
  Timer? _timer;
  int _secondsLeft = 0;
  int _secondsPerQuestion = 30;
  DateTime? _questionStartTime;
  DateTime? _quizStartTime;

  String _board = '';
  String _classLevel = '';
  String _subject = '';
  String _chapter = '';

  bool _finished = false;

  // ---------------------------------------------------------- getters ----

  /// Current question — sirf tab call karein jab totalQuestions > 0 ho.
  Question get currentQuestion => _questions[_index];

  int get currentIndex => _index;

  int get totalQuestions => _questions.length;

  int get secondsLeft => _secondsLeft;

  /// null = user ne abhi jawab nahi diya.
  int? get selectedIndex => _selectedIndex;

  bool get isAnswered => _selectedIndex != null || _isTimedOut;

  bool _isTimedOut = false;

  bool get isFinished => _finished;

  /// Kitne sawalat jawab dye ja chukay (answered / skipped / timeout).
  int get answeredCount => _answers.length;

  // ------------------------------------------------------- quiz flow ----

  /// Naya quiz shuru karta hai. Empty list par foran finished.
  void start(
    List<Question> questions, {
    int secondsPerQuestion = 30,
    String board = '',
    String classLevel = '',
    String subject = '',
    String chapter = '',
  }) {
    reset(notify: false);
    _questions = List<Question>.unmodifiable(questions);
    _secondsPerQuestion = secondsPerQuestion;
    _board = board;
    _classLevel = classLevel;
    _subject = subject;
    _chapter = chapter;

    if (_questions.isEmpty) {
      // Khali quiz: crash se bachne ke liye foran finished.
      _finished = true;
      notifyListeners();
      return;
    }

    _quizStartTime = DateTime.now();
    _startQuestionTimer();
    notifyListeners();
  }

  /// Option select karna = jawab lock. Sirf ek dafa kaam karta hai.
  void selectOption(int index) {
    if (_finished || isAnswered) return;
    if (_questions.isEmpty) return;
    if (index < 0 || index >= currentQuestion.options.length) return;

    _timer?.cancel();
    _selectedIndex = index;
    _answers.add(
      AnsweredQuestion(
        question: currentQuestion,
        selectedIndex: index,
        secondsTaken: _elapsedQuestionSeconds(),
      ),
    );
    notifyListeners();
  }

  /// Agla sawal — sirf tab jab current ka jawab ho chuka ho (ya skip).
  void next() {
    if (_finished || !isAnswered) return;
    _advance();
  }

  /// Jawab diye baghair aagay barhna — skipped record hota hai.
  void skip() {
    if (_finished || isAnswered) return;
    _timer?.cancel();
    _answers.add(
      AnsweredQuestion(
        question: currentQuestion,
        selectedIndex: null,
        secondsTaken: _elapsedQuestionSeconds(),
      ),
    );
    _advance();
  }

  /// Quiz khatam kar ke result banata hai. Bachay huay sawalat
  /// skipped count hotay hain.
  QuizResult finish() {
    _timer?.cancel();
    _finished = true;

    // Jo sawalat reh gaye, unhein skipped record kar do.
    for (var i = _answers.length; i < _questions.length; i++) {
      _answers.add(
        AnsweredQuestion(
          question: _questions[i],
          selectedIndex: null,
          secondsTaken: 0,
        ),
      );
    }

    final durationSecs = _quizStartTime == null
        ? 0
        : DateTime.now().difference(_quizStartTime!).inSeconds;

    final result = QuizResult(
      board: _board,
      classLevel: _classLevel,
      subject: _subject,
      chapter: _chapter,
      answers: List<AnsweredQuestion>.unmodifiable(_answers),
      durationSecs: durationSecs,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    return result;
  }

  /// Sab state clear.
  void reset({bool notify = true}) {
    _timer?.cancel();
    _questions = const [];
    _answers.clear();
    _index = 0;
    _selectedIndex = null;
    _isTimedOut = false;
    _secondsLeft = 0;
    _secondsPerQuestion = 30;
    _questionStartTime = null;
    _quizStartTime = null;
    _board = '';
    _classLevel = '';
    _subject = '';
    _chapter = '';
    _finished = false;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------- internals ----

  void _startQuestionTimer() {
    _timer?.cancel();
    _selectedIndex = null;
    _isTimedOut = false;
    _secondsLeft = _secondsPerQuestion;
    _questionStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        // Timeout: sawal auto-skip ho kar agla aata hai.
        timer.cancel();
        _secondsLeft = 0;
        _isTimedOut = true;
        _answers.add(
          AnsweredQuestion(
            question: currentQuestion,
            selectedIndex: null,
            secondsTaken: _secondsPerQuestion,
          ),
        );
        notifyListeners();
        _advance();
      } else {
        notifyListeners();
      }
    });
  }

  /// Agla sawal, ya aakhri tha to finish.
  void _advance() {
    if (_index + 1 < _questions.length) {
      _index++;
      _startQuestionTimer();
      notifyListeners();
    } else {
      finish();
    }
  }

  /// Is sawal par ab tak kitne second lagay (0..secondsPerQuestion).
  int _elapsedQuestionSeconds() {
    if (_questionStartTime == null) return 0;
    final elapsed = DateTime.now().difference(_questionStartTime!).inSeconds;
    return elapsed.clamp(0, _secondsPerQuestion);
  }
}
