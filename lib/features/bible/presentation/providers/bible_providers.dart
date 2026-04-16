import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/bible_content/bible_content_providers.dart';
import '../../../../core/bible_content/bundled_bible_repository.dart';
import '../../data/repositories/firestore_annotation_repository.dart';
import '../../data/repositories/firestore_bookmark_repository.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/entities/bible_verse.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/annotation_repository.dart';

final bibleRepositoryProvider = Provider<BundledBibleRepository>((ref) {
  return ref.watch(bundledBibleRepositoryProvider);
});

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  return FirestoreAnnotationRepository(FirebaseFirestore.instance);
});

final bookmarkRepositoryProvider = Provider<FirestoreBookmarkRepository>((ref) {
  return FirestoreBookmarkRepository(FirebaseFirestore.instance);
});

final currentTranslationProvider = StateProvider<String>((ref) => 'kjv');

final bibleChapterProvider = FutureProvider.family<List<BibleVerse>, ({String bookId, int chapterNumber})>(
  (ref, args) async {
    final repo = ref.watch(bibleRepositoryProvider);
    final translation = ref.watch(currentTranslationProvider);
    return repo.getChapter(args.bookId, args.chapterNumber, translation);
  },
);

final chapterAnnotationsProvider =
    StreamProvider.family<List<Annotation>, ({String userId, String bookId, int chapterNumber})>(
  (ref, args) {
    final repo = ref.watch(annotationRepositoryProvider);
    return repo.watchChapterAnnotations(args.userId, args.bookId, args.chapterNumber);
  },
);

final userBookmarksProvider = StreamProvider.family<List<Bookmark>, String>(
  (ref, userId) {
    final repo = ref.watch(bookmarkRepositoryProvider);
    return repo.watchBookmarks(userId);
  },
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<BibleVerse>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(bibleRepositoryProvider);
  final translation = ref.watch(currentTranslationProvider);
  return repo.searchAll(query, translation);
});

const kHighlightColors = [
  Color(0xFFFFD700),
  Color(0xFF90EE90),
  Color(0xFFADD8E6),
  Color(0xFFFFB6C1),
];
