import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';

class XpBadge extends StatelessWidget {
  const XpBadge({super.key, required this.xpTotal, this.compact = false});

  final int xpTotal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 13.0 : 17.0;
    final fontSize = compact ? 12.0 : 13.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.xpGold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.xpGold.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: iconSize, color: AppColors.xpGold),
          const SizedBox(width: 5),
          Text(
            _formatXp(xpTotal),
            style: TextStyle(
              color: AppColors.xpGold,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      final k = xp / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k XP';
    }
    return '$xp XP';
  }
}
