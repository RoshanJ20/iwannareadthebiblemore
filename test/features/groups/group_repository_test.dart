import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ignore: unused_import
import 'dart:async';

import 'package:iwannareadthebiblemore/features/groups/data/repositories/firestore_group_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/entities/group.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/entities/nudge.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late FirestoreGroupRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);
    repo = FirestoreGroupRepository(fakeFirestore, mockFunctions);
  });

  group('createGroup', () {
    test('creates a group document and returns Group with generated id', () async {
      final group = await repo.createGroup(
        name: 'Test Group',
        description: 'A test group',
        creatorId: 'user1',
      );

      expect(group.id, isNotEmpty);
      expect(group.name, 'Test Group');
      expect(group.description, 'A test group');
      expect(group.creatorId, 'user1');
      expect(group.memberIds, contains('user1'));
      expect(group.inviteCode.length, 6);
      expect(group.groupStreak, 0);
    });

    test('invite code is uppercase alphanumeric', () async {
      final group = await repo.createGroup(
        name: 'Code Group',
        description: '',
        creatorId: 'user1',
      );
      expect(
        RegExp(r'^[A-Z0-9]{6}$').hasMatch(group.inviteCode),
        isTrue,
        reason: 'Expected 6-char uppercase alphanumeric, got: ${group.inviteCode}',
      );
    });
  });

  group('watchUserGroups', () {
    test('streams groups containing the userId in memberIds', () async {
      await fakeFirestore.collection('groups').add({
        'name': 'Group A',
        'description': '',
        'creatorId': 'user1',
        'inviteCode': 'ABC123',
        'memberIds': ['user1', 'user2'],
        'activePlanId': null,
        'groupStreak': 0,
        'weeklyXpBoard': {},
        'createdAt': DateTime.now(),
      });

      await fakeFirestore.collection('groups').add({
        'name': 'Group B',
        'description': '',
        'creatorId': 'user3',
        'inviteCode': 'XYZ789',
        'memberIds': ['user3'],
        'activePlanId': null,
        'groupStreak': 0,
        'weeklyXpBoard': {},
        'createdAt': DateTime.now(),
      });

      final groups = await repo.watchUserGroups('user1').first;
      expect(groups.length, 1);
      expect(groups.first.name, 'Group A');
    });
  });

  group('findGroupByInviteCode', () {
    test('returns group when code matches', () async {
      await fakeFirestore.collection('groups').add({
        'name': 'My Group',
        'description': '',
        'creatorId': 'user1',
        'inviteCode': 'FIND01',
        'memberIds': ['user1'],
        'activePlanId': null,
        'groupStreak': 0,
        'weeklyXpBoard': {},
        'createdAt': DateTime.now(),
      });

      final group = await repo.findGroupByInviteCode('FIND01');
      expect(group, isNotNull);
      expect(group!.name, 'My Group');
    });

    test('returns null when code does not match', () async {
      final group = await repo.findGroupByInviteCode('NOPE99');
      expect(group, isNull);
    });
  });

  group('joinGroup', () {
    test('adds userId to memberIds', () async {
      final ref = await fakeFirestore.collection('groups').add({
        'name': 'Join Group',
        'description': '',
        'creatorId': 'user1',
        'inviteCode': 'JOIN01',
        'memberIds': ['user1'],
        'activePlanId': null,
        'groupStreak': 0,
        'weeklyXpBoard': {},
        'createdAt': DateTime.now(),
      });

      await repo.joinGroup(ref.id, 'user2');

      final snap = await fakeFirestore.collection('groups').doc(ref.id).get();
      final memberIds = List<String>.from(snap.data()!['memberIds'] as List);
      expect(memberIds, contains('user2'));
    });
  });

  group('leaveGroup', () {
    test('calls onUserLeaveGroup cloud function', () async {
      when(() => mockCallable.call(any()))
          .thenThrow(Exception('cf_ok'));

      try {
        await repo.leaveGroup('group1', 'user1');
      } catch (_) {}

      verify(() => mockFunctions.httpsCallable('onUserLeaveGroup')).called(1);
      verify(() => mockCallable.call({'groupId': 'group1', 'userId': 'user1'}))
          .called(1);
    });
  });

  group('sendNudge', () {
    test('creates a nudge document in /nudges', () async {
      final nudge = Nudge(
        id: '',
        fromUserId: 'userA',
        toUserId: 'userB',
        groupId: 'group1',
        sentAt: DateTime(2025, 1, 1),
        opened: false,
      );

      await repo.sendNudge(nudge);

      final snap = await fakeFirestore.collection('nudges').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['fromUserId'], 'userA');
      expect(snap.docs.first.data()['toUserId'], 'userB');
    });
  });
}
