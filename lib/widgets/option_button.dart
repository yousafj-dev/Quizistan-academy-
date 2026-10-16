import 'package:flutter/material.dart';
import 'package:quizistan_academy/core/theme/app_theme.dart';

/// Visual state of an answer option.
enum OptionState { normal, selected, correct, wrong, disabled }

/// Full-width tappable answer option: label circle (A/B/C/D) + text.
/// Colours change with [state]; taps are ignored when answered or disabled.
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  bool get _isInteractive =>
      onTap != null &&
      state != OptionState.correct &&
      state != OptionState.wrong &&
      state != OptionState.disabled;

  Color get _backgroundColor {
    switch (state) {
      case OptionState.selected:
        return AppTheme.deepBlue.withValues(alpha: 0.08);
      case OptionState.correct:
        return Colors.green.shade100;
      case OptionState.wrong:
        return Colors.red.shade100;
      case OptionState.disabled:
        return Colors.grey.shade200;
      case OptionState.normal:
        return Colors.white;
    }
  }

  Color get _borderColor {
    switch (state) {
      case OptionState.selected:
        return AppTheme.deepBlue;
      case OptionState.correct:
        return Colors.green;
      case OptionState.wrong:
        return Colors.red;
      case OptionState.disabled:
        return Colors.grey.shade300;
      case OptionState.normal:
        return Colors.grey.shade300;
    }
  }

  Color get _labelCircleColor {
    switch (state) {
      case OptionState.selected:
        return AppTheme.deepBlue;
      case OptionState.correct:
        return Colors.green;
      case OptionState.wrong:
        return Colors.red;
      case OptionState.disabled:
        return Colors.grey.shade400;
      case OptionState.normal:
        return AppTheme.deepBlue.withValues(alpha: 0.7);
    }
  }

  Widget? get _trailingIcon {
    switch (state) {
      case OptionState.correct:
        return const Icon(Icons.check_circle, color: Colors.green, size: 24);
      case OptionState.wrong:
        return const Icon(Icons.cancel, color: Colors.red, size: 24);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isInteractive ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _labelCircleColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: state == OptionState.disabled
                        ? Colors.grey.shade600
                        : AppTheme.inkNavy,
                  ),
                ),
              ),
              if (_trailingIcon != null) ...[
                const SizedBox(width: 8),
                _trailingIcon!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
