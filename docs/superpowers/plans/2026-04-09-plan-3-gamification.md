# Gamification Feature — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full gamification system — XP display, streak visualization with tiers, lamb mascot state machine, 7 achievements, XP store, and Cloud Functions for server-side streak/XP/achievement logic.

**Architecture:** Client reads gamification state from Firestore via Riverpod StreamProviders; all mutations (streak updates, XP awards, achievement checks) happen server-side in Cloud Functions to prevent manipulation. Flutter UI renders mascot state, streak tiers, and XP using read-only streams. XP store uses a Firebase Callable Function for atomic purchase validation.

**Tech Stack:** Flutter/Dart, Riverpod, Firestore, Cloud Functions (TypeScript), Lottie

---

## Task 1: Domain models

**Files:**
- Create: `lib/features/gamification/domain/models/user_stats.dart`
- Create: `lib/features/gamification/domain/models/achievement.dart`
- Create: `lib/features/gamification/domain/models/xp_store_item.dart`
- Create: `lib/features/gamification/domain/models/streak_tier.dart`
- Test: `test/features/gamification/domain/models/streak_tier_test.dart`

```dart
// streak_tier.dart
enum StreakTier { grey, orange, red, gold, diamond }

extension StreakTierX on StreakTier {
  static StreakTier fromStreak(int streak) {
    if (streak == 0) return StreakTier.grey;
    if (streak < 7) return StreakTier.orange;
    if (streak < 30) return StreakTier.red;
    if (streak < 100) return StreakTier.gold;
    return StreakTier.diamond;
  }
  Color get color => switch (this) {
    StreakTier.grey => const Color(0xFF9E9E9E),
    StreakTier.orange => const Color(0xFFFF9800),
    StreakTier.red => const Color(0xFFF44336),
    StreakTier.gold => const Color(0xFFFFD700),
    StreakTier.diamond => const Color(0xFF42A5F5),
  };
}

// user_stats.dart
class UserStats {
  final int xpTotal;
  final int xpBalance;
  final int currentStreak;
  final int longestStreak;
  final int streakFreezes;
  final String? activeOutfitId;
  final DateTime? lastReadDate;
  const UserStats({required this.xpTotal, required this.xpBalance, required this.currentStreak, required this.longestStreak, required this.streakFreezes, this.activeOutfitId, this.lastReadDate});
  factory UserStats.empty() => const UserStats(xpTotal: 0, xpBalance: 0, currentStreak: 0, longestStreak: 0, streakFreezes: 0);
  factory UserStats.fromMap(Map<String, dynamic> m) => UserStats(xpTotal: m['xpTotal'] ?? 0, xpBalance: m['xpBalance'] ?? 0, currentStreak: m['currentStreak'] ?? 0, longestStreak: m['longestStreak'] ?? 0, streakFreezes: m['streakFreezes'] ?? 0, activeOutfitId: m['activeOutfitId'], lastReadDate: (m['lastReadDate'] as Timestamp?)?.toDate());
}

// achievement.dart
class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final DateTime? earnedAt; // null = not yet earned
  const Achievement({required this.id, required this.name, required this.description, required this.emoji, this.earnedAt});
}

const kAllAchievementDefs = [
  Achievement(id: 'first_flame', name: 'First Flame', description: 'Reach a 7-day streak', emoji: '🔥'),
  Achievement(id: 'month_of_faith', name: 'Month of Faith', description: 'Reach a 30-day streak', emoji: '📅'),
  Achievement(id: 'better_together', name: 'Better Together', description: 'Join your first group', emoji: '🤝'),
  Achievement(id: 'keepers_nudge', name: "Keeper's Nudge", description: 'Nudge 10 friends who read within 24h', emoji: '👋'),
  Achievement(id: 'in_the_beginning', name: 'In The Beginning', description: 'Read all chapters of Genesis', emoji: '📖'),
  Achievement(id: 'red_letters', name: 'Red Letters', description: 'Read all chapters of Matthew, Mark, Luke and John', emoji: '✝️'),
  Achievement(id: 'group_mvp', name: 'Group MVP', description: 'Top scorer in your group this week', emoji: '🏆'),
];

// xp_store_item.dart
class XpStoreItem {
  final String id;
  final String name;
  final int cost;
  final String category; // 'freeze' | 'outfit_basic' | 'outfit_rare' | 'outfit_legendary'
  final String emoji;
  const XpStoreItem({required this.id, required this.name, required this.cost, required this.category, required this.emoji});
}

const kXpStoreItems = [
  XpStoreItem(id: 'freeze_1', name: 'Streak Freeze', cost: 200, category: 'freeze', emoji: '🧊'),
  XpStoreItem(id: 'outfit_basic_1', name: 'Wool Scarf', cost: 500, category: 'outfit_basic', emoji: '🧣'),
  XpStoreItem(id: 'outfit_basic_2', name: 'Flower Crown', cost: 500, category: 'outfit_basic', emoji: '🌸'),
  XpStoreItem(id: 'outfit_basic_3', name: 'Bow Tie', cost: 500, category: 'outfit_basic', emoji: '🎀'),
  XpStoreItem(id: 'outfit_rare_1', name: 'Angel Wings', cost: 1000, category: 'outfit_rare', emoji: '👼'),
  XpStoreItem(id: 'outfit_rare_2', name: 'Rainbow Blanket', cost: 1000, category: 'outfit_rare', emoji: '🌈'),
  XpStoreItem(id: 'outfit_rare_3', name: 'Golden Bell', cost: 1000, category: 'outfit_rare', emoji: '🔔'),
  XpStoreItem(id: 'outfit_legendary_1', name: 'Crown of Stars', cost: 2000, category: 'outfit_legendary', emoji: '⭐'),
  XpStoreItem(id: 'outfit_legendary_2', name: 'Shepherd Staff', cost: 2000, category: 'outfit_legendary', emoji: '🪄'),
];
```

