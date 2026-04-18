import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AnnotationType { highlight, note }

@immutable
class Annotation {
  const Annotation({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.chapterNumber,
    required this.verseNumber,
    required this.type,
    required this.color,
    this.text,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String bookId;
  final int chapterNumber;
  final int verseNumber;
  final AnnotationType type;
  final Color color;
  final String? text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'bookId': bookId,
        'chapterId': chapterNumber,
        'verseNumber': verseNumber,
        'type': type.name,
        'color': color.value,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Annotation.fromMap(String id, Map<String, dynamic> map) =>
      Annotation(
        id: id,
        userId: map['userId'] as String,
        bookId: map['bookId'] as String,
        chapterNumber: (map['chapterId'] as num).toInt(),
        verseNumber: (map['verseNumber'] as num).toInt(),
        type: AnnotationType.values.firstWhere((e) => e.name == map['type']),
        color: Color(map['color'] as int),
        text: map['text'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Annotation copyWith({
    String? id,
    String? userId,
    String? bookId,
    int? chapterNumber,
    int? verseNumber,
    AnnotationType? type,
    Color? color,
    String? text,
    DateTime? createdAt,
  }) =>
      Annotation(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        bookId: bookId ?? this.bookId,
        chapterNumber: chapterNumber ?? this.chapterNumber,
        verseNumber: verseNumber ?? this.verseNumber,
        type: type ?? this.type,
        color: color ?? this.color,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Annotation && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
