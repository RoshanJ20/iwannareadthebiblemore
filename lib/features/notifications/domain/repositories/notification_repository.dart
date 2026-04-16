import '../entities/app_notification.dart';

/// Abstract repository for persisting and querying notification history.
abstract interface class NotificationRepository {
  /// Streams all notifications for [userId], newest first.
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// Saves an incoming notification to Firestore history.
  Future<void> saveNotification(
    String userId,
    AppNotification notification,
  );

  /// Marks a notification as read.
  Future<void> markRead(String userId, String notificationId);

  /// Returns the count of unread notifications for [userId].
  Stream<int> watchUnreadCount(String userId);
}
