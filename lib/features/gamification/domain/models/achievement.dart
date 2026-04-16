class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final DateTime? earnedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    this.earnedAt,
  });
}

const kAllAchievementDefs = [
  Achievement(id: 'first_flame', name: 'First Flame', description: 'Reach a 7-day streak', emoji: '🔥'),
  Achievement(id: 'month_of_faith', name: 'Month of Faith', description: 'Reach a 30-day streak', emoji: '📅'),
  Achievement(id: 'better_together', name: 'Better Together', description: 'Join your first group', emoji: '🤝'),
  Achievement(id: 'keepers_nudge', name: "Keeper's Nudge", description: 'Nudge 10 friends who read within 24h', emoji: '👋'),
  Achievement(id: 'in_the_beginning', name: 'In The Beginning', description: 'Read all chapters of Genesis', emoji: '📖'),
  Achievement(id: 'red_letters', name: 'Red Letters', description: 'Read all chapters of Matthew, Mark, Luke and John', emoji: '✝️'),
  Achievement(id: 'group_mvp', name: 'Group MVP', description: 'Top scorer in your group this week', emoji: '🏆'),
];
