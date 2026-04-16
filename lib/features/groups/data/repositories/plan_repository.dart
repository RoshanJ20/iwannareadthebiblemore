import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/plan.dart';
import '../../domain/models/user_plan.dart';

class PlanRepository {
  final FirebaseFirestore _db;
  final String _userId;

  PlanRepository(this._db, this._userId);

  Stream<List<ReadingPlan>> watchPlanLibrary() => _db
      .collection('plans')
      .where('isCustom', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.map(ReadingPlan.fromDoc).toList());

  Stream<List<UserPlan>> watchActiveUserPlans() => _db
      .collection('userPlans')
      .where('userId', isEqualTo: _userId)
      .where('isComplete', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.map(UserPlan.fromDoc).toList());

  Future<String> startPlan({required String planId, String? groupId}) async {
    final plan = await _db.collection('plans').doc(planId).get();
    if (!plan.exists) throw Exception('Plan not found');
    final planData = plan.data()!;
    final readings = planData['readings'] as List;
    final todayReading =
        readings.isNotEmpty ? readings[0] as Map<String, dynamic> : null;
    final ref = await _db.collection('userPlans').add({
      'userId': _userId,
      'planId': planId,
      'groupId': groupId,
      'startDate': FieldValue.serverTimestamp(),
      'currentDay': 1,
      'completedDays': [],
      'isComplete': false,
      'todayRead': false,
      'todayChapter': todayReading != null
          ? '${todayReading['book']} ${todayReading['chapter']}'
          : '',
    });
    if (groupId != null) {
      await _db.collection('groups').doc(groupId).update({'activePlanId': planId});
    }
    return ref.id;
  }

  Future<void> markTodayRead(String userPlanId) =>
      _db.collection('userPlans').doc(userPlanId).update({'todayRead': true});
}
