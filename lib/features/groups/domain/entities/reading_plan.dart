import 'plan_reading.dart';

class ReadingPlan {
  const ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.totalDays,
    required this.tags,
    required this.coverEmoji,
    required this.readings,
    required this.isCustom,
    this.creatorId,
  });

  final String id;
  final String name;
  final String description;
  final int totalDays;
  final List<String> tags;
  final String coverEmoji;
  final List<PlanReading> readings;
  final bool isCustom;
  final String? creatorId;

  factory ReadingPlan.fromFirestore(String id, Map<String, dynamic> data) {
    final rawReadings = data['readings'] as List<dynamic>? ?? [];
    return ReadingPlan(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      totalDays: (data['totalDays'] as num?)?.toInt() ?? 0,
      tags: List<String>.from(data['tags'] as List? ?? []),
      coverEmoji: data['coverEmoji'] as String? ?? '📖',
      readings: rawReadings
          .map((r) => PlanReading.fromMap(r as Map<String, dynamic>))
          .toList(),
      isCustom: data['isCustom'] as bool? ?? false,
      creatorId: data['creatorId'] as String?,
    );
  }
}
