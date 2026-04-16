# Onboarding & Polish — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement first-run onboarding (5-screen flow), full profile with stats/heatmap/friends/settings, and account management (export notes, delete account). Polish all screens with proper loading, empty, and error states.

**Architecture:** Onboarding state tracked in Firestore (onboardingComplete field). App router redirects unauthenticated+incomplete-onboarding users to /onboarding. Profile is a read-heavy screen pulling from multiple Firestore streams. Friends use a bidirectional request model in Firestore user docs. All polish (shimmer, empty states, error states) applied in final polish task.

**Tech Stack:** Flutter/Dart, Riverpod, Firestore, go_router, share_plus, package_info_plus, shimmer, flutter_timezone

---

## Task 1: Onboarding routing & state

**Files:**
- Create: `lib/features/onboarding/domain/onboarding_state.dart`
- Create: `lib/features/onboarding/onboarding_providers.dart`
- Modify: `lib/core/navigation/app_router.dart` — add onboarding redirect guard
- Test: `test/features/onboarding/onboarding_providers_test.dart`

```dart
// onboarding_state.dart
enum OnboardingStep { meetLamb, dailyGoal, pickPlan, findFriends, setReminder }

// onboarding_providers.dart
final onboardingCompleteProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return Stream.value(false);
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
      .map((doc) => (doc.data()?['onboardingComplete'] as bool?) ?? false);
});
```

App router redirect: if authenticated AND onboardingComplete == false → redirect to /onboarding. Add to existing auth guard logic.

- [ ] Create `lib/features/onboarding/` directory structure (`domain/`, `presentation/screens/`)
- [ ] Create `lib/features/onboarding/domain/onboarding_state.dart` with the `OnboardingStep` enum
- [ ] Create `lib/features/onboarding/onboarding_providers.dart` with `onboardingCompleteProvider` as a `StreamProvider<bool>` that watches the user's Firestore doc for the `onboardingComplete` field, defaulting to `false` when missing
- [ ] Modify `lib/core/navigation/app_router.dart`: in the existing redirect callback, after the auth check, add a check — if the user is authenticated and `onboardingCompleteProvider` is `false`, redirect to `/onboarding`; add the `/onboarding` route pointing to `OnboardingScreen`
- [ ] Write `test/features/onboarding/onboarding_providers_test.dart`: use `fake_cloud_firestore` and `mocktail`; test that provider emits `false` when the `onboardingComplete` field is absent from the user doc, and `true` when it is set to `true`
- [ ] Run `flutter test test/features/onboarding/onboarding_providers_test.dart`
- [ ] Commit: `feat(onboarding): add onboarding state provider and router redirect guard`

---

## Task 2: Meet the Lamb screen

**Files:**
- Create: `lib/features/onboarding/presentation/screens/onboarding_screen.dart` (container with PageView)
- Create: `lib/features/onboarding/presentation/screens/meet_lamb_screen.dart`

```dart
// onboarding_screen.dart — manages PageView and step progression
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  void _next() {
    if (_page < 4) { setState(() => _page++); _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }
  }
  void _back() {
    if (_page > 0) { setState(() => _page--); _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(controller: _controller, physics: const NeverScrollableScrollPhysics(), children: [
        MeetLambScreen(onNext: _next),
        DailyGoalScreen(onNext: _next, onBack: _back),
        PickPlanScreen(onNext: _next, onBack: _back),
        FindFriendsScreen(onNext: _next, onBack: _back),
        SetReminderScreen(onBack: _back), // last screen handles navigation to home
      ]),
    );
  }
}

// meet_lamb_screen.dart
class MeetLambScreen extends StatelessWidget {
  final VoidCallback onNext;
  const MeetLambScreen({super.key, required this.onNext});
  @override Widget build(BuildContext context) {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Spacer(),
      Container(width: 200, height: 200, decoration: const BoxDecoration(color: Color(0xFFF5F0E8), shape: BoxShape.circle), child: const Icon(Icons.pets, size: 100, color: Color(0xFFBCA882))),
      const SizedBox(height: 32),
      Text('Meet Lamb', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Text('Your reading companion. Lamb celebrates with you when you read, worries when you don\'t, and cries when you break your streak.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 8),
      Text('Read. Together. Every day.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
      const Spacer(),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () async { await HapticsService.heavy(); onNext(); },
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: const Text('Get Started', style: TextStyle(fontSize: 18)),
      )),
    ])));
  }
}
```

