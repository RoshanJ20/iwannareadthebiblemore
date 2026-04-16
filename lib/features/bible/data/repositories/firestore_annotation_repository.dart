import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/repositories/annotation_repository.dart';

class FirestoreAnnotationRepository implements AnnotationRepository {
  FirestoreAnnotationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('annotations');

  @override
  Stream<List<Annotation>> watchChapterAnnotations(
    String userId,
    String bookId,
    int chapterNumber,
  ) {
    return _collection(userId)
        .where('bookId', isEqualTo: bookId)
        .where('chapterId', isEqualTo: chapterNumber)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Annotation.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<Annotation> createAnnotation(Annotation annotation) async {
    final ref = _collection(annotation.userId).doc();
    final withId = annotation.copyWith(id: ref.id);
    await ref.set(withId.toMap());
    return withId;
  }

  @override
  Future<void> updateAnnotation(Annotation annotation) async {
    await _collection(annotation.userId)
        .doc(annotation.id)
        .update(annotation.toMap());
  }

  @override
  Future<void> deleteAnnotation(String userId, String annotationId) async {
    await _collection(userId).doc(annotationId).delete();
  }

  @override
  Future<List<Annotation>> getAnnotationsForChapter(
    String userId,
    String bookId,
    int chapterNumber,
  ) async {
    final snap = await _collection(userId)
        .where('bookId', isEqualTo: bookId)
        .where('chapterId', isEqualTo: chapterNumber)
        .get();
    return snap.docs
        .map((doc) => Annotation.fromMap(doc.id, doc.data()))
        .toList();
  }
}
