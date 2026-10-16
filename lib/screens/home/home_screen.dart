import 'package:flutter/material.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';
import 'package:quizistan_academy/screens/bank/question_bank_screen.dart';
import 'package:quizistan_academy/screens/live/live_room_host_screen.dart';
import 'package:quizistan_academy/screens/live/live_room_join_screen.dart';
import 'package:quizistan_academy/screens/maker/test_maker_screen.dart';
import 'package:quizistan_academy/screens/plans/plans_screen.dart';
import 'package:quizistan_academy/screens/profile/profile_screen.dart';
import 'package:quizistan_academy/screens/quiz/setup_quiz_screen.dart';
import 'package:quizistan_academy/services/ad_service.dart';
import 'package:quizistan_academy/widgets/app_logo.dart';

/// Home screen: brand header, 6-card menu grid, banner ad at the bottom.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openLiveRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Live Room',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Live test host karna hai ya join karna hai?'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LiveRoomHostScreen(),
                    ),
                  );
                },
                child: const Text('Host karo (Teacher)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LiveRoomJoinScreen(),
                    ),
                  );
                },
                child: const Text('Join karo (Student)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Brand header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: const Row(
                children: [
                  AppLogo(size: 54, borderRadius: 14),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assalam-o-Alaikum!',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Quizistan Academy',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Menu grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                childAspectRatio: 1.05,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  _MenuCard(
                    label: 'Quiz Shuru Karo',
                    icon: Icons.quiz,
                    color: AppTheme.deepBlue,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SetupQuizScreen(),
                      ),
                    ),
                  ),
                  _MenuCard(
                    label: 'Question Bank',
                    icon: Icons.library_books,
                    color: AppTheme.royalPurple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QuestionBankScreen(),
                      ),
                    ),
                  ),
                  _MenuCard(
                    label: 'Test Maker',
                    icon: Icons.build,
                    color: AppTheme.vividOrange,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TestMakerScreen(),
                      ),
                    ),
                  ),
                  _MenuCard(
                    label: 'Live Room',
                    icon: Icons.groups,
                    color: AppTheme.deepBlue,
                    onTap: () => _openLiveRoomDialog(context),
                  ),
                  _MenuCard(
                    label: 'Plans',
                    icon: Icons.star,
                    color: AppTheme.vividOrange,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlansScreen(),
                      ),
                    ),
                  ),
                  _MenuCard(
                    label: 'Profile',
                    icon: Icons.person,
                    color: AppTheme.royalPurple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(child: AdService.instance.bannerAd()),
    );
  }
}

/// Single tappable menu card in the home grid.
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.inkNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
