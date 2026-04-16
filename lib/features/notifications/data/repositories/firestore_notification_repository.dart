import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Firestore-backed implementation of [NotificationRepository].
///
/// Collection path: /users/{uid}/notifications/{notificationId}
class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _col(userId)
        .orderBy('receivedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<void> saveNotification(
    String userId,
    AppNotification notification,
  ) async {
    final data = notification.toFirestore();
    if (notification.id.isEmpty) {
      await _col(userId).add(data);
    } else {
      await _col(userId).doc(notification.id).set(data);
    }
  }

  @override
  Future<void> markRead(String userId, String notificationId) async {
    await _col(userId).doc(notificationId).update({'isRead': true});
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _col(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }
}
