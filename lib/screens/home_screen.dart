import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/football_match.dart';
import '../models/loading_status.dart';
import '../theme/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/empty_state.dart';
import '../widgets/match_card.dart';
import '../widgets/matchlab_brand.dart';
import '../widgets/mb_coin_chip.dart';
import 'match_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.loadOnStart = true});

  final bool loadOnStart;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.loadOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        () async {
          await context.read<HomeViewModel>().load();
          if (!mounted) {
            return;
          }
          try {
            await context.read<ProfileViewModel>().refreshStats();
          } catch (_) {}
        }();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const MatchLabBrand(),
        actions: const [MbCoinChip()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: vm.setQuery,
              decoration: const InputDecoration(
                hintText: 'Поиск по команде',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                _chip(vm, MatchListFilter.all, 'Все'),
                _chip(vm, MatchListFilter.upcoming, 'Предстоят'),
                _chip(vm, MatchListFilter.finished, 'Завершены'),
              ],
            ),
          ),
          if (vm.status == LoadingStatus.error && vm.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                vm.errorMessage!,
                style: TextStyle(color: AppColors.of(context).danger),
              ),
            ),
          Expanded(child: _body(context, vm)),
        ],
      ),
    );
  }

  Widget _chip(HomeViewModel vm, MatchListFilter value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: vm.filter == value,
      onSelected: (_) => vm.setFilter(value),
      selectedColor: AppColors.of(context).accentDim,
    );
  }

  Widget _body(BuildContext context, HomeViewModel vm) {
    if (vm.status == LoadingStatus.loading || vm.status == LoadingStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = vm.visible;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyState(
              title: 'Матчей нет',
              subtitle: 'Список пуст. Потяните вниз, чтобы обновить данные.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await vm.load();
        if (context.mounted) {
          try {
            await context.read<ProfileViewModel>().refreshStats();
          } catch (_) {}
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final match = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MatchCard(
              match: match,
              userPrediction: vm.predictionFor(match),
              onTap: () => _openDetails(context, match),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, FootballMatch match) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchDetailsScreen(match: match),
      ),
    );
    if (context.mounted) {
      await context.read<HomeViewModel>().refreshPredictions();
      try {
        await context.read<ProfileViewModel>().refreshStats();
      } catch (_) {}
    }
  }
}
