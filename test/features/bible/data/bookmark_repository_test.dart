import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iwannareadthebiblemore/features/bible/data/bookmark_repository.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_bookmarks_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await Hive.deleteBoxFromDisk('bookmarks');
  });

  test('add and retrieve bookmark', () async {
    final repo = BookmarkRepository();
    const bookmark = Bookmark(
      bookId: 'GEN',
      chapterNumber: 1,
      verseNumber: 1,
      verseText: 'In the beginning',
      reference: 'Genesis 1:1',
    );
    await repo.addBookmark(bookmark);
    final bookmarks = await repo.getBookmarks();
    expect(bookmarks.length, 1);
    expect(bookmarks.first.bookId, 'GEN');
  });

  test('remove bookmark', () async {
    final repo = BookmarkRepository();
    const bookmark = Bookmark(
      bookId: 'GEN',
      chapterNumber: 1,
      verseNumber: 1,
      verseText: 'In the beginning',
      reference: 'Genesis 1:1',
    );
    await repo.addBookmark(bookmark);
    await repo.removeBookmark(bookmark.key);
    expect(await repo.getBookmarks(), isEmpty);
  });

  test('isBookmarked returns correct value', () async {
    final repo = BookmarkRepository();
    const bookmark = Bookmark(
      bookId: 'JHN',
      chapterNumber: 3,
      verseNumber: 16,
      verseText: 'For God so loved the world',
      reference: 'John 3:16',
    );
    expect(await repo.isBookmarked(bookmark.key), isFalse);
    await repo.addBookmark(bookmark);
    expect(await repo.isBookmarked(bookmark.key), isTrue);
  });
}
