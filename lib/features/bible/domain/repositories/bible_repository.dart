import '../entities/bible_verse.dart';

abstract class BibleRepository {
  Future<List<BibleVerse>> getChapter(
    String bookId,
    int chapterNumber,
    String translation,
  );

  Future<List<BibleVerse>> searchVerses(String query, String translation);
}
