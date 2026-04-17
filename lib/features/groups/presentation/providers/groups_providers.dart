import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../data/repositories/firestore_user_plan_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/seed_plans.dart';
import '../../domain/entities/reading_plan.dart' as ent;
import '../../domain/models/group.dart';
import '../../domain/models/group_member.dart';
import '../../domain/models/plan.dart';
import '../../domain/models/user_plan.dart';
import '../../domain/repositories/user_plan_repository.dart';

final prebuiltPlansProvider = Provider<List<ent.ReadingPlan>>(
  (_) => seedPlans,
);

final userPlanRepositoryProvider = Provider<UserPlanRepository>(
  (_) => FirestoreUserPlanRepository(FirebaseFirestore.instance),
);

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) throw StateError('No authenticated user');
  return GroupRepository(FirebaseFirestore.instance, user.uid);
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) throw StateError('No authenticated user');
  return PlanRepository(FirebaseFirestore.instance, user.uid);
});

final myGroupsProvider = StreamProvider<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).watchMyGroups(),
);

final groupDetailProvider = StreamProvider.family<Group?, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final groupMembersProvider = StreamProvider.family<List<GroupMember>, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchMembers(groupId),
);

final planLibraryProvider = StreamProvider<List<ReadingPlan>>(
  (ref) => ref.watch(planRepositoryProvider).watchPlanLibrary(),
);

final activeUserPlansProvider = StreamProvider<List<UserPlan>>(
  (ref) => ref.watch(planRepositoryProvider).watchActiveUserPlans(),
);

// Provides the first group that has an active plan, plus its members
final groupCheckInProvider =
    StreamProvider<({Group group, List<GroupMember> members})?>(
  (ref) async* {
    final groupsAsync = ref.watch(myGroupsProvider);
    final groups = groupsAsync.valueOrNull ?? [];
    final activeGroup =
        groups.where((g) => g.activePlanId != null).firstOrNull;
    if (activeGroup == null) {
      yield null;
      return;
    }
    yield* ref
        .watch(groupRepositoryProvider)
        .watchMembers(activeGroup.id)
        .map((members) => (group: activeGroup, members: members));
  },
);
