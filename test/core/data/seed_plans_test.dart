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

  test('SeedService does not seed plans when collection already has docs',
      () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore
        .collection('plans')
        .add({'name': 'Existing', 'isCustom': false});
    await SeedService.seedPlansIfNeeded(fakeFirestore);
    final snap = await fakeFirestore.collection('plans').get();
    expect(snap.docs.length, 1);
  });

  test('Genesis plan has 10 readings', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await SeedService.seedPlansIfNeeded(fakeFirestore);
    final snap = await fakeFirestore
        .collection('plans')
        .where('name', isEqualTo: 'Start Here: Genesis 1-10')
        .get();
    expect(snap.docs.length, 1);
    final readings = snap.docs.first.data()['readings'] as List;
    expect(readings.length, 10);
  });

  test('Gospel of John plan has 21 readings', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await SeedService.seedPlansIfNeeded(fakeFirestore);
    final snap = await fakeFirestore
        .collection('plans')
        .where('name', isEqualTo: 'Gospel of John')
        .get();
    final readings = snap.docs.first.data()['readings'] as List;
    expect(readings.length, 21);
  });

  test('Proverbs plan has 31 readings', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await SeedService.seedPlansIfNeeded(fakeFirestore);
    final snap = await fakeFirestore
        .collection('plans')
        .where('name', isEqualTo: 'Proverbs 31-day')
        .get();
    final readings = snap.docs.first.data()['readings'] as List;
    expect(readings.length, 31);
  });
}
