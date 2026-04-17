import '../entities/user_plan.dart';

abstract class UserPlanRepository {
  Stream<List<UserPlan>> watchUserPlans(String userId);
  Future<UserPlan> createUserPlan(UserPlan plan);
  Future<void> markTodayRead(
    String userPlanId, {
    required String userId,
    required String todayChapter,
    required String planId,
    String translation,
  });
  Future<void> deleteUserPlan(String userPlanId);
}
