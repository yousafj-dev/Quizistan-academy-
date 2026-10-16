import 'package:flutter/material.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';

/// Circular countdown ring. Turns orange when <= 10s, red when <= 5s.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  final int secondsLeft;
  final int totalSeconds;

  Color get _ringColor {
    if (secondsLeft <= 5) return Colors.red;
    if (secondsLeft <= 10) return AppTheme.vividOrange;
    return AppTheme.deepBlue;
  }

  @override
  Widget build(BuildContext context) {
    final value =
        totalSeconds == 0 ? 0.0 : (secondsLeft / totalSeconds).clamp(0.0, 1.0);
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 7,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(_ringColor),
          ),
          Text(
            '$secondsLeft',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _ringColor,
            ),
          ),
        ],
      ),
    );
  }
}
