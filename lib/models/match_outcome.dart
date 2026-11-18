enum MatchOutcome {
  homeWin,
  draw,
  awayWin,
}

extension MatchOutcomeLabel on MatchOutcome {
  String get shortLabel {
    switch (this) {
      case MatchOutcome.homeWin:
        return 'П1';
      case MatchOutcome.draw:
        return 'X';
      case MatchOutcome.awayWin:
        return 'П2';
    }
  }

  String get fullLabel {
    switch (this) {
      case MatchOutcome.homeWin:
        return 'Победа хозяев';
      case MatchOutcome.draw:
        return 'Ничья';
      case MatchOutcome.awayWin:
        return 'Победа гостей';
    }
  }

  String get storageValue {
    switch (this) {
      case MatchOutcome.homeWin:
        return 'home';
      case MatchOutcome.draw:
        return 'draw';
      case MatchOutcome.awayWin:
        return 'away';
    }
  }

  static MatchOutcome fromStorage(String value) {
    switch (value) {
      case 'home':
        return MatchOutcome.homeWin;
      case 'draw':
        return MatchOutcome.draw;
      case 'away':
        return MatchOutcome.awayWin;
      default:
        throw FormatException('Unknown outcome: $value');
    }
  }

  static MatchOutcome fromScore(int homeScore, int awayScore) {
    if (homeScore > awayScore) {
      return MatchOutcome.homeWin;
    }
    if (homeScore < awayScore) {
      return MatchOutcome.awayWin;
    }
    return MatchOutcome.draw;
  }
}
