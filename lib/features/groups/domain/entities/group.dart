import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
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
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String inviteCode;
  final List<String> memberIds;
  final String? activePlanId;
  final int groupStreak;
  final Map<String, int> weeklyXpBoard;
  final DateTime createdAt;

  factory Group.fromFirestore(String id, Map<dynamic, dynamic> data) {
    final rawBoard =
        (data['weeklyXpBoard'] as Map?)?.cast<String, dynamic>() ?? {};
    final ts = data['createdAt'];
    return Group(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      activePlanId: data['activePlanId'] as String?,
      groupStreak: (data['groupStreak'] as num?)?.toInt() ?? 0,
      weeklyXpBoard:
          rawBoard.map((k, v) => MapEntry(k as String, (v as num).toInt())),
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'creatorId': creatorId,
        'inviteCode': inviteCode,
        'memberIds': memberIds,
        'activePlanId': activePlanId,
        'groupStreak': groupStreak,
        'weeklyXpBoard': weeklyXpBoard,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
