import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../features/groups/domain/entities/user_plan.dart';
import '../../../../features/groups/presentation/providers/groups_providers.dart';
import '../providers/onboarding_providers.dart';
import 'pages/find_friends_page.dart';
import 'pages/meet_the_lamb_page.dart';
import 'pages/pick_first_plan_page.dart';
import 'pages/set_daily_goal_page.dart';
import 'pages/set_reminder_page.dart';

class OnboardingShell extends ConsumerStatefulWidget {
  const OnboardingShell({super.key});

  @override
  ConsumerState<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends ConsumerState<OnboardingShell> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _completing = false;

  static const int _totalPages = 5;

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    if (_completing) return;
    setState(() => _completing = true);

    final data = ref.read(onboardingProvider);
    final uid = ref.read(authNotifierProvider).valueOrNull?.uid;

    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'dailyGoalMinutes': data.goalMinutes,
          'defaultTranslation': 'kjv',
          'reminderTime':
              '${data.reminderTime.hour.toString().padLeft(2, '0')}:${data.reminderTime.minute.toString().padLeft(2, '0')}',
          'timezone': data.timezone,
        }, SetOptions(merge: true));
      } catch (_) {
        // Non-fatal on web/demo — proceed without Firestore write
      }

      if (data.selectedPlanId != null) {
        try {
          final plan = ref
              .read(prebuiltPlansProvider)
              .where((p) => p.id == data.selectedPlanId)
              .firstOrNull;
          if (plan != null) {
            final userPlan = UserPlan(
              id: '',
              userId: uid,
              planId: data.selectedPlanId!,
              startDate: DateTime.now(),
              currentDay: 1,
              completedDays: const [],
              isComplete: false,
              todayChapter: plan.readings.isNotEmpty
                  ? '${plan.readings.first.book} ${plan.readings.first.chapter}'
                  : '',
              todayRead: false,
            );
            await ref
                .read(userPlanRepositoryProvider)
                .createUserPlan(userPlan);
          }
        } catch (_) {
          // Non-fatal on web/demo
        }
      }
    }

    final box = Hive.box('settings');
    await box.put('onboarding_complete', true);

    if (mounted) context.go(Routes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSkip = _currentPage == 2 || _currentPage == 3;
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _ProgressDots(current: _currentPage, total: _totalPages),
        centerTitle: true,
        actions: [
          if (showSkip)
            TextButton(
              key: const Key('skip_button'),
              onPressed: _skip,
              child: const Text(
                'Skip',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          MeetTheLambPage(onNext: _next),
          const SetDailyGoalPage(),
          const PickFirstPlanPage(),
          FindFriendsPage(onNext: _next),
          SetReminderPage(onComplete: _completeOnboarding),
        ],
      ),
      bottomNavigationBar: _currentPage == 0 || _currentPage == 3
          ? null
          : SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('next_button'),
                    onPressed: _completing ? null : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _completing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : Text(
                            isLastPage ? 'All done!' : 'Next',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isDone = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isActive || isDone)
                ? AppColors.primary
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
