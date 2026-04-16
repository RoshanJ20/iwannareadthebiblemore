import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';

class XpBadge extends StatelessWidget {
  const XpBadge({super.key, required this.xpTotal, this.compact = false});

  final int xpTotal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 16.0 : 22.0;
    final fontSize = compact ? 13.0 : 16.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monetization_on, size: iconSize, color: AppColors.xpGold),
        const SizedBox(width: 4),
        Text(
          _formatXp(xpTotal),
          style: TextStyle(
            color: AppColors.xpGold,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
