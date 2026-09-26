import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../utils/constants.dart';

/// 习惯新增 / 编辑表单
class HabitEditScreen extends StatefulWidget {
  const HabitEditScreen({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitEditScreen> createState() => _HabitEditScreenState();
}

class _HabitEditScreenState extends State<HabitEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  late Color _color;
  late IconData _icon;
  late int _targetPerWeek;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descController = TextEditingController(text: h?.description ?? '');
    _color = h == null ? AppConstants.habitPalette.first : Color(h.colorValue);
    _icon = h == null
        ? AppConstants.habitIcons.first
        : IconData(h.iconCodePoint, fontFamily: 'MaterialIcons');
    _targetPerWeek = h?.targetPerWeek ?? 7;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑习惯' : '新增习惯'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Preview(name: _nameController.text, color: _color, icon: _icon),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              maxLength: 20,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: '习惯名称',
                hintText: '例如：早起、读书 30 分钟',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入习惯名称' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLength: 60,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '提醒自己为什么坚持',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            const _Label('选择图标'),
            const SizedBox(height: 10),
            _IconPicker(
              selected: _icon,
              color: _color,
              onChanged: (i) => setState(() => _icon = i),
            ),
            const SizedBox(height: 24),
            const _Label('选择颜色'),
            const SizedBox(height: 10),
            _ColorPicker(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 24),
            const _Label('每周目标'),
            const SizedBox(height: 10),
            _TargetPicker(
              value: _targetPerWeek,
              onChanged: (v) => setState(() => _targetPerWeek = v),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<HabitProvider>();
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (_isEditing) {
      await provider.updateHabit(
        widget.habit!.copyWith(
          name: name,
          description: desc,
          colorValue: _color.toARGB32(),
          iconCodePoint: _icon.codePoint,
          targetPerWeek: _targetPerWeek,
        ),
      );
    } else {
      await provider.addHabit(
        Habit(
          name: name,
          description: desc,
          colorValue: _color.toARGB32(),
          iconCodePoint: _icon.codePoint,
          targetPerWeek: _targetPerWeek,
          sortOrder: provider.habits.length,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? '已保存修改' : '已添加「$name」')),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.name, required this.color, required this.icon});

  final String name;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name.trim().isEmpty ? '新习惯' : name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: name.trim().isEmpty
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final IconData selected;
  final Color color;
  final ValueChanged<IconData> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.habitIcons.map((icon) {
        final isSelected = icon.codePoint == selected.codePoint;
        return GestureDetector(
          onTap: () => onChanged(icon),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.18)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppConstants.habitPalette.map((c) {
        final isSelected = c.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () => onChanged(c),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _TargetPicker extends StatelessWidget {
  const _TargetPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          label: '每周 $value 次',
          onChanged: (v) => onChanged(v.round()),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '每周 $value 次${value == 7 ? '（每天）' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
