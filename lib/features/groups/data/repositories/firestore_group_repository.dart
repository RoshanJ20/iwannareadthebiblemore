import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/nudge.dart';
import '../../domain/repositories/group_repository.dart';

class FirestoreGroupRepository implements GroupRepository {
  FirestoreGroupRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  @override
  Stream<List<Group>> watchUserGroups(String userId) {
    return _groups
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Group.fromFirestore(d.id, d.data()))
            .toList());
  }

  @override
  Stream<List<GroupMember>> watchGroupMembers(String groupId) {
    return _groups
        .doc(groupId)
        .collection('members')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GroupMember.fromFirestore(d.id, d.data()))
            .toList());
  }

  @override
  Future<Group> createGroup({
    required String name,
    required String description,
    required String creatorId,
  }) async {
    final code = _generateInviteCode();
    final now = DateTime.now();
    final data = Group(
      id: '',
      name: name,
      description: description,
      creatorId: creatorId,
      inviteCode: code,
      memberIds: [creatorId],
      groupStreak: 0,
      weeklyXpBoard: {},
      createdAt: now,
    ).toMap();

    final ref = await _groups.add(data);

    await ref
        .collection('members')
        .doc(creatorId)
        .set({'displayName': '', 'photoUrl': null, 'todayRead': false, 'streak': 0});

    return Group.fromFirestore(ref.id, data);
  }

  @override
  Future<Group?> findGroupByInviteCode(String code) async {
    final snap = await _groups
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Group.fromFirestore(doc.id, doc.data());
  }

  @override
  Future<void> joinGroup(String groupId, String userId) async {
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    await _groups
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .set({'displayName': '', 'photoUrl': null, 'todayRead': false, 'streak': 0},
            SetOptions(merge: true));
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    await _functions.httpsCallable('onUserLeaveGroup').call({
      'groupId': groupId,
      'userId': userId,
    });
  }

  @override
  Future<void> sendNudge(Nudge nudge) async {
    await _firestore.collection('nudges').add(nudge.toMap());
  }

  @override
  Future<void> setActivePlan(String groupId, String planId) async {
    await _groups.doc(groupId).update({'activePlanId': planId});
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
