import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../domain/entities/achievement.dart';

class AchievementTile extends StatelessWidget {
  const AchievementTile({
    super.key,
    required this.achievement,
    required this.earned,
    this.earnedAt,
  });

  final Achievement achievement;
  final bool earned;
  final DateTime? earnedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: earned ? AppColors.primary.withOpacity(0.4) : AppColors.textMuted.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                achievement.iconEmoji,
                style: TextStyle(
                  fontSize: 36,
                  color: earned ? null : AppColors.textMuted,
                ),
              ),
              if (!earned)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.lock, size: 16, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: earned ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          if (earned && earnedAt != null)
            Text(
              DateFormat('MMM d, yyyy').format(earnedAt!),
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 11,
              ),
            )
          else
            Text(
              achievement.condition,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
