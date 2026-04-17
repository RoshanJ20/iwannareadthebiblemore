import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/reading_plan.dart';
import '../../domain/repositories/plan_repository.dart';
import '../seed_plans.dart';

class FirestorePlanRepository implements PlanRepository {
  FirestorePlanRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<ReadingPlan>> getOfficialPlans() async {
    final snap = await _firestore
        .collection('plans')
        .where('isCustom', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return seedPlans;
    return snap.docs
        .map((d) => ReadingPlan.fromFirestore(d.id, d.data()))
        .toList();
  }

  @override
  Future<ReadingPlan?> getPlan(String planId) async {
    final seeded = seedPlans.where((p) => p.id == planId).toList();
    if (seeded.isNotEmpty) return seeded.first;

    final doc = await _firestore.collection('plans').doc(planId).get();
    if (!doc.exists) return null;
    return ReadingPlan.fromFirestore(doc.id, doc.data()!);
  }
}
