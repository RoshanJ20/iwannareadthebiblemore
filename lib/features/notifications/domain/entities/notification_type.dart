enum NotificationType {
  dailyReminder,
  streakAtRisk,
  friendNudge,
  groupActivity,
  milestone,
  planCompletion,
  weeklyLeaderboard;

  /// The string value used in FCM data payloads and Firestore.
  String get value {
    switch (this) {
      case NotificationType.dailyReminder:
        return 'daily_reminder';
      case NotificationType.streakAtRisk:
        return 'streak_at_risk';
      case NotificationType.friendNudge:
        return 'friend_nudge';
      case NotificationType.groupActivity:
        return 'group_activity';
      case NotificationType.milestone:
        return 'milestone';
      case NotificationType.planCompletion:
        return 'plan_completion';
      case NotificationType.weeklyLeaderboard:
        return 'weekly_leaderboard';
    }
  }

  /// Display-friendly label shown in the settings screen.
  String get displayName {
    switch (this) {
      case NotificationType.dailyReminder:
        return 'Daily Reminder';
      case NotificationType.streakAtRisk:
        return 'Streak at Risk';
      case NotificationType.friendNudge:
        return 'Friend Nudges';
      case NotificationType.groupActivity:
        return 'Group Activity';
      case NotificationType.milestone:
        return 'Milestones';
      case NotificationType.planCompletion:
        return 'Plan Completion';
      case NotificationType.weeklyLeaderboard:
        return 'Weekly Leaderboard';
    }
  }

  /// Parses a raw string (FCM data payload) to a [NotificationType].
  static NotificationType? fromValue(String value) {
    for (final type in NotificationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
