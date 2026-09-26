/// 打卡习惯数据模型
class Habit {
  final int? id;
  String name;
  String description;
  int colorValue;
  int iconCodePoint;
  int targetPerWeek;
  String? reminderTime; // HH:mm 格式
  bool archived;
  final DateTime createdAt;
  int sortOrder;

  Habit({
    this.id,
    required this.name,
    this.description = '',
    this.colorValue = 0xFF4CAF50,
    this.iconCodePoint = 0xe1a3, // Icons.check_circle_outline
    this.targetPerWeek = 7,
    this.reminderTime,
    this.archived = false,
    DateTime? createdAt,
    this.sortOrder = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_value': colorValue,
      'icon_code_point': iconCodePoint,
      'target_per_week': targetPerWeek,
      'reminder_time': reminderTime,
      'archived': archived ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sort_order': sortOrder,
    };
  }

  factory Habit.fromMap(Map<String, Object?> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      colorValue: map['color_value'] as int? ?? 0xFF4CAF50,
      iconCodePoint: map['icon_code_point'] as int? ?? 0xe1a3,
      targetPerWeek: map['target_per_week'] as int? ?? 7,
      reminderTime: map['reminder_time'] as String?,
      archived: (map['archived'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    int? colorValue,
    int? iconCodePoint,
    int? targetPerWeek,
    String? reminderTime,
    bool? archived,
    int? sortOrder,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      targetPerWeek: targetPerWeek ?? this.targetPerWeek,
      reminderTime: reminderTime ?? this.reminderTime,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
