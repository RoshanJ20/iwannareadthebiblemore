import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import 'data/gamification_repository.dart';
import 'domain/models/achievement.dart';
import 'domain/models/user_stats.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) throw StateError('No authenticated user');
  return GamificationRepository(FirebaseFirestore.instance, user.uid);
});

final userStatsProvider = StreamProvider<UserStats>(
  (ref) => ref.watch(gamificationRepositoryProvider).watchUserStats(),
);

final achievementsProvider = StreamProvider<List<Achievement>>(
  (ref) => ref.watch(gamificationRepositoryProvider).watchAchievements(),
);
