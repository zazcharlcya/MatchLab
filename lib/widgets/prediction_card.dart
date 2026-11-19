import 'package:flutter/material.dart';

import '../models/match_outcome.dart';
import '../models/user_prediction.dart';
import '../theme/app_theme.dart';
import 'team_badge.dart';

class PredictionCard extends StatelessWidget {
  const PredictionCard({
    super.key,
    required this.prediction,
    this.onOpen,
    this.onDelete,
  });

  final UserPrediction prediction;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final match = prediction.match;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (match != null) ...[
                    TeamBadge(name: match.homeTeam, url: match.homeBadge, size: 28),
                    const SizedBox(width: 6),
                    TeamBadge(name: match.awayTeam, url: match.awayBadge, size: 28),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      match == null
                          ? 'Матч ${prediction.matchId}'
                          : '${match.homeTeam} — ${match.awayTeam}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (prediction.canEdit && onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: colors.muted,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Сделан ${formatKickoff(prediction.createdAt)}',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                'Ваш прогноз: ${prediction.chosenOutcome.fullLabel}',
                style: TextStyle(color: colors.text),
              ),
              if (match?.isFinished == true)
                Text(
                  'Факт: ${match!.scoreLabel} · ${prediction.actualOutcome?.fullLabel ?? '—'}',
                  style: TextStyle(color: colors.muted),
                ),
              const SizedBox(height: 8),
              Text(
                _statusText(),
                style: TextStyle(color: _statusColor(colors), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText() {
    switch (prediction.status) {
      case PredictionStatus.active:
        return 'Активен · ждём результат';
      case PredictionStatus.correct:
        return 'Верно · +${prediction.pointsAwarded} баллов';
      case PredictionStatus.incorrect:
        return 'Неверно · 0 баллов';
    }
  }

  Color _statusColor(AppColors colors) {
    switch (prediction.status) {
      case PredictionStatus.active:
        return colors.warning;
      case PredictionStatus.correct:
        return colors.accent;
      case PredictionStatus.incorrect:
        return colors.danger;
    }
  }
}
