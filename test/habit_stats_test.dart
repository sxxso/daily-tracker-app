import 'package:daily_tracker_app/utils/date_utils.dart';
import 'package:daily_tracker_app/utils/habit_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateUtilsX', () {
    test('key 生成 yyyy-MM-dd', () {
      expect(DateUtilsX.key(DateTime(2026, 9, 26)), '2026-09-26');
      expect(DateUtilsX.key(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('startOfWeek 以周一为起点', () {
      // 2026-09-26 是周六
      final saturday = DateTime(2026, 9, 26);
      expect(DateUtilsX.startOfWeek(saturday), DateTime(2026, 9, 21));

      // 周一本身应返回当天
      final monday = DateTime(2026, 9, 21);
      expect(DateUtilsX.startOfWeek(monday), DateTime(2026, 9, 21));

      // 周日属于上一周
      final sunday = DateTime(2026, 9, 27);
      expect(DateUtilsX.startOfWeek(sunday), DateTime(2026, 9, 21));
    });

    test('endOfMonth 处理不同月份长度', () {
      expect(DateUtilsX.endOfMonth(DateTime(2026, 2, 10)), DateTime(2026, 2, 28));
      // 2024 是闰年
      expect(DateUtilsX.endOfMonth(DateTime(2024, 2, 10)), DateTime(2024, 2, 29));
      expect(DateUtilsX.endOfMonth(DateTime(2026, 4, 1)), DateTime(2026, 4, 30));
    });

    test('lastNDays 含今天且升序', () {
      final now = DateTime(2026, 9, 26);
      final days = DateUtilsX.lastNDays(3, now: now);
      expect(days.length, 3);
      expect(days.first, DateTime(2026, 9, 24));
      expect(days.last, DateTime(2026, 9, 26));
    });

    test('lastNDays 跨月边界', () {
      final days = DateUtilsX.lastNDays(3, now: DateTime(2026, 10, 2));
      expect(days.first, DateTime(2026, 9, 30));
      expect(days.last, DateTime(2026, 10, 2));
    });

    test('clock 格式化秒数', () {
      expect(DateUtilsX.clock(0), '00:00');
      expect(DateUtilsX.clock(59), '00:59');
      expect(DateUtilsX.clock(60), '01:00');
      expect(DateUtilsX.clock(1500), '25:00');
      expect(DateUtilsX.clock(-5), '00:00');
    });

    test('durationText 生成可读文本', () {
      expect(DateUtilsX.durationText(45), '45秒');
      expect(DateUtilsX.durationText(120), '2分钟');
      expect(DateUtilsX.durationText(3600), '1小时');
      expect(DateUtilsX.durationText(4800), '1小时20分');
    });
  });

  group('HabitStats.currentStreak', () {
    // 固定「今天」为 2026-09-26
    final now = DateTime(2026, 9, 26);

    test('空集合为 0', () {
      expect(HabitStats.currentStreak({}, now: now), 0);
    });

    test('连续三天含今天', () {
      final keys = {'2026-09-24', '2026-09-25', '2026-09-26'};
      expect(HabitStats.currentStreak(keys, now: now), 3);
    });

    test('今天未打卡时从昨天继续数，不清零', () {
      final keys = {'2026-09-23', '2026-09-24', '2026-09-25'};
      expect(HabitStats.currentStreak(keys, now: now), 3);
    });

    test('昨天和今天都没打卡则为 0', () {
      final keys = {'2026-09-22', '2026-09-23', '2026-09-24'};
      expect(HabitStats.currentStreak(keys, now: now), 0);
    });

    test('中间断档只数最近一段', () {
      final keys = {
        '2026-09-10',
        '2026-09-11',
        // 12-24 断档
        '2026-09-25',
        '2026-09-26',
      };
      expect(HabitStats.currentStreak(keys, now: now), 2);
    });

    test('跨月连续', () {
      final keys = {'2026-08-31', '2026-09-01', '2026-09-02'};
      expect(
        HabitStats.currentStreak(keys, now: DateTime(2026, 9, 2)),
        3,
      );
    });

    test('只有今天一次', () {
      expect(HabitStats.currentStreak({'2026-09-26'}, now: now), 1);
    });
  });

  group('HabitStats.longestStreak', () {
    test('空集合为 0', () {
      expect(HabitStats.longestStreak({}), 0);
    });

    test('取最长的一段而非最后一段', () {
      final keys = {
        '2026-09-01',
        '2026-09-02',
        '2026-09-03',
        '2026-09-04',
        // 断档
        '2026-09-10',
        '2026-09-11',
      };
      expect(HabitStats.longestStreak(keys), 4);
    });

    test('单点记录为 1', () {
      expect(HabitStats.longestStreak({'2026-09-10'}), 1);
    });

    test('无序输入也能正确计算', () {
      final keys = {'2026-09-03', '2026-09-01', '2026-09-02'};
      expect(HabitStats.longestStreak(keys), 3);
    });
  });

  group('HabitStats.completionRate', () {
    final now = DateTime(2026, 9, 26);

    test('空集合为 0', () {
      expect(HabitStats.completionRate({}, days: 7, now: now), 0);
    });

    test('近 7 天打卡 7 天为 1.0', () {
      final keys = {
        for (var i = 0; i < 7; i++)
          DateUtilsX.key(DateTime(2026, 9, 26).subtract(Duration(days: i))),
      };
      expect(HabitStats.completionRate(keys, days: 7, now: now), 1.0);
    });

    test('近 7 天打卡 3 天约为 0.43', () {
      final keys = {'2026-09-24', '2026-09-25', '2026-09-26'};
      expect(
        HabitStats.completionRate(keys, days: 7, now: now),
        closeTo(3 / 7, 0.0001),
      );
    });

    test('超出窗口的旧记录不计入', () {
      final keys = {'2026-08-01', '2026-08-02'};
      expect(HabitStats.completionRate(keys, days: 7, now: now), 0);
    });
  });

  group('HabitStats.countThisWeek', () {
    test('只统计本周一以来的打卡', () {
      // 2026-09-26 是周六，本周一为 09-21
      final now = DateTime(2026, 9, 26);
      final keys = {
        '2026-09-20', // 上周日，不计
        '2026-09-21',
        '2026-09-22',
        '2026-09-26',
      };
      expect(HabitStats.countThisWeek(keys, now: now), 3);
    });

    test('空集合为 0', () {
      expect(HabitStats.countThisWeek({}, now: DateTime(2026, 9, 26)), 0);
    });
  });

  group('HabitStats.isCheckedOn', () {
    test('按日期精确匹配', () {
      final keys = {'2026-09-26'};
      expect(HabitStats.isCheckedOn(keys, DateTime(2026, 9, 26, 23, 59)), isTrue);
      expect(HabitStats.isCheckedOn(keys, DateTime(2026, 9, 27)), isFalse);
    });
  });
}
