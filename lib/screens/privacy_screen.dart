import 'package:flutter/material.dart';

import '../legal/privacy_policy.dart';
import '../theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(privacyPolicyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            privacyPolicyBody.trim(),
            style: TextStyle(color: colors.text, height: 1.45, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