- [ ] Create `lib/features/onboarding/presentation/screens/onboarding_screen.dart` with the `OnboardingScreen` `StatefulWidget` that owns a `PageController` and exposes `_next()` / `_back()` helpers; the `PageView` uses `NeverScrollableScrollPhysics` and hosts all 5 step screens in order
- [ ] Create `lib/features/onboarding/presentation/screens/meet_lamb_screen.dart` with `MeetLambScreen`: circular lamb placeholder, headline "Meet Lamb", body copy, italic tagline "Read. Together. Every day.", and a full-width "Get Started" `ElevatedButton` that calls `HapticsService.heavy()` then `onNext`
- [ ] Write `test/features/onboarding/meet_lamb_screen_test.dart`: pump `MeetLambScreen` with a mock `onNext` callback; verify the tagline text is present; verify tapping "Get Started" calls `onNext`
- [ ] Run `flutter test test/features/onboarding/meet_lamb_screen_test.dart`
- [ ] Commit: `feat(onboarding): add OnboardingScreen PageView container and MeetLamb step`

---

## Task 3: Daily goal screen

**Files:**
- Create: `lib/features/onboarding/presentation/screens/daily_goal_screen.dart`

```dart
class DailyGoalScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext, onBack;
  const DailyGoalScreen({super.key, required this.onNext, required this.onBack});
  @override ConsumerState<DailyGoalScreen> createState() => _DailyGoalScreenState();
}
class _DailyGoalScreenState extends ConsumerState<DailyGoalScreen> {
  int _selectedMinutes = 10;
  final _options = [5, 10, 15, 20];

  @override Widget build(BuildContext context) {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
      Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)),
      const Spacer(),
      Text('Set your daily goal', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('How many minutes per day would you like to read?', textAlign: TextAlign.center),
      const SizedBox(height: 32),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _options.map((m) => GestureDetector(
        onTap: () { setState(() => _selectedMinutes = m); HapticsService.light(); },
        child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: _selectedMinutes == m ? AppColors.primary : Colors.transparent, border: Border.all(color: _selectedMinutes == m ? AppColors.primary : Colors.grey, width: 2)),
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('$m', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedMinutes == m ? Colors.white : null)), Text('min', style: TextStyle(fontSize: 10, color: _selectedMinutes == m ? Colors.white70 : Colors.grey))]))),
      )).toList()),
      const Spacer(),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () async {
          final user = ref.read(authNotifierProvider).valueOrNull;
          if (user == null) return;
          // Auto-detect timezone
          String timezone = DateTime.now().timeZoneName;
          try {
            // Try flutter_timezone for IANA format
            timezone = await FlutterTimezone.getLocalTimezone();
          } catch (_) {}
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'dailyGoalMinutes': _selectedMinutes,
            'timezone': timezone,
          }, SetOptions(merge: true));
          widget.onNext();
        },
        child: const Text('Continue'),
      )),
    ])));
  }
}
```

- [ ] Add `flutter_timezone: ^1.0.8` to `pubspec.yaml` under `dependencies` if not already present; run `flutter pub get`
- [ ] Create `lib/features/onboarding/presentation/screens/daily_goal_screen.dart` with the `DailyGoalScreen` `ConsumerStatefulWidget`: back button, headline, 4 animated circular minute-option tiles (5 / 10 / 15 / 20, defaulting to 10), and a "Continue" button
- [ ] In the "Continue" button handler: read the current user from `authNotifierProvider`; detect the IANA timezone via `FlutterTimezone.getLocalTimezone()` with a fallback to `DateTime.now().timeZoneName`; save `dailyGoalMinutes` and `timezone` to the user's Firestore doc with `merge: true`; then call `onNext()`
- [ ] Write `test/features/onboarding/daily_goal_screen_test.dart`: pump `DailyGoalScreen` with mocked `onNext`/`onBack`; verify 4 minute-option tiles render; tap the "20 min" tile and verify it becomes selected; mock Firestore write and verify "Continue" triggers `onNext`
- [ ] Run `flutter test test/features/onboarding/daily_goal_screen_test.dart`
- [ ] Commit: `feat(onboarding): add DailyGoal step with timezone detection and Firestore save`

---

## Task 4: Pick first plan screen (onboarding)

**Files:**
- Create: `lib/features/onboarding/presentation/screens/pick_plan_screen.dart`

Shows a horizontal scrollable list of the 5 pre-built plans from `/plans`. User can tap to select. "Skip for now" option. On continue: creates a solo `userPlan` for the selected plan.

