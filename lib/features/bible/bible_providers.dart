import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import 'domain/models/bible_book.dart';
import 'domain/models/bible_chapter.dart';
import 'domain/models/annotation.dart';
import 'domain/repositories/bible_repository.dart';
import 'domain/repositories/annotation_repository.dart';
import 'data/local_bible_repository.dart';
import 'data/api_bible_repository.dart';
import 'data/firestore_annotation_repository.dart';

final currentTranslationProvider = StateProvider<String>((ref) => 'kjv');

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  final translation = ref.watch(currentTranslationProvider);
  if (translation == 'kjv' || translation == 'web') {
    return LocalBibleRepository(translation);
  }
  return ApiBibleRepository();
});

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) throw StateError('No authenticated user');
  return FirestoreAnnotationRepository(FirebaseFirestore.instance, user.uid);
});

final bookListProvider = Provider<List<BibleBook>>((ref) {
  return ref.watch(bibleRepositoryProvider).getBooks();
});

final chapterProvider =
    FutureProvider.family<BibleChapter, ({String bookId, int chapterNumber})>(
  (ref, args) =>
      ref.watch(bibleRepositoryProvider).getChapter(args.bookId, args.chapterNumber),
);

final annotationsProvider =
    StreamProvider.family<List<Annotation>, ({String bookId, int chapterId})>(
  (ref, args) => ref
      .watch(annotationRepositoryProvider)
      .watchAnnotations(args.bookId, args.chapterId),
);
