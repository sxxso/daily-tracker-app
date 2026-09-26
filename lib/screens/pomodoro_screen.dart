import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pomodoro_session.dart';
import '../providers/pomodoro_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/progress_ring.dart';

/// 番茄钟主界面：模式切换 + 圆环倒计时 + 控制按钮 + 今日统计
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final TextEditingController _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroProvider>();
    final scheme = Theme.of(context).colorScheme;

    final phaseColor = switch (pomodoro.phase) {
      PomodoroPhase.focus => scheme.primary,
      PomodoroPhase.shortBreak => const Color(0xFF29B6F6),
      PomodoroPhase.longBreak => const Color(0xFF7E57C2),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _PhaseSelector(
          current: pomodoro.phase,
          enabled: pomodoro.isIdle,
          onChanged: pomodoro.switchPhase,
        ),
        const SizedBox(height: 24),
        Center(
          child: ProgressRing(
            progress: pomodoro.progress,
            size: 260,
            strokeWidth: 14,
            color: phaseColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pomodoro.phaseLabel,
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateUtilsX.clock(pomodoro.remainingSeconds),
                  style: TextStyle(
                    fontSize: 58,
                    fontWeight: FontWeight.w300,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: pomodoro.status == TimerStatus.finished
                        ? phaseColor
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '第 ${pomodoro.focusCountToday + (pomodoro.isFocus ? 1 : 0)} 个番茄',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        _TaskField(
          controller: _labelController,
          enabled: pomodoro.isIdle,
          onSubmitted: (v) => pomodoro.start(taskLabel: v),
        ),
        const SizedBox(height: 16),
        _Controls(
          pomodoro: pomodoro,
          onPrimaryPressed: () {
            if (pomodoro.isRunning) {
              pomodoro.pause();
            } else {
              pomodoro.start(taskLabel: _labelController.text);
            }
          },
        ),
        const SizedBox(height: 28),
        _TodayStats(pomodoro: pomodoro),
        const SizedBox(height: 20),
        _RecentSessions(pomodoro: pomodoro),
      ],
    );
  }
}

class _PhaseSelector extends StatelessWidget {
  const _PhaseSelector({
    required this.current,
    required this.enabled,
    required this.onChanged,
  });

  final PomodoroPhase current;
  final bool enabled;
  final ValueChanged<PomodoroPhase> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PomodoroPhase>(
      segments: const [
        ButtonSegment(value: PomodoroPhase.focus, label: Text('专注')),
        ButtonSegment(value: PomodoroPhase.shortBreak, label: Text('短休息')),
        ButtonSegment(value: PomodoroPhase.longBreak, label: Text('长休息')),
      ],
      selected: {current},
      onSelectionChanged:
          enabled ? (s) => onChanged(s.first) : null,
      showSelectedIcon: false,
    );
  }
}

class _TaskField extends StatelessWidget {
  const _TaskField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      maxLength: 40,
      decoration: InputDecoration(
        hintText: enabled ? '这次专注做什么？（可选）' : '计时中…',
        prefixIcon: const Icon(Icons.edit_note),
        counterText: '',
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.pomodoro, required this.onPrimaryPressed});

  final PomodoroProvider pomodoro;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final running = pomodoro.isRunning;
    final idle = pomodoro.isIdle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 重置 / 放弃
        if (!idle)
          IconButton.filledTonal(
            onPressed: () => _confirmStop(context, pomodoro),
            icon: const Icon(Icons.stop_rounded),
            iconSize: 28,
            tooltip: '结束本次',
          )
        else
          const SizedBox(width: 48),

        const SizedBox(width: 24),

        // 主按钮：开始 / 暂停 / 继续
        SizedBox(
          width: 88,
          height: 88,
          child: FilledButton(
            onPressed: onPrimaryPressed,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 40,
            ),
          ),
        ),

        const SizedBox(width: 24),

        // 跳过
        if (!idle)
          IconButton.filledTonal(
            onPressed: () => _confirmSkip(context, pomodoro),
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 28,
            tooltip: '跳过本阶段',
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Future<void> _confirmStop(
    BuildContext context,
    PomodoroProvider pomodoro,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('结束本次？'),
        content: Text(
          pomodoro.isFocus
              ? '专注满 1 分钟的部分会被记录为「中断」，不计入完成数。'
              : '将结束当前休息阶段。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('继续计时'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('结束'),
          ),
        ],
      ),
    );
    if (ok == true) await pomodoro.stop();
  }

  Future<void> _confirmSkip(
    BuildContext context,
    PomodoroProvider pomodoro,
  ) async {
    if (!pomodoro.isFocus) {
      await pomodoro.skip();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('跳过这个番茄？'),
        content: const Text('已投入的时间会记录下来，但不算作完成的番茄。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('再坚持一下'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('跳过'),
          ),
        ],
      ),
    );
    if (ok == true) await pomodoro.skip();
  }
}

class _TodayStats extends StatelessWidget {
  const _TodayStats({required this.pomodoro});

  final PomodoroProvider pomodoro;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_outlined,
            label: '今日番茄',
            value: '${pomodoro.todayFocusCount}',
            unit: '个',
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_outlined,
            label: '专注时长',
            value: DateUtilsX.durationText(pomodoro.todayFocusSeconds),
            color: const Color(0xFF29B6F6),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
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
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
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

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.pomodoro});

  final PomodoroProvider pomodoro;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sessions = pomodoro.recentSessions.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '最近记录',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (sessions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  '还没有番茄钟记录',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < sessions.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  _SessionTile(
                    session: sessions[i],
                    onDelete: () => pomodoro.deleteSession(sessions[i].id!),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onDelete});

  final PomodoroSession session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFocus = session.phase == PomodoroPhase.focus;

    final title = session.label.trim().isEmpty
        ? (isFocus ? '专注' : '休息')
        : session.label.trim();

    final subtitle = [
      DateUtilsX.key(session.startedAt),
      DateUtilsX.durationText(session.actualSeconds),
      if (session.interrupted) '已中断',
    ].join(' · ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isFocus
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        child: Icon(
          isFocus ? Icons.timer : Icons.free_breakfast_outlined,
          size: 20,
          color: isFocus ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('删除这条记录？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('删除'),
                ),
              ],
            ),
          );
          if (ok == true) onDelete();
        },
      ),
    );
  }
}