```dart
class PickPlanScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext, onBack;
  const PickPlanScreen({super.key, required this.onNext, required this.onBack});
  @override ConsumerState<PickPlanScreen> createState() => _PickPlanScreenState();
}
class _PickPlanScreenState extends ConsumerState<PickPlanScreen> {
  String? _selectedPlanId;
  @override Widget build(BuildContext context) {
    final plansAsync = ref.watch(planLibraryProvider);
    return SafeArea(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
      Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)),
      Text('Pick your first plan', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('You can change or add plans anytime.', textAlign: TextAlign.center),
      const SizedBox(height: 16),
      plansAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text('Could not load plans'),
        data: (plans) => SizedBox(height: 180, child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: plans.length,
          itemBuilder: (context, i) {
            final p = plans[i];
            final selected = _selectedPlanId == p.id;
            return GestureDetector(
              onTap: () { setState(() => _selectedPlanId = p.id); HapticsService.light(); },
              child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 130, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300, width: selected ? 2 : 1), color: selected ? AppColors.primary.withOpacity(0.1) : null),
                child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(p.coverEmoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(p.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
                  Text('${p.totalDays} days', style: Theme.of(context).textTheme.bodySmall),
                ]))),
            );
          },
        )),
      ),
      const Spacer(),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _selectedPlanId == null ? null : () async {
          await ref.read(planRepositoryProvider).startPlan(planId: _selectedPlanId!);
          widget.onNext();
        },
        child: const Text('Start Plan'),
      )),
      TextButton(onPressed: widget.onNext, child: const Text('Skip for now')),
    ])));
  }
}
```

- [ ] Create `lib/features/onboarding/presentation/screens/pick_plan_screen.dart` with `PickPlanScreen` as a `ConsumerStatefulWidget`; watch `planLibraryProvider` for the list of pre-built plans
- [ ] Render plans in a horizontal `ListView.builder` inside a fixed-height `SizedBox(height: 180)`; each card is an `AnimatedContainer` (130 px wide) showing `coverEmoji`, `name`, and `totalDays`; tapping a card sets `_selectedPlanId` and calls `HapticsService.light()`
- [ ] The "Start Plan" `ElevatedButton` is disabled (`onPressed: null`) until a plan is selected; when tapped it calls `planRepositoryProvider.startPlan(planId: _selectedPlanId!)` then `onNext()`
- [ ] Add a "Skip for now" `TextButton` below the primary button that calls `onNext()` directly
- [ ] Write `test/features/onboarding/pick_plan_screen_test.dart`: mock `planLibraryProvider` with 3 stub plans; verify plan cards render; tap first card and verify "Start Plan" button becomes enabled; verify "Skip for now" calls `onNext`
- [ ] Run `flutter test test/features/onboarding/pick_plan_screen_test.dart`
- [ ] Commit: `feat(onboarding): add PickPlan step with horizontal plan carousel`

---

## Task 5: Find friends screen (onboarding)

**Files:**
- Create: `lib/features/onboarding/presentation/screens/find_friends_screen.dart`

```dart
class FindFriendsScreen extends ConsumerWidget {
  final VoidCallback onNext, onBack;
  const FindFriendsScreen({super.key, required this.onNext, required this.onBack});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
      Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack)),
      const Spacer(),
      const Icon(Icons.people_outline, size: 80, color: AppColors.primary),
      const SizedBox(height: 16),
      Text('Invite friends', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Bible reading is better together. Share an invite link to get friends on the app.', textAlign: TextAlign.center),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        icon: const Icon(Icons.share),
        label: const Text('Share Invite Link'),
        onPressed: () async {
          final user = ref.read(authNotifierProvider).valueOrNull;
          if (user == null) return;
          await HapticsService.medium();
          await Share.share('Join me on iwannareadthebiblemore — a daily Bible reading app! Download and use my invite link: iwannaread://invite?ref=${user.uid}');
        },
      )),
      const Spacer(),
      TextButton(onPressed: onNext, child: const Text('Skip for now')),
    ])));
  }
}
```

- [ ] Create `lib/features/onboarding/presentation/screens/find_friends_screen.dart` with `FindFriendsScreen` as a `ConsumerWidget`
- [ ] Render the people icon, "Invite friends" headline, body copy, and a full-width `ElevatedButton.icon` labeled "Share Invite Link"
- [ ] In the share button handler: read the current user uid from `authNotifierProvider`; call `HapticsService.medium()`; call `Share.share(...)` with the invite deep link `iwannaread://invite?ref=<uid>`
- [ ] Add a "Skip for now" `TextButton` that calls `onNext()` directly
- [ ] Write `test/features/onboarding/find_friends_screen_test.dart`: mock `authNotifierProvider` to return a user with a known uid; verify "Share Invite Link" button is present; verify tapping it calls `Share.share` with a string containing the user's uid; verify "Skip for now" calls `onNext`
- [ ] Run `flutter test test/features/onboarding/find_friends_screen_test.dart`
- [ ] Commit: `feat(onboarding): add FindFriends step with invite link sharing`

---

## Task 6: Set reminder screen (completes onboarding)

