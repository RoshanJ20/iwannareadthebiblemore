import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../bible_providers.dart';
import '../../domain/models/annotation.dart';
import '../../domain/models/bible_verse.dart';

class NoteSheet extends ConsumerStatefulWidget {
  final String bookId;
  final int chapterId;
  final BibleVerse verse;
  const NoteSheet({
    super.key,
    required this.bookId,
    required this.chapterId,
    required this.verse,
  });

  @override
  ConsumerState<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends ConsumerState<NoteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Note on ${widget.bookId} ${widget.chapterId}:${widget.verse.number}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Write your note...'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              if (_controller.text.trim().isEmpty) return;
              final annotation = Annotation(
                id: const Uuid().v4(),
                bookId: widget.bookId,
                chapterId: widget.chapterId,
                verseNumber: widget.verse.number,
                type: AnnotationType.note,
                text: _controller.text.trim(),
              );
              await ref
                  .read(annotationRepositoryProvider)
                  .saveAnnotation(annotation);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save Note'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
