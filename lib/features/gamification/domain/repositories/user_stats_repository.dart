import '../entities/achievement.dart';
import '../entities/user_stats.dart';

abstract class UserStatsRepository {
  Stream<UserStats> watchUserStats(String userId);
  Stream<List<String>> watchEarnedAchievementIds(String userId);
}
