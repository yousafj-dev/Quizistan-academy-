import 'package:flutter/material.dart';

/// Brand logo widget — shows the Quizistan Academy logo image.
/// User-facing text rule: no text here, just the logo image.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.borderRadius = 18});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/quizistan-logo.webp',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.grey.shade200,
          ),
          alignment: Alignment.center,
          child: Text(
            'Q',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
