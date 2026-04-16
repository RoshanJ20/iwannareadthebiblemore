# Groups & Plans Feature — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement groups (create/join/leave, daily check-in, nudges, weekly XP leaderboard) and reading plans (pre-built library, active plan tracking, completion celebration).

**Architecture:** Firestore-backed repositories for groups and plans, exposed as Riverpod StreamProviders. Group mutations use direct Firestore writes (create/join) or Callable Functions (leave). todayRead = true write triggers the onReadingComplete Cloud Function (Plan 3) for XP/streak. Nudges use Firestore write → Cloud Function for rate limit enforcement and FCM delivery.

**Tech Stack:** Flutter/Dart, Riverpod, Firestore, Firebase Functions (callable), go_router

---

## Task 1: Domain models

**Files:**
- `lib/features/groups/domain/models/group.dart`
- `lib/features/groups/domain/models/group_member.dart`
- `lib/features/groups/domain/models/plan.dart`
- `lib/features/groups/domain/models/user_plan.dart`
- `test/features/groups/domain/models/group_test.dart`

**Failing test first** (`test/features/groups/domain/models/group_test.dart`):
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';

void main() {
  test('Group.fromDoc parses Firestore document correctly', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Morning Crew',
      'description': 'Daily devotional group',
      'creatorId': 'user1',
      'inviteCode': 'ABC123',
      'memberIds': ['user1', 'user2'],
      'activePlanId': 'plan1',
      'groupStreak': 5,
      'weeklyXpBoard': {'user1': 100, 'user2': 80},
    });
    final doc = await fakeFirestore.collection('groups').doc('g1').get();
    final group = Group.fromDoc(doc);
    expect(group.id, 'g1');
    expect(group.name, 'Morning Crew');
    expect(group.inviteCode, 'ABC123');
    expect(group.memberIds, ['user1', 'user2']);
    expect(group.groupStreak, 5);
    expect(group.weeklyXpBoard['user1'], 100);
    expect(group.activePlanId, 'plan1');
  });

  test('GroupMember.fromDoc parses correctly', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore.collection('groups').doc('g1').collection('members').doc('user1').set({
      'displayName': 'Alice',
      'photoUrl': 'https://example.com/photo.jpg',
      'todayRead': true,
      'streak': 7,
    });
    final doc = await fakeFirestore.collection('groups').doc('g1').collection('members').doc('user1').get();
    final member = GroupMember.fromDoc(doc);
    expect(member.userId, 'user1');
    expect(member.displayName, 'Alice');
    expect(member.todayRead, true);
    expect(member.streak, 7);
  });

  test('ReadingPlan.fromDoc parses correctly', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore.collection('plans').doc('p1').set({
      'name': 'Gospel of John',
      'description': 'Read through the Gospel of John',
      'coverEmoji': '✝️',
      'totalDays': 21,
      'tags': ['gospel', 'john'],
      'isCustom': false,
      'readings': [
        {'day': 1, 'book': 'John', 'chapter': '1', 'title': 'The Word'},
      ],
    });
    final doc = await fakeFirestore.collection('plans').doc('p1').get();
    final plan = ReadingPlan.fromDoc(doc);
    expect(plan.name, 'Gospel of John');
    expect(plan.totalDays, 21);
    expect(plan.readings.length, 1);
    expect(plan.readings.first.book, 'John');
  });
}
```

**Implementation** (`lib/features/groups/domain/models/group.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id, name, description, creatorId, inviteCode;
  final List<String> memberIds;
  final String? activePlanId;
  final int groupStreak;
  final Map<String, int> weeklyXpBoard;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.inviteCode,
    required this.memberIds,
    this.activePlanId,
    required this.groupStreak,
    required this.weeklyXpBoard,
  });

  factory Group.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      creatorId: d['creatorId'] ?? '',
      inviteCode: d['inviteCode'] ?? '',
      memberIds: List<String>.from(d['memberIds'] ?? []),
      activePlanId: d['activePlanId'],
      groupStreak: d['groupStreak'] ?? 0,
      weeklyXpBoard: Map<String, int>.from(d['weeklyXpBoard'] ?? {}),
    );
  }
}
```

**Implementation** (`lib/features/groups/domain/models/group_member.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String userId, displayName;
  final String? photoUrl;
  final bool todayRead;
  final int streak;

  const GroupMember({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.todayRead,
    required this.streak,
  });

  factory GroupMember.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GroupMember(
      userId: doc.id,
      displayName: d['displayName'] ?? '',
      photoUrl: d['photoUrl'],
      todayRead: d['todayRead'] ?? false,
      streak: d['streak'] ?? 0,
    );
  }
}
```

**Implementation** (`lib/features/groups/domain/models/plan.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingPlan {
  final String id, name, description, coverEmoji;
  final int totalDays;
  final List<String> tags;
  final List<PlanReading> readings;
  final bool isCustom;

  const ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.coverEmoji,
    required this.totalDays,
    required this.tags,
    required this.readings,
    this.isCustom = false,
  });

  factory ReadingPlan.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReadingPlan(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      coverEmoji: d['coverEmoji'] ?? '📖',
      totalDays: d['totalDays'] ?? 0,
      tags: List<String>.from(d['tags'] ?? []),
      readings: (d['readings'] as List? ?? []).map((r) => PlanReading.fromMap(r as Map<String, dynamic>)).toList(),
      isCustom: d['isCustom'] ?? false,
    );
  }
}

class PlanReading {
  final int day;
  final String book, chapter, title;

  const PlanReading({
    required this.day,
    required this.book,
    required this.chapter,
    required this.title,
  });

