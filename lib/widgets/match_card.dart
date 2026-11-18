import 'package:flutter/material.dart';

import '../models/football_match.dart';
import '../models/match_outcome.dart';
import '../theme/app_theme.dart';
import 'probability_bar.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, required this.onTap});

  final FootballMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final forecast = match.forecast;
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
                      match.league,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                  Text(
                    match.isFinished ? match.scoreLabel : formatKickoff(match.kickoff),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                match.homeTeam,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                match.awayTeam,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (forecast != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Модель: ${forecast.pick.fullLabel}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
}
