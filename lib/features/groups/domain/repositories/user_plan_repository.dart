import '../entities/user_plan.dart';

abstract class UserPlanRepository {
  Stream<List<UserPlan>> watchUserPlans(String userId);
  Future<UserPlan> createUserPlan(UserPlan plan);
  Future<void> markTodayRead(String userPlanId);
  Future<void> deleteUserPlan(String userPlanId);
}
