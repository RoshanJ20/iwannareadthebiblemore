import 'package:flutter/material.dart';
import '../../domain/models/streak_tier.dart';

class StreakWidget extends StatelessWidget {
  final int streak;
  const StreakWidget({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final tier = StreakTierX.fromStreak(streak);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, color: tier.color, size: 28),
        const SizedBox(width: 4),
        Text(
          '$streak',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: tier.color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
