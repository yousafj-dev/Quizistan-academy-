import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizistan_academy/core/constants/app_constants.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/models/question.dart';
import 'package:quizistan_academy/screens/quiz/quiz_screen.dart';
import 'package:quizistan_academy/services/auth_service.dart';
import 'package:quizistan_academy/services/firestore_service.dart';
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
      final uid = (await AuthService.instance.ensureSignedIn()).uid;
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
      var questions = await FirestoreService().fetchQuestions(
        board: _board,
        classLevel: _classLevel,
        subject: _subject,
        chapter: chapterText.isEmpty ? null : chapterText,
        limit: 60,
      );
      if (questions.isEmpty) {
        debugPrint('No remote questions, using bundled samples');
        questions = _fallbackQuestions();
      }
      questions.shuffle();
      final finalList = questions.take(_count.round()).toList();
      if (finalList.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Sawal nahi mile. Filter badal ke try karo.';
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
          _error = 'Kuch garbar ho gayi: $e';
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
            initialValue: _board,
            decoration: const InputDecoration(labelText: 'Board'),
            items: AppConstants.boards
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _board = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _classLevel,
            decoration: const InputDecoration(labelText: 'Class'),
            items: AppConstants.classLevels
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _classLevel = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _subject,
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

List<Question> _fallbackQuestions() {
  final now = DateTime.now();
  Question q(
    String id,
    String subject,
    String text,
    List<String> options,
    int correctIndex,
    String explanation,
  ) =>
      Question(
        id: id,
        board: 'Lahore',
        classLevel: '10',
        subject: subject,
        chapter: '',
        text: text,
        options: options,
        correctIndex: correctIndex,
        explanation: explanation,
        createdBy: 'bundled',
        createdAt: now,
      );

  return [
    q('sample-1', 'Physics', 'Unit of force ka SI unit kya hai?',
        ['Newton', 'Joule', 'Watt', 'Pascal'], 0,
        'Force ka SI unit Newton hai, jiska naam Isaac Newton par rakha gaya.'),
    q('sample-2', 'Chemistry', 'H2O ka common naam kya hai?',
        ['Oxygen', 'Hydrogen', 'Pani', 'Carbon dioxide'], 2,
        'H2O pani ka chemical formula hai — do hydrogen aur ek oxygen.'),
    q('sample-3', 'Biology', 'Photosynthesis plants ke kis hisse mein hoti hai?',
        ['Root', 'Leaf', 'Stem', 'Flower'], 1,
        'Leaf mein chlorophyll hota hai jo sunlight se khana banata hai.'),
    q('sample-4', 'Math', '2x + 4 = 10, to x ki value kya hogi?',
        ['2', '3', '4', '5'], 1,
        '2x = 10 - 4 = 6, is liye x = 3.'),
    q('sample-5', 'English', '"Happy" ka opposite word kya hai?',
        ['Glad', 'Sad', 'Joyful', 'Cheerful'], 1,
        'Happy ka antonym Sad hai.'),
    q('sample-6', 'Urdu', 'Pakistan ka qaumi khel konsa hai?',
        ['Cricket', 'Hockey', 'Football', 'Squash'], 1,
        'Hockey Pakistan ka qaumi khel hai.'),
    q('sample-7', 'Physics', 'Speed of light kitni hoti hai?',
        ['3 x 10^8 m/s', '3 x 10^6 m/s', '1.5 x 10^8 m/s', '3 x 10^5 m/s'], 0,
        'Vacuum mein light ki speed taqreeban 3 x 10^8 m/s hoti hai.'),
    q('sample-8', 'Math', '15 ka 20% kitna hota hai?',
        ['2', '3', '4', '5'], 1,
        '15 x 0.20 = 3.'),
  ];
}
