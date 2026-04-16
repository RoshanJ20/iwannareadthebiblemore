import '../../features/bible/domain/entities/bible_verse.dart';

class ApiBibleClient {
  // API.Bible base URL: https://api.scripture.api.bible/v1
  // Requires API key from environment variable BIBLE_API_KEY

  Future<List<BibleVerse>> fetchChapter(String bibleId, String chapterId) async {
    // TODO: implement with http package once API key is configured
    return [];
  }
}