  factory PlanReading.fromMap(Map<String, dynamic> m) => PlanReading(
    day: m['day'] ?? 0,
    book: m['book'] ?? '',
    chapter: m['chapter'] ?? '',
    title: m['title'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'day': day,
    'book': book,
    'chapter': chapter,
    'title': title,
  };
}
```

**Implementation** (`lib/features/groups/domain/models/user_plan.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPlan {
  final String id, userId, planId;
  final String? groupId;
  final DateTime startDate;
  final int currentDay;
  final List<int> completedDays;
  final bool isComplete, todayRead;
  final String todayChapter;

  const UserPlan({
    required this.id,
    required this.userId,
    required this.planId,
    this.groupId,
    required this.startDate,
    required this.currentDay,
    required this.completedDays,
    required this.isComplete,
    required this.todayRead,
    required this.todayChapter,
  });

  factory UserPlan.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserPlan(
      id: doc.id,
      userId: d['userId'] ?? '',
      planId: d['planId'] ?? '',
      groupId: d['groupId'],
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentDay: d['currentDay'] ?? 1,
      completedDays: List<int>.from(d['completedDays'] ?? []),
      isComplete: d['isComplete'] ?? false,
      todayRead: d['todayRead'] ?? false,
      todayChapter: d['todayChapter'] ?? '',
    );
  }
}
```

**Steps:**
- [ ] Create `lib/features/groups/domain/models/` directory
- [ ] Write failing test in `test/features/groups/domain/models/group_test.dart`
- [ ] Run `flutter test test/features/groups/domain/models/group_test.dart` — confirm red
- [ ] Implement `group.dart`, `group_member.dart`, `plan.dart`, `user_plan.dart`
- [ ] Run tests again — confirm green
- [ ] `git add lib/features/groups/domain/models/ test/features/groups/domain/models/`
- [ ] `git commit -m "feat: add domain models for groups, plans, and user plans"`

---

## Task 2: Group repository (Firestore)

**Files:**
- `lib/features/groups/data/repositories/group_repository.dart`
- `test/features/groups/data/repositories/group_repository_test.dart`

**Failing test first** (`test/features/groups/data/repositories/group_repository_test.dart`):
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/group_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GroupRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = GroupRepository(fakeFirestore, 'user1');
  });

  test('createGroup writes correct Firestore document', () async {
    final groupId = await repo.createGroup(name: 'Bible Study', description: 'A great group');
    final doc = await fakeFirestore.collection('groups').doc(groupId).get();
    expect(doc.exists, true);
    final data = doc.data()!;
    expect(data['name'], 'Bible Study');
    expect(data['creatorId'], 'user1');
    expect(data['memberIds'], contains('user1'));
    expect(data['groupStreak'], 0);
    expect((data['inviteCode'] as String).length, 6);
  });

  test('createGroup creates member subcollection doc for creator', () async {
    final groupId = await repo.createGroup(name: 'Test Group', description: '');
    final memberDoc = await fakeFirestore.collection('groups').doc(groupId).collection('members').doc('user1').get();
    expect(memberDoc.exists, true);
    expect(memberDoc.data()!['todayRead'], false);
  });

  test('joinGroup adds userId to memberIds', () async {
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Existing Group',
      'description': '',
      'creatorId': 'otherUser',
      'inviteCode': 'JOIN01',
      'memberIds': ['otherUser'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    await repo.joinGroup('JOIN01');
    final doc = await fakeFirestore.collection('groups').doc('g1').get();
    expect(doc.data()!['memberIds'], contains('user1'));
  });

  test('joinGroup throws if group not found', () async {
    expect(() => repo.joinGroup('BADCOD'), throwsException);
  });

  test('joinGroup throws if already a member', () async {
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Group',
      'description': '',
      'creatorId': 'user1',
      'inviteCode': 'MYMEMB',
      'memberIds': ['user1'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    expect(() => repo.joinGroup('MYMEMB'), throwsException);
  });

  test('joinGroup throws if group is full (20 members)', () async {
    final members = List.generate(20, (i) => 'user$i');
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Full Group',
      'description': '',
      'creatorId': 'user0',
      'inviteCode': 'FULL01',
      'memberIds': members,
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    expect(() => repo.joinGroup('FULL01'), throwsException);
  });

  test('watchMyGroups streams groups where userId is in memberIds', () async {
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'My Group',
      'description': '',
      'creatorId': 'user1',
      'inviteCode': 'MYGRP1',
      'memberIds': ['user1'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    await fakeFirestore.collection('groups').doc('g2').set({
      'name': 'Other Group',
      'description': '',
      'creatorId': 'otherUser',
      'inviteCode': 'OTHR01',
      'memberIds': ['otherUser'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    final groups = await repo.watchMyGroups().first;
    expect(groups.length, 1);
    expect(groups.first.name, 'My Group');
  });
}
```

**Implementation** (`lib/features/groups/data/repositories/group_repository.dart`):
```dart
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

  Stream<List<GroupMember>> watchMembers(String groupId) =>
      _db
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
```

**Steps:**
- [ ] Create `lib/features/groups/data/repositories/` directory
- [ ] Write failing test in `test/features/groups/data/repositories/group_repository_test.dart`
- [ ] Run `flutter test test/features/groups/data/repositories/group_repository_test.dart` — confirm red
- [ ] Implement `group_repository.dart`
- [ ] Run tests again — confirm green
- [ ] `git add lib/features/groups/data/repositories/group_repository.dart test/features/groups/data/repositories/`
- [ ] `git commit -m "feat: add GroupRepository with create/join/watch group functionality"`

---

## Task 3: Plan repository (Firestore)

**Files:**
- `lib/features/groups/data/repositories/plan_repository.dart`
- `test/features/groups/data/repositories/plan_repository_test.dart`

**Failing test first** (`test/features/groups/data/repositories/plan_repository_test.dart`):
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/plan_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late PlanRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = PlanRepository(fakeFirestore, 'user1');
  });

  test('startPlan creates userPlan document', () async {
    await fakeFirestore.collection('plans').doc('p1').set({
      'name': 'Genesis',
      'description': 'Read Genesis',
      'coverEmoji': '📖',
      'totalDays': 10,
      'tags': ['beginners'],
      'isCustom': false,
      'readings': [
        {'day': 1, 'book': 'Genesis', 'chapter': '1', 'title': 'Creation'},
      ],
    });
    final userPlanId = await repo.startPlan(planId: 'p1');
    final doc = await fakeFirestore.collection('userPlans').doc(userPlanId).get();
    expect(doc.exists, true);
    final data = doc.data()!;
    expect(data['userId'], 'user1');
    expect(data['planId'], 'p1');
    expect(data['currentDay'], 1);
    expect(data['isComplete'], false);
    expect(data['todayRead'], false);
    expect(data['todayChapter'], 'Genesis 1');
    expect(data['groupId'], isNull);
  });

  test('startPlan with groupId sets activePlanId on group', () async {
    await fakeFirestore.collection('plans').doc('p1').set({
      'name': 'Genesis',
      'description': '',
      'coverEmoji': '📖',
      'totalDays': 10,
      'tags': [],
      'isCustom': false,
      'readings': [],
    });
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'My Group',
      'activePlanId': null,
      'memberIds': ['user1'],
    });
    await repo.startPlan(planId: 'p1', groupId: 'g1');
    final groupDoc = await fakeFirestore.collection('groups').doc('g1').get();
    expect(groupDoc.data()!['activePlanId'], 'p1');
  });

  test('markTodayRead sets todayRead to true', () async {
    await fakeFirestore.collection('userPlans').doc('up1').set({
      'userId': 'user1',
      'planId': 'p1',
      'currentDay': 1,
      'todayRead': false,
      'isComplete': false,
      'completedDays': [],
      'todayChapter': 'Genesis 1',
    });
    await repo.markTodayRead('up1');
    final doc = await fakeFirestore.collection('userPlans').doc('up1').get();
    expect(doc.data()!['todayRead'], true);
  });

  test('startPlan throws if plan not found', () async {
    expect(() => repo.startPlan(planId: 'nonexistent'), throwsException);
  });

  test('watchPlanLibrary streams non-custom plans', () async {
    await fakeFirestore.collection('plans').doc('official').set({
      'name': 'Official Plan',
      'description': '',
      'coverEmoji': '📖',
      'totalDays': 7,
      'tags': [],
      'isCustom': false,
      'readings': [],
    });
    await fakeFirestore.collection('plans').doc('custom').set({
      'name': 'My Custom Plan',
      'description': '',
      'coverEmoji': '✨',
      'totalDays': 5,
      'tags': [],
      'isCustom': true,
      'readings': [],
    });
    final plans = await repo.watchPlanLibrary().first;
    expect(plans.length, 1);
    expect(plans.first.name, 'Official Plan');
  });
}
```

**Implementation** (`lib/features/groups/data/repositories/plan_repository.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/plan.dart';
import '../../domain/models/user_plan.dart';

class PlanRepository {
  final FirebaseFirestore _db;
  final String _userId;

  PlanRepository(this._db, this._userId);

