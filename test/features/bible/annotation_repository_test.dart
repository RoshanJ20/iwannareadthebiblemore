import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/bible/data/repositories/firestore_annotation_repository.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/entities/annotation.dart';

Annotation _makeAnnotation({
  String id = '',
  String userId = 'user-1',
  String bookId = 'GEN',
  int chapterNumber = 1,
  int verseNumber = 1,
  AnnotationType type = AnnotationType.highlight,
  Color color = Colors.yellow,
  String? text,
}) =>
    Annotation(
      id: id,
      userId: userId,
      bookId: bookId,
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      type: type,
      color: color,
      text: text,
      createdAt: DateTime(2024, 1, 1),
    );

void main() {
  group('FirestoreAnnotationRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreAnnotationRepository repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repo = FirestoreAnnotationRepository(fakeFirestore);
    });

    test('createAnnotation writes to Firestore and returns annotation with id',
        () async {
      final annotation = _makeAnnotation();
      final created = await repo.createAnnotation(annotation);

      expect(created.id, isNotEmpty);
      expect(created.bookId, equals('GEN'));
      expect(created.chapterNumber, equals(1));

      final doc = await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('annotations')
          .doc(created.id)
          .get();
      expect(doc.exists, isTrue);
    });

    test('updateAnnotation updates existing document', () async {
      final created = await repo.createAnnotation(_makeAnnotation());
      final updated = created.copyWith(
        type: AnnotationType.note,
        text: 'My note',
      );
      await repo.updateAnnotation(updated);

      final doc = await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('annotations')
          .doc(created.id)
          .get();
      expect(doc.data()?['type'], equals('note'));
      expect(doc.data()?['text'], equals('My note'));
    });

    test('deleteAnnotation removes the document', () async {
      final created = await repo.createAnnotation(_makeAnnotation());
      await repo.deleteAnnotation('user-1', created.id);

      final doc = await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('annotations')
          .doc(created.id)
          .get();
      expect(doc.exists, isFalse);
    });

    test('getAnnotationsForChapter returns only matching annotations', () async {
      await repo.createAnnotation(_makeAnnotation(chapterNumber: 1, verseNumber: 1));
      await repo.createAnnotation(_makeAnnotation(chapterNumber: 1, verseNumber: 3));
      await repo.createAnnotation(_makeAnnotation(chapterNumber: 2, verseNumber: 1));

      final chapter1 =
          await repo.getAnnotationsForChapter('user-1', 'GEN', 1);
      expect(chapter1.length, equals(2));

      final chapter2 =
          await repo.getAnnotationsForChapter('user-1', 'GEN', 2);
      expect(chapter2.length, equals(1));
    });

    test('watchChapterAnnotations streams annotations for a chapter', () async {
      await repo.createAnnotation(_makeAnnotation(chapterNumber: 1, verseNumber: 2));

      final stream = repo.watchChapterAnnotations('user-1', 'GEN', 1);
      final result = await stream.first;

      expect(result.length, equals(1));
      expect(result.first.verseNumber, equals(2));
    });

    test('watchChapterAnnotations reflects new annotations', () async {
      final stream = repo.watchChapterAnnotations('user-1', 'GEN', 1);

      await repo.createAnnotation(_makeAnnotation(chapterNumber: 1, verseNumber: 5));

      final result = await stream.first;
      expect(result.isNotEmpty, isTrue);
    });
  });
}
