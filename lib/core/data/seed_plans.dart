import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  static Future<void> seedPlansIfNeeded(FirebaseFirestore db) async {
    final existing = await db.collection('plans').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = db.batch();
    for (final plan in _officialPlans) {
      final ref = db.collection('plans').doc();
      batch.set(ref, plan);
    }
    await batch.commit();
  }

  static final List<Map<String, dynamic>> _officialPlans = [
    {
      'name': 'Start Here: Genesis 1-10',
      'description':
          'Begin your Bible journey with the first 10 chapters of Genesis — creation, the fall, and the flood.',
      'coverEmoji': '📖',
      'totalDays': 10,
      'tags': ['beginners', 'genesis'],
      'isCustom': false,
      'creatorId': null,
      'readings': List.generate(
        10,
        (i) => {
          'day': i + 1,
          'book': 'Genesis',
          'chapter': '${i + 1}',
          'title': _genesisTitles[i],
        },
      ),
    },
    {
      'name': "The Lord's Prayer Week",
      'description':
          "Seven days exploring the Sermon on the Mount and the Lord's Prayer in Matthew and Luke.",
      'coverEmoji': '🙏',
      'totalDays': 7,
      'tags': ['prayer', 'sermon', 'matthew', 'luke'],
      'isCustom': false,
      'creatorId': null,
      'readings': const [
        {'day': 1, 'book': 'Matthew', 'chapter': '5', 'title': 'The Beatitudes'},
        {'day': 2, 'book': 'Matthew', 'chapter': '6', 'title': "The Lord's Prayer"},
        {'day': 3, 'book': 'Matthew', 'chapter': '7', 'title': 'Ask, Seek, Knock'},
        {'day': 4, 'book': 'Luke', 'chapter': '11', 'title': "A Friend at Midnight"},
        {'day': 5, 'book': 'Luke', 'chapter': '12', 'title': 'Do Not Worry'},
        {'day': 6, 'book': 'Luke', 'chapter': '13', 'title': 'The Narrow Door'},
        {'day': 7, 'book': 'Luke', 'chapter': '14', 'title': 'The Cost of Discipleship'},
      ],
    },
    {
      'name': 'Psalms of Comfort',
      'description':
          'Fourteen psalms chosen for comfort, hope, and drawing near to God.',
      'coverEmoji': '💙',
      'totalDays': 14,
      'tags': ['psalms', 'comfort', 'peace'],
      'isCustom': false,
      'creatorId': null,
      'readings': const [
        {'day': 1,  'book': 'Psalms', 'chapter': '23',  'title': 'The Lord Is My Shepherd'},
        {'day': 2,  'book': 'Psalms', 'chapter': '27',  'title': 'The Lord Is My Light'},
        {'day': 3,  'book': 'Psalms', 'chapter': '46',  'title': 'God Is Our Refuge'},
        {'day': 4,  'book': 'Psalms', 'chapter': '91',  'title': 'Under His Wings'},
        {'day': 5,  'book': 'Psalms', 'chapter': '103', 'title': 'Bless the Lord'},
        {'day': 6,  'book': 'Psalms', 'chapter': '121', 'title': 'My Help Comes from the Lord'},
        {'day': 7,  'book': 'Psalms', 'chapter': '130', 'title': 'Out of the Depths'},
        {'day': 8,  'book': 'Psalms', 'chapter': '139', 'title': 'You Have Searched Me'},
        {'day': 9,  'book': 'Psalms', 'chapter': '143', 'title': 'Teach Me to Do Your Will'},
        {'day': 10, 'book': 'Psalms', 'chapter': '34',  'title': 'Taste and See'},
        {'day': 11, 'book': 'Psalms', 'chapter': '42',  'title': 'As the Deer Pants'},
        {'day': 12, 'book': 'Psalms', 'chapter': '51',  'title': 'Create in Me a Clean Heart'},
        {'day': 13, 'book': 'Psalms', 'chapter': '63',  'title': 'My Soul Thirsts for You'},
        {'day': 14, 'book': 'Psalms', 'chapter': '84',  'title': 'How Lovely Is Your Dwelling'},
      ],
    },
    {
      'name': 'Gospel of John',
      'description':
          'Read through all 21 chapters of the Gospel of John — one chapter per day.',
      'coverEmoji': '✝️',
      'totalDays': 21,
      'tags': ['gospel', 'john', 'jesus'],
      'isCustom': false,
      'creatorId': null,
      'readings': List.generate(
        21,
        (i) => {
          'day': i + 1,
          'book': 'John',
          'chapter': '${i + 1}',
          'title': _johnTitles[i],
        },
      ),
    },
    {
      'name': 'Proverbs 31-day',
      'description':
          'A proverb a day for the whole month — all 31 chapters of Proverbs.',
      'coverEmoji': '⚡',
      'totalDays': 31,
      'tags': ['wisdom', 'proverbs'],
      'isCustom': false,
      'creatorId': null,
      'readings': List.generate(
        31,
        (i) => {
          'day': i + 1,
          'book': 'Proverbs',
          'chapter': '${i + 1}',
          'title': 'Proverbs ${i + 1}',
        },
      ),
    },
  ];

  static const _genesisTitles = [
    'Creation',
    'The Garden of Eden',
    'The Fall',
    'Cain and Abel',
    'From Adam to Noah',
    'Wickedness and the Flood',
    'The Flood Continues',
    'The Flood Recedes',
    "God's Covenant with Noah",
    'The Table of Nations',
  ];

  static const _johnTitles = [
    'The Word Became Flesh',
    'The Wedding at Cana',
    'Jesus and Nicodemus',
    'The Woman at the Well',
    "The Official's Son",
    'The Healing at Bethesda',
    'Feeding the Five Thousand',
    'Walking on Water',
    'The Bread of Life',
    'The Woman Caught in Adultery',
    'The Light of the World',
    'The Good Shepherd',
    'The Raising of Lazarus',
    'Mary Anoints Jesus',
    'The Triumphal Entry',
    'Jesus Washes Feet',
    'The Farewell Discourse',
    'The Vine and the Branches',
    'The High Priestly Prayer',
    'The Arrest and Trial',
    'The Resurrection',
  ];
}