  Stream<List<ReadingPlan>> watchPlanLibrary() =>
      _db
          .collection('plans')
          .where('isCustom', isEqualTo: false)
          .snapshots()
          .map((s) => s.docs.map(ReadingPlan.fromDoc).toList());

  Stream<List<UserPlan>> watchActiveUserPlans() =>
      _db
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
    final todayReading = readings.isNotEmpty ? readings[0] as Map<String, dynamic> : null;
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
```

**Steps:**
- [ ] Write failing test in `test/features/groups/data/repositories/plan_repository_test.dart`
- [ ] Run `flutter test test/features/groups/data/repositories/plan_repository_test.dart` — confirm red
- [ ] Implement `plan_repository.dart`
- [ ] Run tests again — confirm green
- [ ] `git add lib/features/groups/data/repositories/plan_repository.dart test/features/groups/data/repositories/plan_repository_test.dart`
- [ ] `git commit -m "feat: add PlanRepository with startPlan/markTodayRead/watch functionality"`

---

## Task 4: Riverpod providers

**Files:**
- `lib/features/groups/presentation/providers/groups_providers.dart`
- `test/features/groups/presentation/providers/groups_providers_test.dart`

**Failing test first** (`test/features/groups/presentation/providers/groups_providers_test.dart`):
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/group_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';

class MockUser extends Mock implements User {
  @override
  String get uid => 'testUser';
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  test('myGroupsProvider emits groups for authenticated user', () async {
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Test Group',
      'description': '',
      'creatorId': 'testUser',
      'inviteCode': 'TEST01',
      'memberIds': ['testUser'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });

    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          GroupRepository(fakeFirestore, 'testUser'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final groups = await container.read(myGroupsProvider.future);
    expect(groups.length, 1);
    expect(groups.first.name, 'Test Group');
  });

  test('planLibraryProvider emits official plans', () async {
    await fakeFirestore.collection('plans').doc('p1').set({
      'name': 'Official Plan',
      'description': '',
      'coverEmoji': '📖',
      'totalDays': 7,
      'tags': [],
      'isCustom': false,
      'readings': [],
    });

    final container = ProviderContainer(
      overrides: [
        planRepositoryProvider.overrideWithValue(
          PlanRepository(fakeFirestore, 'testUser'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final plans = await container.read(planLibraryProvider.future);
    expect(plans.length, 1);
    expect(plans.first.name, 'Official Plan');
  });
}
```

**Implementation** (`lib/features/groups/presentation/providers/groups_providers.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../domain/models/group.dart';
import '../../domain/models/group_member.dart';
import '../../domain/models/plan.dart';
import '../../domain/models/user_plan.dart';

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
```

**Steps:**
- [ ] Create `lib/features/groups/presentation/providers/` directory
- [ ] Write failing test in `test/features/groups/presentation/providers/groups_providers_test.dart`
- [ ] Run `flutter test test/features/groups/presentation/providers/groups_providers_test.dart` — confirm red
- [ ] Implement `groups_providers.dart`
- [ ] Run tests again — confirm green
- [ ] `git add lib/features/groups/presentation/providers/ test/features/groups/presentation/providers/`
- [ ] `git commit -m "feat: add Riverpod providers for groups and plans"`

---

## Task 5: Groups list screen (replace placeholder)

**Files:**
- `lib/features/groups/presentation/screens/groups_screen.dart` (replace)
- `lib/core/navigation/app_router.dart` (add routes)
- `test/features/groups/presentation/screens/groups_screen_test.dart`

**Failing test first** (`test/features/groups/presentation/screens/groups_screen_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/groups_screen.dart';

void main() {
  testWidgets('GroupsScreen renders list of groups', (tester) async {
    final groups = [
      Group(
        id: 'g1',
        name: 'Morning Crew',
        description: '',
        creatorId: 'user1',
        inviteCode: 'ABC123',
        memberIds: ['user1', 'user2'],
        groupStreak: 5,
        weeklyXpBoard: {},
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith((_) => Stream.value(groups)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const GroupsScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Morning Crew'), findsOneWidget);
    expect(find.text('2 members • 🔥 5'), findsOneWidget);
  });

  testWidgets('GroupsScreen shows empty state when no groups', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith((_) => Stream.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const GroupsScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No groups yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('GroupsScreen FAB shows bottom sheet with options', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith((_) => Stream.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const GroupsScreen()),
            GoRoute(path: '/groups/create', builder: (_, __) => const Scaffold()),
            GoRoute(path: '/groups/join', builder: (_, __) => const Scaffold()),
          ]),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Create Group'), findsOneWidget);
    expect(find.text('Join with Code'), findsOneWidget);
  });
}
```

**Implementation** (`lib/features/groups/presentation/screens/groups_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_providers.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupOptions(context, ref),
        child: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) => groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No groups yet', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showGroupOptions(context, ref),
                      child: const Text('Create or Join a Group'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, i) {
                  final g = groups[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(g.name.substring(0, 1))),
                    title: Text(g.name),
                    subtitle: Text('${g.memberIds.length} members • 🔥 ${g.groupStreak}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/groups/${g.id}'),
                  );
                },
              ),
      ),
    );
  }

  void _showGroupOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create Group'),
              onTap: () {
                Navigator.pop(context);
                context.push('/groups/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Join with Code'),
              onTap: () {
                Navigator.pop(context);
                context.push('/groups/join');
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

**Router changes** — add to `lib/core/navigation/app_router.dart` under the groups tab route:
```dart
GoRoute(path: '/groups/create', builder: (_, __) => const CreateGroupScreen()),
GoRoute(path: '/groups/join', builder: (_, __) => const JoinGroupScreen()),
GoRoute(
  path: '/groups/:groupId',
  builder: (_, state) => GroupDetailScreen(groupId: state.pathParameters['groupId']!),
  routes: [
    GoRoute(
      path: 'leaderboard',
      builder: (_, state) => LeaderboardScreen(groupId: state.pathParameters['groupId']!),
    ),
  ],
),
```

**Steps:**
- [ ] Write failing test
- [ ] Run test — confirm red
- [ ] Replace `groups_screen.dart` with implementation above
- [ ] Add routes to `app_router.dart` (stub screens for now — they'll be filled in Tasks 6–8)
- [ ] Run tests — confirm green
- [ ] `git add lib/features/groups/presentation/screens/groups_screen.dart lib/core/navigation/app_router.dart test/features/groups/presentation/screens/groups_screen_test.dart`
- [ ] `git commit -m "feat: implement GroupsScreen with group list, empty state, and FAB options"`

---

## Task 6: Create/Join group screens

**Files:**
- `lib/features/groups/presentation/screens/create_group_screen.dart`
- `lib/features/groups/presentation/screens/join_group_screen.dart`
- `test/features/groups/presentation/screens/create_group_screen_test.dart`
- `test/features/groups/presentation/screens/join_group_screen_test.dart`

**Failing test first** (`test/features/groups/presentation/screens/create_group_screen_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/group_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/create_group_screen.dart';

@GenerateMocks([GroupRepository])
void main() {
  testWidgets('CreateGroupScreen shows error when name is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const CreateGroupScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Create Group').last);
    await tester.pump();

    // Button should not navigate when name is empty (nothing happens)
    expect(find.byType(CreateGroupScreen), findsOneWidget);
  });

  testWidgets('CreateGroupScreen calls createGroup on submit with valid name', (tester) async {
    final mockRepo = MockGroupRepository();
    when(mockRepo.createGroup(name: 'Bible Study', description: '')).thenAnswer((_) async => 'g1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const CreateGroupScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Bible Study');
    await tester.tap(find.text('Create Group').last);
    await tester.pump();

    verify(mockRepo.createGroup(name: 'Bible Study', description: '')).called(1);
  });
}
```

**Implementation** (`lib/features/groups/presentation/screens/create_group_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_providers.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. Morning Devotional Crew',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (_nameCtrl.text.trim().isEmpty) return;
                        setState(() => _loading = true);
                        try {
                          await ref.read(groupRepositoryProvider).createGroup(
                                name: _nameCtrl.text.trim(),
                                description: _descCtrl.text.trim(),
                              );
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Implementation** (`lib/features/groups/presentation/screens/join_group_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_providers.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                hintText: 'Enter 6-character code',
              ),
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (_codeCtrl.text.trim().length != 6) return;
                        setState(() => _loading = true);
                        try {
                          await ref
                              .read(groupRepositoryProvider)
                              .joinGroup(_codeCtrl.text.trim());
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Steps:**
- [ ] Write failing tests for both screens
- [ ] Run tests — confirm red
- [ ] Implement `create_group_screen.dart` and `join_group_screen.dart`
- [ ] Run tests — confirm green
- [ ] `git add lib/features/groups/presentation/screens/create_group_screen.dart lib/features/groups/presentation/screens/join_group_screen.dart test/features/groups/presentation/screens/`
- [ ] `git commit -m "feat: add CreateGroupScreen and JoinGroupScreen"`

---

## Task 7: Group detail screen

**Files:**
- `lib/features/groups/presentation/screens/group_detail_screen.dart`
- `test/features/groups/presentation/screens/group_detail_screen_test.dart`

**Failing test first** (`test/features/groups/presentation/screens/group_detail_screen_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group_member.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/group_detail_screen.dart';

void main() {
  final group = Group(
    id: 'g1',
    name: 'Morning Crew',
    description: '',
    creatorId: 'user1',
    inviteCode: 'ABC123',
    memberIds: ['user1', 'user2'],
    groupStreak: 3,
    weeklyXpBoard: {},
  );

  final members = [
    GroupMember(userId: 'user1', displayName: 'Alice', todayRead: true, streak: 5),
    GroupMember(userId: 'user2', displayName: 'Bob', todayRead: false, streak: 2),
  ];

  testWidgets('GroupDetailScreen renders group name and streak', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailProvider('g1').overrideWith((_) => Stream.value(group)),
          groupMembersProvider('g1').overrideWith((_) => Stream.value(members)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const GroupDetailScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Morning Crew'), findsOneWidget);
    expect(find.text('Group Streak: 3 days'), findsOneWidget);
  });

  testWidgets('GroupDetailScreen shows checkmark for members who read', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailProvider('g1').overrideWith((_) => Stream.value(group)),
          groupMembersProvider('g1').overrideWith((_) => Stream.value(members)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const GroupDetailScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Read today ✅'), findsOneWidget);
    expect(find.text('Not read yet'), findsOneWidget);
  });

  testWidgets('GroupDetailScreen shows Nudge button only for unread members', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailProvider('g1').overrideWith((_) => Stream.value(group)),
          groupMembersProvider('g1').overrideWith((_) => Stream.value(members)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const GroupDetailScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    // Bob hasn't read, so Nudge button should appear
    expect(find.text('Nudge'), findsOneWidget);
  });
}
```

**Implementation** (`lib/features/groups/presentation/screens/group_detail_screen.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../providers/groups_providers.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      appBar: groupAsync.when(
        data: (g) => AppBar(
          title: Text(g?.name ?? ''),
          actions: [
            IconButton(
              icon: const Icon(Icons.leaderboard),
              onPressed: () => context.push('/groups/$groupId/leaderboard'),
            ),
          ],
        ),
        loading: () => AppBar(title: const Text('Group')),
        error: (_, __) => AppBar(title: const Text('Group')),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) => ListView(
          children: [
            groupAsync.when(
              data: (g) => g == null
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange),
                          Text(
                            ' Group Streak: ${g.groupStreak} days',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Today's Check-in",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...members.map((m) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: m.photoUrl != null ? NetworkImage(m.photoUrl!) : null,
                    child: m.photoUrl == null
                        ? Text(m.displayName.isNotEmpty ? m.displayName[0] : '?')
                        : null,
                  ),
                  title: Text(m.displayName.isNotEmpty ? m.displayName : m.userId),
                  subtitle: Text(m.todayRead ? 'Read today ✅' : 'Not read yet'),
                  trailing: m.todayRead
                      ? null
                      : ElevatedButton(
                          onPressed: () => _sendNudge(context, ref, m.userId),
                          child: const Text('Nudge'),
                        ),
                )),
          ],
        ),
      ),
    );
  }

  void _sendNudge(BuildContext context, WidgetRef ref, String toUserId) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('nudges').add({
        'fromUserId': user.uid,
        'toUserId': toUserId,
        'groupId': groupId,
        'sentAt': FieldValue.serverTimestamp(),
        'opened': false,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Nudge sent!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to nudge: $e')));
      }
    }
  }
}
```

**Steps:**
- [ ] Write failing test
- [ ] Run test — confirm red
- [ ] Implement `group_detail_screen.dart`
- [ ] Ensure route `/groups/:groupId` in `app_router.dart` points to `GroupDetailScreen`
- [ ] Run tests — confirm green
- [ ] `git add lib/features/groups/presentation/screens/group_detail_screen.dart test/features/groups/presentation/screens/group_detail_screen_test.dart`
- [ ] `git commit -m "feat: add GroupDetailScreen with member check-in status and nudge button"`

---

## Task 8: Weekly XP leaderboard

**Files:**
- `lib/features/groups/presentation/screens/leaderboard_screen.dart`
- `test/features/groups/presentation/screens/leaderboard_screen_test.dart`

**Failing test first** (`test/features/groups/presentation/screens/leaderboard_screen_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group_member.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/leaderboard_screen.dart';

