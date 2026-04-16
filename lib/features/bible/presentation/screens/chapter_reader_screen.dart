import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/haptics_service.dart';
import '../../bible_providers.dart';
import '../../domain/models/bible_verse.dart';
import '../widgets/verse_action_sheet.dart';

class ChapterReaderScreen extends ConsumerWidget {
  final String bookId;
  final int chapterNumber;
  const ChapterReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(
      chapterProvider((bookId: bookId, chapterNumber: chapterNumber)),
    );
    return Scaffold(
      appBar: AppBar(title: Text('$bookId $chapterNumber')),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (chapter) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chapter.verses.length,
          itemBuilder: (context, i) {
            final verse = chapter.verses[i];
            return _VerseRow(bookId: bookId, chapterId: chapterNumber, verse: verse);
          },
        ),
      ),
    );
  }
}

class _VerseRow extends StatelessWidget {
  final String bookId;
  final int chapterId;
  final BibleVerse verse;
  const _VerseRow({
    required this.bookId,
    required this.chapterId,
    required this.verse,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        await HapticsService.medium();
        if (!context.mounted) return;
        showModalBottomSheet(
          context: context,
          builder: (_) => VerseActionSheet(
            bookId: bookId,
            chapterId: chapterId,
            verse: verse,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${verse.number} ',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.primary),
              ),
              TextSpan(
                text: verse.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
