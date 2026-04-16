import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../gamification_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (achievements) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, i) {
            final a = achievements[i];
            final earned = a.earnedAt != null;
            return GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(a.name),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.emoji,
                          style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(a.description),
                      if (a.earnedAt != null)
                        Text(
                          'Earned ${DateFormat.yMd().format(a.earnedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: earned
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.15),
                  border: earned
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      a.emoji,
                      style: TextStyle(
                        fontSize: 32,
                        color: earned ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: earned ? null : Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
