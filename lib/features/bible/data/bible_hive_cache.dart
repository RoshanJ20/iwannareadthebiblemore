import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/bible_chapter.dart';
import '../domain/models/bible_verse.dart';

class BibleHiveCache {
  static const _boxName = 'bible_cache';

  Future<Box> _openBox() => Hive.openBox(_boxName);

  Future<BibleChapter?> getChapter(String key) async {
    final box = await _openBox();
    final raw = box.get(key);
    if (raw == null) return null;
    final verses = (raw['verses'] as List)
        .map((v) => BibleVerse(number: v['n'] as int, text: v['t'] as String))
        .toList();
    return BibleChapter(number: raw['num'] as int, verses: verses);
  }

  Future<void> putChapter(String key, BibleChapter chapter) async {
    final box = await _openBox();
    await box.put(key, {
      'num': chapter.number,
      'verses': chapter.verses.map((v) => {'n': v.number, 't': v.text}).toList(),
    });
  }
}
