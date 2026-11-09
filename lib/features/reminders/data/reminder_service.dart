import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/database/app_database.dart';
import '../../entries/domain/entities/entry_entity.dart';
import '../../settings/data/settings_repository.dart';

class ReminderService {
  final AppDatabase db;
  final SettingsRepository settings;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<List<Entry>>? _sub;
  bool _initialized = false;

  ReminderService(this.db, this.settings);

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _initialized = true;
  }

  Future<void> startWatching() async {
    if (kIsWeb) return;
    if (!await settings.getRemindersEnabled()) return;
    await init();
    _sub?.cancel();
    _sub = db.watchOverdueTasks().listen((rows) async {
      for (final row in rows) {
        await _showOverdue(row);
      }
    });
  }

  Future<void> scheduleForEntry(EntryEntity entry) async {
    if (kIsWeb) return;
    if (!await settings.getRemindersEnabled()) return;
    if (entry.dueDate == null || entry.id == null) return;
    await init();
    final when = tz.TZDateTime.from(entry.dueDate!, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ceila_due',
        'Pengingat',
        channelDescription: 'Pengingat tenggat dan jadwal',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      entry.id!,
      'Pengingat: ${entry.title}',
      'Sudah waktunya.',
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> _showOverdue(Entry row) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ceila_overdue',
        'Tugas terlambat',
        channelDescription: 'Pengingat berulang tugas terlambat',
        importance: Importance.max,
        priority: Priority.high,
        actions: [AndroidNotificationAction('done', 'Tandai selesai')],
      ),
    );
    await _plugin.show(
      100000 + row.id,
      'Tugas terlambat',
      row.title,
      details,
      payload: '${row.id}',
    );
  }

  void _onResponse(NotificationResponse response) {
    if (response.actionId == 'done' && response.payload != null) {
      final id = int.tryParse(response.payload!);
      if (id != null) db.setTaskDone(id, true);
    }
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  Future<void> dispose() async => _sub?.cancel();
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}
