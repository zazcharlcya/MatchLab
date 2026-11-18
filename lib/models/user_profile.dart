class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.points,
    this.avatarPath,
  });

  final int id;
  final String name;
  final int points;
  final String? avatarPath;

  UserProfile copyWith({
    String? name,
    int? points,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      points: points ?? this.points,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id']! as int,
      name: map['name']! as String,
      points: (map['points'] as int?) ?? 0,
      avatarPath: map['avatar_path'] as String?,
    );
  }
}

class ProfileStats {
  const ProfileStats({
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.points,
  });

  final int total;
  final int correct;
  final int incorrect;
  final int points;

  int get active => total - correct - incorrect;

  double get accuracy {
    final settled = correct + incorrect;
    if (settled == 0) {
      return 0;
    }
    return correct / settled;
  }
}
