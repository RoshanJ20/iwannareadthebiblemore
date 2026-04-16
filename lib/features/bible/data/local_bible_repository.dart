import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/models/bible_book.dart';
import '../domain/models/bible_chapter.dart';
import '../domain/models/bible_verse.dart';
import '../domain/repositories/bible_repository.dart';
import '../../../core/bible_content/bible_book_list.dart';

class LocalBibleRepository implements BibleRepository {
  final String _translation;
  const LocalBibleRepository(this._translation);

  @override
  List<BibleBook> getBooks() => BibleBookList.all;

  @override
  Future<BibleChapter> getChapter(String bookId, int chapterNumber) async {
    final bookFileName = bookId.toLowerCase();
    final jsonStr = await rootBundle.loadString('assets/bible/$_translation/$bookFileName.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final chapters = data['chapters'] as List;
    final chapterData = chapters.firstWhere((c) => c['chapter'] == chapterNumber);
    final verses = (chapterData['verses'] as List)
        .map((v) => BibleVerse(number: v['verse'] as int, text: v['text'] as String))
        .toList();
    return BibleChapter(number: chapterNumber, verses: verses);
  }
}
