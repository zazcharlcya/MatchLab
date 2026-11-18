import 'package:flutter/material.dart';

import '../models/match_outcome.dart';
import '../models/user_prediction.dart';
import '../theme/app_theme.dart';

class PredictionCard extends StatelessWidget {
  const PredictionCard({
    super.key,
    required this.prediction,
    this.onDelete,
  });

  final UserPrediction prediction;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final match = prediction.match;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                    color: AppColors.muted,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ваш прогноз: ${prediction.chosenOutcome.fullLabel}',
              style: const TextStyle(color: AppColors.text),
            ),
            if (match?.isFinished == true)
              Text(
                'Факт: ${match!.scoreLabel} · ${prediction.actualOutcome?.fullLabel ?? '—'}',
                style: const TextStyle(color: AppColors.muted),
              ),
            const SizedBox(height: 8),
            Text(
              _statusText(),
              style: TextStyle(color: _statusColor(), fontWeight: FontWeight.w600),
            ),
          ],
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

  Color _statusColor() {
    switch (prediction.status) {
      case PredictionStatus.active:
        return AppColors.warning;
      case PredictionStatus.correct:
        return AppColors.accent;
      case PredictionStatus.incorrect:
        return AppColors.danger;
    }
  }
}
