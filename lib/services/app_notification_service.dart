import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleTaskNotifications({
    required List<Task> tasks,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await initialize();
    await _plugin.cancelAll();
    if (!enabled) return;

    for (final task in tasks) {
      final dueAt = _dueDateTime(task.nextDue, hour, minute);
      final now = tz.TZDateTime.now(tz.local);
      if (!dueAt.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        _notificationIdForTask(task.id),
        '${task.emoji} ${task.name} is due',
        'Open Life Maintenance to mark it done.',
        dueAt,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'due_tasks',
            'Due Tasks',
            channelDescription: 'Task due reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id,
      );
    }
  }

  int _notificationIdForTask(String taskId) {
    return taskId.hashCode & 0x7fffffff;
  }

  tz.TZDateTime _dueDateTime(String nextDue, int hour, int minute) {
    final parts = nextDue.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return tz.TZDateTime(tz.local, year, month, day, hour, minute);
  }
}
