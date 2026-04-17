import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_bible_client.dart';
import 'bible_content_repository.dart';
import 'bundled_bible_repository.dart';
import 'cached_bible_repository.dart';
import 'hive_bible_cache.dart';

final bundledBibleRepositoryProvider = Provider<BundledBibleRepository>((ref) {
  return BundledBibleRepository();
});

final hiveBibleCacheProvider = Provider<HiveBibleCache>((ref) {
  return HiveBibleCache();
});

final apiBibleKeyProvider = StateProvider<String>((ref) {
  final box = Hive.box('settings');
  return (box.get('api_bible_key') as String?) ?? '';
});

final apiBibleClientProvider = Provider<ApiBibleClient>((ref) {
  final apiKey = ref.watch(apiBibleKeyProvider);
  return ApiBibleClient(apiKey: apiKey);
});

final bibleContentRepositoryProvider = Provider<BibleContentRepository>((ref) {
  return CachedBibleRepository(
    bundled: ref.watch(bundledBibleRepositoryProvider),
    apiClient: ref.watch(apiBibleClientProvider),
    cache: ref.watch(hiveBibleCacheProvider),
  );
});
