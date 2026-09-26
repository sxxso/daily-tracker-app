import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/habit_check_tile.dart';
import '../widgets/progress_ring.dart';
import '../widgets/section_header.dart';
import 'habit_detail_screen.dart';

/// 今日打卡主页：顶部进度环 + 日期条 + 今日习惯列表
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final overview = provider.todayOverview();
    final done = provider.todayCompletedCount;
    final total = provider.todayTotalCount;
    final rate = total == 0 ? 0.0 : done / total;

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _TodayHeader(done: done, total: total, rate: rate),
          const SizedBox(height: 24),
          _WeekStrip(provider: provider),
          const SizedBox(height: 24),
          SectionHeader(
            title: '今日习惯',
            trailing: total == 0 ? null : '$done / $total',
          ),
          const SizedBox(height: 8),
          if (overview.isEmpty)
            const _EmptyHabitsHint()
          else
            ...overview.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HabitCheckTile(
                  habit: item.habit,
                  done: item.done,
                  streak: item.streak,
                  onTap: () => context
                      .read<HabitProvider>()
                      .toggleCheckIn(item.habit.id!),
                  onLongPress: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HabitDetailScreen(habit: item.habit),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({
    required this.done,
    required this.total,
    required this.rate,
  });

  final int done;
  final int total;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            ProgressRing(
              progress: rate,
              size: 92,
              strokeWidth: 9,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(rate * 100).round()}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
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
                  Text(
                    DateUtilsX.humanDate(now),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateUtilsX.key(now)}  周${DateUtilsX.weekdayLabel(now)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    total == 0
                        ? '还没有习惯，去「习惯」页添加一个吧'
                        : done == total
                            ? '今天全部完成，很棒！'
                            : '还有 ${total - done} 项待完成',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 最近 7 天的整体完成情况条，点击某天可回看/补打卡
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.provider});

  final HabitProvider provider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = DateUtilsX.lastNDays(7);
    final today = DateUtilsX.dateOnly(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) {
            final count = provider.countOn(d);
            final total = provider.todayTotalCount;
            final isToday = DateUtilsX.isSameDay(d, today);
            final full = total > 0 && count >= total;

            return GestureDetector(
              onTap: () => _showDaySheet(context, d),
              child: Column(
                children: [
                  Text(
                    DateUtilsX.weekdayLabel(d),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: count == 0
                          ? scheme.surfaceContainerHighest
                          : scheme.primary.withValues(alpha: full ? 1.0 : 0.35),
                      border: isToday
                          ? Border.all(color: scheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: count == 0
                          ? Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            )
                          : Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDaySheet(BuildContext context, DateTime day) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _DaySheet(day: day),
      ),
    );
  }
}

/// 某天的补打卡面板
class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;
    final isFuture = DateUtilsX.dateOnly(day).isAfter(DateUtilsX.dateOnly(DateTime.now()));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateUtilsX.humanDate(day)} 的打卡',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              DateUtilsX.key(day),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (isFuture)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('未来的日期还不能打卡'),
              )
            else if (habits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('还没有习惯'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: habits.map((h) {
                    final checked = provider.isChecked(h.id!, day);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (_) =>
                          provider.toggleCheckIn(h.id!, date: day),
                      title: Text(h.name),
                      secondary: Icon(
                        IconData(
                          h.iconCodePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Color(h.colorValue),
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHabitsHint extends StatelessWidget {
  const _EmptyHabitsHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.playlist_add, size: 48, color: scheme.primary),
            const SizedBox(height: 12),
            const Text(
              '还没有习惯',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '切换到「习惯」标签页，添加你想每天坚持的事',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
