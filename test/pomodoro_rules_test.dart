import 'package:daily_tracker_app/models/pomodoro_session.dart';
import 'package:daily_tracker_app/utils/pomodoro_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PomodoroRules.nextBreakPhase', () {
    test('第 1-3 个番茄进入短休息', () {
      for (final n in [1, 2, 3]) {
        expect(
          PomodoroRules.nextBreakPhase(completedFocusCount: n),
          PomodoroPhase.shortBreak,
          reason: '完成第 $n 个番茄后应为短休息',
        );
      }
    });

    test('第 4 个番茄进入长休息', () {
      expect(
        PomodoroRules.nextBreakPhase(completedFocusCount: 4),
        PomodoroPhase.longBreak,
      );
    });

    test('第 8 个番茄再次进入长休息', () {
      expect(
        PomodoroRules.nextBreakPhase(completedFocusCount: 8),
        PomodoroPhase.longBreak,
      );
    });

    test('第 5-7 个番茄回到短休息', () {
      for (final n in [5, 6, 7]) {
        expect(
          PomodoroRules.nextBreakPhase(completedFocusCount: n),
          PomodoroPhase.shortBreak,
        );
      }
    });

    test('0 个完成数时退化为短休息，不会误判长休息', () {
      expect(
        PomodoroRules.nextBreakPhase(completedFocusCount: 0),
        PomodoroPhase.shortBreak,
      );
    });

    test('支持自定义长休息间隔', () {
      expect(
        PomodoroRules.nextBreakPhase(
          completedFocusCount: 2,
          focusPerLongBreak: 2,
        ),
        PomodoroPhase.longBreak,
      );
      expect(
        PomodoroRules.nextBreakPhase(
          completedFocusCount: 3,
          focusPerLongBreak: 2,
        ),
        PomodoroPhase.shortBreak,
      );
    });

    test('间隔为 0 或负数时不崩，返回短休息', () {
      expect(
        PomodoroRules.nextBreakPhase(
          completedFocusCount: 4,
          focusPerLongBreak: 0,
        ),
        PomodoroPhase.shortBreak,
      );
      expect(
        PomodoroRules.nextBreakPhase(
          completedFocusCount: 4,
          focusPerLongBreak: -1,
        ),
        PomodoroPhase.shortBreak,
      );
    });
  });

  group('PomodoroRules.isCompletedFocus', () {
    test('跑满且未中断算完成', () {
      expect(
        PomodoroRules.isCompletedFocus(
          phase: PomodoroPhase.focus,
          interrupted: false,
          actualSeconds: 1500,
          plannedSeconds: 1500,
        ),
        isTrue,
      );
    });

    test('中断不算完成', () {
      expect(
        PomodoroRules.isCompletedFocus(
          phase: PomodoroPhase.focus,
          interrupted: true,
          actualSeconds: 1500,
          plannedSeconds: 1500,
        ),
        isFalse,
      );
    });

    test('未跑满不算完成', () {
      expect(
        PomodoroRules.isCompletedFocus(
          phase: PomodoroPhase.focus,
          interrupted: false,
          actualSeconds: 600,
          plannedSeconds: 1500,
        ),
        isFalse,
      );
    });

    test('休息阶段不算专注完成', () {
      expect(
        PomodoroRules.isCompletedFocus(
          phase: PomodoroPhase.shortBreak,
          interrupted: false,
          actualSeconds: 300,
          plannedSeconds: 300,
        ),
        isFalse,
      );
    });
  });

  group('PomodoroRules.totalFocusSeconds', () {
    test('只累加未中断的专注阶段', () {
      final sessions = [
        PomodoroSession(
          phase: PomodoroPhase.focus,
          actualSeconds: 1500,
          plannedMinutes: 25,
        ),
        PomodoroSession(
          phase: PomodoroPhase.shortBreak,
          actualSeconds: 300,
          plannedMinutes: 5,
        ),
        PomodoroSession(
          phase: PomodoroPhase.focus,
          actualSeconds: 600,
          plannedMinutes: 25,
          interrupted: true,
        ),
        PomodoroSession(
          phase: PomodoroPhase.focus,
          actualSeconds: 1200,
          plannedMinutes: 20,
        ),
      ];
      expect(PomodoroRules.totalFocusSeconds(sessions), 2700);
    });

    test('空列表为 0', () {
      expect(PomodoroRules.totalFocusSeconds([]), 0);
    });
  });

  group('PomodoroRules.groupByDay', () {
    test('按开始日期分组统计数量与时长', () {
      final sessions = [
        PomodoroSession(
          phase: PomodoroPhase.focus,
          actualSeconds: 1500,
          plannedMinutes: 25,
          startedAt: DateTime(2026, 9, 26, 9),
        ),
        PomodoroSession(
          phase: PomodoroPhase.focus,
          actualSeconds: 1500,
          plannedMinutes: 25,
          startedAt: DateTime(2026, 9, 26, 14),
        ),
        PomodoroSession(
          phase: PomodoroPhase.focus,
          actualSeconds: 1200,
          plannedMinutes: 20,
          startedAt: DateTime(2026, 9, 25, 20),
        ),
      ];

      final grouped = PomodoroRules.groupByDay(sessions);
      expect(grouped['2026-09-26']!.count, 2);
      expect(grouped['2026-09-26']!.seconds, 3000);
      expect(grouped['2026-09-25']!.count, 1);
      expect(grouped['2026-09-25']!.seconds, 1200);
    });

    test('忽略中断与休息记录', () {
      final sessions = [
        PomodoroSession(
          phase: PomodoroPhase.focus,
          actualSeconds: 600,
          plannedMinutes: 25,
          interrupted: true,
          startedAt: DateTime(2026, 9, 26, 9),
        ),
        PomodoroSession(
          phase: PomodoroPhase.longBreak,
          actualSeconds: 900,
          plannedMinutes: 15,
          startedAt: DateTime(2026, 9, 26, 10),
        ),
      ];
      expect(PomodoroRules.groupByDay(sessions), isEmpty);
    });
  });

  group('PomodoroSession 序列化', () {
    test('toMap / fromMap 往返一致', () {
      final original = PomodoroSession(
        id: 7,
        habitId: 3,
        label: '写代码',
        plannedMinutes: 25,
        actualSeconds: 1500,
        phase: PomodoroPhase.focus,
        interrupted: false,
        startedAt: DateTime(2026, 9, 26, 9, 30),
        endedAt: DateTime(2026, 9, 26, 9, 55),
      );

      final restored = PomodoroSession.fromMap(original.toMap());

      expect(restored.id, 7);
      expect(restored.habitId, 3);
      expect(restored.label, '写代码');
      expect(restored.plannedMinutes, 25);
      expect(restored.actualSeconds, 1500);
      expect(restored.phase, PomodoroPhase.focus);
      expect(restored.interrupted, isFalse);
      expect(restored.startedAt, original.startedAt);
      expect(restored.endedAt, original.endedAt);
      expect(restored.dayKey, '2026-09-26');
    });

    test('interrupted 以整数存储', () {
      final s = PomodoroSession(interrupted: true);
      expect(s.toMap()['interrupted'], 1);
      expect(PomodoroSession.fromMap(s.toMap()).interrupted, isTrue);
    });

    test('未知 phase 字符串回退为 focus', () {
      final map = PomodoroSession().toMap()..['phase'] = 'unknown_phase';
      expect(PomodoroSession.fromMap(map).phase, PomodoroPhase.focus);
    });
  });
}
