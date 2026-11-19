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

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PredictionsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PredictionsViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои прогнозы'),
        actions: const [MbCoinChip()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                _chip(vm, PredictionListFilter.all, 'Все'),
                _chip(vm, PredictionListFilter.active, 'Активные'),
                _chip(vm, PredictionListFilter.correct, 'Верные'),
                _chip(vm, PredictionListFilter.incorrect, 'Неверные'),
              ],
            ),
          ),
          Expanded(child: _body(vm)),
        ],
      ),
    );
  }

  Widget _chip(PredictionsViewModel vm, PredictionListFilter value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: vm.filter == value,
      onSelected: (_) => vm.setFilter(value),
      selectedColor: AppColors.of(context).accentDim,
    );
  }

  Widget _body(PredictionsViewModel vm) {
    if (vm.status == LoadingStatus.loading || vm.status == LoadingStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.status == LoadingStatus.error) {
      return EmptyState(title: 'Ошибка', subtitle: vm.errorMessage ?? '');
    }
    final items = vm.visible;
    if (items.isEmpty) {
      return const EmptyState(
        title: 'Прогнозов нет',
        subtitle: 'Откройте матч и сохраните исход. Это бесплатно, без ставок.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PredictionCard(
            prediction: item,
            onOpen: item.match == null ? null : () => _openMatch(item),
            onDelete: item.canEdit ? () => vm.delete(item) : null,
          ),
        );
      },
    );
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
    if (mounted) {
      await context.read<PredictionsViewModel>().load();
      try {
        await context.read<ProfileViewModel>().refreshStats();
      } catch (_) {}
    }
  }
}
