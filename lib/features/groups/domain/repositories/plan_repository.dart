import '../entities/reading_plan.dart';

abstract class PlanRepository {
  Future<List<ReadingPlan>> getOfficialPlans();
  Future<ReadingPlan?> getPlan(String planId);
}
