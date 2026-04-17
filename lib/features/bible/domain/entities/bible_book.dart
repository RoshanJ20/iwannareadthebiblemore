import 'package:flutter/foundation.dart';

enum Testament { old, newTestament }

@immutable
class BibleBook {
  const BibleBook({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.testament,
    required this.totalChapters,
  });

  final String id;
  final String name;
  final String abbreviation;
  final Testament testament;
  final int totalChapters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BibleBook && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
