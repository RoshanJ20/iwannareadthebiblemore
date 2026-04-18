import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/web_mock/web_mock_repositories.dart';
import '../../data/repositories/firestore_group_repository.dart';
import '../../data/repositories/firestore_plan_repository.dart';
import '../../data/repositories/firestore_user_plan_repository.dart';
import '../../data/seed_plans.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/reading_plan.dart';
import '../../domain/entities/user_plan.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/plan_repository.dart';
import '../../domain/repositories/user_plan_repository.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  if (kIsWeb) return WebMockGroupRepository();
  return FirestoreGroupRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return FirestorePlanRepository(FirebaseFirestore.instance);
});

final userPlanRepositoryProvider = Provider<UserPlanRepository>((ref) {
  if (kIsWeb) return WebMockUserPlanRepository();
  return FirestoreUserPlanRepository(FirebaseFirestore.instance);
});

final userGroupsProvider =
    StreamProvider.family<List<Group>, String>((ref, userId) {
  return ref.watch(groupRepositoryProvider).watchUserGroups(userId);
});

final groupMembersProvider =
    StreamProvider.family<List<GroupMember>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).watchGroupMembers(groupId);
});

final activePlanProvider =
    FutureProvider.family<ReadingPlan?, String>((ref, groupId) async {
  final groups = await ref.watch(userGroupsProvider(groupId).future);
  final group = groups.isNotEmpty ? groups.first : null;
  final planId = group?.activePlanId;
  if (planId == null) return null;
  return ref.watch(planRepositoryProvider).getPlan(planId);
});

final userActivePlansProvider =
    StreamProvider.family<List<UserPlan>, String>((ref, userId) {
  return ref.watch(userPlanRepositoryProvider).watchUserPlans(userId);
});

final prebuiltPlansProvider = Provider<List<ReadingPlan>>((ref) => seedPlans);

final todayUserPlanProvider =
    Provider.family<UserPlan?, String>((ref, userId) {
  final plansAsync = ref.watch(userActivePlansProvider(userId));
  return plansAsync.whenOrNull(
    data: (plans) => plans
        .where((p) => !p.isComplete && !p.todayRead)
        .toList()
        .firstOrNull,
  );
});