**Test:** `StreakTierX.fromStreak()` returns correct tier for 0, 3, 7, 30, 100.

**Steps:**
- [ ] Create `lib/features/gamification/domain/models/` directory structure
- [ ] Write `streak_tier.dart` with `StreakTier` enum and `StreakTierX` extension
- [ ] Write `user_stats.dart` with `UserStats` class, `fromMap` factory, and `empty` factory
- [ ] Write `achievement.dart` with `Achievement` class and `kAllAchievementDefs` constant (7 entries)
- [ ] Write `xp_store_item.dart` with `XpStoreItem` class and `kXpStoreItems` constant (9 entries)
- [ ] Write `test/features/gamification/domain/models/streak_tier_test.dart` testing `fromStreak` for values 0, 3, 7, 30, 100
- [ ] Run `flutter test test/features/gamification/domain/models/streak_tier_test.dart` and confirm all pass
- [ ] Run `flutter analyze lib/features/gamification/domain/` and fix any issues
- [ ] `git add lib/features/gamification/domain/ test/features/gamification/domain/` and commit: `feat: add gamification domain models (UserStats, Achievement, XpStoreItem, StreakTier)`

---

## Task 2: Gamification repository & Firestore data layer

**Files:**
- Create: `lib/features/gamification/data/gamification_repository.dart`
- Test: `test/features/gamification/data/gamification_repository_test.dart`

```dart
class GamificationRepository {
  final FirebaseFirestore _db;
  final String _userId;
  GamificationRepository(this._db, this._userId);

  Stream<UserStats> watchUserStats() => _db.collection('users').doc(_userId).snapshots().map((doc) => doc.exists ? UserStats.fromMap(doc.data()!) : UserStats.empty());

  Stream<List<Achievement>> watchAchievements() {
    return _db.collection('users').doc(_userId).collection('achievements').snapshots().map((snap) {
      final earned = {for (final doc in snap.docs) doc.id: (doc.data()['earnedAt'] as Timestamp).toDate()};
      return kAllAchievementDefs.map((a) => Achievement(id: a.id, name: a.name, description: a.description, emoji: a.emoji, earnedAt: earned[a.id])).toList();
    });
  }
}
```

**Test:** Stream emits correct `UserStats` from `FakeFirebaseFirestore` doc.

**Steps:**
- [ ] Create `lib/features/gamification/data/` directory
- [ ] Write `gamification_repository.dart` with `GamificationRepository` class implementing `watchUserStats()` and `watchAchievements()`
- [ ] Write `test/features/gamification/data/gamification_repository_test.dart` using `fake_cloud_firestore`:
  - Test `watchUserStats()` emits `UserStats.empty()` when doc does not exist
  - Test `watchUserStats()` emits correct `UserStats` when doc has xpTotal, xpBalance, currentStreak, longestStreak, streakFreezes
  - Test `watchAchievements()` returns all 7 achievements with `earnedAt` null for unearned and populated for earned
