enum AnnotationType { highlight, note }

class Annotation {
  final String id;
  final String bookId;
  final int chapterId;
  final int verseNumber;
  final AnnotationType type;
  final String? color;
  final String? text;
  const Annotation({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.verseNumber,
    required this.type,
    this.color,
    this.text,
  });
}
