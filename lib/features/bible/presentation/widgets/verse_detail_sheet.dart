import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/entities/bible_verse.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/bible_providers.dart';

class VerseDetailSheet extends ConsumerStatefulWidget {
  const VerseDetailSheet({
    super.key,
    required this.verse,
    required this.userId,
    this.existingAnnotation,
  });

  final BibleVerse verse;
  final String userId;
  final Annotation? existingAnnotation;

  @override
  ConsumerState<VerseDetailSheet> createState() => _VerseDetailSheetState();
}

class _VerseDetailSheetState extends ConsumerState<VerseDetailSheet> {
  bool _showNoteField = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingAnnotation?.text != null) {
      _noteController.text = widget.existingAnnotation!.text!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String get _reference =>
      '${widget.verse.bookId} ${widget.verse.chapterNumber}:${widget.verse.verseNumber}';

  Future<void> _addHighlight(Color color) async {
    final repo = ref.read(annotationRepositoryProvider);
    final annotation = Annotation(
      id: '',
      userId: widget.userId,
      bookId: widget.verse.bookId,
      chapterNumber: widget.verse.chapterNumber,
      verseNumber: widget.verse.verseNumber,
      type: AnnotationType.highlight,
      color: color,
      createdAt: DateTime.now(),
    );

    if (widget.existingAnnotation != null) {
      await repo.updateAnnotation(
        widget.existingAnnotation!.copyWith(color: color, type: AnnotationType.highlight),
      );
    } else {
      await repo.createAnnotation(annotation);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    final repo = ref.read(annotationRepositoryProvider);
    final annotation = Annotation(
      id: '',
      userId: widget.userId,
      bookId: widget.verse.bookId,
      chapterNumber: widget.verse.chapterNumber,
      verseNumber: widget.verse.verseNumber,
      type: AnnotationType.note,
      color: AppColors.primary,
      text: text,
      createdAt: DateTime.now(),
    );

    if (widget.existingAnnotation != null) {
      await repo.updateAnnotation(
        widget.existingAnnotation!.copyWith(text: text, type: AnnotationType.note),
      );
    } else {
      await repo.createAnnotation(annotation);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addBookmark() async {
    final repo = ref.read(bookmarkRepositoryProvider);
    await repo.addBookmark(Bookmark(
      id: '',
      userId: widget.userId,
      bookId: widget.verse.bookId,
      chapterNumber: widget.verse.chapterNumber,
      verseNumber: widget.verse.verseNumber,
      verseText: widget.verse.text,
      createdAt: DateTime.now(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verse bookmarked')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _reference,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.verse.text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.surfaceElevated),
          const SizedBox(height: 12),
          Text(
            'Highlight',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: kHighlightColors.map((color) {
              return GestureDetector(
                onTap: () => _addHighlight(color),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.existingAnnotation?.color == color
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_showNoteField) ...[
            TextField(
              controller: _noteController,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Write a note...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showNoteField = false),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Save', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                _ActionButton(
                  icon: Icons.edit_note,
                  label: 'Add Note',
                  onTap: () => setState(() => _showNoteField = true),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.bookmark_outline,
                  label: 'Bookmark',
                  onTap: _addBookmark,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {
                    Share.share('$_reference\n\n"${widget.verse.text}"');
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
