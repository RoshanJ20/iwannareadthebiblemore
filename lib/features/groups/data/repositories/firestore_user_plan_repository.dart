import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_plan.dart';
import '../../domain/repositories/user_plan_repository.dart';

const _bookNameToId = {
  'Genesis': 'GEN', 'Exodus': 'EXO', 'Leviticus': 'LEV',
  'Numbers': 'NUM', 'Deuteronomy': 'DEU', 'Joshua': 'JOS',
  'Judges': 'JDG', 'Ruth': 'RUT', '1 Samuel': '1SA', '2 Samuel': '2SA',
  '1 Kings': '1KI', '2 Kings': '2KI', '1 Chronicles': '1CH', '2 Chronicles': '2CH',
  'Ezra': 'EZR', 'Nehemiah': 'NEH', 'Esther': 'EST', 'Job': 'JOB',
  'Psalms': 'PSA', 'Psalm': 'PSA', 'Proverbs': 'PRO', 'Ecclesiastes': 'ECC',
  'Song of Solomon': 'SNG', 'Isaiah': 'ISA', 'Jeremiah': 'JER',
  'Lamentations': 'LAM', 'Ezekiel': 'EZK', 'Daniel': 'DAN', 'Hosea': 'HOS',
  'Joel': 'JOL', 'Amos': 'AMO', 'Obadiah': 'OBA', 'Jonah': 'JON',
  'Micah': 'MIC', 'Nahum': 'NAH', 'Habakkuk': 'HAB', 'Zephaniah': 'ZEP',
  'Haggai': 'HAG', 'Zechariah': 'ZEC', 'Malachi': 'MAL',
  'Matthew': 'MAT', 'Mark': 'MRK', 'Luke': 'LUK', 'John': 'JHN',
  'Acts': 'ACT', 'Romans': 'ROM', '1 Corinthians': '1CO', '2 Corinthians': '2CO',
  'Galatians': 'GAL', 'Ephesians': 'EPH', 'Philippians': 'PHP',
  'Colossians': 'COL', '1 Thessalonians': '1TH', '2 Thessalonians': '2TH',
  '1 Timothy': '1TI', '2 Timothy': '2TI', 'Titus': 'TIT', 'Philemon': 'PHM',
  'Hebrews': 'HEB', 'James': 'JAS', '1 Peter': '1PE', '2 Peter': '2PE',
  '1 John': '1JN', '2 John': '2JN', '3 John': '3JN', 'Jude': 'JUD',
  'Revelation': 'REV',
};

class FirestoreUserPlanRepository implements UserPlanRepository {
  FirestoreUserPlanRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _userPlans =>
      _firestore.collection('userPlans');

  @override
  Stream<List<UserPlan>> watchUserPlans(String userId) {
    return _userPlans
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserPlan.fromFirestore(d.id, d.data()))
            .toList());
  }

  @override
  Future<UserPlan> createUserPlan(UserPlan plan) async {
    final ref = await _userPlans.add(plan.toMap());
    return UserPlan.fromFirestore(ref.id, plan.toMap());
  }

  @override
  Future<void> markTodayRead(
    String userPlanId, {
    required String userId,
    required String todayChapter,
    required String planId,
    String translation = 'kjv',
  }) async {
    final (bookId, chapterNumber) = _parseTodayChapter(todayChapter);
    final dateStr = _todayDateStr();

    final batch = _firestore.batch();

    batch.update(_userPlans.doc(userPlanId), {'todayRead': true});

    batch.set(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('readingLog')
          .doc(dateStr),
      {
        'date': dateStr,
        'bookId': bookId,
        'chapterId': chapterNumber,
        'planId': planId,
        'xpEarned': 50,
        'translation': translation,
      },
    );

    batch.set(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('bookProgress')
          .doc(bookId),
      {
        'chapters': FieldValue.arrayUnion([chapterNumber]),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  @override
  Future<void> deleteUserPlan(String userPlanId) async {
    await _userPlans.doc(userPlanId).delete();
  }

  (String bookId, int chapter) _parseTodayChapter(String todayChapter) {
    final trimmed = todayChapter.trim();
    final lastSpace = trimmed.lastIndexOf(' ');
    if (lastSpace == -1) return ('GEN', 1);

    final bookName = trimmed.substring(0, lastSpace);
    final chapterStr = trimmed.substring(lastSpace + 1);
    final chapter = int.tryParse(chapterStr) ?? 1;
    final bookId = _bookNameToId[bookName] ?? 'GEN';
    return (bookId, chapter);
  }

  String _todayDateStr() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
