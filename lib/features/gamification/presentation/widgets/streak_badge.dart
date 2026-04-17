import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak, this.compact = false});

  final int streak;
  final bool compact;

  Color get _tierColor {
    if (streak == 0) return AppColors.textMuted;
    if (streak < 7) return AppColors.streakOrange;
    if (streak < 30) return AppColors.streakRed;
    if (streak < 100) return AppColors.streakGold;
    return AppColors.streakDiamond;
  }

  @override
  Widget build(BuildContext context) {
    final color = _tierColor;
    final iconSize = compact ? 16.0 : 22.0;
    final fontSize = compact ? 13.0 : 16.0;

    if (streak == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            '0',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, size: iconSize, color: color),
        const SizedBox(width: 4),
        Text(
          '$streak',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
