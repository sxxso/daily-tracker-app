import 'package:intl/intl.dart';

/// 日期处理工具：统一以「本地日期」为准做按天聚合
class DateUtilsX {
  static final DateFormat _keyFmt = DateFormat('yyyy-MM-dd');

  /// yyyy-MM-dd
  static String key(DateTime d) => _keyFmt.format(d);

  /// 去掉时分秒
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 一周起点为周一
  static DateTime startOfWeek(DateTime d) {
    final day = dateOnly(d);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

  /// 生成 [from, to] 之间（含端点）的连续日期列表
  static List<DateTime> daysBetween(DateTime from, DateTime to) {
    final start = dateOnly(from);
    final end = dateOnly(to);
    final days = <DateTime>[];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return days;
  }

  /// 最近 n 天（含今天），升序
  static List<DateTime> lastNDays(int n, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    return List.generate(
      n,
      (i) => today.subtract(Duration(days: n - 1 - i)),
    );
  }

  static String humanDate(DateTime d) {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(d);
    final diff = target.difference(today).inDays;
    if (diff == 0) return '今天';
    if (diff == -1) return '昨天';
    if (diff == 1) return '明天';
    return DateFormat('M月d日').format(d);
  }

  static String weekdayLabel(DateTime d) =>
      const ['一', '二', '三', '四', '五', '六', '日'][d.weekday - 1];

  /// 秒 -> mm:ss
  static String clock(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  /// 秒 -> 「1小时20分」这类可读文本
  static String durationText(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0 && m > 0) return '$h小时$m分';
    if (h > 0) return '$h小时';
    if (m > 0) return '$m分钟';
    return '$totalSeconds秒';
  }
}
