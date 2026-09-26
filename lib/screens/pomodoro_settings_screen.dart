import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pomodoro_provider.dart';

/// 番茄钟参数设置
class PomodoroSettingsScreen extends StatelessWidget {
  const PomodoroSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('番茄钟设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Column(
              children: [
                _DurationTile(
                  icon: Icons.timer_outlined,
                  title: '专注时长',
                  value: pomodoro.focusMinutes,
                  min: 5,
                  max: 90,
                  step: 5,
                  onChanged: (v) => pomodoro.updateSettings(focus: v),
                ),
                const Divider(height: 1, indent: 56),
                _DurationTile(
                  icon: Icons.free_breakfast_outlined,
                  title: '短休息时长',
                  value: pomodoro.shortBreakMinutes,
                  min: 1,
                  max: 30,
                  step: 1,
                  onChanged: (v) => pomodoro.updateSettings(shortBreak: v),
                ),
                const Divider(height: 1, indent: 56),
                _DurationTile(
                  icon: Icons.weekend_outlined,
                  title: '长休息时长',
                  value: pomodoro.longBreakMinutes,
                  min: 5,
                  max: 60,
                  step: 5,
                  onChanged: (v) => pomodoro.updateSettings(longBreak: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.play_circle_outline),
                  title: const Text('自动开始下一阶段'),
                  subtitle: const Text('专注结束后直接进入休息倒计时'),
                  value: pomodoro.autoStartNext,
                  onChanged: (v) => pomodoro.updateSettings(autoStart: v),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('阶段结束提醒'),
                  subtitle: const Text('结束时推送通知，切到后台也能收到'),
                  value: pomodoro.soundEnabled,
                  onChanged: (v) => pomodoro.updateSettings(sound: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '每完成 4 个专注番茄后自动进入长休息。修改时长不会影响正在进行的计时。',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // 步长可能大于下限（例如长休息 5 分钟起、每次 5 分钟），
    // 因此用 clamp 保证不会越过边界。
    final next = (value + step).clamp(min, max);
    final prev = (value - step).clamp(min, max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 15)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(prev) : null,
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$value 分',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(next) : null,
          ),
        ],
      ),
    );
  }
}
