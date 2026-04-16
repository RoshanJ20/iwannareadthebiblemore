import 'package:flutter/material.dart';
import '../../domain/models/bible_verse.dart';
import 'highlight_picker.dart';
import 'note_sheet.dart';
import '../services/verse_sharing_service.dart';

class VerseActionSheet extends StatelessWidget {
  final String bookId;
  final int chapterId;
  final BibleVerse verse;
  const VerseActionSheet({
    super.key,
    required this.bookId,
    required this.chapterId,
    required this.verse,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.highlight),
            title: const Text('Highlight'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                builder: (_) => HighlightPicker(
                  bookId: bookId,
                  chapterId: chapterId,
                  verse: verse,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_add),
            title: const Text('Add Note'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => NoteSheet(
                  bookId: bookId,
                  chapterId: chapterId,
                  verse: verse,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Verse'),
            onTap: () {
              Navigator.pop(context);
              VerseSharingService.shareText(
                verse: verse,
                reference: '$bookId $chapterId:${verse.number}',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Close'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
