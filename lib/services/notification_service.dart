import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = 
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    // 处理通知点击
    // 可以通过 payload 传递任务ID等信息
  }

  static Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// 发送即时通知
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      '任务提醒',
      channelDescription: '社交任务提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// 预约通知
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      return; // 不预约过去的时间
    }
    
    const androidDetails = AndroidNotificationDetails(
      'task_schedule_channel',
      '定时任务',
      channelDescription: '定时任务提醒',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// 取消预约通知
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// 取消所有通知
  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// 发送任务提醒
  static Future<void> showTaskReminder(SocialTask task) async {
    await showNotification(
      id: task.id.hashCode,
      title: '📋 ${task.title}',
      body: task.description,
      payload: task.id,
    );
  }

  /// 预约任务提醒
  static Future<void> scheduleTaskReminder(SocialTask task) async {
    await scheduleNotification(
      id: task.id.hashCode,
      title: '📋 ${task.title}',
      body: task.description,
      scheduledTime: task.scheduledAt,
      payload: task.id,
    );
  }

  /// 发送每日任务汇总
  static Future<void> showDailyTaskSummary(List<SocialTask> tasks) async {
    if (tasks.isEmpty) return;
    
    final pendingCount = tasks.where((t) => t.status == TaskStatus.pending).length;
    if (pendingCount == 0) return;
    
    await showNotification(
      id: 'daily_summary'.hashCode,
      title: '🌟 今日社交任务',
      body: '您有 $pendingCount 个待完成的社交任务，快去看看吧！',
      payload: 'daily_summary',
    );
  }
}
