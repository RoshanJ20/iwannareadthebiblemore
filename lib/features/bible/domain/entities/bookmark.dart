import 'package:flutter/foundation.dart';

@immutable
class Bookmark {
  const Bookmark({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String bookId;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'bookId': bookId,
        'chapterNumber': chapterNumber,
        'verseNumber': verseNumber,
        'verseText': verseText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromMap(String id, Map<String, dynamic> map) => Bookmark(
        id: id,
        userId: map['userId'] as String,
        bookId: map['bookId'] as String,
        chapterNumber: (map['chapterNumber'] as num).toInt(),
        verseNumber: (map['verseNumber'] as num).toInt(),
        verseText: map['verseText'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Bookmark && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
