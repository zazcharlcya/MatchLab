import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/predictions_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'home_screen.dart';
import 'predictions_screen.dart';
import 'profile_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          PredictionsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) {
          setState(() => _index = value);
          context.read<ProfileViewModel>().refreshStats();
          if (value == 1) {
            context.read<PredictionsViewModel>().load();
          }
          if (value == 2) {
            context.read<ProfileViewModel>().load();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Матчи'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Прогнозы'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }
}
