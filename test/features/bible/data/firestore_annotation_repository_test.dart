import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/bible/data/firestore_annotation_repository.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/models/annotation.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreAnnotationRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FirestoreAnnotationRepository(fakeFirestore, 'test-user');
  });

  test('save and watch annotation', () async {
    const annotation = Annotation(
      id: 'ann1',
      bookId: 'GEN',
      chapterId: 1,
      verseNumber: 1,
      type: AnnotationType.highlight,
      color: '#FFD700',
    );

    await repo.saveAnnotation(annotation);

    final annotations = await repo.watchAnnotations('GEN', 1).first;
    expect(annotations.length, 1);
    expect(annotations.first.id, 'ann1');
    expect(annotations.first.color, '#FFD700');
  });

  test('delete annotation', () async {
    const annotation = Annotation(
      id: 'ann2',
      bookId: 'GEN',
      chapterId: 1,
      verseNumber: 2,
      type: AnnotationType.note,
      text: 'My note',
    );

    await repo.saveAnnotation(annotation);
    await repo.deleteAnnotation('ann2');

    final annotations = await repo.watchAnnotations('GEN', 1).first;
    expect(annotations, isEmpty);
  });
}
