import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';

class FirestoreBookmarkRepository implements BookmarkRepository {
  FirestoreBookmarkRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('bookmarks');

  Stream<List<Bookmark>> watchBookmarks(String userId) {
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Bookmark.fromMap(doc.id, doc.data())).toList());
  }

  Future<Bookmark> addBookmark(Bookmark bookmark) async {
    final ref = _collection(bookmark.userId).doc();
    final withId = Bookmark(
      id: ref.id,
      userId: bookmark.userId,
      bookId: bookmark.bookId,
      chapterNumber: bookmark.chapterNumber,
      verseNumber: bookmark.verseNumber,
      verseText: bookmark.verseText,
      createdAt: bookmark.createdAt,
    );
    await ref.set(withId.toMap());
    return withId;
  }

  Future<void> removeBookmark(String userId, String bookmarkId) async {
    await _collection(userId).doc(bookmarkId).delete();
  }

  Future<bool> isBookmarked(
    String userId,
    String bookId,
    int chapterNumber,
    int verseNumber,
  ) async {
    final snap = await _collection(userId)
        .where('bookId', isEqualTo: bookId)
        .where('chapterNumber', isEqualTo: chapterNumber)
        .where('verseNumber', isEqualTo: verseNumber)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
