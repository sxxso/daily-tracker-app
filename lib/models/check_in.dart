import 'package:intl/intl.dart';

/// 单次打卡记录。同一习惯同一天最多一条（dateKey 唯一约束）。
class CheckIn {
  final int? id;
  final int habitId;

  /// 格式 yyyy-MM-dd，用于按天唯一索引与快速查询
  final String dateKey;
  final DateTime checkInAt;
  String note;
  int? mood; // 1-5，可选

  CheckIn({
    this.id,
    required this.habitId,
    required this.dateKey,
    DateTime? checkInAt,
    this.note = '',
    this.mood,
  }) : checkInAt = checkInAt ?? DateTime.now();

  static String keyFor(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date_key': dateKey,
      'check_in_at': checkInAt.millisecondsSinceEpoch,
      'note': note,
      'mood': mood,
    };
  }

  factory CheckIn.fromMap(Map<String, Object?> map) {
    return CheckIn(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      dateKey: map['date_key'] as String,
      checkInAt: DateTime.fromMillisecondsSinceEpoch(
        map['check_in_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      note: map['note'] as String? ?? '',
      mood: map['mood'] as int?,
    );
  }
}
