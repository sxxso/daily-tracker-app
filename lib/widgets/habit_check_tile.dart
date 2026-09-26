import 'package:flutter/material.dart';

import '../models/habit.dart';

/// 习惯卡片：图标 + 名称 + 连续天数 + 打卡按钮
class HabitCheckTile extends StatelessWidget {
  const HabitCheckTile({
    super.key,
    required this.habit,
    required this.done,
    required this.streak,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final Habit habit;
  final bool done;
  final int streak;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 传入时替换默认的打卡勾选按钮（习惯管理页用于放置拖拽手柄）
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(habit.colorValue);

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: done
                      ? color
                      : color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: done ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: scheme.onSurfaceVariant,
                        color: done ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle ??
                          (streak > 0 ? '连续 $streak 天' : '还没有开始'),
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  _CheckButton(
                    done: done,
                    color: color,
                    onTap: onTap,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.done,
    required this.color,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : Colors.transparent,
          border: Border.all(
            color: done ? color : scheme.outlineVariant,
            width: 2,
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: done ? 1 : 0,
          child: const Icon(Icons.check, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