void main() {
  final group = Group(
    id: 'g1',
    name: 'Morning Crew',
    description: '',
    creatorId: 'user1',
    inviteCode: 'ABC123',
    memberIds: ['user1', 'user2', 'user3'],
    groupStreak: 0,
    weeklyXpBoard: {'user1': 150, 'user2': 200, 'user3': 50},
  );

  final members = [
    GroupMember(userId: 'user1', displayName: 'Alice', todayRead: true, streak: 5),
    GroupMember(userId: 'user2', displayName: 'Bob', todayRead: true, streak: 7),
    GroupMember(userId: 'user3', displayName: 'Carol', todayRead: false, streak: 1),
  ];

  testWidgets('LeaderboardScreen sorts members by weekly XP descending', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailProvider('g1').overrideWith((_) => Stream.value(group)),
          groupMembersProvider('g1').overrideWith((_) => Stream.value(members)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const LeaderboardScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    // Bob has most XP (200), so should appear first
    final bobTile = find.ancestor(
      of: find.text('Bob'),
      matching: find.byType(ListTile),
    );
    expect(bobTile, findsOneWidget);
    expect(find.text('200 XP'), findsOneWidget);
  });

  testWidgets('LeaderboardScreen shows gold medal for first place', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailProvider('g1').overrideWith((_) => Stream.value(group)),
          groupMembersProvider('g1').overrideWith((_) => Stream.value(members)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const LeaderboardScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('🥇'), findsOneWidget);
    expect(find.text('🥈'), findsOneWidget);
    expect(find.text('🥉'), findsOneWidget);
  });
}
```

**Implementation** (`lib/features/groups/presentation/screens/leaderboard_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groups_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  final String groupId;

  const LeaderboardScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Leaderboard')),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (group) {
          if (group == null) return const Center(child: Text('Group not found'));
          final board = group.weeklyXpBoard;
          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (members) {
              final sorted = [...members]
                ..sort((a, b) => (board[b.userId] ?? 0).compareTo(board[a.userId] ?? 0));
              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, i) {
                  final m = sorted[i];
                  final xp = board[m.userId] ?? 0;
                  final medal = i == 0
                      ? '🥇'
                      : i == 1
                          ? '🥈'
                          : i == 2
                              ? '🥉'
                              : '${i + 1}.';
                  return ListTile(
                    leading: Text(medal, style: const TextStyle(fontSize: 24)),
                    title: Text(m.displayName),
                    trailing: Text(
                      '$xp XP',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

**Steps:**
- [ ] Write failing test
- [ ] Run test — confirm red
- [ ] Implement `leaderboard_screen.dart`
- [ ] Ensure route `/groups/:groupId/leaderboard` in `app_router.dart` points to `LeaderboardScreen`
- [ ] Run tests — confirm green
- [ ] `git add lib/features/groups/presentation/screens/leaderboard_screen.dart test/features/groups/presentation/screens/leaderboard_screen_test.dart`
- [ ] `git commit -m "feat: add weekly XP LeaderboardScreen with sorted rankings"`

---

## Task 9: Plans library screen (replace placeholder)

**Files:**
- `lib/features/groups/presentation/screens/plans_screen.dart` (replace)
- `test/features/groups/presentation/screens/plans_screen_test.dart`

**Failing test first** (`test/features/groups/presentation/screens/plans_screen_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/plan.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/user_plan.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/plans_screen.dart';

void main() {
  final plans = [
    ReadingPlan(
      id: 'p1',
      name: 'Gospel of John',
      description: 'Read through John',
      coverEmoji: '✝️',
      totalDays: 21,
      tags: ['gospel'],
      readings: [],
    ),
  ];

  testWidgets('PlansScreen renders plan library', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value(plans)),
          activeUserPlansProvider.overrideWith((_) => Stream.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const PlansScreen()),
            GoRoute(path: '/plans/:planId', builder: (_, __) => const Scaffold()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Gospel of John'), findsOneWidget);
    expect(find.text('21 days • gospel'), findsOneWidget);
    expect(find.text('Plan Library'), findsOneWidget);
  });

  testWidgets('PlansScreen shows active plan with Mark Read button', (tester) async {
    final activePlans = [
      UserPlan(
        id: 'up1',
        userId: 'user1',
        planId: 'p1',
        startDate: DateTime.now(),
        currentDay: 3,
        completedDays: [1, 2],
        isComplete: false,
        todayRead: false,
        todayChapter: 'John 3',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value(plans)),
          activeUserPlansProvider.overrideWith((_) => Stream.value(activePlans)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const PlansScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('My Active Plans'), findsOneWidget);
    expect(find.text('John 3'), findsOneWidget);
    expect(find.text('Mark Read'), findsOneWidget);
  });

  testWidgets('PlansScreen shows check icon when todayRead is true', (tester) async {
    final activePlans = [
      UserPlan(
        id: 'up1',
        userId: 'user1',
        planId: 'p1',
        startDate: DateTime.now(),
        currentDay: 3,
        completedDays: [1, 2],
        isComplete: false,
        todayRead: true,
        todayChapter: 'John 3',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value(plans)),
          activeUserPlansProvider.overrideWith((_) => Stream.value(activePlans)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const PlansScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Mark Read'), findsNothing);
  });
}
```

**Implementation** (`lib/features/groups/presentation/screens/plans_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_providers.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(planLibraryProvider);
    final activePlansAsync = ref.watch(activeUserPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: ListView(
        children: [
          activePlansAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (active) => active.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'My Active Plans',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ...active.map((up) => ListTile(
                            title: Text(up.todayChapter),
                            subtitle: LinearProgressIndicator(
                              value: up.currentDay / (up.completedDays.length + 1),
                            ),
                            trailing: up.todayRead
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : ElevatedButton(
                                    onPressed: () async {
                                      await ref
                                          .read(planRepositoryProvider)
                                          .markTodayRead(up.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Marked as read!')),
                                        );
                                      }
                                    },
                                    child: const Text('Mark Read'),
                                  ),
                          )),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Plan Library', style: Theme.of(context).textTheme.titleMedium),
          ),
          plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (plans) => plans.isEmpty
                ? const Center(child: Text('No plans available'))
                : Column(
                    children: plans
                        .map((p) => ListTile(
                              leading: Text(p.coverEmoji,
                                  style: const TextStyle(fontSize: 32)),
                              title: Text(p.name),
                              subtitle: Text('${p.totalDays} days • ${p.tags.join(', ')}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/plans/${p.id}'),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
```

**Steps:**
- [ ] Write failing test
- [ ] Run test — confirm red
- [ ] Replace `plans_screen.dart` with the implementation above
- [ ] Run tests — confirm green
- [ ] `git add lib/features/groups/presentation/screens/plans_screen.dart test/features/groups/presentation/screens/plans_screen_test.dart`
- [ ] `git commit -m "feat: implement PlansScreen with active plans and plan library"`

---

## Task 10: Plan detail screen + start plan flow

**Files:**
- `lib/features/groups/presentation/screens/plan_detail_screen.dart`
- `test/features/groups/presentation/screens/plan_detail_screen_test.dart`

Also add route `/plans/:planId` to `app_router.dart`.

**Failing test first** (`test/features/groups/presentation/screens/plan_detail_screen_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/plan.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/plan_detail_screen.dart';

@GenerateMocks([PlanRepository])
void main() {
  final plan = ReadingPlan(
    id: 'p1',
    name: 'Gospel of John',
    description: 'Read through the Gospel of John',
    coverEmoji: '✝️',
    totalDays: 21,
    tags: ['gospel', 'john'],
    readings: [
      PlanReading(day: 1, book: 'John', chapter: '1', title: 'The Word'),
      PlanReading(day: 2, book: 'John', chapter: '2', title: 'Wedding at Cana'),
    ],
  );

  testWidgets('PlanDetailScreen renders plan info and readings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value([plan])),
          myGroupsProvider.overrideWith((_) => Stream.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const PlanDetailScreen(planId: 'p1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Gospel of John'), findsOneWidget);
    expect(find.text('Read through the Gospel of John'), findsOneWidget);
    expect(find.text('Day 1: The Word'), findsOneWidget);
    expect(find.text('John 1'), findsOneWidget);
    expect(find.text('Start Solo'), findsOneWidget);
    expect(find.text('Start with Group'), findsOneWidget);
  });

  testWidgets('PlanDetailScreen Start Solo calls startPlan with null groupId', (tester) async {
    final mockRepo = MockPlanRepository();
    when(mockRepo.startPlan(planId: 'p1', groupId: null)).thenAnswer((_) async => 'up1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value([plan])),
          myGroupsProvider.overrideWith((_) => Stream.value([])),
          planRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const PlanDetailScreen(planId: 'p1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Start Solo'));
    await tester.pump();

    verify(mockRepo.startPlan(planId: 'p1', groupId: null)).called(1);
  });
}
```

**Implementation** (`lib/features/groups/presentation/screens/plan_detail_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/plan.dart';
import '../providers/groups_providers.dart';

class PlanDetailScreen extends ConsumerWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(planLibraryProvider);

    return plansAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (plans) {
        final plan = plans.firstWhere(
          (p) => p.id == planId,
          orElse: () => throw Exception('Plan not found'),
        );

        return Scaffold(
          appBar: AppBar(title: Text(plan.name)),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(plan.coverEmoji,
                          style: const TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: 8),
                    Text(plan.description,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          plan.tags.map((t) => Chip(label: Text(t))).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ...plan.readings.map(
                (r) => ListTile(
                  title: Text('Day ${r.day}: ${r.title}'),
                  subtitle: Text('${r.book} ${r.chapter}'),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _startPlan(context, ref, plan, null),
                    child: const Text('Start Solo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showGroupPicker(context, ref, plan),
                    child: const Text('Start with Group'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startPlan(
    BuildContext context,
    WidgetRef ref,
    ReadingPlan plan,
    String? groupId,
  ) async {
    await ref.read(planRepositoryProvider).startPlan(planId: planId, groupId: groupId);
    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Started "${plan.name}"!')),
      );
    }
  }

  void _showGroupPicker(BuildContext context, WidgetRef ref, ReadingPlan plan) {
    final groups = ref.read(myGroupsProvider).valueOrNull ?? [];
    if (groups.isEmpty) {
      _startPlan(context, ref, plan, null);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose a group'),
        children: groups
            .map(
              (g) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _startPlan(context, ref, plan, g.id);
                },
                child: Text(g.name),
              ),
            )
            .toList(),
      ),
    );
  }
}
```

**Router change** — add to `app_router.dart`:
```dart
GoRoute(
  path: '/plans/:planId',
  builder: (_, state) => PlanDetailScreen(planId: state.pathParameters['planId']!),
),
```

**Steps:**
- [ ] Write failing test
- [ ] Run test — confirm red
- [ ] Implement `plan_detail_screen.dart`
- [ ] Add `/plans/:planId` route to `app_router.dart`
- [ ] Run tests — confirm green
- [ ] `git add lib/features/groups/presentation/screens/plan_detail_screen.dart lib/core/navigation/app_router.dart test/features/groups/presentation/screens/plan_detail_screen_test.dart`
- [ ] `git commit -m "feat: add PlanDetailScreen with Start Solo and Start with Group flow"`

---

## Task 11: Nudge Cloud Function (TypeScript)

**Files:**
- `functions/src/nudge.ts`
- `functions/src/index.ts` (export update)

**Implementation** (`functions/src/nudge.ts`):
```typescript
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';

const db = admin.firestore();

export const onNudgeSent = onDocumentCreated('nudges/{nudgeId}', async (event) => {
  const nudge = event.data?.data();
  if (!nudge) return;
  const { fromUserId, toUserId, groupId } = nudge;

  // Rate limit: 1 nudge per sender→recipient pair per 24h
  const dayAgo = new Date(Date.now() - 86400000);
  const pairSnap = await db.collection('nudges')
    .where('fromUserId', '==', fromUserId)
    .where('toUserId', '==', toUserId)
    .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(dayAgo))
    .get();
  if (pairSnap.docs.length > 1) {
    await event.data?.ref.delete();
    return;
  }

  // Rate limit: max 5 nudges per sender per day
  const totalSnap = await db.collection('nudges')
    .where('fromUserId', '==', fromUserId)
    .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(dayAgo))
    .get();
  if (totalSnap.docs.length > 5) {
    await event.data?.ref.delete();
    return;
  }

  // Deliver FCM notification
  const toUser = await db.collection('users').doc(toUserId).get();
  const fcmToken = toUser.data()?.fcmToken;
  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Someone nudged you! 👋',
        body: "Time to read today's passage.",
      },
      data: { type: 'nudge', groupId: groupId || '' },
    });
  }
});

export const onUserLeaveGroup = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) throw new Error('Unauthenticated');
  const { groupId } = request.data as { groupId: string };

  const groupRef = db.collection('groups').doc(groupId);
  const batch = db.batch();
  batch.update(groupRef, {
    memberIds: admin.firestore.FieldValue.arrayRemove(userId),
  });
  batch.delete(groupRef.collection('members').doc(userId));
  batch.set(groupRef.collection('messages').doc(), {
    senderId: 'system',
    text: 'A member left the group.',
    type: 'system',
    timestamp: admin.firestore.Timestamp.now(),
  });
  await batch.commit();

  // Detach user's active plans from this group
  const plansSnap = await db.collection('userPlans')
    .where('userId', '==', userId)
    .where('groupId', '==', groupId)
    .get();
  const planBatch = db.batch();
  plansSnap.docs.forEach((doc) => planBatch.update(doc.ref, { groupId: null }));
  await planBatch.commit();

  return { success: true };
});
```

**Update `functions/src/index.ts`** — add exports:
```typescript
export { onNudgeSent, onUserLeaveGroup } from './nudge';
```

**Note:** No Flutter widget test for this task. Verify manually using Firebase Emulator or write a Jest/Mocha test in `functions/src/__tests__/nudge.test.ts` if the project has a JS test setup.

**Steps:**
- [ ] Create `functions/src/nudge.ts` with the implementation above
- [ ] Export `onNudgeSent` and `onUserLeaveGroup` from `functions/src/index.ts`
- [ ] Run `cd functions && npm run build` — confirm TypeScript compiles without errors
- [ ] `git add functions/src/nudge.ts functions/src/index.ts`
- [ ] `git commit -m "feat: add onNudgeSent (rate-limited FCM) and onUserLeaveGroup Cloud Functions"`

---

## Task 12: Seed pre-built plans

**Files:**
- `lib/core/data/seed_plans.dart`
- `test/core/data/seed_plans_test.dart`

**Failing test first** (`test/core/data/seed_plans_test.dart`):
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/core/data/seed_plans.dart';

void main() {
  test('SeedService seeds exactly 5 plans when collection is empty', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await SeedService.seedPlansIfNeeded(fakeFirestore);
    final snap = await fakeFirestore.collection('plans').get();
    expect(snap.docs.length, 5);
  });

  test('SeedService does not seed plans when collection already has docs', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore.collection('plans').add({'name': 'Existing', 'isCustom': false});
    await SeedService.seedPlansIfNeeded(fakeFirestore);
    final snap = await fakeFirestore.collection('plans').get();
    expect(snap.docs.length, 1); // unchanged
  });

  test('Genesis plan has 10 readings', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await SeedService.seedPlansIfNeeded(fakeFirestore);
    final snap = await fakeFirestore.collection('plans')
        .where('name', isEqualTo: 'Start Here: Genesis 1-10')
        .get();
    expect(snap.docs.length, 1);
    final readings = snap.docs.first.data()['readings'] as List;
    expect(readings.length, 10);
  });

  test('Gospel of John plan has 21 readings', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await SeedService.seedPlansIfNeeded(fakeFirestore);
    final snap = await fakeFirestore.collection('plans')
        .where('name', isEqualTo: 'Gospel of John')
        .get();
    final readings = snap.docs.first.data()['readings'] as List;
    expect(readings.length, 21);
  });

  test('Proverbs plan has 31 readings', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await SeedService.seedPlansIfNeeded(fakeFirestore);
    final snap = await fakeFirestore.collection('plans')
        .where('name', isEqualTo: 'Proverbs 31-day')
        .get();
    final readings = snap.docs.first.data()['readings'] as List;
    expect(readings.length, 31);
  });
}
```

**Implementation** (`lib/core/data/seed_plans.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  static Future<void> seedPlansIfNeeded(FirebaseFirestore db) async {
    final existing = await db.collection('plans').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = db.batch();
    for (final plan in _officialPlans) {
      final ref = db.collection('plans').doc();
      batch.set(ref, plan);
    }
    await batch.commit();
  }

  static final List<Map<String, dynamic>> _officialPlans = [
    {
      'name': 'Start Here: Genesis 1-10',
      'description': 'Begin your Bible journey with the first 10 chapters of Genesis — creation, the fall, and the flood.',
      'coverEmoji': '📖',
      'totalDays': 10,
      'tags': ['beginners', 'genesis'],
      'isCustom': false,
      'creatorId': null,
      'readings': List.generate(
        10,
        (i) => {
          'day': i + 1,
          'book': 'Genesis',
          'chapter': '${i + 1}',
          'title': _genesisTitles[i],
        },
      ),
    },
    {
      'name': "The Lord's Prayer Week",
      'description': "Seven days exploring the Sermon on the Mount and the Lord's Prayer in Matthew and Luke.",
      'coverEmoji': '🙏',
      'totalDays': 7,
      'tags': ['prayer', 'sermon', 'matthew', 'luke'],
      'isCustom': false,
      'creatorId': null,
      'readings': const [
        {'day': 1, 'book': 'Matthew', 'chapter': '5', 'title': 'The Beatitudes'},
        {'day': 2, 'book': 'Matthew', 'chapter': '6', 'title': "The Lord's Prayer"},
        {'day': 3, 'book': 'Matthew', 'chapter': '7', 'title': 'Ask, Seek, Knock'},
        {'day': 4, 'book': 'Luke', 'chapter': '11', 'title': "A Friend at Midnight"},
        {'day': 5, 'book': 'Luke', 'chapter': '12', 'title': 'Do Not Worry'},
        {'day': 6, 'book': 'Luke', 'chapter': '13', 'title': 'The Narrow Door'},
        {'day': 7, 'book': 'Luke', 'chapter': '14', 'title': 'The Cost of Discipleship'},
      ],
    },
    {
      'name': 'Psalms of Comfort',
      'description': 'Fourteen psalms chosen for comfort, hope, and drawing near to God.',
      'coverEmoji': '💙',
      'totalDays': 14,
      'tags': ['psalms', 'comfort', 'peace'],
      'isCustom': false,
      'creatorId': null,
      'readings': const [
        {'day': 1,  'book': 'Psalms', 'chapter': '23',  'title': 'The Lord Is My Shepherd'},
        {'day': 2,  'book': 'Psalms', 'chapter': '27',  'title': 'The Lord Is My Light'},
        {'day': 3,  'book': 'Psalms', 'chapter': '46',  'title': 'God Is Our Refuge'},
        {'day': 4,  'book': 'Psalms', 'chapter': '91',  'title': 'Under His Wings'},
        {'day': 5,  'book': 'Psalms', 'chapter': '103', 'title': 'Bless the Lord'},
        {'day': 6,  'book': 'Psalms', 'chapter': '121', 'title': 'My Help Comes from the Lord'},
        {'day': 7,  'book': 'Psalms', 'chapter': '130', 'title': 'Out of the Depths'},
        {'day': 8,  'book': 'Psalms', 'chapter': '139', 'title': 'You Have Searched Me'},
        {'day': 9,  'book': 'Psalms', 'chapter': '143', 'title': 'Teach Me to Do Your Will'},
        {'day': 10, 'book': 'Psalms', 'chapter': '34',  'title': 'Taste and See'},
        {'day': 11, 'book': 'Psalms', 'chapter': '42',  'title': 'As the Deer Pants'},
        {'day': 12, 'book': 'Psalms', 'chapter': '51',  'title': 'Create in Me a Clean Heart'},
        {'day': 13, 'book': 'Psalms', 'chapter': '63',  'title': 'My Soul Thirsts for You'},
        {'day': 14, 'book': 'Psalms', 'chapter': '84',  'title': 'How Lovely Is Your Dwelling'},
      ],
    },
    {
      'name': 'Gospel of John',
      'description': 'Read through all 21 chapters of the Gospel of John — one chapter per day.',
      'coverEmoji': '✝️',
      'totalDays': 21,
      'tags': ['gospel', 'john', 'jesus'],
      'isCustom': false,
      'creatorId': null,
      'readings': List.generate(
        21,
        (i) => {
          'day': i + 1,
          'book': 'John',
          'chapter': '${i + 1}',
          'title': _johnTitles[i],
        },
      ),
    },
    {
      'name': 'Proverbs 31-day',
      'description': 'A proverb a day for the whole month — all 31 chapters of Proverbs.',
      'coverEmoji': '⚡',
      'totalDays': 31,
      'tags': ['wisdom', 'proverbs'],
      'isCustom': false,
      'creatorId': null,
      'readings': List.generate(
        31,
        (i) => {
          'day': i + 1,
          'book': 'Proverbs',
          'chapter': '${i + 1}',
          'title': 'Proverbs ${i + 1}',
        },
      ),
    },
  ];

  static const _genesisTitles = [
    'Creation',
    'The Garden of Eden',
    'The Fall',
    'Cain and Abel',
    'From Adam to Noah',
    'Wickedness and the Flood',
    'The Flood Continues',
    'The Flood Recedes',
    "God's Covenant with Noah",
    'The Table of Nations',
  ];

  static const _johnTitles = [
    'The Word Became Flesh',
    'The Wedding at Cana',
    'Jesus and Nicodemus',
    'The Woman at the Well',
    'The Official\'s Son',
    'The Healing at Bethesda',
    'Feeding the Five Thousand',
    'Walking on Water',
    'The Bread of Life',
    'The Woman Caught in Adultery',
    'The Light of the World',
    'The Good Shepherd',
    'The Raising of Lazarus',
    'Mary Anoints Jesus',
    'The Triumphal Entry',
    'Jesus Washes Feet',
    'The Farewell Discourse',
    'The Vine and the Branches',
    'The High Priestly Prayer',
    'The Arrest and Trial',
    'The Resurrection',
  ];
}
```

**Call from app initialization** — in your `firebase_module.dart` or `main.dart`, in debug mode only:
```dart
if (kDebugMode) {
  await SeedService.seedPlansIfNeeded(FirebaseFirestore.instance);
}
```

**Steps:**
- [ ] Create `lib/core/data/seed_plans.dart`
- [ ] Write failing test in `test/core/data/seed_plans_test.dart`
- [ ] Run `flutter test test/core/data/seed_plans_test.dart` — confirm red
- [ ] Implement `SeedService` in `seed_plans.dart`
- [ ] Run tests — confirm green
- [ ] Add `SeedService.seedPlansIfNeeded(FirebaseFirestore.instance)` call in debug init
- [ ] `git add lib/core/data/seed_plans.dart test/core/data/seed_plans_test.dart`
- [ ] `git commit -m "feat: add SeedService with 5 pre-built reading plans"`

---

## Task 13: Home screen group check-in card

**Files:**
- `lib/features/groups/presentation/widgets/group_check_in_card.dart`
- `lib/features/home/presentation/screens/home_screen.dart` (update to integrate card)
- `lib/features/groups/presentation/providers/groups_providers.dart` (add groupCheckInProvider)
- `test/features/groups/presentation/widgets/group_check_in_card_test.dart`

**Failing test first** (`test/features/groups/presentation/widgets/group_check_in_card_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group_member.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/widgets/group_check_in_card.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

class MockUser extends Mock implements User {
  @override String get uid => 'user1';
}

void main() {
  final group = Group(
    id: 'g1',
    name: 'Morning Crew',
    description: '',
    creatorId: 'user1',
    inviteCode: 'ABC123',
    memberIds: ['user1', 'user2', 'user3'],
    groupStreak: 4,
    weeklyXpBoard: {},
  );

  final members = [
    GroupMember(userId: 'user1', displayName: 'Alice', todayRead: true, streak: 5),
    GroupMember(userId: 'user2', displayName: 'Bob', todayRead: false, streak: 2),
    GroupMember(userId: 'user3', displayName: 'Carol', todayRead: false, streak: 1),
  ];

  testWidgets('GroupCheckInCard shows nudge chips for unread members only', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier()..state = AsyncValue.data(MockUser()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => Scaffold(
                body: GroupCheckInCard(group: group, members: members),
              ),
            ),
            GoRoute(path: '/groups/:groupId', builder: (_, __) => const Scaffold()),
          ]),
        ),
      ),
    );
    await tester.pump();

    // Bob and Carol haven't read — two nudge chips
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);
    // Alice read — no chip for her
    expect(find.byType(ActionChip), findsNWidgets(2));
  });

  testWidgets('GroupCheckInCard shows read count', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier()..state = AsyncValue.data(MockUser()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => Scaffold(
                body: GroupCheckInCard(group: group, members: members),
              ),
            ),
            GoRoute(path: '/groups/:groupId', builder: (_, __) => const Scaffold()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1/3 read today'), findsOneWidget);
  });
}
```

**Implementation** (`lib/features/groups/presentation/widgets/group_check_in_card.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../domain/models/group.dart';
import '../../domain/models/group_member.dart';

