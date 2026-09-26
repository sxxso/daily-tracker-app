import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/section_header.dart';

/// 数据统计页：打卡趋势 + 番茄钟趋势 + 习惯排行
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _days = 7;
  Map<String, Map<String, int>> _pomodoroStats = {};
  bool _loadingPomodoro = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPomodoro());
  }

  Future<void> _loadPomodoro() async {
    final provider = context.read<PomodoroProvider>();
    final stats = await provider.dailyStats(_days);
    if (!mounted) return;
    setState(() {
      _pomodoroStats = stats;
      _loadingPomodoro = false;
    });
  }

  Future<void> _changeRange(int days) async {
    setState(() {
      _days = days;
      _loadingPomodoro = true;
    });
    await _loadPomodoro();
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>();

    if (habits.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final trend = habits.trend(_days);
    final days = DateUtilsX.lastNDays(_days);

    // 汇总
    final totalCheckIns = habits.habits.fold<int>(
      0,
      (sum, h) => sum + habits.totalCheckIns(h.id!),
    );
    final activeHabits = habits.habits.length;
    final avgRate = activeHabits == 0
        ? 0.0
        : habits.habits
                .map((h) => habits.completionRate(h.id!, days: _days))
                .reduce((a, b) => a + b) /
            activeHabits;

    final pomodoroCount = _pomodoroStats.values
        .fold<int>(0, (sum, e) => sum + (e['count'] ?? 0));
    final pomodoroSeconds = _pomodoroStats.values
        .fold<int>(0, (sum, e) => sum + (e['seconds'] ?? 0));

    return RefreshIndicator(
      onRefresh: () async {
        await habits.load();
        await _loadPomodoro();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _RangeSelector(days: _days, onChanged: _changeRange),
          const SizedBox(height: 20),

          // 概览
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.check_circle_outline,
                  label: '累计打卡',
                  value: '$totalCheckIns',
                  unit: '次',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.trending_up,
                  label: '平均完成率',
                  value: '${(avgRate * 100).round()}',
                  unit: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.timer_outlined,
                  label: '番茄总数',
                  value: '$pomodoroCount',
                  unit: '个',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.hourglass_bottom,
                  label: '专注时长',
                  value: DateUtilsX.durationText(pomodoroSeconds),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          const SectionHeader(title: '打卡趋势'),
          const SizedBox(height: 12),
          _ChartCard(
            height: 200,
            child: _CheckInBarChart(trend: trend, days: _days),
          ),

          const SizedBox(height: 28),
          const SectionHeader(title: '番茄钟趋势'),
          const SizedBox(height: 12),
          _ChartCard(
            height: 200,
            child: _loadingPomodoro
                ? const Center(child: CircularProgressIndicator())
                : _PomodoroBarChart(
                    days: days,
                    stats: _pomodoroStats,
                  ),
          ),

          const SizedBox(height: 28),
          const SectionHeader(title: '习惯排行'),
          const SizedBox(height: 12),
          _HabitRanking(habits: habits, days: _days),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('近 7 天')),
        ButtonSegment(value: 14, label: Text('近 14 天')),
        ButtonSegment(value: 30, label: Text('近 30 天')),
      ],
      selected: {days},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit!,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
        child: SizedBox(height: height, child: child),
      ),
    );
  }
}

/// 每日打卡数量柱状图
class _CheckInBarChart extends StatelessWidget {
  const _CheckInBarChart({required this.trend, required this.days});

  final List<MapEntry<DateTime, int>> trend;
  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxY = trend.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    final top = (maxY + 1).toDouble();
    // 天数多时只标注部分横轴，避免拥挤
    final labelStep = days <= 7 ? 1 : (days <= 14 ? 2 : 5);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: top,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: top <= 5 ? 1 : (top / 4).ceilToDouble(),
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: top <= 5 ? 1 : (top / 4).ceilToDouble(),
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                if (i % labelStep != 0 && i != trend.length - 1) {
                  return const SizedBox.shrink();
                }
                final d = trend[i].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    days <= 7 ? '周${DateUtilsX.weekdayLabel(d)}' : '${d.day}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final d = trend[group.x];
              return BarTooltipItem(
                '${DateUtilsX.key(d.key)}\n${rod.toY.toInt()} 次',
                const TextStyle(fontSize: 12, color: Colors.white),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < trend.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: trend[i].value.toDouble(),
                  width: days <= 7 ? 18 : (days <= 14 ? 10 : 5),
                  borderRadius: BorderRadius.circular(4),
                  color: scheme.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 每日专注番茄数柱状图
class _PomodoroBarChart extends StatelessWidget {
  const _PomodoroBarChart({required this.days, required this.stats});

  final List<DateTime> days;
  final Map<String, Map<String, int>> stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = days
        .map((d) => stats[DateUtilsX.key(d)]?['count'] ?? 0)
        .toList();
    final maxY = counts.fold<int>(0, (m, v) => v > m ? v : m);

    if (maxY == 0) {
      return Center(
        child: Text(
          '这段时间还没有番茄钟记录',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final top = (maxY + 1).toDouble();
    final labelStep = days.length <= 7 ? 1 : (days.length <= 14 ? 2 : 5);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: top,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: top <= 5 ? 1 : (top / 4).ceilToDouble(),
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: top <= 5 ? 1 : (top / 4).ceilToDouble(),
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                if (i % labelStep != 0 && i != days.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    days.length <= 7
                        ? '周${DateUtilsX.weekdayLabel(days[i])}'
                        : '${days[i].day}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final d = days[group.x];
              final secs = stats[DateUtilsX.key(d)]?['seconds'] ?? 0;
              return BarTooltipItem(
                '${DateUtilsX.key(d)}\n${rod.toY.toInt()} 个 · ${DateUtilsX.durationText(secs)}',
                const TextStyle(fontSize: 12, color: Colors.white),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  width: days.length <= 7 ? 18 : (days.length <= 14 ? 10 : 5),
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFF29B6F6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 按完成率排序的习惯列表
class _HabitRanking extends StatelessWidget {
  const _HabitRanking({required this.habits, required this.days});

  final HabitProvider habits;
  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (habits.habits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              '还没有习惯数据',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    final ranked = habits.habits.map((h) {
      return (
        habit: h,
        rate: habits.completionRate(h.id!, days: days),
        streak: habits.currentStreak(h.id!),
        total: habits.totalCheckIns(h.id!),
      );
    }).toList()
      ..sort((a, b) => b.rate.compareTo(a.rate));

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < ranked.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(ranked[i].habit.colorValue)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      IconData(
                        ranked[i].habit.iconCodePoint,
                        fontFamily: 'MaterialIcons',
                      ),
                      size: 20,
                      color: Color(ranked[i].habit.colorValue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ranked[i].habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '连续 ${ranked[i].streak} 天 · 累计 ${ranked[i].total} 次',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(ranked[i].rate * 100).round()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(ranked[i].habit.colorValue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