**Files:**
- Create: `lib/features/onboarding/presentation/screens/set_reminder_screen.dart`

```dart
class SetReminderScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const SetReminderScreen({super.key, required this.onBack});
  @override ConsumerState<SetReminderScreen> createState() => _SetReminderScreenState();
}
class _SetReminderScreenState extends ConsumerState<SetReminderScreen> {
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _loading = false;

  @override Widget build(BuildContext context) {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
      Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)),
      const Spacer(),
      const Icon(Icons.notifications_outlined, size: 80, color: AppColors.primary),
      Text('Set a reminder', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('We\'ll remind you to read at this time each day.', textAlign: TextAlign.center),
      const SizedBox(height: 32),
      GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(context: context, initialTime: _time);
          if (picked != null) setState(() => _time = picked);
        },
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
          child: Text(_time.format(context), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary))),
      ),
      const Spacer(),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _loading ? null : () async {
          setState(() => _loading = true);
          final user = ref.read(authNotifierProvider).valueOrNull;
          if (user == null) return;
          final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
          // Save to Firestore + schedule local notification + mark onboarding complete
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'reminderTime': timeStr, 'onboardingComplete': true, 'defaultTranslation': 'kjv'}, SetOptions(merge: true));
          // Schedule local notification (LocalNotificationService from Plan 5)
          // await LocalNotificationService.instance.scheduleReminder(_time);
          if (context.mounted) context.go('/');
        },
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: _loading ? const CircularProgressIndicator() : const Text('Let\'s Go!', style: TextStyle(fontSize: 18)),
      )),
    ])));
  }
}
```

- [ ] Create `lib/features/onboarding/presentation/screens/set_reminder_screen.dart` with `SetReminderScreen` as a `ConsumerStatefulWidget`; default time is 08:00
- [ ] Render the notifications icon, "Set a reminder" headline, body copy, and a tappable time display container that opens a `showTimePicker` dialog; update `_time` state when a new time is picked
- [ ] Format the selected `TimeOfDay` as a zero-padded `HH:mm` string (e.g. `"08:00"`) for storage
- [ ] In the "Let's Go!" button handler: set `_loading = true`; write `reminderTime`, `onboardingComplete: true`, and `defaultTranslation: 'kjv'` to Firestore with `merge: true`; add a commented-out call for `LocalNotificationService.instance.scheduleReminder(_time)` (wired in Plan 5); navigate to `/` via `context.go('/')`
- [ ] Write `test/features/onboarding/set_reminder_screen_test.dart`: verify "Let's Go!" button renders; mock Firestore; tap the button and verify Firestore receives `onboardingComplete: true` and a valid `reminderTime` string; verify navigation to `/` is triggered
- [ ] Run `flutter test test/features/onboarding/set_reminder_screen_test.dart`
- [ ] Commit: `feat(onboarding): add SetReminder step that marks onboarding complete and navigates home`

---

## Task 7: Full profile screen (replace placeholder)

**Files:**
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart`

Replace the existing placeholder with a full profile screen containing: avatar header, stats row, reading heatmap, achievements preview, and navigation tiles for Friends, Lamb Outfits, and Settings.

```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final statsAsync = ref.watch(userStatsProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), actions: [
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Header
        Center(child: Column(children: [
          CircleAvatar(radius: 40, backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null, child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null),
          const SizedBox(height: 8),
          Text(user.displayName ?? 'Anonymous', style: Theme.of(context).textTheme.titleLarge),
        ])),
        const SizedBox(height: 24),
        // Stats
        statsAsync.when(
          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
          data: (stats) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _StatItem(label: 'Total XP', value: '${stats.xpTotal}'),
            _StatItem(label: 'Streak', value: '${stats.currentStreak}'),
            _StatItem(label: 'Best', value: '${stats.longestStreak}'),
          ]),
        ),
        const SizedBox(height: 24),
        // Heatmap
        Text('Reading Activity', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ReadingHeatmap(userId: user.uid),
        const SizedBox(height: 24),
        // Achievements
        achievementsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (achievements) {
            final earned = achievements.where((a) => a.earnedAt != null).take(3).toList();
            return earned.isEmpty ? const SizedBox.shrink() : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text('Achievements', style: Theme.of(context).textTheme.titleSmall), const Spacer(), TextButton(onPressed: () => context.push('/achievements'), child: const Text('View all'))]),
              Row(children: earned.map((a) => Padding(padding: const EdgeInsets.only(right: 8), child: Text(a.emoji, style: const TextStyle(fontSize: 32)))).toList()),
            ]);
          },
        ),
        const SizedBox(height: 16),
        // Navigation tiles
        ListTile(leading: const Icon(Icons.people_outline), title: const Text('Friends'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/friends')),
        ListTile(leading: const Icon(Icons.pets), title: const Text('Lamb Outfits'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/xp-store')),
        ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings')),
      ]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});
  @override Widget build(BuildContext context) => Column(children: [Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), Text(label, style: Theme.of(context).textTheme.bodySmall)]);
}
```

- [ ] Open `lib/features/profile/presentation/screens/profile_screen.dart` and replace the placeholder widget body with the full `ProfileScreen` implementation above
- [ ] Add `_StatItem` as a private widget class in the same file
- [ ] Import `ReadingHeatmap` from `lib/features/profile/presentation/widgets/reading_heatmap.dart` (created in Task 8 — add the import now, the file will be created next)
- [ ] Verify that `userStatsProvider` and `achievementsProvider` exist from Plans 3 and 4; if they are named differently, use the correct provider names and add a `// TODO:` comment noting any discrepancy
- [ ] Add routes `/friends` and `/achievements` as stub routes to `app_router.dart` if they do not already exist (they may have been added in Plan 4)
- [ ] Write `test/features/profile/presentation/screens/profile_screen_test.dart`: mock `authNotifierProvider` with a user whose `displayName` is "Test User"; mock `userStatsProvider` with stub stats; verify "Test User" text renders and the three stat labels ("Total XP", "Streak", "Best") are present
- [ ] Run `flutter test test/features/profile/presentation/screens/profile_screen_test.dart`
- [ ] Commit: `feat(profile): replace placeholder with full profile screen (stats, heatmap, achievements, nav tiles)`

