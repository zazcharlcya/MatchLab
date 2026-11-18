import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/football_match.dart';
import '../models/loading_status.dart';
import '../models/match_outcome.dart';
import '../prediction_engine/prediction_engine.dart';
import '../repositories/match_repository.dart';
import '../repositories/prediction_repository.dart';
import '../services/app_logger.dart';
import '../theme/app_theme.dart';
import '../viewmodels/match_viewmodel.dart';
import '../widgets/probability_bar.dart';

class MatchDetailsScreen extends StatelessWidget {
  const MatchDetailsScreen({super.key, required this.match});

  final FootballMatch match;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MatchViewModel(
        match: match,
        matchRepository: context.read<MatchRepository>(),
        predictionRepository: context.read<PredictionRepository>(),
        engine: context.read<PredictionEngine>(),
        logger: context.read<AppLog>(),
      )..load(),
      child: const _MatchDetailsView(),
    );
  }
}

class _MatchDetailsView extends StatelessWidget {
  const _MatchDetailsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MatchViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика матча')),
      body: switch (vm.status) {
        LoadingStatus.loading || LoadingStatus.initial => const Center(
            child: CircularProgressIndicator(),
          ),
        LoadingStatus.error => Center(child: Text(vm.errorMessage ?? 'Ошибка')),
        LoadingStatus.success => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${vm.match.homeTeam} — ${vm.match.awayTeam}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '${vm.match.league} · ${formatKickoff(vm.match.kickoff)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              if (vm.match.venue != null) ...[
                const SizedBox(height: 4),
                Text(vm.match.venue!, style: const TextStyle(color: AppColors.muted)),
              ],
              const SizedBox(height: 16),
              _section(
                'Модель MatchLab',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Elo: ${vm.forecast.homeElo.round()} — ${vm.forecast.awayElo.round()}'),
                    Text(
                      'Ожидаемые голы: ${vm.forecast.expectedHomeGoals.toStringAsFixed(2)} — ${vm.forecast.expectedAwayGoals.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    ProbabilityBar(
                      home: vm.forecast.homeWin,
                      draw: vm.forecast.draw,
                      away: vm.forecast.awayWin,
                    ),
                    const SizedBox(height: 12),
                    const Text('Вероятные счета', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final score in vm.forecast.topScores)
                          Chip(
                            label: Text('${score.label} ${percent(score.probability)}'),
                            backgroundColor: AppColors.accentDim,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _section(
                'Последние результаты',
                vm.recent.isEmpty
                    ? const Text(
                        'Истории по этим командам в выборке пока нет. Модель использует средние лиги.',
                        style: TextStyle(color: AppColors.muted),
                      )
                    : Column(
                        children: [
                          for (final item in vm.recent.take(6))
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text('${item.homeTeam} ${item.scoreLabel} ${item.awayTeam}'),
                              subtitle: Text(item.league),
                            ),
                        ],
                      ),
              ),
              _section('Ваш прогноз', _PredictionForm(vm: vm)),
            ],
          ),
      },
    );
  }

  Widget _section(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PredictionForm extends StatelessWidget {
  const _PredictionForm({required this.vm});

  final MatchViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final outcome in MatchOutcome.values)
              ChoiceChip(
                label: Text(outcome.fullLabel),
                selected: vm.selected == outcome,
                onSelected: vm.match.canPredict ? (_) => vm.select(outcome) : null,
                selectedColor: AppColors.accentDim,
              ),
          ],
        ),
        if (vm.formError != null) ...[
          const SizedBox(height: 8),
          Text(vm.formError!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: vm.match.canPredict
              ? () async {
                  final ok = await vm.save();
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Прогноз сохранён. Баллы только за верный исход.')),
                    );
                  }
                }
              : null,
          child: Text(vm.existing == null ? 'Сохранить прогноз' : 'Изменить прогноз'),
        ),
        if (vm.existing != null && vm.existing!.canEdit)
          TextButton(
            onPressed: () async {
              await vm.remove();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Прогноз удалён')),
                );
              }
            },
            child: const Text('Удалить прогноз'),
          ),
      ],
    );
  }
}
