import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final int xpTotal;
  final int xpBalance;
  final int currentStreak;
  final int longestStreak;
  final int streakFreezes;
  final String? activeOutfitId;
  final DateTime? lastReadDate;

  const UserStats({
    required this.xpTotal,
    required this.xpBalance,
    required this.currentStreak,
    required this.longestStreak,
    required this.streakFreezes,
    this.activeOutfitId,
    this.lastReadDate,
  });

  factory UserStats.empty() => const UserStats(
        xpTotal: 0,
        xpBalance: 0,
        currentStreak: 0,
        longestStreak: 0,
        streakFreezes: 0,
      );

  factory UserStats.fromMap(Map<String, dynamic> m) => UserStats(
        xpTotal: (m['xpTotal'] as num?)?.toInt() ?? 0,
        xpBalance: (m['xpBalance'] as num?)?.toInt() ?? 0,
        currentStreak: (m['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (m['longestStreak'] as num?)?.toInt() ?? 0,
        streakFreezes: (m['streakFreezes'] as num?)?.toInt() ?? 0,
        activeOutfitId: m['activeOutfitId'] as String?,
        lastReadDate: (m['lastReadDate'] as Timestamp?)?.toDate(),
      );
}