---

## Task 8: Reading heatmap widget

**Files:**
- Create: `lib/features/profile/presentation/widgets/reading_heatmap.dart`
- Test: `test/features/profile/presentation/widgets/reading_heatmap_test.dart`

```dart
class ReadingHeatmap extends ConsumerWidget {
  final String userId;
  const ReadingHeatmap({super.key, required this.userId});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_readingLogsProvider(userId));
    return logsAsync.when(
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (logs) {
        final readDates = logs.map((d) => d.split('T')[0]).toSet();
        final now = DateTime.now();
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return SizedBox(height: 80, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: _buildWeeks(readDates, yearAgo, now, context))));
      },
    );
  }

  List<Widget> _buildWeeks(Set<String> readDates, DateTime start, DateTime end, BuildContext context) {
    final weeks = <Widget>[];
    var current = start;
    while (current.isBefore(end)) {
      final days = <Widget>[];
      for (int d = 0; d < 7 && current.isBefore(end); d++) {
        final dateStr = '${current.year}-${current.month.toString().padLeft(2,'0')}-${current.day.toString().padLeft(2,'0')}';
        final read = readDates.contains(dateStr);
        days.add(Container(width: 10, height: 10, margin: const EdgeInsets.all(1), decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: read ? AppColors.primary : AppColors.primary.withOpacity(0.1))));
        current = current.add(const Duration(days: 1));
      }
      weeks.add(Column(children: days));
    }
    return weeks;
  }
}

final _readingLogsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final snap = await FirebaseFirestore.instance.collection('users').doc(userId).collection('readingLog').get();
  return snap.docs.map((d) => d.id).toList(); // doc IDs are dateStr (YYYY-MM-DD)
});
```

- [ ] Create `lib/features/profile/presentation/widgets/reading_heatmap.dart` with the `ReadingHeatmap` `ConsumerWidget` and the private `_readingLogsProvider` `FutureProvider.family`
- [ ] The `_readingLogsProvider` fetches the `readingLog` subcollection under the user's Firestore doc; document IDs are date strings in `YYYY-MM-DD` format
- [ ] In `_buildWeeks`: iterate day-by-day from `yearAgo` to `now`, grouping into columns of 7 days; each day is a 10x10 `Container` with `borderRadius: 2`; read days use `AppColors.primary`, unread days use `AppColors.primary.withOpacity(0.1)`
- [ ] Write `test/features/profile/presentation/widgets/reading_heatmap_test.dart`: use `fake_cloud_firestore`; seed the `readingLog` subcollection with 3 known dates; pump `ReadingHeatmap(userId: 'test-uid')`; verify the widget renders (no overflow errors); verify approximately 52 week-columns are present in the scroll view
- [ ] Run `flutter test test/features/profile/presentation/widgets/reading_heatmap_test.dart`
- [ ] Commit: `feat(profile): add ReadingHeatmap widget with year-view GitHub-style grid`

---

## Task 9: Settings screen

**Files:**
- Create: `lib/features/profile/presentation/screens/settings_screen.dart`
- Test: `test/features/profile/presentation/screens/settings_screen_test.dart`

