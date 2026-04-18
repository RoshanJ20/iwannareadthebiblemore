import 'dart:async';
import '../../features/bible/domain/entities/annotation.dart';
import '../../features/bible/domain/entities/bookmark.dart';
import '../../features/bible/domain/repositories/annotation_repository.dart';
import '../../features/bible/domain/repositories/bookmark_repository.dart';
import '../../features/gamification/domain/entities/user_stats.dart';
import '../../features/gamification/domain/repositories/user_stats_repository.dart';
import '../../features/groups/domain/entities/group.dart';
import '../../features/groups/domain/entities/group_member.dart';
import '../../features/groups/domain/entities/nudge.dart';
import '../../features/groups/domain/entities/user_plan.dart';
import '../../features/groups/domain/repositories/group_repository.dart';
import '../../features/groups/domain/repositories/user_plan_repository.dart';

/// Demo user stats shown on web when Firebase is unavailable.
final _demoStats = UserStats(
  userId: 'demo-user-001',
  xpTotal: 1250,
  xpBalance: 800,
  currentStreak: 7,
  longestStreak: 14,
  lastReadDate: DateTime.now().subtract(const Duration(hours: 2)),
  streakFreezes: 1,
);

class WebMockUserStatsRepository implements UserStatsRepository {
  @override
  Stream<UserStats> watchUserStats(String userId) =>
      Stream.value(_demoStats);

  @override
  Stream<List<String>> watchEarnedAchievementIds(String userId) =>
      Stream.value(['first_flame', 'better_together']);
}

class WebMockGroupRepository implements GroupRepository {
  @override
  Stream<List<Group>> watchUserGroups(String userId) =>
      Stream.value([]);

  @override
  Stream<List<GroupMember>> watchGroupMembers(String groupId) =>
      Stream.value([]);

  @override
  Future<Group> createGroup({
    required String name,
    required String description,
    required String creatorId,
  }) async {
    return Group(
      id: 'mock-group-1',
      name: name,
      description: description,
      inviteCode: 'DEMO01',
      creatorId: creatorId,
      memberIds: [creatorId],
      activePlanId: null,
      groupStreak: 0,
      weeklyXpBoard: {},
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Group?> findGroupByInviteCode(String code) async => null;

  @override
  Future<void> joinGroup(String groupId, String userId) async {}

  @override
  Future<void> leaveGroup(String groupId, String userId) async {}

  @override
  Future<void> sendNudge(Nudge nudge) async {}

  @override
  Future<void> setActivePlan(String groupId, String planId) async {}
}

class WebMockUserPlanRepository implements UserPlanRepository {
  @override
  Stream<List<UserPlan>> watchUserPlans(String userId) =>
      Stream.value([]);

  @override
  Future<UserPlan> createUserPlan(UserPlan plan) async => plan;

  @override
  Future<void> markTodayRead(
    String userPlanId, {
    required String userId,
    required String todayChapter,
    required String planId,
    String translation = 'KJV',
  }) async {}

  @override
  Future<void> deleteUserPlan(String userPlanId) async {}
}

class WebMockBookmarkRepository implements BookmarkRepository {
  final List<Bookmark> _bookmarks = [
    Bookmark(
      id: 'mock-bm-1',
      userId: 'demo-user-001',
      bookId: 'GEN',
      chapterNumber: 1,
      verseNumber: 1,
      verseText: 'In the beginning God created the heaven and the earth.',
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Stream<List<Bookmark>> watchBookmarks(String userId) =>
      Stream.value(List.of(_bookmarks));

  @override
  Future<Bookmark> addBookmark(Bookmark bookmark) async {
    _bookmarks.add(bookmark);
    return bookmark;
  }

  @override
  Future<void> removeBookmark(String userId, String bookmarkId) async {
    _bookmarks.removeWhere((b) => b.id == bookmarkId);
  }

  @override
  Future<bool> isBookmarked(String userId, String bookId, int chapterNumber, int verseNumber) async {
    return _bookmarks.any((b) =>
        b.userId == userId &&
        b.bookId == bookId &&
        b.chapterNumber == chapterNumber &&
        b.verseNumber == verseNumber);
  }
}

class WebMockAnnotationRepository implements AnnotationRepository {
  @override
  Stream<List<Annotation>> watchChapterAnnotations(
      String userId, String bookId, int chapterNumber) =>
      Stream.value([]);

  @override
  Future<Annotation> createAnnotation(Annotation annotation) async =>
      annotation;

  @override
  Future<void> updateAnnotation(Annotation annotation) async {}

  @override
  Future<void> deleteAnnotation(String userId, String annotationId) async {}

  @override
  Future<List<Annotation>> getAnnotationsForChapter(
      String userId, String bookId, int chapterNumber) async =>
      [];
}
