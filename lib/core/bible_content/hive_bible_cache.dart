import 'package:hive_flutter/hive_flutter.dart';

class HiveBibleCache {
  static const _boxName = 'bible_cache';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  String? get(String key) => _box?.get(key);

  Future<void> put(String key, String value) async {
    await _box?.put(key, value);
  }

  Future<void> delete(String key) async {
    await _box?.delete(key);
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}
