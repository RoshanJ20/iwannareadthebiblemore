import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/group.dart';
import '../../domain/models/group_member.dart';

class GroupRepository {
  final FirebaseFirestore _db;
  final String _userId;

  GroupRepository(this._db, this._userId);

  Stream<List<Group>> watchMyGroups() {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: _userId)
        .snapshots()
        .map((s) => s.docs.map(Group.fromDoc).toList());
  }

  Stream<Group?> watchGroup(String groupId) =>
      _db.collection('groups').doc(groupId).snapshots().map(
            (d) => d.exists ? Group.fromDoc(d) : null,
          );

  Stream<List<GroupMember>> watchMembers(String groupId) => _db
      .collection('groups')
      .doc(groupId)
      .collection('members')
      .snapshots()
      .map((s) => s.docs.map(GroupMember.fromDoc).toList());

  Future<String> createGroup({
    required String name,
    required String description,
  }) async {
    final inviteCode = _generateCode();
    final ref = await _db.collection('groups').add({
      'name': name,
      'description': description,
      'creatorId': _userId,
      'inviteCode': inviteCode,
      'memberIds': [_userId],
      'activePlanId': null,
      'groupStreak': 0,
      'weeklyXpBoard': {},
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.collection('members').doc(_userId).set({
      'displayName': '',
      'todayRead': false,
      'streak': 0,
    });
    return ref.id;
  }

  Future<void> joinGroup(String inviteCode) async {
    final snap = await _db
        .collection('groups')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw Exception('Group not found');
    final groupDoc = snap.docs.first;
    final members = List<String>.from(groupDoc.data()['memberIds'] ?? []);
    if (members.length >= 20) throw Exception('Group is full');
    if (members.contains(_userId)) throw Exception('Already a member');
    await groupDoc.reference.update({
      'memberIds': FieldValue.arrayUnion([_userId]),
    });
    await groupDoc.reference.collection('members').doc(_userId).set({
      'displayName': '',
      'todayRead': false,
      'streak': 0,
    });
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
