import '../entities/annotation.dart';

abstract class AnnotationRepository {
  Stream<List<Annotation>> watchChapterAnnotations(
    String userId,
    String bookId,
    int chapterNumber,
  );

  Future<Annotation> createAnnotation(Annotation annotation);

  Future<void> updateAnnotation(Annotation annotation);

  Future<void> deleteAnnotation(String userId, String annotationId);

  Future<List<Annotation>> getAnnotationsForChapter(
    String userId,
    String bookId,
    int chapterNumber,
  );
}
