import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String userId, displayName;
  final String? photoUrl;
  final bool todayRead;
  final int streak;

  const GroupMember({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.todayRead,
    required this.streak,
  });

  factory GroupMember.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GroupMember(
      userId: doc.id,
      displayName: d['displayName'] ?? '',
      photoUrl: d['photoUrl'],
      todayRead: d['todayRead'] ?? false,
      streak: d['streak'] ?? 0,
    );
  }
}
