import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_check_tile.dart';
import 'habit_detail_screen.dart';
import 'habit_edit_screen.dart';

/// 习惯管理：列表 + 新增 + 编辑 + 删除 + 拖拽排序
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final habits = provider.habits;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: habits.isEmpty
          ? _EmptyState(
              onAdd: () => _openEditor(context),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: habits.length,
              onReorder: (oldIndex, newIndex) {
                final list = [...habits];
                if (newIndex > oldIndex) newIndex -= 1;
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                provider.reorder(list);
              },
              itemBuilder: (context, index) {
                final habit = habits[index];
                return Padding(
                  key: ValueKey(habit.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HabitCheckTile(
                    habit: habit,
                    done: provider.isChecked(habit.id!, DateTime.now()),
                    streak: provider.currentStreak(habit.id!),
                    subtitle:
                        '本周 ${provider.thisWeekCount(habit.id!)}/${habit.targetPerWeek} 次',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HabitDetailScreen(habit: habit),
                      ),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('新增习惯'),
      ),
    );
  }

  void _openEditor(BuildContext context, {Habit? habit}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HabitEditScreen(habit: habit)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_rtl, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            const Text(
              '还没有习惯',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '添加每天想坚持的事，\n比如早起、读书、运动、喝水',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('新增习惯'),
            ),
          ],
        ),
      ),
    );
  }
}