- [ ] Run `flutter test test/features/gamification/data/gamification_repository_test.dart` and confirm all pass
- [ ] `git add lib/features/gamification/data/ test/features/gamification/data/` and commit: `feat: add GamificationRepository with Firestore streams for stats and achievements`

---

## Task 3: Riverpod providers

**Files:**
- Create: `lib/features/gamification/gamification_providers.dart`
- Test: `test/features/gamification/gamification_providers_test.dart`

```dart
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) throw StateError('No authenticated user');
  return GamificationRepository(FirebaseFirestore.instance, user.uid);
});

final userStatsProvider = StreamProvider<UserStats>((ref) => ref.watch(gamificationRepositoryProvider).watchUserStats());
final achievementsProvider = StreamProvider<List<Achievement>>((ref) => ref.watch(gamificationRepositoryProvider).watchAchievements());
```

**Test:** `userStatsProvider` emits `UserStats` from overridden repository.

**Steps:**
- [ ] Write `lib/features/gamification/gamification_providers.dart` with `gamificationRepositoryProvider`, `userStatsProvider`, and `achievementsProvider`
- [ ] Write `test/features/gamification/gamification_providers_test.dart`:
  - Override `gamificationRepositoryProvider` with a mock repository using mocktail
  - Verify `userStatsProvider` emits the `UserStats` returned by the mock's `watchUserStats()` stream
  - Verify `achievementsProvider` emits the list returned by `watchAchievements()`
- [ ] Run `flutter test test/features/gamification/gamification_providers_test.dart` and confirm all pass
- [ ] `git add lib/features/gamification/gamification_providers.dart test/features/gamification/gamification_providers_test.dart` and commit: `feat: add Riverpod providers for gamification (userStats, achievements)`

---

## Task 4: Streak display widget

**Files:**
- Create: `lib/features/gamification/presentation/widgets/streak_widget.dart`
- Test: `test/features/gamification/presentation/widgets/streak_widget_test.dart`

```dart
class StreakWidget extends StatelessWidget {
  final int streak;
  const StreakWidget({super.key, required this.streak});
  @override Widget build(BuildContext context) {
    final tier = StreakTierX.fromStreak(streak);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.local_fire_department, color: tier.color, size: 28),
      const SizedBox(width: 4),
      Text('$streak', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: tier.color, fontWeight: FontWeight.bold)),
    ]);
  }
}
```

**Test:** Renders orange flame for streak=3, gold for streak=30.

**Steps:**
- [ ] Create `lib/features/gamification/presentation/widgets/` directory
- [ ] Write `streak_widget.dart` with `StreakWidget` stateless widget that reads `StreakTierX.fromStreak(streak)` for color
- [ ] Write `test/features/gamification/presentation/widgets/streak_widget_test.dart`:
  - Pump `StreakWidget(streak: 3)` and verify the `Icon` has color `Color(0xFFFF9800)` (orange)
  - Pump `StreakWidget(streak: 30)` and verify the `Icon` has color `Color(0xFFFFD700)` (gold)
  - Pump `StreakWidget(streak: 0)` and verify color is grey
- [ ] Run `flutter test test/features/gamification/presentation/widgets/streak_widget_test.dart` and confirm all pass
- [ ] `git add lib/features/gamification/presentation/widgets/streak_widget.dart test/features/gamification/presentation/widgets/streak_widget_test.dart` and commit: `feat: add StreakWidget with tier-colored flame icon`

---

## Task 5: XP display widget

**Files:**
- Create: `lib/features/gamification/presentation/widgets/xp_widget.dart`
- Test: `test/features/gamification/presentation/widgets/xp_widget_test.dart`

```dart
class XpWidget extends StatelessWidget {
  final int xpBalance;
  final int xpTotal;
  const XpWidget({super.key, required this.xpBalance, required this.xpTotal});
  @override Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
        const SizedBox(width: 4),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: xpBalance),
          duration: const Duration(milliseconds: 600),
          builder: (_, val, __) => Text('$val XP', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFFFFD700))),
        ),
      ]),
      Text('$xpTotal total XP', style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
```

**Test:** Displays correct `xpBalance` and `xpTotal` text.

