import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  const UserStats({
    required this.userId,
    required this.xpTotal,
    required this.xpBalance,
    required this.currentStreak,
    required this.longestStreak,
    this.lastReadDate,
    required this.streakFreezes,
  });

  final String userId;
  final int xpTotal;
  final int xpBalance;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadDate;
  final int streakFreezes;

  factory UserStats.fromFirestore(String userId, Map<String, dynamic> data) {
    final ts = data['lastReadDate'];
    return UserStats(
      userId: userId,
      xpTotal: (data['xpTotal'] as num?)?.toInt() ?? 0,
      xpBalance: (data['xpBalance'] as num?)?.toInt() ?? 0,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (data['longestStreak'] as num?)?.toInt() ?? 0,
      lastReadDate: ts is Timestamp ? ts.toDate() : null,
      streakFreezes: (data['streakFreezes'] as num?)?.toInt() ?? 0,
    );
  }

  UserStats copyWith({
    int? xpTotal,
    int? xpBalance,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastReadDate,
    int? streakFreezes,
  }) {
    return UserStats(
      userId: userId,
      xpTotal: xpTotal ?? this.xpTotal,
      xpBalance: xpBalance ?? this.xpBalance,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      streakFreezes: streakFreezes ?? this.streakFreezes,
    );
  }
}
