import 'package:flutter/material.dart';

class AppColors {
  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.accent,
    required this.accentDim,
    required this.text,
    required this.muted,
    required this.warning,
    required this.danger,
    required this.away,
    required this.badgeFill,
    required this.badgeBorder,
  });

  final Color background;
  final Color surface;
  final Color card;
  final Color accent;
  final Color accentDim;
  final Color text;
  final Color muted;
  final Color warning;
  final Color danger;
  final Color away;
  final Color badgeFill;
  final Color badgeBorder;

  static const dark = AppColors(
    background: Color(0xFF101216),
    surface: Color(0xFF171B21),
    card: Color(0xFF1E242C),
    accent: Color(0xFF2EE6A6),
    accentDim: Color(0xFF1A3D34),
    text: Color(0xFFE8EDF2),
    muted: Color(0xFF8B95A1),
    warning: Color(0xFFE6C15A),
    danger: Color(0xFFE57373),
    away: Color(0xFF4C8DFF),
    badgeFill: Color(0xFF252B34),
    badgeBorder: Color(0xFF3A4450),
  );

  static const light = AppColors(
    background: Color(0xFFF3F5F7),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    accent: Color(0xFF0C9B74),
    accentDim: Color(0xFFD5F4EA),
    text: Color(0xFF1B2128),
    muted: Color(0xFF66707C),
    warning: Color(0xFFB8860B),
    danger: Color(0xFFC44545),
    away: Color(0xFF2F6FE0),
    badgeFill: Color(0xFFE8ECF0),
    badgeBorder: Color(0xFFD0D6DD),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

class AppTheme {
  static ThemeData dark() => _from(AppColors.dark, Brightness.dark);

  static ThemeData light() => _from(AppColors.light, Brightness.light);

  static ThemeData _from(AppColors colors, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: brightness == Brightness.dark ? const Color(0xFF06281D) : Colors.white,
      secondary: colors.away,
      onSecondary: Colors.white,
      surface: colors.surface,
      onSurface: colors.text,
      error: colors.danger,
      onError: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        hintStyle: TextStyle(color: colors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.muted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: colors.badgeBorder,
    );
  }
}

const _shortMonths = [
  'янв',
  'фев',
  'мар',
  'апр',
  'мая',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек',
];

const _fullMonths = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String formatKickoff(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_shortMonths[local.month - 1]}, ${formatClock(local)}';
}

String formatClock(DateTime value) {
  final local = value.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String formatHistoryDay(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) {
    return 'Сегодня';
  }
  if (day == today.subtract(const Duration(days: 1))) {
    return 'Вчера';
  }
  return '${local.day} ${_fullMonths[local.month - 1]} ${local.year}';
}

String percent(double value) => '${(value * 100).round()}%';
