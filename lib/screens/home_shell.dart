import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import '../providers/pomodoro_provider.dart';
import 'habits_screen.dart';
import 'pomodoro_screen.dart';
import 'pomodoro_settings_screen.dart';
import 'stats_screen.dart';
import 'today_screen.dart';

/// 底部导航容器。番茄钟计时在切页后仍在后台运行，Tab 上会显示运行指示点。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['今日打卡', '番茄钟', '习惯管理', '数据统计'];

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroProvider>();
    final habits = context.watch<HabitProvider>();

    final pages = const [
      TodayScreen(),
      PomodoroScreen(),
      HabitsScreen(),
      StatsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          if (_index == 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  habits.loading
                      ? ''
                      : '${habits.todayCompletedCount}/${habits.todayTotalCount}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          if (_index == 1)
            IconButton(
              tooltip: '番茄钟设置',
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PomodoroSettingsScreen(),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '打卡',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pomodoro.isActive,
              child: const Icon(Icons.timer_outlined),
            ),
            selectedIcon: const Icon(Icons.timer),
            label: '番茄钟',
          ),
          const NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: '习惯',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '统计',
          ),
        ],
      ),
    );
  }
}
