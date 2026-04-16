import '../models/bible_book.dart';
import '../models/bible_chapter.dart';

abstract class BibleRepository {
  List<BibleBook> getBooks();
  Future<BibleChapter> getChapter(String bookId, int chapterNumber);
}
