import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_user_stats_repository.dart';
import '../../data/services/xp_store_service.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/entities/xp_store_item.dart';
import '../../domain/repositories/user_stats_repository.dart';
import '../widgets/mascot_widget.dart';

final userStatsRepositoryProvider = Provider<UserStatsRepository>((ref) {
  return FirestoreUserStatsRepository(FirebaseFirestore.instance);
});

final xpStoreServiceProvider = Provider<XpStoreService>((ref) {
  return XpStoreService(FirebaseFunctions.instance);
});

final userStatsProvider =
    StreamProvider.family<UserStats, String>((ref, userId) {
  return ref.watch(userStatsRepositoryProvider).watchUserStats(userId);
});

final userAchievementsProvider =
    StreamProvider.family<List<Achievement>, String>((ref, userId) {
  final allAchievements = ref.watch(allAchievementsProvider);
  return ref
      .watch(userStatsRepositoryProvider)
      .watchEarnedAchievementIds(userId)
      .map((earnedIds) => allAchievements
          .where((a) => earnedIds.contains(a.id))
          .toList());
});

final allAchievementsProvider = Provider<List<Achievement>>((ref) {
  return const [
    Achievement(
      id: 'first_flame',
      title: 'First Flame',
      description: 'Reach a 7-day reading streak',
      iconEmoji: '🔥',
      condition: '7-day streak',
    ),
    Achievement(
      id: 'month_of_faith',
      title: 'Month of Faith',
      description: 'Reach a 30-day reading streak',
      iconEmoji: '📅',
      condition: '30-day streak',
    ),
    Achievement(
      id: 'better_together',
      title: 'Better Together',
      description: 'Join your first reading group',
      iconEmoji: '🤝',
      condition: 'Join first group',
    ),
    Achievement(
      id: 'keepers_nudge',
      title: "Keeper's Nudge",
      description: 'Nudge 10 friends who read',
      iconEmoji: '👋',
      condition: 'Nudge 10 friends who read',
    ),
    Achievement(
      id: 'in_the_beginning',
      title: 'In The Beginning',
      description: 'Complete all chapters of Genesis',
      iconEmoji: '📖',
      condition: 'All Genesis chapters complete',
    ),
    Achievement(
      id: 'red_letters',
      title: 'Red Letters',
      description: 'Complete all chapters of Matthew, Mark, Luke, and John',
      iconEmoji: '✝️',
      condition: 'All chapters of Matthew+Mark+Luke+John',
    ),
    Achievement(
      id: 'group_mvp',
      title: 'Group MVP',
      description: 'Top scorer in the weekly XP board at Sunday reset',
      iconEmoji: '🏆',
      condition: 'Top scorer in weeklyXpBoard at Sunday reset',
    ),
  ];
});

final mascotStateProvider =
    Provider.family<MascotState, String>((ref, userId) {
  final statsAsync = ref.watch(userStatsProvider(userId));
  return statsAsync.when(
    loading: () => MascotState.idle,
    error: (_, __) => MascotState.idle,
    data: (stats) => _deriveMascotState(stats),
  );
});

MascotState _deriveMascotState(UserStats stats) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final lastRead = stats.lastReadDate;
  final readToday = lastRead != null &&
      DateTime(lastRead.year, lastRead.month, lastRead.day) == today;

  if (stats.currentStreak == 0 && lastRead != null) {
    final daysSinceRead = today.difference(
      DateTime(lastRead.year, lastRead.month, lastRead.day),
    ).inDays;
    if (daysSinceRead >= 3) return MascotState.sleeping;
    return MascotState.sad;
  }

  if (lastRead == null) {
    return MascotState.sleeping;
  }

  final daysSinceRead = today.difference(
    DateTime(lastRead.year, lastRead.month, lastRead.day),
  ).inDays;

  if (daysSinceRead >= 3) return MascotState.sleeping;

  if (stats.currentStreak >= 100 && readToday) return MascotState.onFire;

  if (stats.currentStreak >= 7 && readToday) return MascotState.excited;

  if (!readToday && stats.currentStreak > 0) {
    final minutesUntilMidnight =
        DateTime(today.year, today.month, today.day + 1)
            .difference(now)
            .inMinutes;
    if (minutesUntilMidnight < 120) return MascotState.worried;
  }

  return MascotState.idle;
}

final xpStoreItemsProvider = Provider<List<XpStoreItem>>((ref) {
  return const [
    XpStoreItem(
      id: 'streak_freeze',
      name: 'Streak Freeze',
      xpCost: 200,
      itemType: XpItemType.freeze,
      rarity: XpItemRarity.common,
    ),
    XpStoreItem(
      id: 'mascot_outfit_basic_1',
      name: 'Basic Outfit I',
      xpCost: 500,
      itemType: XpItemType.mascotOutfit,
      rarity: XpItemRarity.basic,
    ),
    XpStoreItem(
      id: 'mascot_outfit_basic_2',
      name: 'Basic Outfit II',
      xpCost: 500,
      itemType: XpItemType.mascotOutfit,
      rarity: XpItemRarity.basic,
    ),
    XpStoreItem(
      id: 'mascot_outfit_basic_3',
      name: 'Basic Outfit III',
      xpCost: 500,
      itemType: XpItemType.mascotOutfit,
      rarity: XpItemRarity.basic,
    ),
    XpStoreItem(
      id: 'mascot_outfit_rare_1',
      name: 'Rare Outfit I',
      xpCost: 1000,
      itemType: XpItemType.mascotOutfit,
      rarity: XpItemRarity.rare,
    ),
    XpStoreItem(
      id: 'mascot_outfit_rare_2',
      name: 'Rare Outfit II',
      xpCost: 1000,
      itemType: XpItemType.mascotOutfit,
      rarity: XpItemRarity.rare,
    ),
    XpStoreItem(
      id: 'mascot_outfit_rare_3',
      name: 'Rare Outfit III',
      xpCost: 1000,
      itemType: XpItemType.mascotOutfit,
      rarity: XpItemRarity.rare,
    ),
    XpStoreItem(
      id: 'mascot_outfit_legendary_1',
      name: 'Legendary Outfit I',
      xpCost: 2000,
      itemType: XpItemType.mascotOutfit,
      rarity: XpItemRarity.legendary,
    ),
    XpStoreItem(
      id: 'mascot_outfit_legendary_2',
      name: 'Legendary Outfit II',
      xpCost: 2000,
      itemType: XpItemType.mascotOutfit,
      rarity: XpItemRarity.legendary,
    ),
  ];
});
