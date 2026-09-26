import 'package:flutter/material.dart';

/// 全局常量与主题配置
class AppConstants {
  static const String dbName = 'daily_tracker.db';
  static const int dbVersion = 1;

  static const String tableHabits = 'habits';
  static const String tableCheckIns = 'check_ins';
  static const String tablePomodoro = 'pomodoro_sessions';
  static const String tableSettings = 'app_settings';

  /// 番茄钟默认时长（分钟）
  static const int defaultFocusMinutes = 25;
  static const int defaultShortBreakMinutes = 5;
  static const int defaultLongBreakMinutes = 15;

  /// 每完成 N 个专注番茄后进入长休息
  static const int focusPerLongBreak = 4;

  static const List<String> weekDayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  static const List<Color> habitPalette = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];

  /// 可选习惯图标
  static const List<IconData> habitIcons = [
    Icons.check_circle_outline,
    Icons.fitness_center,
    Icons.menu_book,
    Icons.self_improvement,
    Icons.directions_run,
    Icons.local_drink,
    Icons.bedtime,
    Icons.code,
    Icons.brush,
    Icons.music_note,
    Icons.savings,
    Icons.cleaning_services,
  ];
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF121316),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E2024),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
