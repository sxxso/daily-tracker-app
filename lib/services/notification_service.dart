import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 本地通知封装。
///
/// 番茄钟阶段结束的通知用 [scheduleAt] 预排到系统闹钟，这样即使 App 被切到
/// 后台甚至被杀掉，提醒仍然会按时弹出——只靠 Dart 计时器在后台会被系统节流。
///
/// 通知是锦上添花的能力：任何初始化失败都降级为「不通知」，不让 App 崩溃。
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// 预排通知使用的固定 id，同一时刻只需一个
  static const int _scheduledPhaseId = 1001;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'daily_tracker_channel',
    '打卡与番茄钟提醒',
    channelDescription: '习惯打卡提醒与番茄钟阶段结束通知',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    category: AndroidNotificationCategory.alarm,
  );

  Future<void> init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // 时区数据用于把「本地时间」正确换算成系统闹钟触发时刻
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        final locationName = info.locationId;
        if (locationName.isNotEmpty) {
          tz.setLocalLocation(tz.getLocation(locationName));
        } else {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      } catch (e) {
        // 拿不到时区名时退回 UTC，通知时间可能略有偏差，但不会崩
        debugPrint('读取本地时区失败，退回默认时区: $e');
      }

      _ready = true;
    } catch (e) {
      debugPrint('NotificationService 初始化失败，将不发送通知: $e');
      _ready = false;
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: _androidDetails),
      );
    } catch (e) {
      debugPrint('发送通知失败: $e');
    }
  }

  /// 在 [fireAt] 时刻提醒。用于番茄钟阶段结束。
  Future<void> scheduleAt({
    required DateTime fireAt,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    // 已经过去的时间点直接跳过，避免立即弹出
    if (!fireAt.isAfter(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        _scheduledPhaseId,
        title,
        body,
        tz.TZDateTime.from(fireAt, tz.local),
        const NotificationDetails(android: _androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('预排通知失败: $e');
    }
  }

  Future<void> cancelScheduled() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_scheduledPhaseId);
    } catch (e) {
      debugPrint('取消预排通知失败: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('取消通知失败: $e');
    }
  }
}
