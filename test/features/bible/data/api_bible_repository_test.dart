import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:iwannareadthebiblemore/features/bible/data/api_bible_repository.dart';
import 'package:iwannareadthebiblemore/features/bible/data/bible_hive_cache.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/models/bible_chapter.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockBibleHiveCache extends Mock implements BibleHiveCache {}

void main() {
  late MockHttpClient mockClient;
  late MockBibleHiveCache mockCache;
  late ApiBibleRepository repo;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(const BibleChapter(number: 0, verses: []));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockCache = MockBibleHiveCache();
    repo = ApiBibleRepository(client: mockClient, cache: mockCache);
  });

  test('returns cached chapter without HTTP call', () async {
    const cached = BibleChapter(number: 1, verses: []);
    when(() => mockCache.getChapter(any())).thenAnswer((_) async => cached);

    final result = await repo.getChapter('GEN', 1);
    expect(result, cached);
    verifyNever(() => mockClient.get(any(), headers: any(named: 'headers')));
  });

  test('fetches and parses chapter from API on cache miss', () async {
    when(() => mockCache.getChapter(any())).thenAnswer((_) async => null);
    when(() => mockCache.putChapter(any(), any())).thenAnswer((_) async {});

    const responseBody = '''
    {
      "data": {
        "content": [
          {"type": "verse", "number": "1", "items": [{"text": "In the beginning"}]},
          {"type": "verse", "number": "2", "items": [{"text": "The earth was formless"}]}
        ]
      }
    }
    ''';
    when(() => mockClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(responseBody, 200));

    final result = await repo.getChapter('GEN', 1);
    expect(result.verses.length, 2);
    expect(result.verses.first.text, 'In the beginning');
  });
}
