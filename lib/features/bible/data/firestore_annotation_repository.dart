import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/annotation.dart';

class FirestoreAnnotationRepository {
  final FirebaseFirestore _db;
  final String _userId;

  FirestoreAnnotationRepository(this._db, this._userId);

  CollectionReference get _col =>
      _db.collection('users').doc(_userId).collection('annotations');

  Stream<List<Annotation>> watchAnnotations(String bookId, int chapterId) {
    return _col
        .where('bookId', isEqualTo: bookId)
        .where('chapterId', isEqualTo: chapterId)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  Future<void> saveAnnotation(Annotation annotation) async {
    await _col.doc(annotation.id).set({
      'bookId': annotation.bookId,
      'chapterId': annotation.chapterId,
      'verseNumber': annotation.verseNumber,
      'type': annotation.type.name,
      'color': annotation.color,
      'text': annotation.text,
    });
  }

  Future<void> deleteAnnotation(String annotationId) =>
      _col.doc(annotationId).delete();

  Annotation _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Annotation(
      id: doc.id,
      bookId: d['bookId'] as String,
      chapterId: d['chapterId'] as int,
      verseNumber: d['verseNumber'] as int,
      type: AnnotationType.values.byName(d['type'] as String),
      color: d['color'] as String?,
      text: d['text'] as String?,
    );
  }
}
