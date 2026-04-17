import 'package:flutter/foundation.dart';

@immutable
class BibleVerse {
  const BibleVerse({
    required this.bookId,
    required this.chapterNumber,
    required this.verseNumber,
    required this.text,
  });

  final String bookId;
  final int chapterNumber;
  final int verseNumber;
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleVerse &&
          other.bookId == bookId &&
          other.chapterNumber == chapterNumber &&
          other.verseNumber == verseNumber;

  @override
  int get hashCode => Object.hash(bookId, chapterNumber, verseNumber);
}
