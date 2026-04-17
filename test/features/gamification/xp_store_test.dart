import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/gamification/domain/entities/xp_store_item.dart';
import 'package:iwannareadthebiblemore/features/gamification/presentation/providers/gamification_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('xpStoreItemsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('returns a non-empty catalog', () {
      final items = container.read(xpStoreItemsProvider);
      expect(items, isNotEmpty);
    });

    test('contains exactly one streak freeze item at 200 XP', () {
      final items = container.read(xpStoreItemsProvider);
      final freezes = items.where((i) => i.itemType == XpItemType.freeze).toList();
      expect(freezes.length, equals(1));
      expect(freezes.first.xpCost, equals(200));
    });

    test('contains 3 basic mascot outfits at 500 XP each', () {
      final items = container.read(xpStoreItemsProvider);
      final basic = items.where(
        (i) => i.itemType == XpItemType.mascotOutfit && i.rarity == XpItemRarity.basic,
      ).toList();
      expect(basic.length, equals(3));
      expect(basic.every((i) => i.xpCost == 500), isTrue);
    });

    test('contains 3 rare mascot outfits at 1000 XP each', () {
      final items = container.read(xpStoreItemsProvider);
      final rare = items.where(
        (i) => i.itemType == XpItemType.mascotOutfit && i.rarity == XpItemRarity.rare,
      ).toList();
      expect(rare.length, equals(3));
      expect(rare.every((i) => i.xpCost == 1000), isTrue);
    });

    test('contains 2 legendary mascot outfits at 2000 XP each', () {
      final items = container.read(xpStoreItemsProvider);
      final legendary = items.where(
        (i) => i.itemType == XpItemType.mascotOutfit && i.rarity == XpItemRarity.legendary,
      ).toList();
      expect(legendary.length, equals(2));
      expect(legendary.every((i) => i.xpCost == 2000), isTrue);
    });

    test('all items have non-empty id and name', () {
      final items = container.read(xpStoreItemsProvider);
      for (final item in items) {
        expect(item.id, isNotEmpty);
        expect(item.name, isNotEmpty);
        expect(item.xpCost, greaterThan(0));
      }
    });

    test('all item ids are unique', () {
      final items = container.read(xpStoreItemsProvider);
      final ids = items.map((i) => i.id).toSet();
      expect(ids.length, equals(items.length));
    });
  });
}
