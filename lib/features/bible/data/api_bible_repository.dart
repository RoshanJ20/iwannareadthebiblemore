import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/bible_book.dart';
import '../domain/models/bible_chapter.dart';
import '../domain/models/bible_verse.dart';
import '../domain/repositories/bible_repository.dart';
import '../../../core/bible_content/bible_book_list.dart';
import 'bible_hive_cache.dart';

const String _apiBibleKey = String.fromEnvironment('API_BIBLE_KEY', defaultValue: '');

class ApiBibleRepository implements BibleRepository {
  final http.Client _client;
  final BibleHiveCache _cache;

  ApiBibleRepository({http.Client? client, BibleHiveCache? cache})
      : _client = client ?? http.Client(),
        _cache = cache ?? BibleHiveCache();

  @override
  List<BibleBook> getBooks() => BibleBookList.all;

  @override
  Future<BibleChapter> getChapter(String bookId, int chapterNumber) async {
    final cacheKey = 'apibible_${bookId}_$chapterNumber';
    final cached = await _cache.getChapter(cacheKey);
    if (cached != null) return cached;

    const bibleId = 'de4e12af7f28f599-02';
    final chapterId = '$bookId.$chapterNumber';
    final uri = Uri.parse(
      'https://api.scripture.api.bible/v1/bibles/$bibleId/chapters/$chapterId'
      '?content-type=json&include-notes=false&include-titles=false'
      '&include-chapter-numbers=false&include-verse-numbers=true',
    );
    final response = await _client.get(uri, headers: {'api-key': _apiBibleKey});
    if (response.statusCode != 200) {
      throw Exception('API.Bible error: ${response.statusCode}');
    }
    final chapter = _parseResponse(
      json.decode(response.body) as Map<String, dynamic>,
      chapterNumber,
    );
    await _cache.putChapter(cacheKey, chapter);
    return chapter;
  }

  BibleChapter _parseResponse(Map<String, dynamic> body, int chapterNumber) {
    final data = body['data'] as Map<String, dynamic>;
    final content = data['content'] as List;
    final verses = <BibleVerse>[];
    for (final item in content) {
      if (item['type'] == 'verse') {
        final verseNum = int.parse(item['number'].toString());
        final text = (item['items'] as List).map((i) => i['text'] ?? '').join(' ');
        verses.add(BibleVerse(number: verseNum, text: text.trim()));
      }
    }
    return BibleChapter(number: chapterNumber, verses: verses);
  }
}
