import 'package:cloud_firestore/cloud_firestore.dart';

class Nudge {
  const Nudge({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.groupId,
    required this.sentAt,
    required this.opened,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String groupId;
  final DateTime sentAt;
  final bool opened;

  factory Nudge.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['sentAt'];
    return Nudge(
      id: id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      sentAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      opened: data['opened'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'groupId': groupId,
        'sentAt': Timestamp.fromDate(sentAt),
        'opened': opened,
      };
}
