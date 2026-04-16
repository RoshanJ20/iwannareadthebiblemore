import '../entities/group.dart';
import '../entities/group_member.dart';
import '../entities/nudge.dart';

abstract class GroupRepository {
  Stream<List<Group>> watchUserGroups(String userId);
  Stream<List<GroupMember>> watchGroupMembers(String groupId);
  Future<Group> createGroup({required String name, required String description, required String creatorId});
  Future<Group?> findGroupByInviteCode(String code);
  Future<void> joinGroup(String groupId, String userId);
  Future<void> leaveGroup(String groupId, String userId);
  Future<void> sendNudge(Nudge nudge);
  Future<void> setActivePlan(String groupId, String planId);
}
