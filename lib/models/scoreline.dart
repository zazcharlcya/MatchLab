class Scoreline {
  const Scoreline({
    required this.homeGoals,
    required this.awayGoals,
    required this.probability,
  });

  final int homeGoals;
  final int awayGoals;
  final double probability;

  String get label => '$homeGoals:$awayGoals';
}
