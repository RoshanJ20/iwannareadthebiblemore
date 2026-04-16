import '../models/annotation.dart';

abstract class AnnotationRepository {
  Stream<List<Annotation>> watchAnnotations(String bookId, int chapterId);
  Future<void> saveAnnotation(Annotation annotation);
  Future<void> deleteAnnotation(String annotationId);
}