**Steps:**
- [ ] Write `xp_widget.dart` with `XpWidget` showing animated `xpBalance` and static `xpTotal`
- [ ] Write `test/features/gamification/presentation/widgets/xp_widget_test.dart`:
  - Pump `XpWidget(xpBalance: 350, xpTotal: 1200)` and pump animation to completion with `tester.pumpAndSettle()`
  - Verify text `'350 XP'` is present
  - Verify text `'1200 total XP'` is present
- [ ] Run `flutter test test/features/gamification/presentation/widgets/xp_widget_test.dart` and confirm all pass
- [ ] `git add lib/features/gamification/presentation/widgets/xp_widget.dart test/features/gamification/presentation/widgets/xp_widget_test.dart` and commit: `feat: add XpWidget with animated balance counter`

---

## Task 6: Lamb mascot widget

**Files:**
- Create: `lib/features/gamification/presentation/widgets/lamb_mascot_widget.dart`
- Create: `lib/features/gamification/domain/services/lamb_state_service.dart`
- Test: `test/features/gamification/domain/services/lamb_state_service_test.dart`

```dart
// lamb_state_service.dart
enum LambState { idle, excited, celebrating, worried, sad, sleeping, onFire }

class LambStateService {
  static LambState fromStats(UserStats stats, {bool readToday = false, DateTime? lastOpenedApp}) {
    final now = DateTime.now();
    if (lastOpenedApp != null && now.difference(lastOpenedApp).inDays >= 3) return LambState.sleeping;
    if (stats.currentStreak >= 100 && readToday) return LambState.onFire;
    if (stats.currentStreak >= 7 && readToday) return LambState.excited;
    // worried: <2hrs until midnight and not read today
    final midnight = DateTime(now.year, now.month, now.day + 1);
    if (!readToday && midnight.difference(now).inHours < 2) return LambState.worried;
    return LambState.idle;
  }

  static String lottieAssetPath(LambState state) => switch (state) {
    LambState.idle => 'assets/lottie/lamb_idle.json',
    LambState.excited => 'assets/lottie/lamb_excited.json',
    LambState.celebrating => 'assets/lottie/lamb_celebrating.json',
    LambState.worried => 'assets/lottie/lamb_worried.json',
    LambState.sad => 'assets/lottie/lamb_sad.json',
    LambState.sleeping => 'assets/lottie/lamb_sleeping.json',
    LambState.onFire => 'assets/lottie/lamb_onfire.json',
  };

  static Color fallbackColor(LambState state) => switch (state) {
    LambState.idle => const Color(0xFFF5F0E8),
    LambState.excited => const Color(0xFFFF9800),
    LambState.celebrating => const Color(0xFFFFD700),
    LambState.worried => const Color(0xFFFF5722),
    LambState.sad => const Color(0xFF9E9E9E),
    LambState.sleeping => const Color(0xFF90A4AE),
    LambState.onFire => const Color(0xFFFF1744),
  };
}

// lamb_mascot_widget.dart
class LambMascotWidget extends ConsumerWidget {
  final double size;
  const LambMascotWidget({super.key, this.size = 160});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    return statsAsync.when(
      loading: () => SizedBox(width: size, height: size, child: const CircularProgressIndicator()),
      error: (_, __) => _fallback(LambState.idle),
      data: (stats) {
        final state = LambStateService.fromStats(stats);
        final assetPath = LambStateService.lottieAssetPath(state);
        return SizedBox(width: size, height: size,
          child: Lottie.asset(assetPath, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _fallback(state)));
      },
    );
  }
  Widget _fallback(LambState state) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: LambStateService.fallbackColor(state), shape: BoxShape.circle),
    child: const Icon(Icons.pets, size: 64, color: Colors.white),
  );
}
```

**Test:** `LambStateService.fromStats` returns correct states for various stats combinations.

**Steps:**
- [ ] Create `lib/features/gamification/domain/services/` directory
- [ ] Write `lamb_state_service.dart` with `LambState` enum and `LambStateService` static methods
- [ ] Write `lamb_mascot_widget.dart` as a `ConsumerWidget` watching `userStatsProvider`, rendering Lottie with fallback circle
- [ ] Add Lottie asset placeholder files to `assets/lottie/` (create empty JSON stubs for each of the 7 states: `lamb_idle.json`, `lamb_excited.json`, `lamb_celebrating.json`, `lamb_worried.json`, `lamb_sad.json`, `lamb_sleeping.json`, `lamb_onfire.json`) — real assets to be added by designer later
- [ ] Ensure `pubspec.yaml` assets section includes `assets/lottie/`
- [ ] Write `test/features/gamification/domain/services/lamb_state_service_test.dart`:
  - `sleeping` when `lastOpenedApp` is 4 days ago
  - `onFire` when `currentStreak >= 100` and `readToday = true`
  - `excited` when `currentStreak == 7` and `readToday = true`
  - `worried` when `readToday = false` and current time is within 2 hours of midnight (mock `DateTime.now` or use a clock interface if needed)
  - `idle` as default
