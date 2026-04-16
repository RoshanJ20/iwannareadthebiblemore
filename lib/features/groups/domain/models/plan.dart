import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingPlan {
  final String id, name, description, coverEmoji;
  final int totalDays;
  final List<String> tags;
  final List<PlanReading> readings;
  final bool isCustom;

  const ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.coverEmoji,
    required this.totalDays,
    required this.tags,
    required this.readings,
    this.isCustom = false,
  });

  factory ReadingPlan.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReadingPlan(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      coverEmoji: d['coverEmoji'] ?? '📖',
      totalDays: d['totalDays'] ?? 0,
      tags: List<String>.from(d['tags'] ?? []),
      readings: (d['readings'] as List? ?? [])
          .map((r) => PlanReading.fromMap(r as Map<String, dynamic>))
          .toList(),
      isCustom: d['isCustom'] ?? false,
    );
  }
}

class PlanReading {
  final int day;
  final String book, chapter, title;

  const PlanReading({
    required this.day,
    required this.book,
    required this.chapter,
    required this.title,
  });

  factory PlanReading.fromMap(Map<String, dynamic> m) => PlanReading(
        day: m['day'] ?? 0,
        book: m['book'] ?? '',
        chapter: m['chapter'] ?? '',
        title: m['title'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'day': day,
        'book': book,
        'chapter': chapter,
        'title': title,
      };
}
