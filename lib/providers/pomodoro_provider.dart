import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pomodoro_session.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/pomodoro_rules.dart';

enum TimerStatus { idle, running, paused, finished }

/// 番茄钟状态机。
///
/// 计时不依赖 Timer.periodic 的累计次数（App 切后台会被节流），
/// 而是每 tick 用「墙钟时间 - 起始时间」重算剩余秒数，保证后台回来仍然准确。
class PomodoroProvider extends ChangeNotifier {
  PomodoroProvider(this._db);

  final DatabaseService _db;
  Timer? _ticker;

  // ------------------------------------------------------------ 时长配置

  int focusMinutes = AppConstants.defaultFocusMinutes;
  int shortBreakMinutes = AppConstants.defaultShortBreakMinutes;
  int longBreakMinutes = AppConstants.defaultLongBreakMinutes;
  bool autoStartNext = false;
  bool soundEnabled = true;

  // ------------------------------------------------------------ 运行状态

  TimerStatus status = TimerStatus.idle;
  PomodoroPhase phase = PomodoroPhase.focus;
  String label = '';
  int? linkedHabitId;

  /// 本阶段计划时长（秒）
  int plannedSeconds = AppConstants.defaultFocusMinutes * 60;

  /// 剩余秒数
  int remainingSeconds = AppConstants.defaultFocusMinutes * 60;

  /// 当前阶段实际已流逝秒数（用于记录 interrupted 时的真实时长）
  int elapsedSeconds = 0;

  DateTime? _phaseStartedAt;

  /// 今日统计
  int todayFocusCount = 0;
  int todayFocusSeconds = 0;

  /// 最近完成的会话（用于历史列表）
  List<PomodoroSession> recentSessions = [];

  bool get isRunning => status == TimerStatus.running;
  bool get isIdle => status == TimerStatus.idle;
  bool get isFocus => phase == PomodoroPhase.focus;

  /// 计时正在进行或暂停中（用于底部导航的运行指示点）
  bool get isActive =>
      status == TimerStatus.running || status == TimerStatus.paused;

  double get progress {
    if (plannedSeconds <= 0) return 0;
    final done = plannedSeconds - remainingSeconds;
    return (done / plannedSeconds).clamp(0.0, 1.0);
  }

  /// 今日已完成专注番茄数（含未落库的当前这一个）
  int get focusCountToday => todayFocusCount;

  String get phaseLabel => switch (phase) {
        PomodoroPhase.focus => '专注中',
        PomodoroPhase.shortBreak => '短休息',
        PomodoroPhase.longBreak => '长休息',
      };

  // ------------------------------------------------------------ 初始化

  Future<void> init() async {
    await _loadSettings();
    plannedSeconds = focusMinutes * 60;
    remainingSeconds = plannedSeconds;
    await refreshTodayStats();
    await loadRecentSessions();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    focusMinutes = await _readInt('focus_minutes', AppConstants.defaultFocusMinutes);
    shortBreakMinutes =
        await _readInt('short_break_minutes', AppConstants.defaultShortBreakMinutes);
    longBreakMinutes =
        await _readInt('long_break_minutes', AppConstants.defaultLongBreakMinutes);
    autoStartNext = (await _db.getSetting('auto_start_next')) == 'true';
    soundEnabled = (await _db.getSetting('sound_enabled')) != 'false';
  }

  Future<int> _readInt(String key, int fallback) async {
    final raw = await _db.getSetting(key);
    return int.tryParse(raw ?? '') ?? fallback;
  }

