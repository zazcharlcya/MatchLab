import 'package:flutter/material.dart';

import '../repositories/user_repository.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({required UserRepository userRepository}) : _users = userRepository;

  final UserRepository _users;

  bool isDark = true;

  ThemeMode get mode => isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    isDark = await _users.isDarkTheme();
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    isDark = value;
    notifyListeners();
    await _users.setDarkTheme(value);
  }
}