- [ ] Run `flutter test test/features/gamification/domain/services/lamb_state_service_test.dart` and confirm all pass
- [ ] `git add lib/features/gamification/ assets/lottie/ test/features/gamification/domain/services/` and commit: `feat: add LambStateService state machine and LambMascotWidget with Lottie`

---

## Task 7: Home screen (real implementation)

**Files:**
- Modify: `lib/features/shell/presentation/home_screen.dart` (replace placeholder)
- Test: `test/features/shell/presentation/home_screen_test.dart`

```dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('iwannareadthebiblemore'), actions: [
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
      ]),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userStatsProvider),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Center(child: LambMascotWidget()),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('Could not load stats'),
            data: (stats) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              StreakWidget(streak: stats.currentStreak),
              XpWidget(xpBalance: stats.xpBalance, xpTotal: stats.xpTotal),
            ]),
          ),
          const SizedBox(height: 24),
          // Today's reading card — placeholder until Plan 4 (Groups & Plans)
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today\'s Reading', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Start a reading plan to see today\'s passage here.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => context.go('/plans'), child: const Text('Browse Plans')),
          ]))),
          const SizedBox(height: 16),
          // Verse of the day — reads from /verseOfDay/{today}
          const VerseOfDayCard(),
        ]),
      ),
    );
  }
}

class VerseOfDayCard extends ConsumerWidget {
  const VerseOfDayCard({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final verseAsync = ref.watch(_verseOfDayProvider(today));
    return verseAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))),
      error: (_, __) => const SizedBox.shrink(),
      data: (verse) => verse == null ? const SizedBox.shrink() : Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Verse of the Day', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
        const SizedBox(height: 8),
        Text('"${verse['text']}"', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(height: 4),
        Text('— ${verse['reference']}', style: Theme.of(context).textTheme.bodySmall),
      ]))),
    );
  }
}

final _verseOfDayProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, dateStr) async {
  final doc = await FirebaseFirestore.instance.collection('verseOfDay').doc(dateStr).get();
  return doc.exists ? doc.data() : null;
});
```

**Test:** `HomeScreen` renders without crashing with mocked `userStatsProvider`.

**Steps:**
- [ ] Replace the placeholder body of `lib/features/shell/presentation/home_screen.dart` with the full implementation above
- [ ] Add required imports: `gamification_providers.dart`, `streak_widget.dart`, `xp_widget.dart`, `lamb_mascot_widget.dart`, `intl` (for `DateFormat`), `go_router`
- [ ] Add `intl` to `pubspec.yaml` if not already present, then run `flutter pub get`
- [ ] Write `test/features/shell/presentation/home_screen_test.dart`:
  - Override `userStatsProvider` with a stream of `UserStats(xpTotal: 500, xpBalance: 300, currentStreak: 5, longestStreak: 10, streakFreezes: 1)`
  - Override `_verseOfDayProvider` to return null (no verse today)
  - Pump `HomeScreen` and call `tester.pumpAndSettle()`
  - Verify `StreakWidget` and `XpWidget` are present in the tree
  - Verify `'Today\'s Reading'` text is visible
- [ ] Run `flutter test test/features/shell/presentation/home_screen_test.dart` and confirm all pass
- [ ] Run `flutter test` (full suite) to confirm no regressions in the 17 existing tests
- [ ] `git add lib/features/shell/presentation/home_screen.dart test/features/shell/presentation/home_screen_test.dart` and commit: `feat: implement HomeScreen with mascot, streak, XP, and verse of the day`

---

## Task 8: Achievements screen

**Files:**
- Create: `lib/features/gamification/presentation/screens/achievements_screen.dart`
- Test: `test/features/gamification/presentation/screens/achievements_screen_test.dart`

