import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/check_in.dart';
import '../models/habit.dart';
import '../models/pomodoro_session.dart';
import '../utils/constants.dart';

/// 本地 SQLite 数据库封装。所有读写集中在此，UI 层不直接接触 sqflite。
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableHabits} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        target_per_week INTEGER NOT NULL DEFAULT 7,
        reminder_time TEXT,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 同一习惯同一天只能有一条打卡记录
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCheckIns} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date_key TEXT NOT NULL,
        check_in_at INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        mood INTEGER,
        UNIQUE(habit_id, date_key),
        FOREIGN KEY(habit_id) REFERENCES ${AppConstants.tableHabits}(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_checkins_date ON ${AppConstants.tableCheckIns}(date_key)',
    );

    await db.execute('''
      CREATE TABLE ${AppConstants.tablePomodoro} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER,
        label TEXT NOT NULL DEFAULT '',
        planned_minutes INTEGER NOT NULL,
        actual_seconds INTEGER NOT NULL DEFAULT 0,
        phase TEXT NOT NULL DEFAULT 'focus',
        interrupted INTEGER NOT NULL DEFAULT 0,
        started_at INTEGER NOT NULL,
        ended_at INTEGER NOT NULL,
        day_key TEXT NOT NULL,
        FOREIGN KEY(habit_id) REFERENCES ${AppConstants.tableHabits}(id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_pomodoro_day ON ${AppConstants.tablePomodoro}(day_key)',
    );

    await db.execute('''
      CREATE TABLE ${AppConstants.tableSettings} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ---------------------------------------------------------------- 习惯 CRUD

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return db.insert(AppConstants.tableHabits, habit.toMap()..remove('id'));
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update(
      AppConstants.tableHabits,
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(int id) async {
    final db = await database;
    await db.delete(AppConstants.tableHabits, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Habit>> getHabits({bool includeArchived = false}) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableHabits,
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  // ---------------------------------------------------------------- 打卡记录

  Future<void> checkIn(int habitId, {DateTime? at, String note = ''}) async {
    final db = await database;
    final when = at ?? DateTime.now();
    await db.insert(
      AppConstants.tableCheckIns,
      CheckIn(
        habitId: habitId,
        dateKey: CheckIn.keyFor(when),
        checkInAt: when,
        note: note,
      ).toMap()
        ..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> undoCheckIn(int habitId, DateTime date) async {
    final db = await database;
    await db.delete(
      AppConstants.tableCheckIns,
      where: 'habit_id = ? AND date_key = ?',
      whereArgs: [habitId, CheckIn.keyFor(date)],
    );
  }

  Future<List<CheckIn>> getCheckInsForHabit(int habitId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableCheckIns,
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date_key DESC',
    );
    return rows.map(CheckIn.fromMap).toList();
  }

  /// 全部打卡记录的 dateKey 集合，按 habitId 分组。用于一次查询渲染整月日历。
  Future<Map<int, Set<String>>> getAllCheckInKeys() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableCheckIns,
      columns: ['habit_id', 'date_key'],
    );
    final result = <int, Set<String>>{};
    for (final row in rows) {
      final habitId = row['habit_id'] as int;
      result.putIfAbsent(habitId, () => <String>{}).add(row['date_key'] as String);
    }
    return result;
  }

  /// 某天已打卡的习惯 id 集合
  Future<Set<int>> getCheckedHabitIdsOn(DateTime date) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableCheckIns,
      columns: ['habit_id'],
      where: 'date_key = ?',
      whereArgs: [CheckIn.keyFor(date)],
    );
    return rows.map((r) => r['habit_id'] as int).toSet();
  }

  /// 指定日期区间内的每日打卡总数：{dateKey: count}
  Future<Map<String, int>> getDailyCheckInCounts({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT date_key, COUNT(*) AS cnt
      FROM ${AppConstants.tableCheckIns}
      WHERE date_key BETWEEN ? AND ?
      GROUP BY date_key
    ''', [CheckIn.keyFor(from), CheckIn.keyFor(to)]);
    return {
      for (final r in rows) r['date_key'] as String: r['cnt'] as int,
    };
  }

  // ------------------------------------------------------------ 番茄钟记录

  Future<int> insertPomodoro(PomodoroSession session) async {
    final db = await database;
    return db.insert(
      AppConstants.tablePomodoro,
      session.toMap()..remove('id'),
    );
  }

  Future<void> deletePomodoro(int id) async {
    final db = await database;
    await db.delete(
      AppConstants.tablePomodoro,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PomodoroSession>> getPomodoroSessions({
    DateTime? from,
    DateTime? to,
    PomodoroPhase? phase,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('day_key >= ?');
      args.add(PomodoroSession.dayKeyOf(from));
    }
    if (to != null) {
      where.add('day_key <= ?');
      args.add(PomodoroSession.dayKeyOf(to));
    }
    if (phase != null) {
      where.add('phase = ?');
      args.add(phase.name);
    }
    final rows = await db.query(
      AppConstants.tablePomodoro,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'started_at DESC',
    );
    return rows.map(PomodoroSession.fromMap).toList();
  }

  /// 指定区间内每个「已完成专注番茄」的聚合：{dateKey: {'count': n, 'seconds': s}}
  Future<Map<String, Map<String, int>>> getPomodoroDailyStats({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT day_key,
             COUNT(*) AS cnt,
             COALESCE(SUM(actual_seconds), 0) AS secs
      FROM ${AppConstants.tablePomodoro}
      WHERE phase = ? AND interrupted = 0 AND day_key BETWEEN ? AND ?
      GROUP BY day_key
    ''', [
      PomodoroPhase.focus.name,
      PomodoroSession.dayKeyOf(from),
      PomodoroSession.dayKeyOf(to),
    ]);
    return {
      for (final r in rows)
        r['day_key'] as String: {
          'count': r['cnt'] as int,
          'seconds': (r['secs'] as num).toInt(),
        },
    };
  }

  // ---------------------------------------------------------------- 设置项

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableSettings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      AppConstants.tableSettings,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
