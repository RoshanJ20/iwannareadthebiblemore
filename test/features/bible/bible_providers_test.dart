import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:iwannareadthebiblemore/core/bible_content/bundled_bible_repository.dart';
import 'package:iwannareadthebiblemore/features/bible/data/repositories/firestore_annotation_repository.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/entities/bible_verse.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/repositories/annotation_repository.dart';
import 'package:iwannareadthebiblemore/features/bible/presentation/providers/bible_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bible Providers', () {
    late ProviderContainer container;
    late BundledBibleRepository mockBibleRepo;
    late FakeFirebaseFirestore fakeFirestore;
    late AnnotationRepository annotationRepo;

    setUp(() {
      mockBibleRepo = BundledBibleRepository();
      fakeFirestore = FakeFirebaseFirestore();
      annotationRepo = FirestoreAnnotationRepository(fakeFirestore);

      container = ProviderContainer(overrides: [
        bibleRepositoryProvider.overrideWithValue(mockBibleRepo),
        annotationRepositoryProvider.overrideWithValue(annotationRepo),
      ]);
    });

    tearDown(() => container.dispose());

    test('currentTranslationProvider defaults to kjv', () {
      expect(container.read(currentTranslationProvider), equals('kjv'));
    });

    test('currentTranslationProvider can be updated', () {
      container.read(currentTranslationProvider.notifier).state = 'web';
      expect(container.read(currentTranslationProvider), equals('web'));
    });

    test('bibleChapterProvider returns verses for GEN chapter 1', () async {
      final verses = await container.read(
        bibleChapterProvider((bookId: 'GEN', chapterNumber: 1)).future,
      );
      expect(verses, isA<List<BibleVerse>>());
      expect(verses, isNotEmpty);
      expect(verses.first.bookId, equals('GEN'));
      expect(verses.first.chapterNumber, equals(1));
    });

    test('bibleChapterProvider returns empty for missing book', () async {
      final verses = await container.read(
        bibleChapterProvider((bookId: 'PSA', chapterNumber: 1)).future,
      );
      expect(verses, isEmpty);
    });

    test('bibleChapterProvider uses current translation', () async {
      container.read(currentTranslationProvider.notifier).state = 'web';
      final verses = await container.read(
        bibleChapterProvider((bookId: 'GEN', chapterNumber: 1)).future,
      );
      expect(verses, isNotEmpty);
      expect(
        verses.first.text,
        contains('In the beginning'),
      );
    });

    test('chapterAnnotationsProvider streams empty list initially', () async {
      final stream = container.read(
        chapterAnnotationsProvider(
          (userId: 'user-1', bookId: 'GEN', chapterNumber: 1),
        ).stream,
      );
      final result = await stream.first;
      expect(result, isEmpty);
    });

    test('searchResultsProvider returns empty when query is blank', () async {
      container.read(searchQueryProvider.notifier).state = '';
      final results = await container.read(searchResultsProvider.future);
      expect(results, isEmpty);
    });

    test('searchResultsProvider returns results for valid query', () async {
      container.read(searchQueryProvider.notifier).state = 'beginning';
      final results = await container.read(searchResultsProvider.future);
      expect(results, isNotEmpty);
      expect(
        results.every((v) => v.text.toLowerCase().contains('beginning')),
        isTrue,
      );
    });
  });
}
