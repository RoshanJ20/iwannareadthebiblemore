class PlanReading {
  const PlanReading({
    required this.day,
    required this.book,
    required this.chapter,
    required this.title,
  });

  final int day;
  final String book;
  final int chapter;
  final String title;

  Map<String, dynamic> toMap() => {
        'day': day,
        'book': book,
        'chapter': chapter,
        'title': title,
      };

  factory PlanReading.fromMap(Map<String, dynamic> map) => PlanReading(
        day: (map['day'] as num).toInt(),
        book: map['book'] as String,
        chapter: (map['chapter'] as num).toInt(),
        title: map['title'] as String,
      );
}
