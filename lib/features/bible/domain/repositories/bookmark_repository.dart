import '../entities/bookmark.dart';

abstract class BookmarkRepository {
  Stream<List<Bookmark>> watchBookmarks(String userId);
  Future<Bookmark> addBookmark(Bookmark bookmark);
  Future<void> removeBookmark(String userId, String bookmarkId);
  Future<bool> isBookmarked(String userId, String bookId, int chapterNumber, int verseNumber);
}
