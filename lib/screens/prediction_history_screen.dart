import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loading_status.dart';
import '../models/user_prediction.dart';
import '../theme/app_theme.dart';
import '../viewmodels/predictions_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/empty_state.dart';
import '../widgets/mb_coin_chip.dart';
import '../widgets/prediction_card.dart';
import 'match_details_screen.dart';

enum PredictionHistoryKind { all, correct, incorrect }

class PredictionHistoryScreen extends StatefulWidget {
  const PredictionHistoryScreen({
    super.key,
    required this.kind,
  });

  final PredictionHistoryKind kind;

  String get title {
    return switch (kind) {
      PredictionHistoryKind.all => 'Все прогнозы',
      PredictionHistoryKind.correct => 'Верные',
      PredictionHistoryKind.incorrect => 'Неверные',
    };
  }

  @override
  State<PredictionHistoryScreen> createState() => _PredictionHistoryScreenState();
}

class _PredictionHistoryScreenState extends State<PredictionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PredictionsViewModel>().load();
    });
  }

  List<UserPrediction> _filtered(List<UserPrediction> items) {
    return items.where((item) {
      return switch (widget.kind) {
        PredictionHistoryKind.all => true,
        PredictionHistoryKind.correct => item.status == PredictionStatus.correct,
        PredictionHistoryKind.incorrect => item.status == PredictionStatus.incorrect,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PredictionsViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [MbCoinChip()],
      ),
      body: _body(vm),
    );
  }

  Widget _body(PredictionsViewModel vm) {
    if (vm.status == LoadingStatus.loading || vm.status == LoadingStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.status == LoadingStatus.error) {
      return EmptyState(title: 'Ошибка', subtitle: vm.errorMessage ?? '');
    }
    final items = _filtered(vm.items);
    if (items.isEmpty) {
      return const EmptyState(
        emoji: '🙁',
        title: 'Тут пока пусто',
        subtitle: 'Как появится история, она будет здесь — по времени, от новых к старым.',
      );
    }
    final groups = _groupByDay(items);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8, top: index == 0 ? 4 : 16),
              child: Text(
                group.$1,
                style: TextStyle(
                  color: AppColors.of(context).muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            for (final item in group.$2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PredictionCard(
                  prediction: item,
                  onOpen: item.match == null ? null : () => _openMatch(item),
                ),
              ),
          ],
        );
      },
    );
  }

  List<(String, List<UserPrediction>)> _groupByDay(List<UserPrediction> items) {
    final groups = <String, List<UserPrediction>>{};
    final order = <String>[];
    for (final item in items) {
      final label = formatHistoryDay(item.createdAt);
      final bucket = groups.putIfAbsent(label, () {
        order.add(label);
        return <UserPrediction>[];
      });
      bucket.add(item);
    }
    return [for (final label in order) (label, groups[label]!)];
  }

  Future<void> _openMatch(UserPrediction item) async {
    final match = item.match;
    if (match == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchDetailsScreen(match: match),
      ),
    );
    if (!mounted) {
      return;
    }
    final predictions = context.read<PredictionsViewModel>();
    final profile = context.read<ProfileViewModel>();
    await predictions.load();
    try {
      await profile.refreshStats();
    } catch (_) {}
  }
}
