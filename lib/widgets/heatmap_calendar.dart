import 'package:flutter/material.dart';

/// 月历热力图：按周排布，已打卡的日期填充习惯颜色。
class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({
    super.key,
    required this.month,
    required this.color,
    required this.isChecked,
    this.onTapDay,
  });

  /// 任意属于目标月份的日期
  final DateTime month;
  final Color color;
  final bool Function(DateTime day) isChecked;
  final ValueChanged<DateTime>? onTapDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // 周一为每周起点：首日前面留空格
    final leading = first.weekday - DateTime.monday;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: [
        Row(
          children: ['一', '二', '三', '四', '五', '六', '日']
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leading + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final day = DateTime(month.year, month.month, dayNumber);
            final checked = isChecked(day);
            final isToday = _isToday(day);
            final isFuture = day.isAfter(DateTime.now());

            return GestureDetector(
              onTap: onTapDay == null ? null : () => onTapDay!(day),
              child: Container(
                decoration: BoxDecoration(
                  color: checked
                      ? color
                      : scheme.surfaceContainerHighest.withValues(
                          alpha: isFuture ? 0.3 : 1.0,
                        ),
                  borderRadius: BorderRadius.circular(9),
                  border: isToday ? Border.all(color: color, width: 2) : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: checked ? FontWeight.bold : FontWeight.normal,
                      color: checked
                          ? Colors.white
                          : scheme.onSurfaceVariant.withValues(
                              alpha: isFuture ? 0.4 : 1.0,
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }
}
