import '../models/pomodoro_session.dart';
import 'date_utils.dart';

/// 番茄钟流程规则的纯函数，便于单元测试。
class PomodoroRules {
  const PomodoroRules._();

  /// 决定专注结束后该进入哪种休息。
  ///
  /// [completedFocusCount] 是**已落库的**今日完成专注数（含刚结束的那个）。
  /// 每完成 [focusPerLongBreak] 个进入长休息，其余进入短休息。
  static PomodoroPhase nextBreakPhase({
    required int completedFocusCount,
    int focusPerLongBreak = 4,
  }) {
    if (focusPerLongBreak <= 0) return PomodoroPhase.shortBreak;
    if (completedFocusCount <= 0) return PomodoroPhase.shortBreak;
    return completedFocusCount % focusPerLongBreak == 0
        ? PomodoroPhase.longBreak
        : PomodoroPhase.shortBreak;
  }

  /// 某次专注是否算作「完成的番茄」：跑满计划时长且未被中断。
  static bool isCompletedFocus({
    required PomodoroPhase phase,
    required bool interrupted,
    required int actualSeconds,
    required int plannedSeconds,
  }) {
    if (phase != PomodoroPhase.focus) return false;
    if (interrupted) return false;
    return actualSeconds >= plannedSeconds;
  }

  /// 今日已完成专注的合计时长（秒）
  static int totalFocusSeconds(Iterable<PomodoroSession> sessions) {
    var total = 0;
    for (final s in sessions) {
      if (s.phase == PomodoroPhase.focus && !s.interrupted) {
        total += s.actualSeconds;
      }
    }
    return total;
  }

  /// 按天汇总专注数量与时长
  static Map<String, ({int count, int seconds})> groupByDay(
    Iterable<PomodoroSession> sessions,
  ) {
    final result = <String, ({int count, int seconds})>{};
    for (final s in sessions) {
      if (s.phase != PomodoroPhase.focus || s.interrupted) continue;
      final key = DateUtilsX.key(s.startedAt);
      final prev = result[key];
      result[key] = (
        count: (prev?.count ?? 0) + 1,
        seconds: (prev?.seconds ?? 0) + s.actualSeconds,
      );
    }
    return result;
  }
}
