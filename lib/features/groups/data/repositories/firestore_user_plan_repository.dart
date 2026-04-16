import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_plan.dart';
import '../../domain/repositories/user_plan_repository.dart';

class FirestoreUserPlanRepository implements UserPlanRepository {
  FirestoreUserPlanRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _userPlans =>
      _firestore.collection('userPlans');

  @override
  Stream<List<UserPlan>> watchUserPlans(String userId) {
    return _userPlans
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserPlan.fromFirestore(d.id, d.data()))
            .toList());
  }

  @override
  Future<UserPlan> createUserPlan(UserPlan plan) async {
    final ref = await _userPlans.add(plan.toMap());
    return UserPlan.fromFirestore(ref.id, plan.toMap());
  }

  @override
  Future<void> markTodayRead(String userPlanId) async {
    await _userPlans.doc(userPlanId).update({'todayRead': true});
  }

  @override
  Future<void> deleteUserPlan(String userPlanId) async {
    await _userPlans.doc(userPlanId).delete();
  }
}
