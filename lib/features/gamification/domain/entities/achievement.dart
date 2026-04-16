class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.condition,
  });

  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final String condition;
}
