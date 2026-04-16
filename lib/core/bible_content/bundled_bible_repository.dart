import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/bible/domain/entities/bible_verse.dart';
import 'bible_content_repository.dart';

class BundledBibleRepository implements BibleContentRepository {
  final Map<String, List<BibleVerse>> _cache = {};

  @override
  Future<List<BibleVerse>> getChapter(
    String bookId,
    int chapterNumber,
    String translation,
  ) async {
    final cacheKey = '${translation}_${bookId}_$chapterNumber';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final allVerses = await _loadBook(bookId, translation);
    final chapter = allVerses.where((v) => v.chapterNumber == chapterNumber).toList();
    _cache[cacheKey] = chapter;
    return chapter;
  }

  @override
  Future<List<BibleVerse>> searchVerses(String query, String translation) async {
    if (query.trim().isEmpty) return [];

    final lower = query.toLowerCase();
    final results = <BibleVerse>[];

    for (final bookKey in _loadedBookIds(translation)) {
      final verses = await _loadBook(bookKey, translation);
      for (final verse in verses) {
        if (verse.text.toLowerCase().contains(lower)) {
          results.add(verse);
        }
      }
    }
    return results;
  }

  Future<List<BibleVerse>> searchAll(String query, String translation) async {
    if (query.trim().isEmpty) return [];

    final lower = query.toLowerCase();
    final results = <BibleVerse>[];
    const bundledBooks = ['GEN'];

    for (final bookId in bundledBooks) {
      try {
        final verses = await _loadBook(bookId, translation);
        for (final verse in verses) {
          if (verse.text.toLowerCase().contains(lower)) {
            results.add(verse);
          }
        }
      } catch (_) {
        // book not bundled
      }
    }
    return results;
  }

  List<String> _loadedBookIds(String translation) {
    return _cache.keys
        .where((k) => k.startsWith('${translation}_'))
        .map((k) {
          final parts = k.split('_');
          return parts.length >= 2 ? parts[1] : '';
        })
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<List<BibleVerse>> _loadBook(String bookId, String translation) async {
    final bookCacheKey = '${translation}_${bookId}_all';
    if (_cache.containsKey(bookCacheKey)) return _cache[bookCacheKey]!;

    final path = 'assets/bible/${translation.toLowerCase()}/${bookId.toUpperCase()}.json';
    try {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final chapters = json['chapters'] as List<dynamic>;
      final verses = <BibleVerse>[];

      for (final chap in chapters) {
        final chapMap = chap as Map<String, dynamic>;
        final chapNum = (chapMap['number'] as num).toInt();
        final verseList = chapMap['verses'] as List<dynamic>;
        for (final v in verseList) {
          final vMap = v as Map<String, dynamic>;
          verses.add(BibleVerse(
            bookId: bookId,
            chapterNumber: chapNum,
            verseNumber: (vMap['number'] as num).toInt(),
            text: vMap['text'] as String,
          ));
        }
      }

      _cache[bookCacheKey] = verses;

      for (final chap in chapters) {
        final chapMap = chap as Map<String, dynamic>;
        final chapNum = (chapMap['number'] as num).toInt();
        final chapterVerses = verses.where((v) => v.chapterNumber == chapNum).toList();
        _cache['${translation}_${bookId}_$chapNum'] = chapterVerses;
      }

      return verses;
    } on FlutterError {
      return [];
    } catch (_) {
      return [];
    }
  }
}
