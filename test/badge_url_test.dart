import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/services/badge_url.dart';
import 'package:matchlab/theme/league_identity.dart';

void main() {
  test('Wikimedia SVG превращается в PNG-превью', () {
    const svg =
        'https://upload.wikimedia.org/wikipedia/commons/1/1f/Logo_FC_Bayern_Muenchen.svg';
    expect(
      BadgeUrl.displayUrl(svg),
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Logo_FC_Bayern_Muenchen.svg/250px-Logo_FC_Bayern_Muenchen.svg.png',
    );
  });

  test('обычный PNG не трогаем', () {
    const png = 'https://i.imgur.com/v0tkpNx.png';
    expect(BadgeUrl.displayUrl(png), png);
  });

  test('http-эмблема поднимается до https', () {
    expect(
      BadgeUrl.displayUrl('http://example.com/badge.png'),
      'https://example.com/badge.png',
    );
  });

  test('Бундеслига даёт флаг Германии', () {
    final identity = LeagueIdentity.of('1. Fußball-Bundesliga 2026/2027');
    expect(identity.flag, '🇩🇪');
    expect(identity.country, 'Германия');
    expect(identity.shortLeague, 'Bundesliga');
  });
}
