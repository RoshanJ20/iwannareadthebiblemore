import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/bible/domain/entities/bible_verse.dart';

class HiveBibleCache {
  static const _boxName = 'bible_cache';
  static const _ttlDays = 30;

  Box<dynamic>? _box;

  Future<Box<dynamic>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  Future<void> init() async {
    await _getBox();
  }

  String _chapterKey(String bookId, int chapterNumber, String translation) =>
      '${translation.toLowerCase()}_${bookId}_$chapterNumber';

  Future<List<BibleVerse>?> getChapter(
    String bookId,
    int chapterNumber,
    String translation,
  ) async {
    final box = await _getBox();
    final key = _chapterKey(bookId, chapterNumber, translation);
    final raw = box.get(key) as String?;
    if (raw == null) return null;

    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(wrapper['t'] as int);
      if (DateTime.now().difference(savedAt).inDays >= _ttlDays) {
        await box.delete(key);
        return null;
      }

      final list = wrapper['v'] as List<dynamic>;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        return BibleVerse(
          bookId: m['b'] as String,
          chapterNumber: m['c'] as int,
          verseNumber: m['n'] as int,
          text: m['t'] as String,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveChapter(
    String bookId,
    int chapterNumber,
    String translation,
    List<BibleVerse> verses,
  ) async {
    final box = await _getBox();
    final key = _chapterKey(bookId, chapterNumber, translation);
    final wrapper = {
      't': DateTime.now().millisecondsSinceEpoch,
      'v': verses
          .map((v) => {
                'b': v.bookId,
                'c': v.chapterNumber,
                'n': v.verseNumber,
                't': v.text,
              })
          .toList(),
    };
    await box.put(key, jsonEncode(wrapper));
  }

  Future<String?> get(String key) async => (await _getBox()).get(key) as String?;

  Future<void> put(String key, String value) async {
    (await _getBox()).put(key, value);
  }

  Future<void> delete(String key) async {
    await (await _getBox()).delete(key);
  }

  Future<void> clear() async {
    await (await _getBox()).clear();
  }
}
