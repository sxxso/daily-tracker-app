import 'package:intl/intl.dart';

/// 番茄钟会话类型
enum PomodoroPhase { focus, shortBreak, longBreak }

/// 一次完整的番茄钟会话记录
class PomodoroSession {
  final int? id;

  /// 关联的习惯/任务标签，可为空表示无标签
  final int? habitId;

  /// 本次专注对应的任务名（自由文本）
  String label;

  /// 计划专注时长（分钟）
  int plannedMinutes;

  /// 实际专注时长（秒）
  int actualSeconds;

  PomodoroPhase phase;

  /// 是否被用户提前中断
  bool interrupted;

  final DateTime startedAt;
  DateTime endedAt;

  PomodoroSession({
    this.id,
    this.habitId,
    this.label = '',
    this.plannedMinutes = 25,
    this.actualSeconds = 0,
    this.phase = PomodoroPhase.focus,
    this.interrupted = false,
    DateTime? startedAt,
    DateTime? endedAt,
  })  : startedAt = startedAt ?? DateTime.now(),
        endedAt = endedAt ?? DateTime.now();

  /// 格式 yyyy-MM-dd，便于按天统计
  static String dayKeyOf(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
  String get dayKey => dayKeyOf(startedAt);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'label': label,
      'planned_minutes': plannedMinutes,
      'actual_seconds': actualSeconds,
      'phase': phase.name,
      'interrupted': interrupted ? 1 : 0,
      'started_at': startedAt.millisecondsSinceEpoch,
      'ended_at': endedAt.millisecondsSinceEpoch,
      'day_key': dayKey,
    };
  }

  factory PomodoroSession.fromMap(Map<String, Object?> map) {
    return PomodoroSession(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int?,
      label: map['label'] as String? ?? '',
      plannedMinutes: map['planned_minutes'] as int? ?? 25,
      actualSeconds: map['actual_seconds'] as int? ?? 0,
      phase: PomodoroPhase.values.firstWhere(
        (p) => p.name == (map['phase'] as String? ?? 'focus'),
        orElse: () => PomodoroPhase.focus,
      ),
      interrupted: (map['interrupted'] as int? ?? 0) == 1,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        map['started_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      endedAt: DateTime.fromMillisecondsSinceEpoch(
        map['ended_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
