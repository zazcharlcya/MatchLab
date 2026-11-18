import 'football_match.dart';
import 'match_outcome.dart';

enum PredictionStatus { active, correct, incorrect }

class UserPrediction {
  const UserPrediction({
    required this.id,
    required this.matchId,
    required this.chosenOutcome,
    required this.createdAt,
    required this.status,
    required this.pointsAwarded,
    this.actualOutcome,
    this.match,
  });

  final int id;
  final String matchId;
  final MatchOutcome chosenOutcome;
  final DateTime createdAt;
  final PredictionStatus status;
  final int pointsAwarded;
  final MatchOutcome? actualOutcome;
  final FootballMatch? match;

  bool get isActive => status == PredictionStatus.active;

  bool get canEdit {
    final current = match;
    return isActive && current != null && current.canPredict;
  }

  UserPrediction copyWith({
    MatchOutcome? chosenOutcome,
    PredictionStatus? status,
    int? pointsAwarded,
    MatchOutcome? actualOutcome,
    FootballMatch? match,
  }) {
    return UserPrediction(
      id: id,
      matchId: matchId,
      chosenOutcome: chosenOutcome ?? this.chosenOutcome,
      createdAt: createdAt,
      status: status ?? this.status,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      actualOutcome: actualOutcome ?? this.actualOutcome,
      match: match ?? this.match,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id == 0 ? null : id,
      'match_id': matchId,
      'chosen_outcome': chosenOutcome.storageValue,
      'actual_outcome': actualOutcome?.storageValue,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'points_awarded': pointsAwarded,
    };
  }

  factory UserPrediction.fromMap(Map<String, Object?> map) {
    final actual = map['actual_outcome'] as String?;
    return UserPrediction(
      id: map['id']! as int,
      matchId: map['match_id']! as String,
      chosenOutcome: MatchOutcomeLabel.fromStorage(map['chosen_outcome']! as String),
      createdAt: DateTime.parse(map['created_at']! as String),
      status: PredictionStatus.values.byName(map['status']! as String),
      pointsAwarded: (map['points_awarded'] as int?) ?? 0,
      actualOutcome: actual == null ? null : MatchOutcomeLabel.fromStorage(actual),
    );
  }
}
