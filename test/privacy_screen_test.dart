import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/legal/privacy_policy.dart';
import 'package:matchlab/screens/privacy_screen.dart';
import 'package:matchlab/theme/app_theme.dart';

void main() {
  testWidgets('политика конфиденциальности открывается и читается', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const PrivacyScreen(),
      ),
    );
    expect(find.text(privacyPolicyTitle), findsOneWidget);
    expect(find.textContaining('ставки'), findsOneWidget);
    expect(find.textContaining('Камера'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
