import '../../features/bible/domain/entities/bible_verse.dart';
import 'api_bible_client.dart';
import 'bible_content_repository.dart';
import 'bundled_bible_repository.dart';
import 'hive_bible_cache.dart';

class CachedBibleRepository implements BibleContentRepository {
  CachedBibleRepository({
    required BundledBibleRepository bundled,
    required ApiBibleClient apiClient,
    required HiveBibleCache cache,
  })  : _bundled = bundled,
        _apiClient = apiClient,
        _cache = cache;

  final BundledBibleRepository _bundled;
  final ApiBibleClient _apiClient;
  final HiveBibleCache _cache;

  static const _bundledTranslations = {'kjv', 'web'};

  @override
  Future<List<BibleVerse>> getChapter(
    String bookId,
    int chapterNumber,
    String translation,
  ) async {
    if (_bundledTranslations.contains(translation.toLowerCase())) {
      return _bundled.getChapter(bookId, chapterNumber, translation);
    }

    final cached = await _cache.getChapter(bookId, chapterNumber, translation);
    if (cached != null) return cached;

    final verses =
        await _apiClient.fetchChapter(bookId, chapterNumber, translation);
    if (verses.isNotEmpty) {
      await _cache.saveChapter(bookId, chapterNumber, translation, verses);
    }
    return verses;
  }

  @override
  Future<List<BibleVerse>> searchVerses(
    String query,
    String translation,
  ) async {
    if (_bundledTranslations.contains(translation.toLowerCase())) {
      return _bundled.searchVerses(query, translation);
    }
    return _apiClient.searchVerses(query, translation);
  }
}