```dart
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (achievements) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: achievements.length,
          itemBuilder: (context, i) {
            final a = achievements[i];
            final earned = a.earnedAt != null;
            return GestureDetector(
              onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: Text(a.name), content: Column(mainAxisSize: MainAxisSize.min, children: [Text(a.emoji, style: const TextStyle(fontSize: 48)), const SizedBox(height: 8), Text(a.description), if (a.earnedAt != null) Text('Earned ${DateFormat.yMd().format(a.earnedAt!)}', style: Theme.of(context).textTheme.bodySmall)]))),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: earned ? AppColors.primary.withOpacity(0.2) : Colors.grey.withOpacity(0.15), border: earned ? Border.all(color: AppColors.primary, width: 2) : null),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(a.emoji, style: TextStyle(fontSize: 32, color: earned ? null : Colors.grey)),
                  const SizedBox(height: 4),
                  Text(a.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: earned ? null : Colors.grey)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

**Test:** 7 achievement tiles rendered; earned ones show colored border.

**Steps:**
- [ ] Create `lib/features/gamification/presentation/screens/` directory
- [ ] Write `achievements_screen.dart` with `AchievementsScreen` as a `ConsumerWidget` watching `achievementsProvider`
- [ ] Write `test/features/gamification/presentation/screens/achievements_screen_test.dart`:
  - Override `achievementsProvider` with a stream of all 7 `kAllAchievementDefs` where 2 have `earnedAt` populated and 5 do not
  - Pump `AchievementsScreen` and `pumpAndSettle()`
  - Verify exactly 7 tiles are present (find by emoji text or label)
  - Verify earned tiles have a `Border` decoration (inspect the `Container` widget's `decoration`)
- [ ] Run `flutter test test/features/gamification/presentation/screens/achievements_screen_test.dart` and confirm all pass
- [ ] Add route `/achievements` to the app router (wherever routing is configured)
- [ ] `git add lib/features/gamification/presentation/screens/achievements_screen.dart test/features/gamification/presentation/screens/achievements_screen_test.dart` and commit: `feat: add AchievementsScreen with 7-badge grid`

---

## Task 9: XP store screen

**Files:**
- Create: `lib/features/gamification/presentation/screens/xp_store_screen.dart`
- Test: `test/features/gamification/presentation/screens/xp_store_screen_test.dart`

```dart
class XpStoreScreen extends ConsumerWidget {
  const XpStoreScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('XP Store')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            const Icon(Icons.star, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text('${stats.xpBalance} XP available', style: Theme.of(context).textTheme.titleMedium),
          ])),
          Expanded(child: ListView.builder(
            itemCount: kXpStoreItems.length,
            itemBuilder: (context, i) {
              final item = kXpStoreItems[i];
              final canAfford = stats.xpBalance >= item.cost;
              return ListTile(
                leading: Text(item.emoji, style: const TextStyle(fontSize: 32)),
                title: Text(item.name),
                subtitle: Text('${item.cost} XP'),
                trailing: ElevatedButton(
                  onPressed: canAfford ? () => _confirmPurchase(context, ref, item, stats) : null,
                  child: const Text('Buy'),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }

  void _confirmPurchase(BuildContext context, WidgetRef ref, XpStoreItem item, UserStats stats) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Buy ${item.name}?'),
      content: Text('This will cost ${item.cost} XP. You have ${stats.xpBalance} XP.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(context);
          try {
            await FirebaseFunctions.instance.httpsCallable('xpStorePurchase').call({'itemId': item.id});
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} purchased!')));
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
          }
        }, child: const Text('Confirm')),
      ],
    ));
  }
}
```

**Test:** Items render; Buy button disabled when `xpBalance < item.cost`.

**Steps:**
- [ ] Add `cloud_functions` to `pubspec.yaml` if not already present (`firebase_functions: ^4.x.x`), then run `flutter pub get`
- [ ] Write `xp_store_screen.dart` with `XpStoreScreen` as a `ConsumerWidget` watching `userStatsProvider`
- [ ] Write `test/features/gamification/presentation/screens/xp_store_screen_test.dart`:
  - Override `userStatsProvider` with `UserStats` having `xpBalance: 600`
  - Pump `XpStoreScreen` and `pumpAndSettle()`
  - Verify items costing 200 and 500 have enabled Buy buttons
  - Verify items costing 1000 and 2000 have disabled Buy buttons (onPressed is null)
  - Verify `'600 XP available'` text is present
- [ ] Run `flutter test test/features/gamification/presentation/screens/xp_store_screen_test.dart` and confirm all pass
- [ ] Add route `/store` to the app router
- [ ] `git add lib/features/gamification/presentation/screens/xp_store_screen.dart test/features/gamification/presentation/screens/xp_store_screen_test.dart` and commit: `feat: add XpStoreScreen with purchase confirmation and affordability gating`

---

## Task 10: Cloud Functions — streak & XP (TypeScript)

**Files:**
- Create: `functions/src/streak.ts`
- Create: `functions/src/achievements.ts`
- Create: `functions/src/index.ts` (imports and exports all functions)

> Note: Cloud Functions unit tests use `firebase-functions-test`. Full unit test coverage for the TypeScript functions is recommended but optional at this stage; integration testing via the Firebase Emulator is acceptable.

```typescript
// functions/src/streak.ts
import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { checkAchievements } from './achievements';