Full settings screen with 4 sections (Notifications, Reading, Privacy, Account):

```dart
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        // Notifications section
        const _SectionHeader('Notifications'),
        ListTile(title: const Text('Daily Reminder'), subtitle: const Text('Set reminder time'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/settings/notifications')),
        // Reading section
        const _SectionHeader('Reading'),
        ListTile(title: const Text('Default Translation'), subtitle: const Text('KJV, WEB, or others'), trailing: const Icon(Icons.chevron_right), onTap: () => _showTranslationPicker(context, ref)),
        ListTile(title: const Text('Theme'), trailing: Switch(value: Theme.of(context).brightness == Brightness.dark, onChanged: (_) {})), // Theme toggle stub
        // Privacy section
        const _SectionHeader('Privacy'),
        SwitchListTile(title: const Text('Show streak to friends'), value: true, onChanged: (v) {}), // stub
        SwitchListTile(title: const Text('Allow nudges from group'), value: true, onChanged: (v) {}), // stub
        // Account section
        const _SectionHeader('Account'),
        ListTile(leading: const Icon(Icons.upload_outlined), title: const Text('Export Notes'), onTap: () => _exportNotes(context, ref)),
        ListTile(leading: const Icon(Icons.logout), title: const Text('Sign Out'), onTap: () => ref.read(authNotifierProvider.notifier).signOut()),
        ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('Delete Account', style: TextStyle(color: Colors.red)), onTap: () => _confirmDeleteAccount(context, ref)),
        ListTile(leading: const Icon(Icons.info_outline), title: const Text('Licenses'), onTap: () => showLicensePage(context: context)),
        const SizedBox(height: 32),
      ]),
    );
  }

  void _showTranslationPicker(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => SimpleDialog(title: const Text('Default Translation'), children: ['kjv', 'web'].map((t) => SimpleDialogOption(onPressed: () { Navigator.pop(context); /* save to Firestore */ }, child: Text(t.toUpperCase()))).toList()));
  }

  Future<void> _exportNotes(BuildContext context, WidgetRef ref) async { /* implemented in Task 10 */ }
  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) { /* implemented in Task 11 */ }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 4), child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)));
}
```

- [ ] Add `package_info_plus: ^8.0.0` to `pubspec.yaml` under `dependencies` if not already present; run `flutter pub get`
- [ ] Create `lib/features/profile/presentation/screens/settings_screen.dart` with `SettingsScreen` as a `ConsumerWidget` and the private `_SectionHeader` widget
- [ ] Implement the 4 sections: Notifications (Daily Reminder tile → `/settings/notifications`), Reading (Default Translation tile opens dialog, Theme switch stub), Privacy (two `SwitchListTile` stubs), Account (Export Notes, Sign Out, Delete Account, Licenses)
- [ ] In `_showTranslationPicker`: show a `SimpleDialog` with "KJV" and "WEB" options; on selection, dismiss the dialog and save `defaultTranslation` to the user's Firestore doc with `merge: true`
- [ ] Add routes `/settings` and `/settings/notifications` to `lib/core/navigation/app_router.dart`; `/settings/notifications` can be a stub screen for now
- [ ] Leave `_exportNotes` and `_confirmDeleteAccount` as stubs with comments referencing Tasks 10 and 11
- [ ] Write `test/features/profile/presentation/screens/settings_screen_test.dart`: pump `SettingsScreen`; verify all 4 section headers render ("Notifications", "Reading", "Privacy", "Account"); verify tapping "Sign Out" calls `authNotifierProvider.notifier.signOut()`
- [ ] Run `flutter test test/features/profile/presentation/screens/settings_screen_test.dart`
- [ ] Commit: `feat(profile): add Settings screen with 4 sections and stub handlers`

---

## Task 10: Export notes

**Files:**
- Create: `lib/features/profile/domain/services/export_notes_service.dart`
- Modify: `lib/features/profile/presentation/screens/settings_screen.dart` — wire `_exportNotes`

```dart
class ExportNotesService {
  static Future<void> exportNotes(String userId) async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(userId).collection('annotations').get();
    final buffer = StringBuffer();
    buffer.writeln('My Bible Notes — Exported from iwannareadthebiblemore');
    buffer.writeln('=' * 50);
    buffer.writeln();
    for (final doc in snap.docs) {
      final d = doc.data();
      final type = d['type'] as String? ?? 'note';
      final bookId = d['bookId'] as String? ?? '';
      final chapterId = d['chapterId'] as int? ?? 0;
      final verseNumber = d['verseNumber'] as int? ?? 0;
      final text = d['text'] as String? ?? '';
      final color = d['color'] as String?;
      if (type == 'note' && text.isNotEmpty) {
        buffer.writeln('$bookId $chapterId:$verseNumber');
        buffer.writeln(text);
        buffer.writeln('---');
      } else if (type == 'highlight' && color != null) {
        buffer.writeln('$bookId $chapterId:$verseNumber [Highlight: $color]');
        buffer.writeln('---');
      }
    }
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/my_bible_notes.txt').writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'My Bible Notes');
  }
}
```