class GroupCheckInCard extends ConsumerWidget {
  final Group group;
  final List<GroupMember> members;

  const GroupCheckInCard({
    super.key,
    required this.group,
    required this.members,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = members.where((m) => !m.todayRead).toList();
    final read = members.where((m) => m.todayRead).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(group.name, style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${read.length}/${members.length} read today',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => context.push('/groups/${group.id}'),
                  child: const Text('View'),
                ),
              ],
            ),
            if (unread.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: unread.map((m) {
                  return ActionChip(
                    avatar: CircleAvatar(
                      child: Text(
                        m.displayName.isNotEmpty ? m.displayName[0] : '?',
                      ),
                    ),
                    label: Text(m.displayName),
                    onPressed: () async {
                      final user = ref.read(authNotifierProvider).valueOrNull;
                      if (user == null) return;
                      await FirebaseFirestore.instance.collection('nudges').add({
                        'fromUserId': user.uid,
                        'toUserId': m.userId,
                        'groupId': group.id,
                        'sentAt': FieldValue.serverTimestamp(),
                        'opened': false,
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nudge sent!')),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Add `groupCheckInProvider`** to `lib/features/groups/presentation/providers/groups_providers.dart`:
```dart
// Provides the first group that has an active plan, plus its members
final groupCheckInProvider = StreamProvider<({Group group, List<GroupMember> members})?>(
  (ref) async* {
    final groupsAsync = ref.watch(myGroupsProvider);
    final groups = groupsAsync.valueOrNull ?? [];
    final activeGroup = groups.where((g) => g.activePlanId != null).firstOrNull;
    if (activeGroup == null) { yield null; return; }
    yield* ref
        .watch(groupRepositoryProvider)
        .watchMembers(activeGroup.id)
        .map((members) => (group: activeGroup, members: members));
  },
);
```

**HomeScreen integration** — in `lib/features/home/presentation/screens/home_screen.dart`, add the card near the top of the body:
```dart
// Inside build, add before existing content:
final checkInAsync = ref.watch(groupCheckInProvider);
checkInAsync.when(
  data: (data) => data != null
      ? GroupCheckInCard(group: data.group, members: data.members)
      : const SizedBox.shrink(),
  loading: () => const SizedBox.shrink(),
  error: (_, __) => const SizedBox.shrink(),
),
```

**Steps:**
- [ ] Write failing test in `test/features/groups/presentation/widgets/group_check_in_card_test.dart`
- [ ] Run test — confirm red
- [ ] Create `lib/features/groups/presentation/widgets/group_check_in_card.dart`
- [ ] Add `groupCheckInProvider` to `groups_providers.dart`
- [ ] Integrate `GroupCheckInCard` into `home_screen.dart`
- [ ] Run all tests — confirm green
- [ ] `git add lib/features/groups/presentation/widgets/ lib/features/groups/presentation/providers/groups_providers.dart lib/features/home/presentation/screens/home_screen.dart test/features/groups/presentation/widgets/`
- [ ] `git commit -m "feat: add GroupCheckInCard with nudge chips and integrate into HomeScreen"`

---

## Summary

| Task | What ships |
|------|-----------|
| 1 | `Group`, `GroupMember`, `ReadingPlan`, `PlanReading`, `UserPlan` domain models |
| 2 | `GroupRepository` — watchMyGroups, watchGroup, watchMembers, createGroup, joinGroup |
| 3 | `PlanRepository` — watchPlanLibrary, watchActiveUserPlans, startPlan, markTodayRead |
| 4 | Riverpod providers — groupRepository, planRepository, myGroups, groupDetail, groupMembers, planLibrary, activeUserPlans |
| 5 | `GroupsScreen` — group list, empty state, FAB with create/join sheet; routes added |
| 6 | `CreateGroupScreen` + `JoinGroupScreen` |
| 7 | `GroupDetailScreen` — members check-in, group streak, nudge button |
| 8 | `LeaderboardScreen` — weekly XP sorted, medal icons |
| 9 | `PlansScreen` — active plans with mark-read + plan library |
| 10 | `PlanDetailScreen` — readings list, Start Solo, Start with Group flow |
| 11 | Cloud Functions: `onNudgeSent` (rate-limit + FCM), `onUserLeaveGroup` (callable) |
| 12 | `SeedService` — seeds 5 pre-built plans into Firestore on first run |
| 13 | `GroupCheckInCard` widget + `groupCheckInProvider` + HomeScreen integration |

**After all 13 tasks:** All groups and plans functionality is complete. The app supports creating and joining groups, reading plan library, active plan tracking, daily check-ins visible to group members, nudging unread members, a weekly XP leaderboard, and the five official pre-built reading plans.