const db = admin.firestore();

export const onReadingComplete = onDocumentUpdated('userPlans/{userPlanId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.todayRead === after.todayRead || !after.todayRead) return;

  const userId = after.userId as string;
  const userRef = db.collection('users').doc(userId);
  const groupId = after.groupId as string | null;

  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    const user = userDoc.data() || {};
    const today = new Date().toISOString().split('T')[0];
    const lastReadDate = user.lastReadDate?.toDate()?.toISOString().split('T')[0];
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];

    let currentStreak = user.currentStreak || 0;
    let longestStreak = user.longestStreak || 0;
    const isExtra = lastReadDate === today; // already read today = extra

    if (!isExtra) {
      if (lastReadDate === yesterday) { currentStreak += 1; }
      else { currentStreak = 1; }
      if (currentStreak > longestStreak) longestStreak = currentStreak;
    }

    const xpEarned = isExtra ? 20 : 50;
    tx.update(userRef, {
      currentStreak, longestStreak, lastReadDate: admin.firestore.Timestamp.now(),
      xpTotal: admin.firestore.FieldValue.increment(xpEarned),
      xpBalance: admin.firestore.FieldValue.increment(xpEarned),
    });
    tx.set(userRef.collection('readingLog').doc(today), { date: today, bookId: after.bookId || '', xpEarned });

    // Milestone XP bonuses
    const milestoneXp = currentStreak === 7 ? 100 : currentStreak === 30 ? 400 : currentStreak === 100 ? 1500 : 0;
    if (milestoneXp > 0) {
      tx.update(userRef, { xpTotal: admin.firestore.FieldValue.increment(milestoneXp), xpBalance: admin.firestore.FieldValue.increment(milestoneXp) });
    }
  });

  await checkAchievements(userId);

  // Update group member todayRead
  if (groupId) {
    await db.collection('groups').doc(groupId).collection('members').doc(userId).update({ todayRead: true });
  }
});

export const dailyStreakCheck = onSchedule('every 1 minutes', async () => {
  const now = new Date();
  const users = await db.collection('users').get();
  const batch = db.batch();
  for (const doc of users.docs) {
    const user = doc.data();
    const timezone = user.timezone || 'UTC';
    // Simple approach: check if it's past midnight in user timezone
    const userMidnight = new Date(now.toLocaleString('en-US', { timeZone: timezone }));
    if (userMidnight.getHours() !== 0 || userMidnight.getMinutes() > 1) continue;
    const lastRead = user.lastReadDate?.toDate()?.toISOString().split('T')[0];
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
    if (lastRead === yesterday || lastRead === new Date().toISOString().split('T')[0]) continue; // read yesterday or today, ok
    if ((user.streakFreezes || 0) > 0) {
      batch.update(doc.ref, { streakFreezes: admin.firestore.FieldValue.increment(-1) });
    } else if ((user.currentStreak || 0) > 0) {
      batch.update(doc.ref, { currentStreak: 0 });
    }
  }
  await batch.commit();
});
```

```typescript
// functions/src/achievements.ts
import * as admin from 'firebase-admin';
const db = admin.firestore();

