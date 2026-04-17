import 'notification_type.dart';

/// Represents a notification received by the app, stored in Firestore history.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
    required this.isRead,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;

  /// Arbitrary key-value data from the FCM payload (e.g. groupId, bookId).
  final Map<String, String> data;

  final DateTime receivedAt;
  final bool isRead;

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, String>? data,
    DateTime? receivedAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'receivedAt': receivedAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromFirestore(
    String id,
    Map<String, dynamic> map,
  ) {
    return AppNotification(
      id: id,
      type: NotificationType.fromValue(map['type'] as String? ?? '') ??
          NotificationType.dailyReminder,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      data: Map<String, String>.from(map['data'] as Map? ?? {}),
      receivedAt: DateTime.tryParse(map['receivedAt'] as String? ?? '') ??
          DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
