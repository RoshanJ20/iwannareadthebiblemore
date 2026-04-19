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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: earned
              ? AppColors.primary.withOpacity(0.35)
              : AppColors.textMuted.withOpacity(0.15),
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (earned)
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              Opacity(
                opacity: earned ? 1.0 : 0.35,
                child: Text(
                  achievement.iconEmoji,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
              if (!earned)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.lock_rounded, size: 14, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: earned ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w500,
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
