import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/repositories/user_stats_repository.dart';

class FirestoreUserStatsRepository implements UserStatsRepository {
  FirestoreUserStatsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<UserStats> watchUserStats(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) {
      final data = snap.data() ?? {};
      return UserStats.fromFirestore(userId, data);
    });
  }

  @override
  Stream<List<String>> watchEarnedAchievementIds(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data()['achievementId'] as String? ?? d.id).toList());
  }
}
