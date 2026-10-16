import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/screens/splash/splash_screen.dart';
import 'package:quizistan_academy/services/ad_service.dart';
import 'package:quizistan_academy/services/quiz_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase is optional at runtime: the app still opens (with bundled
  // sample questions) when init fails, e.g. before google-services is added.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
  // AdMob is stub-safe: banner areas stay empty when init fails.
  await AdService.instance.init();
  runApp(const QuizistanApp());
}

class QuizistanApp extends StatelessWidget {
  const QuizistanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizEngine()),
      ],
      child: MaterialApp(
        title: 'Quizistan Academy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