- [ ] Add `path_provider: ^2.1.0` to `pubspec.yaml` under `dependencies` if not already present; run `flutter pub get`
- [ ] Create `lib/features/profile/domain/services/export_notes_service.dart` with the `ExportNotesService` class and its static `exportNotes(String userId)` method
- [ ] The method fetches all docs from the `annotations` subcollection; formats notes (`type == 'note'`) as `bookId chapterId:verseNumber\n<text>\n---` and highlights (`type == 'highlight'`) as `bookId chapterId:verseNumber [Highlight: color]\n---`; writes the result to a temp file; calls `Share.shareXFiles` with the file
- [ ] Modify `lib/features/profile/presentation/screens/settings_screen.dart`: replace the `_exportNotes` stub body with a call to `ExportNotesService.exportNotes(user.uid)` where `user` is read from `authNotifierProvider`; wrap in a try/catch that shows a `SnackBar` on error
- [ ] Write `test/features/profile/domain/services/export_notes_service_test.dart`: use `fake_cloud_firestore`; seed 2 note annotations and 1 highlight annotation; call `ExportNotesService.exportNotes('test-uid')`; mock `Share.shareXFiles` via mocktail; verify the shared file content contains the expected note text and highlight entry
- [ ] Run `flutter test test/features/profile/domain/services/export_notes_service_test.dart`
- [ ] Commit: `feat(profile): add ExportNotesService to export annotations as a shareable text file`

---

## Task 11: Delete account

**Files:**
- Create: `functions/src/account.ts` — `deleteAccount` Cloud Function
- Modify: `lib/features/profile/presentation/screens/settings_screen.dart` — wire `_confirmDeleteAccount`

```typescript
// functions/src/account.ts
import * as admin from 'firebase-admin';
import { onCall } from 'firebase-functions/v2/https';
const db = admin.firestore();

export const deleteAccount = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) throw new Error('Unauthenticated');
  // Delete Firestore user doc (subcollections handled by extension or client)
  await db.collection('users').doc(userId).delete();
  // Delete Firebase Auth user
  await admin.auth().deleteUser(userId);
  return { success: true };
});
```

Flutter confirmation dialog:
```dart
void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
  final ctrl = TextEditingController();
  showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('Delete Account'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('This permanently deletes your account and all data. Type DELETE to confirm.'),
      const SizedBox(height: 12),
      TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Type DELETE')),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () async {
          if (ctrl.text != 'DELETE') return;
          Navigator.pop(context);
          try {
            await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
            await ref.read(authNotifierProvider.notifier).signOut();
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
          }
        },
        child: const Text('Delete Forever', style: TextStyle(color: Colors.white)),
      ),
    ],
  ));
}
```

- [ ] Create `functions/src/account.ts` with the `deleteAccount` `onCall` Cloud Function; it reads `request.auth?.uid`, throws if unauthenticated, deletes the Firestore user doc, deletes the Firebase Auth user, and returns `{ success: true }`
- [ ] Export `deleteAccount` from `functions/src/index.ts` alongside the existing function exports
- [ ] Modify `lib/features/profile/presentation/screens/settings_screen.dart`: replace the `_confirmDeleteAccount` stub with the full `AlertDialog` implementation; it renders a `TextField` requiring the exact text "DELETE"; "Cancel" dismisses; "Delete Forever" (red) only proceeds if the text matches, calls the `deleteAccount` Cloud Function, then calls `signOut()`
- [ ] Add `firebase_functions` import to `settings_screen.dart` if not already present (it should have been added in Plan 4)
- [ ] Write `test/features/profile/presentation/screens/delete_account_test.dart`: pump `SettingsScreen`; tap "Delete Account"; verify the dialog appears; enter text other than "DELETE" and tap "Delete Forever" — verify the Cloud Function is NOT called; enter "DELETE" and tap — verify the Cloud Function IS called and `signOut` is called
- [ ] Run `flutter test test/features/profile/presentation/screens/delete_account_test.dart`
- [ ] Commit: `feat(profile): add delete account Cloud Function and confirmation dialog with DELETE guard`

---

## Task 12: Polish pass — loading/empty/error states + shimmer

