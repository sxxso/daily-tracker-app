import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../services/database_service.dart';
import '../utils/date_utils.dart';
import '../utils/habit_stats.dart';

/// 习惯与打卡的状态中心。持有全部习惯 + 打卡索引，供各页面直接派生统计。
class HabitProvider extends ChangeNotifier {
  HabitProvider(this._db);

  final DatabaseService _db;

  List<Habit> _habits = [];
  Map<int, Set<String>> _checkInKeys = {};
  bool _loading = true;

  List<Habit> get habits => _habits;
  bool get loading => _loading;

  /// 今日已打卡的习惯 id
  Set<int> get todayCheckedIds {
    final key = DateUtilsX.key(DateTime.now());
    return {
      for (final entry in _checkInKeys.entries)
        if (entry.value.contains(key)) entry.key,
    };
  }

  int get todayCompletedCount => todayCheckedIds.length;
  int get todayTotalCount => _habits.length;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _habits = await _db.getHabits();
    _checkInKeys = await _db.getAllCheckInKeys();
    _loading = false;
    notifyListeners();
  }

  // ------------------------------------------------------------ 习惯增删改

  Future<void> addHabit(Habit habit) async {
    await _db.insertHabit(habit);
    await load();
  }

  Future<void> updateHabit(Habit habit) async {
    await _db.updateHabit(habit);
    await load();
  }

  Future<void> deleteHabit(int id) async {
    await _db.deleteHabit(id);
    await load();
  }

  Future<void> reorder(List<Habit> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      final h = ordered[i];
      if (h.sortOrder != i) {
        await _db.updateHabit(h.copyWith(sortOrder: i));
      }
    }
    await load();
  }

  // ---------------------------------------------------------------- 打卡

  /// 切换某习惯在指定日期的打卡状态，返回切换后是否为「已打卡」
  Future<bool> toggleCheckIn(int habitId, {DateTime? date}) async {
    final day = date ?? DateTime.now();
    final key = DateUtilsX.key(day);
    final set = _checkInKeys[habitId] ?? <String>{};
    final willCheck = !set.contains(key);

    if (willCheck) {
      await _db.checkIn(habitId, at: day);
    } else {
      await _db.undoCheckIn(habitId, day);
    }

    // 本地索引同步更新，避免整表重查造成的闪烁
    final updated = {...set};
    if (willCheck) {
      updated.add(key);
    } else {
      updated.remove(key);
    }
    _checkInKeys[habitId] = updated;
    notifyListeners();
    return willCheck;
  }

  bool isChecked(int habitId, DateTime date) =>
      _checkInKeys[habitId]?.contains(DateUtilsX.key(date)) ?? false;

  Set<String> keysFor(int habitId) => _checkInKeys[habitId] ?? <String>{};

  /// 某天的打卡数量
  int countOn(DateTime date) {
    final key = DateUtilsX.key(date);
    var n = 0;
    for (final set in _checkInKeys.values) {
      if (set.contains(key)) n++;
    }
    return n;
  }

  // ---------------------------------------------------------------- 统计

  /// 当前连续打卡天数。今天未打卡不算中断（从昨天继续数）。
  int currentStreak(int habitId, {DateTime? now}) =>
      HabitStats.currentStreak(keysFor(habitId), now: now);

  int longestStreak(int habitId) => HabitStats.longestStreak(keysFor(habitId));

  /// 累计打卡次数
  int totalCheckIns(int habitId) => _checkInKeys[habitId]?.length ?? 0;

  /// 近 n 天的完成率（0.0 - 1.0）
  double completionRate(int habitId, {int days = 30, DateTime? now}) =>
      HabitStats.completionRate(keysFor(habitId), days: days, now: now);

  /// 本周（周一至周日）已打卡天数
  int thisWeekCount(int habitId, {DateTime? now}) =>
      HabitStats.countThisWeek(keysFor(habitId), now: now);

  /// 近 n 天每日总打卡数，用于趋势图
  List<MapEntry<DateTime, int>> trend(int days, {DateTime? now}) {
    return DateUtilsX.lastNDays(days, now: now)
        .map((d) => MapEntry(d, countOn(d)))
        .toList();
  }

  /// 今日所有习惯的完成情况
  List<({Habit habit, bool done, int streak})> todayOverview() {
    return _habits
        .map((h) => (
              habit: h,
              done: isChecked(h.id!, DateTime.now()),
              streak: currentStreak(h.id!),
            ))
        .toList();
  }
}