  Future<void> updateSettings({
    int? focus,
    int? shortBreak,
    int? longBreak,
    bool? autoStart,
    bool? sound,
  }) async {
    if (focus != null) {
      focusMinutes = focus;
      await _db.setSetting('focus_minutes', '$focus');
    }
    if (shortBreak != null) {
      shortBreakMinutes = shortBreak;
      await _db.setSetting('short_break_minutes', '$shortBreak');
    }
    if (longBreak != null) {
      longBreakMinutes = longBreak;
      await _db.setSetting('long_break_minutes', '$longBreak');
    }
    if (autoStart != null) {
      autoStartNext = autoStart;
      await _db.setSetting('auto_start_next', '$autoStart');
    }
    if (sound != null) {
      soundEnabled = sound;
      await _db.setSetting('sound_enabled', '$sound');
    }
    // 空闲状态下调整专注时长需立即反映到表盘
    if (isIdle && phase == PomodoroPhase.focus) {
      plannedSeconds = focusMinutes * 60;
      remainingSeconds = plannedSeconds;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ 计时控制

  void start({String? taskLabel, int? habitId}) {
    if (taskLabel != null) label = taskLabel;
    if (habitId != null) linkedHabitId = habitId;

    if (status == TimerStatus.paused) {
      // 从暂停恢复：重置墙钟基准，避免暂停期间被计入
      _phaseStartedAt = DateTime.now().subtract(Duration(seconds: elapsedSeconds));
      status = TimerStatus.running;
      _startTicker();
      _schedulePhaseNotification();
      notifyListeners();
      return;
    }

    if (status == TimerStatus.running) return;

    plannedSeconds = _plannedFor(phase);
    remainingSeconds = plannedSeconds;
    elapsedSeconds = 0;
    _phaseStartedAt = DateTime.now();
    status = TimerStatus.running;
    _startTicker();
    _schedulePhaseNotification();
    notifyListeners();
  }

  void pause() {
    if (status != TimerStatus.running) return;
    _ticker?.cancel();
    _ticker = null;
    status = TimerStatus.paused;
    _cancelPhaseNotification();
    notifyListeners();
  }

  /// 放弃当前阶段。专注阶段会被记为「中断」并落库。
  Future<void> stop({bool record = true}) async {
    _ticker?.cancel();
    _ticker = null;
    _cancelPhaseNotification();

    if (record && phase == PomodoroPhase.focus && elapsedSeconds >= 60) {
      await _persistSession(interrupted: true);
    }

    status = TimerStatus.idle;
    phase = PomodoroPhase.focus;
    plannedSeconds = focusMinutes * 60;
    remainingSeconds = plannedSeconds;
    elapsedSeconds = 0;
    _phaseStartedAt = null;
    await refreshTodayStats();
    notifyListeners();
  }

  /// 跳过当前阶段（休息阶段常用）
  Future<void> skip() async {
    _ticker?.cancel();
    _ticker = null;
    _cancelPhaseNotification();

    // 跳过专注时不计入完成数，但已投入的时间照实记录
    if (phase == PomodoroPhase.focus && elapsedSeconds >= 60) {
      await _persistSession(interrupted: true);
    }
    _advancePhase(completedFocusCount: todayFocusCount);

    status = autoStartNext ? TimerStatus.running : TimerStatus.idle;
    if (status == TimerStatus.running) {
      _phaseStartedAt = DateTime.now();
      _startTicker();
      _schedulePhaseNotification();
    } else {
      elapsedSeconds = 0;
      _phaseStartedAt = null;
    }
    await refreshTodayStats();
    notifyListeners();
  }

  /// 手动切到指定阶段（点表盘上的模式按钮）
  void switchPhase(PomodoroPhase target) {
    _ticker?.cancel();
    _ticker = null;
    _cancelPhaseNotification();
    phase = target;
    plannedSeconds = _plannedFor(target);
    remainingSeconds = plannedSeconds;
    elapsedSeconds = 0;
    _phaseStartedAt = null;
    status = TimerStatus.idle;
    notifyListeners();
  }

  int _plannedFor(PomodoroPhase p) => switch (p) {
        PomodoroPhase.focus => focusMinutes * 60,
        PomodoroPhase.shortBreak => shortBreakMinutes * 60,
        PomodoroPhase.longBreak => longBreakMinutes * 60,
      };

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (status != TimerStatus.running || _phaseStartedAt == null) return;

    final passed = DateTime.now().difference(_phaseStartedAt!).inSeconds;
    elapsedSeconds = passed.clamp(0, plannedSeconds);
    remainingSeconds = (plannedSeconds - passed).clamp(0, plannedSeconds);

    if (remainingSeconds <= 0) {
      _onPhaseComplete();
      return;
    }
    notifyListeners();
  }

  Future<void> _onPhaseComplete() async {
    _ticker?.cancel();
    _ticker = null;
    _cancelPhaseNotification();
    elapsedSeconds = plannedSeconds;
    remainingSeconds = 0;

    final wasFocus = phase == PomodoroPhase.focus;
    if (wasFocus) {
      await _persistSession(interrupted: false);
    }

    status = TimerStatus.finished;
    notifyListeners();

    // 短暂展示「完成」状态后自动进入下一阶段
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // 先刷新今日统计，再用更新后的完成数决定该短休息还是长休息
    await refreshTodayStats();
    _advancePhase(completedFocusCount: todayFocusCount);
    status = autoStartNext ? TimerStatus.running : TimerStatus.idle;
    if (status == TimerStatus.running) {
      _phaseStartedAt = DateTime.now();
      elapsedSeconds = 0;
      _startTicker();
      _schedulePhaseNotification();
    } else {
      elapsedSeconds = 0;
      _phaseStartedAt = null;
    }
    notifyListeners();
  }

  /// 把「本阶段结束」预排进系统闹钟，App 退到后台也能按时提醒。
  void _schedulePhaseNotification() {
    if (!soundEnabled) return;
    final fireAt = DateTime.now().add(Duration(seconds: remainingSeconds));
    NotificationService.instance.scheduleAt(
      fireAt: fireAt,
      title: phase == PomodoroPhase.focus ? '专注完成' : '休息结束',
      body: phase == PomodoroPhase.focus ? '起来活动一下吧' : '继续下一个番茄',
    );
  }

  void _cancelPhaseNotification() {
    NotificationService.instance.cancelScheduled();
  }

  /// 专注 -> 休息；休息 -> 专注。
  ///
  /// [completedFocusCount] 必须是「已落库的今日完成数」（含刚结束的这一个），
  /// 否则第 1 个番茄就会误判成长休息。
  void _advancePhase({required int completedFocusCount}) {
    if (phase == PomodoroPhase.focus) {
      phase = PomodoroRules.nextBreakPhase(
        completedFocusCount: completedFocusCount,
        focusPerLongBreak: AppConstants.focusPerLongBreak,
      );
    } else {
      phase = PomodoroPhase.focus;
    }
    plannedSeconds = _plannedFor(phase);
    remainingSeconds = plannedSeconds;
    elapsedSeconds = 0;
  }

  Future<void> _persistSession({required bool interrupted}) async {
    final session = PomodoroSession(
      habitId: linkedHabitId,
      label: label,
      plannedMinutes: plannedSeconds ~/ 60,
      actualSeconds: elapsedSeconds,
      phase: phase,
      interrupted: interrupted,
      startedAt: _phaseStartedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
    );
    await _db.insertPomodoro(session);
  }

  // ------------------------------------------------------------ 统计与历史

  Future<void> refreshTodayStats() async {
    final today = DateTime.now();
    final stats = await _db.getPomodoroDailyStats(from: today, to: today);
    final entry = stats[DateUtilsX.key(today)];
    todayFocusCount = entry?['count'] ?? 0;
    todayFocusSeconds = entry?['seconds'] ?? 0;
  }

  Future<void> loadRecentSessions({int limit = 60}) async {
    final all = await _db.getPomodoroSessions();
    recentSessions = all.take(limit).toList();
    notifyListeners();
  }

  Future<void> deleteSession(int id) async {
    await _db.deletePomodoro(id);
    await refreshTodayStats();
    await loadRecentSessions();
  }

  /// 近 n 天专注统计，用于图表
  Future<Map<String, Map<String, int>>> dailyStats(int days) async {
    final range = DateUtilsX.lastNDays(days);
    return _db.getPomodoroDailyStats(from: range.first, to: range.last);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
