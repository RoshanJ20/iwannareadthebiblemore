import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/groups/data/seed_plans.dart';

void main() {
  group('seedPlans', () {
    test('contains exactly 5 plans', () {
      expect(seedPlans.length, 5);
    });

    test('all plan ids are unique', () {
      final ids = seedPlans.map((p) => p.id).toSet();
      expect(ids.length, 5);
    });

    test('each plan has readings', () {
      for (final plan in seedPlans) {
        expect(plan.readings, isNotEmpty,
            reason: '${plan.name} has no readings');
      }
    });

    test('each reading list length matches totalDays', () {
      for (final plan in seedPlans) {
        expect(plan.readings.length, plan.totalDays,
            reason:
                '${plan.name}: readings.length=${plan.readings.length} != totalDays=${plan.totalDays}');
      }
    });

    test('Genesis Journey has 50 days and reads Genesis', () {
      final plan = seedPlans.firstWhere((p) => p.id == 'seed_genesis_journey');
      expect(plan.totalDays, 50);
      expect(plan.readings.every((r) => r.book == 'GEN'), isTrue);
    });

    test('Psalms of Praise has 30 days and reads Psalms', () {
      final plan = seedPlans.firstWhere((p) => p.id == 'seed_psalms_of_praise');
      expect(plan.totalDays, 30);
      expect(plan.readings.every((r) => r.book == 'PSA'), isTrue);
    });

    test('The Life of Jesus has 28 days and reads Matthew', () {
      final plan = seedPlans.firstWhere((p) => p.id == 'seed_life_of_jesus');
      expect(plan.totalDays, 28);
      expect(plan.readings.every((r) => r.book == 'MAT'), isTrue);
    });

    test('Proverbs for Life has 31 days and reads Proverbs', () {
      final plan =
          seedPlans.firstWhere((p) => p.id == 'seed_proverbs_for_life');
      expect(plan.totalDays, 31);
      expect(plan.readings.every((r) => r.book == 'PRO'), isTrue);
    });

    test('Sermon on the Mount has 7 days and reads Matthew 5-7', () {
      final plan =
          seedPlans.firstWhere((p) => p.id == 'seed_sermon_on_the_mount');
      expect(plan.totalDays, 7);
      expect(plan.readings.every((r) => r.book == 'MAT'), isTrue);
      final chapters = plan.readings.map((r) => r.chapter).toSet();
      expect(chapters.intersection({5, 6, 7}), isNotEmpty);
    });

    test('day numbers are sequential starting from 1', () {
      for (final plan in seedPlans) {
        for (var i = 0; i < plan.readings.length; i++) {
          expect(plan.readings[i].day, i + 1,
              reason:
                  '${plan.name} day ${i + 1} mismatch: got ${plan.readings[i].day}');
        }
      }
    });

    test('each plan has a non-empty coverEmoji', () {
      for (final plan in seedPlans) {
        expect(plan.coverEmoji, isNotEmpty,
            reason: '${plan.name} has empty coverEmoji');
      }
    });

    test('each plan has at least one tag', () {
      for (final plan in seedPlans) {
        expect(plan.tags, isNotEmpty,
            reason: '${plan.name} has no tags');
      }
    });

    test('no plan is marked as custom', () {
      expect(seedPlans.every((p) => !p.isCustom), isTrue);
    });
  });
}
