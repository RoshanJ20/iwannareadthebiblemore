import 'package:hive_flutter/hive_flutter.dart';

class Bookmark {
  final String bookId;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final String reference;

  const Bookmark({
    required this.bookId,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
    required this.reference,
  });

  String get key => '${bookId}_${chapterNumber}_$verseNumber';

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'chapterNumber': chapterNumber,
        'verseNumber': verseNumber,
        'verseText': verseText,
        'reference': reference,
      };

  factory Bookmark.fromMap(Map<String, dynamic> m) => Bookmark(
        bookId: m['bookId'] as String,
        chapterNumber: m['chapterNumber'] as int,
        verseNumber: m['verseNumber'] as int,
        verseText: m['verseText'] as String,
        reference: m['reference'] as String,
      );
}

class BookmarkRepository {
  static const _boxName = 'bookmarks';

  Future<Box> _open() => Hive.openBox(_boxName);

  Future<void> addBookmark(Bookmark bookmark) async {
    final box = await _open();
    await box.put(bookmark.key, bookmark.toMap());
  }

  Future<void> removeBookmark(String key) async {
    final box = await _open();
    await box.delete(key);
  }

  Future<List<Bookmark>> getBookmarks() async {
    final box = await _open();
    return box.values
        .map((v) => Bookmark.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  Future<bool> isBookmarked(String key) async {
    final box = await _open();
    return box.containsKey(key);
  }
}
