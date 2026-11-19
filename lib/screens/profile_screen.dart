import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loading_status.dart';
import '../theme/app_theme.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/theme_controller.dart';
import '../widgets/mb_coin_chip.dart';
import 'prediction_history_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  late final TextEditingController _nameController;
  var _editingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<ProfileViewModel>();
      await vm.load();
      if (!mounted) {
        return;
      }
      _nameController.text = vm.nameDraft;
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final vm = context.read<ProfileViewModel>();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    final ok = await vm.saveName(_nameController.text);
    if (!ok || !mounted) {
      return;
    }
    _nameFocus.unfocus();
    setState(() => _editingName = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Имя сохранено')),
    );
  }

  void _startEditing() {
    setState(() => _editingName = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final colors = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: const [MbCoinChip()],
      ),
      body: vm.status == LoadingStatus.loading || vm.status == LoadingStatus.initial
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: colors.accentDim,
                        backgroundImage: vm.profile?.avatarPath == null
                            ? null
                            : FileImage(File(vm.profile!.avatarPath!)),
                        child: vm.profile?.avatarPath == null
                            ? Icon(Icons.person, size: 48, color: colors.accent)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: vm.captureAvatar,
                        child: const Text('Сделать фото для аватара'),
                      ),
                      if (vm.cameraMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          vm.cameraMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.warning),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: _editingName
                      ? TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.words,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: 'Имя',
                            suffixIcon: IconButton(
                              tooltip: 'Сохранить',
                              onPressed: _saveName,
                              icon: Icon(Icons.check, color: colors.accent),
                            ),
                          ),
                          validator: (value) {
                            vm.validateName(value ?? '');
                            return vm.nameError;
                          },
                          onFieldSubmitted: (_) => _saveName(),
                        )
                      : Material(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _startEditing,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Имя',
                                          style: TextStyle(color: colors.muted, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          vm.profile?.name ?? 'Аналитик',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.edit_outlined, color: colors.muted, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                _stat(
                  'Всего прогнозов',
                  '${vm.stats.total}',
                  onTap: () => _openHistory(PredictionHistoryKind.all),
                ),
                _stat(
                  'Верные',
                  '${vm.stats.correct}',
                  onTap: () => _openHistory(PredictionHistoryKind.correct),
                ),
                _stat(
                  'Неверные',
                  '${vm.stats.incorrect}',
                  onTap: () => _openHistory(PredictionHistoryKind.incorrect),
                ),
                _stat('Точность', '${(vm.stats.accuracy * 100).round()}%'),
                const SizedBox(height: 16),
                Text(
                  'Баллы виртуальные: начисляются только за правильный прогноз (+10). Без ставок, пополнений и вывода.',
                  style: TextStyle(color: colors.muted),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Конфиденциальность'),
                    trailing: Icon(Icons.chevron_right, color: colors.muted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Consumer<ThemeController>(
                    builder: (context, theme, _) {
                      final dark = theme.isDark;
                      return ActionChip(
                        avatar: Icon(
                          dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                          size: 18,
                          color: colors.accent,
                        ),
                        label: Text(dark ? 'Тёмная тема' : 'Светлая тема'),
                        onPressed: () => theme.setDark(!dark),
                        backgroundColor: colors.accentDim,
                        side: BorderSide.none,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _openHistory(PredictionHistoryKind kind) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PredictionHistoryScreen(kind: kind),
      ),
    );
    if (mounted) {
      await context.read<ProfileViewModel>().refreshStats();
    }
  }

  Widget _stat(String label, String value, {VoidCallback? onTap}) {
    final colors = AppColors.of(context);
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, color: colors.muted),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
