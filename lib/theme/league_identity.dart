/// OpenLigaDB не присылает страну команды. Для текущей выборки (bl1)
/// все клубы немецкие — страну берём из лиги, а не из выдуманного поля API.
class LeagueIdentity {
  const LeagueIdentity({
    required this.flag,
    required this.country,
    required this.shortLeague,
  });

  final String flag;
  final String country;
  final String shortLeague;

  String get caption => '$flag  $country · $shortLeague';

  static LeagueIdentity of(String league) {
    final lower = league.toLowerCase();
    if (lower.contains('bundesliga')) {
      return const LeagueIdentity(
        flag: '🇩🇪',
        country: 'Германия',
        shortLeague: 'Bundesliga',
      );
    }
    if (lower.contains('premier league')) {
      return const LeagueIdentity(
        flag: '🇬🇧',
        country: 'Англия',
        shortLeague: 'Premier League',
      );
    }
    return LeagueIdentity(
      flag: '⚽',
      country: '',
      shortLeague: league,
    );
  }
}
