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
    final iconSize = compact ? 13.0 : 17.0;
    final fontSize = compact ? 12.0 : 13.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            streak == 0 ? Icons.circle_outlined : Icons.local_fire_department,
            size: iconSize,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '$streak',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 2),
            Text(
              streak == 1 ? 'day' : 'days',
              style: TextStyle(
                color: color.withOpacity(0.65),
                fontSize: fontSize - 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
