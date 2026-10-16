import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizistan_academy/core/constants/app_constants.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/models/question.dart';
import 'package:quizistan_academy/screens/quiz/quiz_screen.dart';
import 'package:quizistan_academy/services/analytics_service.dart';
import 'package:quizistan_academy/services/auth_service.dart';
import 'package:quizistan_academy/services/firestore_service.dart';
import 'package:quizistan_academy/services/local_question_bank.dart';
import 'package:quizistan_academy/services/quiz_engine.dart';
import 'package:quizistan_academy/widgets/app_logo.dart';

class SetupQuizScreen extends StatefulWidget {
  const SetupQuizScreen({super.key});

  @override
  State<SetupQuizScreen> createState() => _SetupQuizScreenState();
}

class _SetupQuizScreenState extends State<SetupQuizScreen> {
  String? _board = AppConstants.boards.first;
  String? _classLevel = AppConstants.classLevels.first;
  String? _subject = AppConstants.subjects.first;
  final TextEditingController _chapter = TextEditingController();
  double _count = AppConstants.defaultQuestionCount.toDouble();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _chapter.dispose();
    super.dispose();
  }

  Future<void> _startQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Offline mode: no sign-in needed; profile/limits stay on the phone.
      String uid = 'local-user';
      if (AuthService.firebaseReady) {
        try {
          uid = (await AuthService.instance.ensureSignedIn()).uid;
        } catch (e) {
          debugPrint('SetupQuiz sign-in failed: $e');
        }
      }
      final profile = await AuthService.instance.loadProfile();
      final isPremium = profile?.isPremium ?? false;

      final prefs = await SharedPreferences.getInstance();
      final dayKey =
          'quiz_count_${DateTime.now().toIso8601String().substring(0, 10)}';
      final used = prefs.getInt(dayKey) ?? 0;
      if (!isPremium && used >= AppConstants.freeDailyQuizLimit) {
        setState(() {
          _loading = false;
          _error = 'Aaj ka free limit khatam! Kal dobara try karo ya Premium lo.';
        });
        return;
      }

      final chapterText = _chapter.text.trim();
      List<Question> questions = const [];
      if (AuthService.firebaseReady) {
        try {
          questions = await FirestoreService().fetchQuestions(
            board: _board,
            classLevel: _classLevel,
            subject: _subject,
            chapter: chapterText.isEmpty ? null : chapterText,
            limit: 60,
          );
        } catch (e) {
          debugPrint('SetupQuiz remote fetch failed: $e');
        }
      }
      if (questions.isEmpty) {
        // Offline ya khali result: bundled sample sawalat.
        questions = await LocalQuestionBank.fetch(
          classLevel: _classLevel,
          subject: _subject,
          chapter: chapterText.isEmpty ? null : chapterText,
          limit: 60,
        );
      }
      questions.shuffle();
      final finalList = questions.take(_count.round()).toList();
      if (finalList.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Is filter me sawal nahi mile. Subject ya class badal ke try karo.';
        });
        return;
      }

      if (!isPremium) {
        await prefs.setInt(dayKey, used + 1);
      }

      if (!mounted) return;
      final engine = context.read<QuizEngine>();
      engine.start(
        finalList,
        secondsPerQuestion: AppConstants.defaultSecondsPerQuestion,
        board: _board ?? '',
        classLevel: _classLevel ?? '',
        subject: _subject ?? '',
        chapter: chapterText,
      );
      debugPrint('Quiz started for uid=$uid with ${finalList.length} questions');
      await AnalyticsService.instance.logQuizStart(
        board: _board ?? '',
        classLevel: _classLevel ?? '',
        subject: _subject ?? '',
        count: finalList.length,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QuizScreen()),
        );
      }
    } catch (e) {
      debugPrint('Setup quiz failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          // Never show raw technical errors to the user.
          _error = 'Quiz shuru nahi ho saka. Dobara try karo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: AppLogo(size: 56)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _board,
            decoration: const InputDecoration(labelText: 'Board'),
            items: AppConstants.boards
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _board = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _classLevel,
            decoration: const InputDecoration(labelText: 'Class'),
            items: AppConstants.classLevels
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _classLevel = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: AppConstants.subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _subject = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chapter,
            decoration: const InputDecoration(
              labelText: 'Chapter (optional)',
              hintText: 'e.g. Photosynthesis',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sawalon ki tadad: ${_count.round()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _count,
            min: 5,
            max: 30,
            divisions: 25,
            label: '${_count.round()}',
            onChanged: (v) => setState(() => _count = v),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vividOrange,
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Quiz Shuru Karo'),
            ),
          ),
        ],
      ),
    );
  }
}
