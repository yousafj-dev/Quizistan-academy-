import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/screens/quiz/result_screen.dart';
import 'package:quizistan_academy/services/analytics_service.dart';
import 'package:quizistan_academy/services/auth_service.dart';
import 'package:quizistan_academy/services/firestore_service.dart';
import 'package:quizistan_academy/services/quiz_engine.dart';
import 'package:quizistan_academy/widgets/option_button.dart';
import 'package:quizistan_academy/widgets/question_card.dart';
import 'package:quizistan_academy/widgets/timer_ring.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<QuizEngine>();

    if (engine.totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Koi sawal nahi mile.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Wapis'),
              ),
            ],
          ),
        ),
      );
    }

    if (engine.isFinished) {
      if (!_done) {
        _done = true;
        final engine = context.read<QuizEngine>();
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final result = engine.finish();
          try {
            // Offline: result sirf is session me dikhta hai, save online par hoga.
            if (AuthService.firebaseReady) {
              final uid = (await AuthService.instance.ensureSignedIn()).uid;
              await FirestoreService().saveResult(uid, result);
            }
          } catch (e) {
            debugPrint('saveResult failed: $e');
          }
          await AnalyticsService.instance.logQuizComplete(
            subject: result.subject,
            total: result.total,
            correct: result.correct,
          );
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ResultScreen(result: result),
              ),
            );
          }
        });
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final q = engine.currentQuestion;
    const labels = ['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Sawal ${engine.currentIndex + 1} of ${engine.totalQuestions}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value:
                      (engine.currentIndex + 1) / engine.totalQuestions,
                  backgroundColor: Colors.grey.shade200,
                  color: AppTheme.royalPurple,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TimerRing(
                    secondsLeft: engine.secondsLeft,
                    totalSeconds: 30,
                  ),
                ),
                const SizedBox(height: 16),
                QuestionCard(
                  question: q,
                  index: engine.currentIndex,
                  total: engine.totalQuestions,
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OptionButton(
                      label: labels[i],
                      text: q.options[i],
                      state: _optionState(engine, i),
                      onTap: engine.isAnswered
                          ? null
                          : () => engine.selectOption(i),
                    ),
                  ),
                if (engine.isAnswered)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: engine.selectedIndex == q.correctIndex
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      engine.selectedIndex == q.correctIndex
                          ? 'Jawab sahi! 🎉'
                          : 'Ghalat! Sahi jawab: ${q.options[q.correctIndex]}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: engine.selectedIndex == q.correctIndex
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (!engine.isAnswered)
                    Expanded(
                      child: TextButton(
                        onPressed: () => engine.skip(),
                        child: const Text('Choro'),
                      ),
                    ),
                  if (engine.isAnswered)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => engine.next(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.vividOrange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Agla Sawal'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  OptionState _optionState(QuizEngine engine, int i) {
    final q = engine.currentQuestion;
    if (!engine.isAnswered) {
      return engine.selectedIndex == i
          ? OptionState.selected
          : OptionState.normal;
    }
    if (i == q.correctIndex) return OptionState.correct;
    if (i == engine.selectedIndex) return OptionState.wrong;
    return OptionState.disabled;
  }
}
