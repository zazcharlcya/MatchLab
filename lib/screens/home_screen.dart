import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/football_match.dart';
import '../models/loading_status.dart';
import '../theme/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/empty_state.dart';
import '../widgets/match_card.dart';
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
        context.read<HomeViewModel>().load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MatchLab'),
            Text(
              'Футбольная аналитика',
              style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w400),
            ),
          ],
        ),
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
              child: Text(vm.errorMessage!, style: const TextStyle(color: AppColors.danger)),
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
      selectedColor: AppColors.accentDim,
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
      onRefresh: vm.load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final match = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MatchCard(
              match: match,
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
      await context.read<HomeViewModel>().load();
    }
  }
}