export async function checkAchievements(userId: string): Promise<void> {
  const userRef = db.collection('users').doc(userId);
  const [userDoc, achievementsSnap, groupsSnap] = await Promise.all([
    userRef.get(),
    userRef.collection('achievements').get(),
    db.collection('groups').where('memberIds', 'array-contains', userId).limit(1).get(),
  ]);
  const user = userDoc.data() || {};
  const earned = new Set(achievementsSnap.docs.map(d => d.id));
  const batch = db.batch();

  const grant = (id: string) => {
    if (!earned.has(id)) batch.set(userRef.collection('achievements').doc(id), { achievementId: id, earnedAt: admin.firestore.Timestamp.now() });
  };

  if (user.currentStreak >= 7) grant('first_flame');
  if (user.currentStreak >= 30) grant('month_of_faith');
  if (!groupsSnap.empty) grant('better_together');

  // bookProgress checks
  const genesisProgress = await userRef.collection('bookProgress').doc('GEN').get();
  if (genesisProgress.exists && (genesisProgress.data()?.chapters || []).length >= 50) grant('in_the_beginning');

  await batch.commit();
}
```

```typescript
// functions/src/index.ts
import * as admin from 'firebase-admin';
admin.initializeApp();
export { onReadingComplete, dailyStreakCheck } from './streak';
export { onPlanComplete, xpStorePurchase } from './store';
```

**Steps:**
- [ ] Check if `functions/` directory already exists; if not, run `firebase init functions` from the project root (select TypeScript, do not overwrite existing files) or create manually with `functions/package.json`, `functions/tsconfig.json`
- [ ] Install dependencies: `cd functions && npm install firebase-admin firebase-functions` and `npm install --save-dev typescript @types/node firebase-functions-test`
- [ ] Write `functions/src/achievements.ts`
- [ ] Write `functions/src/streak.ts` (imports `checkAchievements` from `./achievements`)
- [ ] Write `functions/src/index.ts` (initializes admin, exports from streak and store)
- [ ] Run `cd functions && npm run build` (or `npx tsc --noEmit`) and fix any TypeScript errors
- [ ] `git add functions/src/streak.ts functions/src/achievements.ts functions/src/index.ts` and commit: `feat: add Cloud Functions for streak tracking, XP awards, and achievement checks`

---

## Task 11: Cloud Functions — XP store & plan completion

**Files:**
- Create: `functions/src/store.ts`

```typescript
// functions/src/store.ts
import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';
const db = admin.firestore();

export const onPlanComplete = onDocumentUpdated('userPlans/{userPlanId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.isComplete === after.isComplete || !after.isComplete) return;
  const userId = after.userId as string;
  await db.collection('users').doc(userId).update({
    xpTotal: admin.firestore.FieldValue.increment(500),
    xpBalance: admin.firestore.FieldValue.increment(500),
  });
});

export const xpStorePurchase = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) throw new Error('Unauthenticated');
  const { itemId } = request.data as { itemId: string };
  const itemCosts: Record<string, number> = {
    freeze_1: 200, outfit_basic_1: 500, outfit_basic_2: 500, outfit_basic_3: 500,
    outfit_rare_1: 1000, outfit_rare_2: 1000, outfit_rare_3: 1000,
    outfit_legendary_1: 2000, outfit_legendary_2: 2000,
  };
  const cost = itemCosts[itemId];
  if (!cost) throw new Error('Unknown item');
  const userRef = db.collection('users').doc(userId);
  await db.runTransaction(async (tx) => {
    const user = (await tx.get(userRef)).data() || {};
    if ((user.xpBalance || 0) < cost) throw new Error('Insufficient XP');
    tx.update(userRef, { xpBalance: admin.firestore.FieldValue.increment(-cost) });
    if (itemId === 'freeze_1') tx.update(userRef, { streakFreezes: admin.firestore.FieldValue.increment(1) });
    else tx.update(userRef, { activeOutfitId: itemId });
  });
  return { success: true };
});
```

**Steps:**
- [ ] Write `functions/src/store.ts` with `onPlanComplete` (+500 XP on plan completion) and `xpStorePurchase` callable (validates balance, deducts XP, grants freeze or outfit atomically)
- [ ] Verify `functions/src/index.ts` already exports `onPlanComplete` and `xpStorePurchase` from `./store` (added in Task 10)
- [ ] Run `cd functions && npm run build` (or `npx tsc --noEmit`) and fix any TypeScript errors
- [ ] Optionally test `xpStorePurchase` logic with `firebase-functions-test`: mock auth context with uid, mock Firestore, verify XP deduction and item grant
- [ ] Run full Flutter test suite one final time: `flutter test` — confirm all tests pass
- [ ] `git add functions/src/store.ts` and commit: `feat: add Cloud Functions for XP store purchases and plan completion rewards`
