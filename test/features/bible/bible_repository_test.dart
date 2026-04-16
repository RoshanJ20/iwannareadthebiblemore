import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/core/bible_content/bundled_bible_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledBibleRepository', () {
    late BundledBibleRepository repo;

    setUp(() {
      repo = BundledBibleRepository();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('loads GEN chapter 1 from bundled KJV asset', () async {
      final verses = await repo.getChapter('GEN', 1, 'kjv');
      expect(verses, isNotEmpty);
      expect(verses.first.bookId, equals('GEN'));
      expect(verses.first.chapterNumber, equals(1));
      expect(verses.first.verseNumber, equals(1));
      expect(
        verses.first.text,
        equals('In the beginning God created the heaven and the earth.'),
      );
      expect(verses.length, equals(31));
    });

    test('loads GEN chapter 2 from bundled KJV asset', () async {
      final verses = await repo.getChapter('GEN', 2, 'kjv');
      expect(verses.length, equals(7));
      expect(verses.first.chapterNumber, equals(2));
    });

    test('loads GEN chapter 1 from bundled WEB asset', () async {
      final verses = await repo.getChapter('GEN', 1, 'web');
      expect(verses, isNotEmpty);
      expect(verses.first.text,
          equals('In the beginning, God created the heavens and the earth.'));
    });

    test('returns empty list for missing book', () async {
      final verses = await repo.getChapter('PSA', 1, 'kjv');
      expect(verses, isEmpty);
    });

    test('returns empty list for unknown translation', () async {
      final verses = await repo.getChapter('GEN', 1, 'niv');
      expect(verses, isEmpty);
    });

    test('caches loaded book in memory', () async {
      final first = await repo.getChapter('GEN', 1, 'kjv');
      final second = await repo.getChapter('GEN', 1, 'kjv');
      expect(identical(first, second), isTrue);
    });

    test('searchAll finds verses containing query', () async {
      final results = await repo.searchAll('light', 'kjv');
      expect(results, isNotEmpty);
      for (final v in results) {
        expect(v.text.toLowerCase(), contains('light'));
      }
    });

    test('searchAll returns empty for blank query', () async {
      final results = await repo.searchAll('   ', 'kjv');
      expect(results, isEmpty);
    });
  });
}
