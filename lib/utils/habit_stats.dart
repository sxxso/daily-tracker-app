import 'date_utils.dart';

/// 打卡统计的纯函数集合。
///
/// 输入统一是「该习惯所有打卡日期的 yyyy-MM-dd 集合」，不依赖数据库和
/// Flutter 运行时，因此可以直接单元测试。
class HabitStats {
  const HabitStats._();

  /// 当前连续打卡天数。
  ///
  /// 今天尚未打卡不算中断——从昨天继续往前数，这样用户在当天晚上打开
  /// App 时不会看到连续天数被清零。
  static int currentStreak(Set<String> keys, {DateTime? now}) {
    if (keys.isEmpty) return 0;

    var cursor = DateUtilsX.dateOnly(now ?? DateTime.now());
    if (!keys.contains(DateUtilsX.key(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!keys.contains(DateUtilsX.key(cursor))) return 0;
    }

    var streak = 0;
    while (keys.contains(DateUtilsX.key(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 历史最长连续天数
  static int longestStreak(Set<String> keys) {
    if (keys.isEmpty) return 0;

    final sorted = keys.toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]);
      final cur = DateTime.parse(sorted[i]);
      if (cur.difference(prev).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  /// 近 [days] 天完成率，0.0 - 1.0
  static double completionRate(
    Set<String> keys, {
    int days = 30,
    DateTime? now,
  }) {
    if (keys.isEmpty) return 0;
    final range = DateUtilsX.lastNDays(days, now: now);
    var hit = 0;
    for (final d in range) {
      if (keys.contains(DateUtilsX.key(d))) hit++;
    }
    return hit / days;
  }

  /// 指定日期是否已打卡
  static bool isCheckedOn(Set<String> keys, DateTime day) =>
      keys.contains(DateUtilsX.key(day));

  /// 本周（周一起）已打卡天数
  static int countThisWeek(Set<String> keys, {DateTime? now}) {
    final start = DateUtilsX.startOfWeek(now ?? DateTime.now());
    var n = 0;
    for (var i = 0; i < 7; i++) {
      if (keys.contains(DateUtilsX.key(start.add(Duration(days: i))))) n++;
    }
    return n;
  }
}
