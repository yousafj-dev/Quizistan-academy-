import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/models/quiz_result.dart';
import 'package:quizistan_academy/screens/home/home_screen.dart';
import 'package:quizistan_academy/screens/quiz/quiz_screen.dart';
import 'package:quizistan_academy/services/ad_service.dart';
import 'package:quizistan_academy/services/quiz_engine.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result});

  final QuizResult result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    // Quiz khatam hone par poori screen ka ad (zyada se zyada 3 min me 1 baar)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.showInterstitialIfDue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final mistakes = result.mistakes;

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Tumhara Score',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.scorePercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Score',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('Sahi', result.correct, Colors.green),
              const SizedBox(width: 8),
              _statCard('Ghalat', result.wrong, Colors.red),
              const SizedBox(width: 8),
              _statCard('Choray', result.skipped, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Ghaltiyan dekho',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (mistakes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Kamal! Sab jawab sahi! 🎉',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          else
            for (final m in mistakes)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.question.text,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tumhara jawab: ${m.selectedIndex == null ? 'Chor diya' : m.question.options[m.selectedIndex!]}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      Text(
                        'Sahi jawab: ${m.question.options[m.question.correctIndex]}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (m.question.explanation.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          m.question.explanation,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 16),
          if (mistakes.isNotEmpty)
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  context.read<QuizEngine>().start(
                        mistakes.map((m) => m.question).toList(),
                        secondsPerQuestion: 30,
                        board: result.board,
                        classLevel: result.classLevel,
                        subject: result.subject,
                        chapter: result.chapter,
                      );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuizScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.royalPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ghalat Sawal Dobara'),
              ),
            ),
          if (mistakes.isNotEmpty) const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
