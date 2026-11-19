import 'package:flutter/material.dart';

import '../models/football_match.dart';
import '../models/match_outcome.dart';
import '../models/user_prediction.dart';
import '../theme/app_theme.dart';
import '../theme/league_identity.dart';
import 'probability_bar.dart';
import 'team_badge.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.userPrediction,
  });

  final FootballMatch match;
  final VoidCallback onTap;
  final UserPrediction? userPrediction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final forecast = match.forecast;
    final league = LeagueIdentity.of(match.league);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      league.caption,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ),
                  Text(
                    match.isFinished ? match.scoreLabel : formatKickoff(match.kickoff),
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _teamLine(match.homeTeam, match.homeBadge),
              const SizedBox(height: 10),
              _teamLine(match.awayTeam, match.awayBadge),
              if (userPrediction != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Ваш прогноз: ${userPrediction!.chosenOutcome.fullLabel}',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (forecast != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Модель: ${forecast.pick.fullLabel}',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ProbabilityBar(
                  home: forecast.homeWin,
                  draw: forecast.draw,
                  away: forecast.awayWin,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamLine(String name, String? badge) {
    return Row(
      children: [
        TeamBadge(name: name, url: badge, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
