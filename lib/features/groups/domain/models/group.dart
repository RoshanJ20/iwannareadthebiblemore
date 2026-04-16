import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id, name, description, creatorId, inviteCode;
  final List<String> memberIds;
  final String? activePlanId;
  final int groupStreak;
  final Map<String, int> weeklyXpBoard;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.inviteCode,
    required this.memberIds,
    this.activePlanId,
    required this.groupStreak,
    required this.weeklyXpBoard,
  });

  factory Group.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      creatorId: d['creatorId'] ?? '',
      inviteCode: d['inviteCode'] ?? '',
      memberIds: List<String>.from(d['memberIds'] ?? []),
      activePlanId: d['activePlanId'],
      groupStreak: d['groupStreak'] ?? 0,
      weeklyXpBoard: Map<String, int>.from(d['weeklyXpBoard'] ?? {}),
    );
  }
}
