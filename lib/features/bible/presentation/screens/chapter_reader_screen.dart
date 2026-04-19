import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/bible_content/book_catalog.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/entities/bible_verse.dart';
import '../providers/bible_providers.dart';
import '../providers/reader_preferences_provider.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/verse_detail_sheet.dart';

class ChapterReaderScreen extends ConsumerStatefulWidget {
  const ChapterReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
  });

  final String bookId;
  final int chapterNumber;

  @override
  ConsumerState<ChapterReaderScreen> createState() =>
      _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends ConsumerState<ChapterReaderScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToChapter(int chapter) =>
      context.go(Routes.chapterReaderPath(widget.bookId, chapter));

  TextStyle _resolveBodyFont(ReaderPreferences prefs) {
    final base = TextStyle(
      fontSize: prefs.fontSize,
      height: prefs.lineHeight,
      color: AppColors.textPrimary,
    );
    switch (prefs.fontFamily) {
      case 'lora':
        return GoogleFonts.lora(textStyle: base);
      case 'garamond':
        return GoogleFonts.ebGaramond(textStyle: base);
      default:
        return base;
    }
  }

  TextStyle _resolveHeadingFont(ReaderPreferences prefs) {
    final base = TextStyle(
      fontSize: prefs.fontSize * 1.5,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.2,
      letterSpacing: -0.3,
    );
    switch (prefs.fontFamily) {
      case 'lora':
        return GoogleFonts.lora(textStyle: base);
      case 'garamond':
        return GoogleFonts.ebGaramond(textStyle: base);
      default:
        return base;
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = kBibleBooks.firstWhere(
      (b) => b.id == widget.bookId,
      orElse: () => kBibleBooks.first,
    );

    final chapterAsync = ref.watch(
      bibleChapterProvider(
          (bookId: widget.bookId, chapterNumber: widget.chapterNumber)),
    );

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    final annotationsAsync = userId.isNotEmpty
        ? ref.watch(chapterAnnotationsProvider((
            userId: userId,
            bookId: widget.bookId,
            chapterNumber: widget.chapterNumber
          )))
        : const AsyncData<List<Annotation>>([]);

    final translation = ref.watch(currentTranslationProvider);
    final prefs = ref.watch(readerPreferencesProvider);
    final bodyFont = _resolveBodyFont(prefs);
    final headingFont = _resolveHeadingFont(prefs);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textSecondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '${book.name} ${widget.chapterNumber}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: translation,
                dropdownColor: AppColors.surfaceElevated,
                icon: const Icon(Icons.expand_more,
                    color: AppColors.textMuted, size: 14),
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
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
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, size: 20),
            tooltip: 'Reading settings',
            onPressed: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const ReaderSettingsSheet(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -600 && widget.chapterNumber < book.totalChapters) {
            _goToChapter(widget.chapterNumber + 1);
          } else if (v > 600 && widget.chapterNumber > 1) {
            _goToChapter(widget.chapterNumber - 1);
          }
        },
        child: chapterAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text('Error loading chapter',
                style: TextStyle(color: AppColors.error)),
          ),
          data: (verses) {
            if (verses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          color: AppColors.textMuted.withOpacity(0.5), size: 52),
                      const SizedBox(height: 20),
                      Text(
                        'Not available in ${translation.toUpperCase()}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try KJV or WEB for offline reading,\nor add an API key in Settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            final annotations = annotationsAsync.valueOrNull ?? [];

            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: prefs.horizontalPadding,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${book.name} ${widget.chapterNumber}',
                    style: headingFont,
                  ),
                  const SizedBox(height: 32),

                  _ChapterProse(
                    verses: verses,
                    annotations: annotations,
                    prefs: prefs,
                    bodyFont: bodyFont,
                    onVerseTap: (verse) {
                      final existing = annotations
                          .where((a) =>
                              a.verseNumber == verse.verseNumber &&
                              a.type == AnnotationType.highlight)
                          .firstOrNull;
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
                    },
                  ),

                  const SizedBox(height: 56),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.chapterNumber > 1)
                        _NavButton(
                          label: 'Chapter ${widget.chapterNumber - 1}',
                          icon: Icons.chevron_left_rounded,
                          iconFirst: true,
                          onTap: () => _goToChapter(widget.chapterNumber - 1),
                        )
                      else
                        const SizedBox.shrink(),
                      if (widget.chapterNumber < book.totalChapters)
                        _NavButton(
                          label: 'Chapter ${widget.chapterNumber + 1}',
                          icon: Icons.chevron_right_rounded,
                          iconFirst: false,
                          onTap: () => _goToChapter(widget.chapterNumber + 1),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChapterProse extends StatelessWidget {
  const _ChapterProse({
    required this.verses,
    required this.annotations,
    required this.prefs,
    required this.bodyFont,
    required this.onVerseTap,
  });

  final List<BibleVerse> verses;
  final List<Annotation> annotations;
  final ReaderPreferences prefs;
  final TextStyle bodyFont;
  final void Function(BibleVerse) onVerseTap;

  @override
  Widget build(BuildContext context) {
    final highlights = <int, Color>{};
    for (final a in annotations) {
      if (a.type == AnnotationType.highlight) {
        highlights[a.verseNumber] = a.color;
      }
    }

    final spans = <InlineSpan>[];
    for (final verse in verses) {
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.top,
        child: GestureDetector(
          onTap: () => onVerseTap(verse),
          child: Padding(
            padding: const EdgeInsets.only(right: 3, top: 1),
            child: Text(
              '${verse.verseNumber}',
              style: TextStyle(
                fontSize: prefs.fontSize * 0.6,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: prefs.lineHeight,
              ),
            ),
          ),
        ),
      ));

      final highlight = highlights[verse.verseNumber];
      spans.add(TextSpan(
        text: '${verse.text} ',
        style: highlight != null
            ? bodyFont.copyWith(
                backgroundColor: highlight.withAlpha(55),
              )
            : bodyFont,
      ));
    }

    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        children: spans,
        style: bodyFont,
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.iconFirst,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool iconFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconFirst
              ? [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]
              : [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(icon, size: 18, color: AppColors.primary),
                ],
        ),
      ),
    );
  }
}
