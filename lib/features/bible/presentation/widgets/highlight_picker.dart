import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/design_system/haptics_service.dart';
import '../../bible_providers.dart';
import '../../domain/models/annotation.dart';
import '../../domain/models/bible_verse.dart';

const _highlightColors = ['#FFD700', '#90EE90', '#87CEEB', '#FFB6C1', '#DDA0DD'];

class HighlightPicker extends ConsumerWidget {
  final String bookId;
  final int chapterId;
  final BibleVerse verse;
  const HighlightPicker({
    super.key,
    required this.bookId,
    required this.chapterId,
    required this.verse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a highlight color'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _highlightColors.map((color) {
                return GestureDetector(
                  onTap: () async {
                    await HapticsService.light();
                    final annotation = Annotation(
                      id: const Uuid().v4(),
                      bookId: bookId,
                      chapterId: chapterId,
                      verseNumber: verse.number,
                      type: AnnotationType.highlight,
                      color: color,
                    );
                    await ref
                        .read(annotationRepositoryProvider)
                        .saveAnnotation(annotation);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
