import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/theme/app_theme.dart';

void main() {
  test('formatKickoff показывает день и время', () {
    final value = DateTime(2026, 11, 18, 21, 5);
    expect(formatKickoff(value), '18 ноя, 21:05');
    expect(formatClock(value), '21:05');
  });

  test('formatHistoryDay отличает сегодня и вчера', () {
    final now = DateTime.now();
    expect(formatHistoryDay(now), 'Сегодня');
    expect(formatHistoryDay(now.subtract(const Duration(days: 1))), 'Вчера');
  });
}
