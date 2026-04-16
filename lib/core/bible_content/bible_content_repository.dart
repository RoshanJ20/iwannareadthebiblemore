import '../../features/bible/domain/entities/bible_verse.dart';

abstract class BibleContentRepository {
  Future<List<BibleVerse>> getChapter(
    String bookId,
    int chapterNumber,
    String translation,
  );

  Future<List<BibleVerse>> searchVerses(String query, String translation);
}
