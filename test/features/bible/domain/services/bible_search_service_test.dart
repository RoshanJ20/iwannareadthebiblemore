import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/models/bible_book.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/models/bible_chapter.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/models/bible_verse.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/repositories/bible_repository.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/services/bible_search_service.dart';

class MockBibleRepository extends Mock implements BibleRepository {}

void main() {
  late MockBibleRepository mockRepo;
  late BibleSearchService service;

  setUp(() {
    mockRepo = MockBibleRepository();
    service = BibleSearchService(mockRepo);
  });

  test('returns empty list for short query', () async {
    final results = await service.search('ab');
    expect(results, isEmpty);
  });

  test('finds verse containing query', () async {
    const books = [BibleBook(id: 'GEN', name: 'Genesis', chapterCount: 50)];
    const chapter = BibleChapter(number: 1, verses: [
      BibleVerse(number: 1, text: 'In the beginning God created the heaven and the earth.'),
      BibleVerse(number: 3, text: 'And God said, Let there be light: and there was light.'),
    ]);
    when(() => mockRepo.getBooks()).thenReturn(books);
    when(() => mockRepo.getChapter('GEN', 1)).thenAnswer((_) async => chapter);

    final results = await service.search('light');
    expect(results.length, 1);
    expect(results.first.verse.number, 3);
    expect(results.first.book.id, 'GEN');
  });
}
