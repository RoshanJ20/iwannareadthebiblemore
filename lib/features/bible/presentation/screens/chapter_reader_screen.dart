import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/bible_content/book_catalog.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/entities/bible_verse.dart';
import '../providers/bible_providers.dart';
import '../widgets/verse_detail_sheet.dart';

class ChapterReaderScreen extends ConsumerWidget {
  const ChapterReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
  });

  final String bookId;
  final int chapterNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = kBibleBooks.firstWhere(
      (b) => b.id == bookId,
      orElse: () => kBibleBooks.first,
    );

    final chapterAsync = ref.watch(
      bibleChapterProvider((bookId: bookId, chapterNumber: chapterNumber)),
    );

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    final annotationsAsync = userId.isNotEmpty
        ? ref.watch(chapterAnnotationsProvider(
            (userId: userId, bookId: bookId, chapterNumber: chapterNumber)))
        : const AsyncData<List<Annotation>>([]);

    final translation = ref.watch(currentTranslationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Text('${book.name} $chapterNumber'),
        actions: [
          DropdownButton<String>(
            value: translation,
            dropdownColor: AppColors.surface,
            underline: const SizedBox(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            items: const [
              DropdownMenuItem(value: 'niv', child: Text('NIV')),
              DropdownMenuItem(value: 'esv', child: Text('ESV')),
              DropdownMenuItem(value: 'nlt', child: Text('NLT')),
              DropdownMenuItem(value: 'nasb', child: Text('NASB')),
              DropdownMenuItem(value: 'kjv', child: Text('KJV')),
              DropdownMenuItem(value: 'web', child: Text('WEB')),
            ],
            onChanged: (v) {
              if (v != null) {
                ref.read(currentTranslationProvider.notifier).state = v;
              }
            },
          ),
          const SizedBox(width: 4),
          if (chapterNumber > 1)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous chapter',
              onPressed: () => context.go(
                Routes.chapterReaderPath(bookId, chapterNumber - 1),
              ),
            ),
          if (chapterNumber < book.totalChapters)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next chapter',
              onPressed: () => context.go(
                Routes.chapterReaderPath(bookId, chapterNumber + 1),
              ),
            ),
        ],
      ),
      body: chapterAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error loading chapter', style: TextStyle(color: AppColors.error)),
        ),
        data: (verses) {
          if (verses.isEmpty) {
            return const Center(
              child: Text(
                'Chapter not available in this translation.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final annotations = annotationsAsync.valueOrNull ?? [];

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              final verseAnnotations = annotations
                  .where((a) => a.verseNumber == verse.verseNumber)
                  .toList();
              final highlight = verseAnnotations
                  .where((a) => a.type == AnnotationType.highlight)
                  .firstOrNull;

              return _VerseRow(
                verse: verse,
                highlight: highlight,
                userId: userId,
                onLongPress: () => _showVerseSheet(context, verse, userId, highlight),
              );
            },
          );
        },
      ),
    );
  }

  void _showVerseSheet(
    BuildContext context,
    BibleVerse verse,
    String userId,
    Annotation? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VerseDetailSheet(
        verse: verse,
        userId: userId,
        existingAnnotation: existing,
      ),
    );
  }
}

class _VerseRow extends StatelessWidget {
  const _VerseRow({
    required this.verse,
    required this.highlight,
    required this.userId,
    required this.onLongPress,
  });

  final BibleVerse verse;
  final Annotation? highlight;
  final String userId;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final highlightColor = highlight?.color;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${verse.verseNumber}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 2.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: highlightColor != null
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: highlightColor.withAlpha(204),
                            width: 2,
                          ),
                        ),
                        color: highlightColor.withAlpha(31),
                      )
                    : null,
                padding: highlightColor != null
                    ? const EdgeInsets.symmetric(vertical: 2, horizontal: 4)
                    : EdgeInsets.zero,
                child: Text(
                  verse.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