**Files:**
- Modify: `pubspec.yaml` — add `shimmer: ^3.0.0`
- Create: `lib/core/design_system/shimmer_loading.dart`
- Create: `lib/core/design_system/empty_state.dart`
- Create: `lib/core/design_system/error_state.dart`
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart` — shimmer stats
- Modify: `lib/features/groups/presentation/screens/groups_screen.dart` — shimmer + empty state
- Modify: `lib/features/plans/presentation/screens/plans_screen.dart` — shimmer cards
- Modify: `lib/features/bible/presentation/screens/bible_screen.dart` — shimmer book list

```dart
// shimmer_loading.dart
class ShimmerLoading extends StatelessWidget {
  final double width, height;
  final double borderRadius;
  const ShimmerLoading({super.key, required this.width, required this.height, this.borderRadius = 8});
  @override Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(width: width, height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(borderRadius))),
    );
  }
}

// empty_state.dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.action});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 64, color: Colors.grey),
    const SizedBox(height: 16),
    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
    const SizedBox(height: 8),
    Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
    if (action != null) ...[const SizedBox(height: 16), action!],
  ])));
}

// error_state.dart
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 64, color: Colors.red),
    const SizedBox(height: 16),
    Text(message, textAlign: TextAlign.center),
    if (onRetry != null) ...[const SizedBox(height: 16), ElevatedButton(onPressed: onRetry, child: const Text('Retry'))],
  ])));
}
```

Shimmer replacements per screen:
- **ProfileScreen stats row** — loading state: `Row` of 3 `ShimmerLoading(width: 80, height: 40)` widgets
- **GroupsScreen** — loading state: `ListView` of 4 `ShimmerLoading(width: double.infinity, height: 72)` tiles; empty state: `EmptyState(icon: Icons.group_outlined, title: 'No groups yet', subtitle: 'Create or join a group to read with friends', action: ElevatedButton(...))`
- **PlansScreen** — loading state: `Row` of 3 `ShimmerLoading(width: 130, height: 180, borderRadius: 16)` cards
- **BibleScreen** — loading state: `ListView` of 6 `ShimmerLoading(width: double.infinity, height: 48)` list tiles

- [ ] Add `shimmer: ^3.0.0` to `pubspec.yaml`; run `flutter pub get`
- [ ] Create `lib/core/design_system/shimmer_loading.dart` with the `ShimmerLoading` widget; it adapts `baseColor` and `highlightColor` for dark/light theme using `Theme.of(context).brightness`
- [ ] Create `lib/core/design_system/empty_state.dart` with the `EmptyState` widget; `action` is optional
- [ ] Create `lib/core/design_system/error_state.dart` with the `ErrorState` widget; `onRetry` is optional
- [ ] Modify `lib/features/profile/presentation/screens/profile_screen.dart`: in the `statsAsync.when(loading: ...)` handler, replace `CircularProgressIndicator` with a `Row` of 3 `ShimmerLoading(width: 80, height: 40)` widgets; in the `error` handler, replace `SizedBox.shrink()` with `ErrorState(message: 'Could not load stats')`
- [ ] Modify `lib/features/groups/presentation/screens/groups_screen.dart`: replace loading state with a `ListView` of 4 shimmer tiles; add an empty-list check after the `data` state loads — if the list is empty, return `EmptyState(icon: Icons.group_outlined, title: 'No groups yet', subtitle: 'Create or join a group to read with friends', action: ElevatedButton(onPressed: () => context.push('/groups/create'), child: const Text('Create Group')))`; replace error state with `ErrorState(message: 'Could not load groups', onRetry: () => ref.refresh(groupsProvider))`
- [ ] Modify `lib/features/plans/presentation/screens/plans_screen.dart`: replace loading state with a horizontal `Row` (or `ListView`) of 3 shimmer cards sized 130x180 with `borderRadius: 16`; replace error state with `ErrorState`
- [ ] Modify `lib/features/bible/presentation/screens/bible_screen.dart`: replace loading state with a `ListView` of 6 shimmer list tiles; replace error state with `ErrorState`
- [ ] Write `test/core/design_system/shimmer_loading_test.dart`: pump `ShimmerLoading(width: 100, height: 40)` inside a `MaterialApp`; verify it renders without errors
- [ ] Write `test/core/design_system/empty_state_test.dart`: pump `EmptyState(icon: Icons.group, title: 'No groups', subtitle: 'Try creating one')`; verify title and subtitle text are present
- [ ] Write `test/core/design_system/error_state_test.dart`: pump `ErrorState(message: 'Something went wrong', onRetry: () {})`; verify error message and "Retry" button are present
- [ ] Run `flutter test test/core/design_system/`
- [ ] Run `flutter test` (full suite) to confirm no regressions
- [ ] Commit: `feat(polish): add ShimmerLoading, EmptyState, ErrorState and apply across all screens`
