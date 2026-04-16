import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bible_content_repository.dart';
import 'bundled_bible_repository.dart';
import 'api_bible_client.dart';
import 'hive_bible_cache.dart';

final bundledBibleRepositoryProvider = Provider<BundledBibleRepository>((ref) {
  return BundledBibleRepository();
});

final bibleContentRepositoryProvider = Provider<BibleContentRepository>((ref) {
  return ref.watch(bundledBibleRepositoryProvider);
});

final apiBibleClientProvider = Provider<ApiBibleClient>((ref) {
  return ApiBibleClient();
});

final hiveBibleCacheProvider = Provider<HiveBibleCache>((ref) {
  return HiveBibleCache();
});
