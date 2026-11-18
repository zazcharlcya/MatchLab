import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loading_status.dart';
import '../theme/app_theme.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<ProfileViewModel>();
      await vm.load();
      _nameController.text = vm.nameDraft;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
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
                        backgroundColor: AppColors.accentDim,
                        backgroundImage: vm.profile?.avatarPath == null
                            ? null
                            : FileImage(File(vm.profile!.avatarPath!)),
                        child: vm.profile?.avatarPath == null
                            ? const Icon(Icons.person, size: 48, color: AppColors.accent)
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
                          style: const TextStyle(color: AppColors.warning),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    errorText: vm.nameError,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final ok = await vm.saveName(_nameController.text);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Имя сохранено')),
                      );
                    }
                  },
                  child: const Text('Сохранить имя'),
                ),
                const SizedBox(height: 24),
                _stat('Баллы', '${vm.stats.points}'),
                _stat('Всего прогнозов', '${vm.stats.total}'),
                _stat('Верные', '${vm.stats.correct}'),
                _stat('Неверные', '${vm.stats.incorrect}'),
                _stat('Точность', '${(vm.stats.accuracy * 100).round()}%'),
                const SizedBox(height: 16),
                const Text(
                  'Баллы виртуальные: начисляются только за правильный прогноз (+10). Без ставок, пополнений и вывода.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
