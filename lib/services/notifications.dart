import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/date_utils.dart';
import '../domain/models.dart';
import '../domain/recurrence.dart';

/// Локальные напоминания. По умолчанию у дел выключены.
///
/// ID уведомлений детерминированы от id дела, чтобы можно было пере/отменять
/// при сохранении, сдвиге по зависимости и удалении.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'daylane_reminders';
  static const _channelName = 'Напоминания';

  /// Диапазон id, зарезервированный под одно дело (для правила eachDay).
  static const int _slotsPerTask = 64;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      // Реальная зона устройства (иначе tz.local = UTC и время уедет).
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      /* оставляем tz.local как есть, если зону не удалось определить */
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Напоминания о делах DayLane',
        importance: Importance.high,
      ),
    );
    _ready = true;
  }

  Future<void> requestPermissions() async {
    await init();
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    // На Android 13+ точные будильники требуют отдельного разрешения.
    await android?.requestExactAlarmsPermission();
  }

  int _baseId(int taskId) => taskId * _slotsPerTask;

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  /// Пере-планирует напоминания для дела (сперва отменяет старые).
  Future<void> reschedule(TaskModel task) async {
    await init();
    await cancelForTask(task.id);
    if (task.id == null || !task.reminderEnabled || task.isDone ||
        task.deferred) {
      return;
    }

    final base = _baseId(task.id!);
    final dates = _reminderDates(task);
    for (var i = 0; i < dates.length && i < _slotsPerTask; i++) {
      // Сдвиг «за N дней до».
      final fireDate = addDays(dates[i], -task.reminderDaysBefore);
      final when = _atTime(fireDate, task.reminderMinutes);
      if (when.isBefore(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        id: base + i,
        title: task.title,
        body: _body(task, dates[i]),
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelForTask(int? taskId) async {
    if (taskId == null) return;
    await init();
    final base = _baseId(taskId);
    for (var i = 0; i < _slotsPerTask; i++) {
      await _plugin.cancel(id: base + i);
    }
  }

  List<DateTime> _reminderDates(TaskModel t) {
    if (t.isRecurring) {
      return nextOccurrences(t, dateOnly(DateTime.now()), 12);
    }
    if (t.isSingle) return [t.startDate];
    switch (t.reminderRule) {
      case ReminderRule.atStart:
        return [t.startDate];
      case ReminderRule.atEnd:
        return [t.endDate];
      case ReminderRule.eachDay:
        final out = <DateTime>[];
        for (var day = dateOnly(t.startDate);
            !day.isAfter(dateOnly(t.endDate));
            day = addDays(day, 1)) {
          out.add(day);
        }
        return out;
    }
  }

  String _body(TaskModel t, DateTime day) {
    if (t.isPeriod) {
      final n = daysBetween(t.startDate, day) + 1;
      return '${dayOfPeriodLabel(n, t.durationDays)} · ${formatDayMonth(day)}';
    }
    return formatDayMonth(day);
  }

  tz.TZDateTime _atTime(DateTime date, int minutes) {
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      minutes ~/ 60,
      minutes % 60,
    );
  }
}
