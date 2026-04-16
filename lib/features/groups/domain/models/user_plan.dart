import 'package:cloud_firestore/cloud_firestore.dart';

class UserPlan {
  final String id, userId, planId;
  final String? groupId;
  final DateTime startDate;
  final int currentDay;
  final List<int> completedDays;
  final bool isComplete, todayRead;
  final String todayChapter;

  const UserPlan({
    required this.id,
    required this.userId,
    required this.planId,
    this.groupId,
    required this.startDate,
    required this.currentDay,
    required this.completedDays,
    required this.isComplete,
    required this.todayRead,
    required this.todayChapter,
  });

  factory UserPlan.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserPlan(
      id: doc.id,
      userId: d['userId'] ?? '',
      planId: d['planId'] ?? '',
      groupId: d['groupId'],
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentDay: d['currentDay'] ?? 1,
      completedDays: List<int>.from(d['completedDays'] ?? []),
      isComplete: d['isComplete'] ?? false,
      todayRead: d['todayRead'] ?? false,
      todayChapter: d['todayChapter'] ?? '',
    );
  }
}
