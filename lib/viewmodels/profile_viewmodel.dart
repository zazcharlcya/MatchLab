import 'package:flutter/foundation.dart';

import '../models/loading_status.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';
import '../services/app_logger.dart';
import '../services/camera_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required UserRepository userRepository,
    required AppLog logger,
  })  : _userRepository = userRepository,
        _logger = logger;

  final UserRepository _userRepository;
  final AppLog _logger;

  LoadingStatus status = LoadingStatus.initial;
  String? errorMessage;
  String? cameraMessage;
  String? nameError;
  UserProfile? profile;
  ProfileStats stats = const ProfileStats(
    total: 0,
    correct: 0,
    incorrect: 0,
    points: 0,
  );
  String nameDraft = '';

  Future<void> load() async {
    status = LoadingStatus.loading;
    cameraMessage = null;
    notifyListeners();
    try {
      profile = await _userRepository.getUser();
      stats = await _userRepository.stats();
      nameDraft = profile?.name ?? '';
      status = LoadingStatus.success;
    } catch (error, stack) {
      _logger.error('Profile: ошибка загрузки', error, stack);
      errorMessage = 'Не удалось загрузить профиль.';
      status = LoadingStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshStats() async {
    try {
      profile = await _userRepository.getUser();
      stats = await _userRepository.stats();
      notifyListeners();
    } catch (error, stack) {
      _logger.error('Profile: ошибка обновления баллов', error, stack);
    }
  }

  bool validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      nameError = 'Введите имя — поле не может быть пустым.';
      notifyListeners();
      return false;
    }
    if (trimmed.length < 2) {
      nameError = 'Имя должно содержать минимум 2 символа.';
      notifyListeners();
      return false;
    }
    if (trimmed.length > 24) {
      nameError = 'Имя не длиннее 24 символов.';
      notifyListeners();
      return false;
    }
    if (!RegExp(r"^[A-Za-zА-Яа-яЁё\s\-]+$").hasMatch(trimmed)) {
      nameError = 'Только буквы, пробел и дефис.';
      notifyListeners();
      return false;
    }
    nameError = null;
    return true;
  }

  Future<bool> saveName(String value) async {
    if (!validateName(value)) {
      return false;
    }
    await _userRepository.updateName(value.trim());
    await load();
    return true;
  }

  Future<void> captureAvatar() async {
    cameraMessage = null;
    notifyListeners();
    try {
      final path = await _userRepository.updateAvatarFromCamera();
      if (path == null) {
        cameraMessage = 'Фото не сделано — можно продолжить без аватара.';
      }
      await load();
    } on CameraPermissionDenied catch (error) {
      cameraMessage = error.toString();
      _logger.info('Profile: отказ в разрешении камеры');
      notifyListeners();
    } catch (error, stack) {
      _logger.error('Profile: ошибка камеры', error, stack);
      cameraMessage = 'Не удалось открыть камеру. Приложение работает без фото.';
      notifyListeners();
    }
  }
}
