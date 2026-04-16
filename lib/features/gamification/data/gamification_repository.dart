import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/achievement.dart';
import '../domain/models/user_stats.dart';

class GamificationRepository {
  final FirebaseFirestore _db;
  final String _userId;

  GamificationRepository(this._db, this._userId);

  Stream<UserStats> watchUserStats() => _db
      .collection('users')
      .doc(_userId)
      .snapshots()
      .map((doc) =>
          doc.exists ? UserStats.fromMap(doc.data()!) : UserStats.empty());

  Stream<List<Achievement>> watchAchievements() {
    return _db
        .collection('users')
        .doc(_userId)
        .collection('achievements')
        .snapshots()
        .map((snap) {
      final earned = {
        for (final doc in snap.docs)
          doc.id: (doc.data()['earnedAt'] as Timestamp).toDate()
      };
      return kAllAchievementDefs
          .map((a) => Achievement(
                id: a.id,
                name: a.name,
                description: a.description,
                emoji: a.emoji,
                earnedAt: earned[a.id],
              ))
          .toList();
    });
  }
}
