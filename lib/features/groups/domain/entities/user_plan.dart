import 'package:cloud_firestore/cloud_firestore.dart';

class UserPlan {
  const UserPlan({
    required this.id,
    required this.userId,
    required this.planId,
    this.groupId,
    required this.startDate,
    required this.currentDay,
    required this.completedDays,
    required this.isComplete,
    required this.todayChapter,
    required this.todayRead,
  });

  final String id;
  final String userId;
  final String planId;
  final String? groupId;
  final DateTime startDate;
  final int currentDay;
  final List<int> completedDays;
  final bool isComplete;
  final String todayChapter;
  final bool todayRead;

  factory UserPlan.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['startDate'];
    return UserPlan(
      id: id,
      userId: data['userId'] as String? ?? '',
      planId: data['planId'] as String? ?? '',
      groupId: data['groupId'] as String?,
      startDate: ts is Timestamp ? ts.toDate() : DateTime.now(),
      currentDay: (data['currentDay'] as num?)?.toInt() ?? 1,
      completedDays: List<int>.from(
        (data['completedDays'] as List? ?? []).map((e) => (e as num).toInt()),
      ),
      isComplete: data['isComplete'] as bool? ?? false,
      todayChapter: data['todayChapter'] as String? ?? '',
      todayRead: data['todayRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'planId': planId,
        'groupId': groupId,
        'startDate': Timestamp.fromDate(startDate),
        'currentDay': currentDay,
        'completedDays': completedDays,
        'isComplete': isComplete,
        'todayChapter': todayChapter,
        'todayRead': todayRead,
      };

  UserPlan copyWith({bool? todayRead, bool? isComplete, int? currentDay}) {
    return UserPlan(
      id: id,
      userId: userId,
      planId: planId,
      groupId: groupId,
      startDate: startDate,
      currentDay: currentDay ?? this.currentDay,
      completedDays: completedDays,
      isComplete: isComplete ?? this.isComplete,
      todayChapter: todayChapter,
      todayRead: todayRead ?? this.todayRead,
    );
  }
}
