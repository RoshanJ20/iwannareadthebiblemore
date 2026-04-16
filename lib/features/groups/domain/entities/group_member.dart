class GroupMember {
  const GroupMember({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.todayRead,
    required this.streak,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final bool todayRead;
  final int streak;

  factory GroupMember.fromFirestore(String userId, Map<String, dynamic> data) {
    return GroupMember(
      userId: userId,
      displayName: data['displayName'] as String? ?? 'Member',
      photoUrl: data['photoUrl'] as String?,
      todayRead: data['todayRead'] as bool? ?? false,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'todayRead': todayRead,
        'streak': streak,
      };
}
