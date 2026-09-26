import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/heatmap_calendar.dart';
import '../widgets/progress_ring.dart';
import 'habit_edit_screen.dart';

/// 单习惯详情：连续天数、完成率、月历热力图
class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({super.key, required this.habit});

  final Habit habit;

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    // 习惯可能已被删除
    final habit = provider.habits.firstWhere(
      (h) => h.id == widget.habit.id,
      orElse: () => widget.habit,
    );

    final color = Color(habit.colorValue);
    final streak = provider.currentStreak(habit.id!);
    final longest = provider.longestStreak(habit.id!);
    final total = provider.totalCheckIns(habit.id!);
    final rate30 = provider.completionRate(habit.id!, days: 30);
    final weekCount = provider.thisWeekCount(habit.id!);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            tooltip: '编辑',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HabitEditScreen(habit: habit)),
            ),
          ),
          IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, provider, habit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ProgressRing(
                    progress: rate30,
                    size: 96,
                    strokeWidth: 10,
                    color: color,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(rate30 * 100).round()}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          '近30天',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, color: color),
                            const SizedBox(width: 6),
                            Text(
                              '连续 $streak 天',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '最长连续 $longest 天',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '本周 $weekCount / ${habit.targetPerWeek} 次',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (habit.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.notes,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(habit.description)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  _MiniStat(label: '累计打卡', value: '$total', unit: '次'),
                  _MiniStat(label: '目标', value: '${habit.targetPerWeek}', unit: '次/周'),
                  _MiniStat(
                    label: '创建于',
                    value: '${habit.createdAt.month}/${habit.createdAt.day}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '打卡记录',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                  ),
                  Text(
                    '${_month.year}年${_month.month}月',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _isCurrentMonth
                        ? null
                        : () => setState(
                              () => _month = DateTime(_month.year, _month.month + 1),
                            ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HeatmapCalendar(
                month: _month,
                color: color,
                isChecked: (d) => provider.isChecked(habit.id!, d),
                onTapDay: (d) => _showDayDialog(context, provider, habit, d),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  Future<void> _showDayDialog(
    BuildContext context,
    HabitProvider provider,
    Habit habit,
    DateTime day,
  ) async {
    final checked = provider.isChecked(habit.id!, day);
    final isFuture =
        DateUtilsX.dateOnly(day).isAfter(DateUtilsX.dateOnly(DateTime.now()));

    if (isFuture) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未来的日期还不能打卡')),
      );
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(DateUtilsX.key(day)),
        content: Text(checked ? '这一天已打卡' : '这一天还没有打卡'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'toggle'),
            child: Text(checked ? '取消打卡' : '补打卡'),
          ),
        ],
      ),
    );

    if (action == 'toggle') {
      await provider.toggleCheckIn(habit.id!, date: day);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HabitProvider provider,
    Habit habit,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除「${habit.name}」？'),
        content: const Text('该习惯的所有打卡记录也会一并删除，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await provider.deleteHabit(habit.id!);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
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
    );
  }
}
