import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../../core/database/app_database.dart';
import '../../entries/domain/entities/entry_entity.dart';
import '../../entries/domain/usecases/entry_usecases.dart';
import '../../reminders/data/reminder_service.dart';
import '../../settings/data/settings_repository.dart';

class OverlayService {
  static bool get isPlatformSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final AppDatabase _database;
  final AddEntry _addEntry;
  final SetTaskDone _setTaskDone;
  final ReminderService _reminders;
  final SettingsRepository _settings;
  StreamSubscription<dynamic>? _subscription;

  OverlayService(
    this._database,
    this._addEntry,
    this._setTaskDone,
    this._reminders,
    this._settings,
  );

  Future<void> start() async {
    if (!isPlatformSupported) return;
    _subscription ??= FlutterOverlayWindow.overlayListener.listen(
      (message) => unawaited(_handleMessage(message)),
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      },
    );

    if (!await _settings.getOverlayEnabled()) return;
    try {
      if (await FlutterOverlayWindow.isPermissionGranted() &&
          !await FlutterOverlayWindow.isActive()) {
        await show();
      }
    } on PlatformException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
  }

  Future<void> show() async {
    if (!isPlatformSupported) return;
    if (await FlutterOverlayWindow.isActive()) return;
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) {
      throw PlatformException(
        code: 'OVERLAY_DISPLAY_UNAVAILABLE',
        message: 'Android display metrics are not available.',
      );
    }
    final view = views.first;
    final pixelRatio = view.devicePixelRatio;
    if (view.physicalSize.isEmpty || pixelRatio <= 0) {
      throw PlatformException(
        code: 'OVERLAY_DISPLAY_UNAVAILABLE',
        message: 'Android display metrics are invalid.',
      );
    }
    final logicalSize = view.physicalSize / pixelRatio;
    final bubbleSize = (76 * pixelRatio).round();
    await FlutterOverlayWindow.showOverlay(
      height: bubbleSize,
      width: bubbleSize,
      alignment: OverlayAlignment.bottomRight,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: 'Ceila aktif',
      overlayContent: 'Ketuk untuk mencatat dengan cepat',
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      startPosition: const OverlayPosition(0, 0),
    );
    var started = false;
    for (var attempt = 0; attempt < 20; attempt++) {
      if (await FlutterOverlayWindow.isActive()) {
        started = true;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!started) {
      throw PlatformException(
        code: 'OVERLAY_START_TIMEOUT',
        message: 'Android overlay service did not start.',
      );
    }
    await FlutterOverlayWindow.shareData({
      'action': 'screen_size',
      'width': logicalSize.width,
      'height': logicalSize.height,
    });
  }

  Future<void> stop() async {
    if (!isPlatformSupported) return;
    await FlutterOverlayWindow.closeOverlay();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  Future<void> _handleMessage(dynamic message) async {
    if (message is! Map) return;

    switch (message['action']) {
      case 'add_entry':
        await _handleAddEntry(message);
        return;
      case 'complete_task':
        await _handleCompleteTask(message);
        return;
      case 'load_open_tasks':
        await _sendOpenTasks();
        return;
      case 'stop_overlay':
        await _settings.setOverlayEnabled(false);
        await stop();
        return;
    }
  }

  Future<void> _handleAddEntry(Map<dynamic, dynamic> message) async {
    final title = message['title'];
    final type = switch (message['type']) {
      'task' => EntryKind.task,
      'income' => EntryKind.income,
      'expense' => EntryKind.expense,
      'maintenance' => EntryKind.maintenance,
      _ => null,
    };
    if (title is! String ||
        title.trim().isEmpty ||
        title.trim().length > 120 ||
        type == null) {
      await _send({
        'action': 'entry_result',
        'success': false,
        'message': 'Periksa judul dan tipe catatan.',
      });
      return;
    }

    final amount = _readInt(message['amount']);
    if ((type == EntryKind.income || type == EntryKind.expense) &&
        (amount == null || amount < 0)) {
      await _send({
        'action': 'entry_result',
        'success': false,
        'message': 'Nominal tidak valid.',
      });
      return;
    }

    final rawDueDate = message['dueDate'];
    final dueDate = rawDueDate is String ? DateTime.tryParse(rawDueDate) : null;
    if (rawDueDate != null && dueDate == null) {
      await _send({
        'action': 'entry_result',
        'success': false,
        'message': 'Tanggal tidak valid.',
      });
      return;
    }
    final entry = EntryEntity(
      type: type,
      title: title.trim(),
      note: _readText(message['note']),
      createdAt: DateTime.now(),
      dueDate: dueDate,
      amount: amount,
      category: _readText(message['category']),
      odometerKm: _readInt(message['odometerKm']),
      nextKm: _readInt(message['nextKm']),
    );

    try {
      final id = await _addEntry(entry);
      try {
        await _reminders.scheduleForEntry(entry.copyWith(id: id));
      } on PlatformException catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      }
      await _send({
        'action': 'entry_result',
        'success': true,
        'message': 'Catatan tersimpan.',
      });
    } on Exception catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      await _send({
        'action': 'entry_result',
        'success': false,
        'message': 'Catatan gagal disimpan.',
      });
    }
  }

  Future<void> _handleCompleteTask(Map<dynamic, dynamic> message) async {
    final id = _readInt(message['id']);
    if (id == null) {
      await _send({'action': 'task_result', 'success': false});
      return;
    }
    try {
      await _setTaskDone((id: id, done: true));
      await _reminders.cancel(id);
      await _send({'action': 'task_result', 'success': true});
      await _sendOpenTasks();
    } on Exception catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      await _send({'action': 'task_result', 'success': false});
    }
  }

  Future<void> _sendOpenTasks() async {
    try {
      final rows = await _database.watchOpenTasks().first;
      await _send({
        'action': 'open_tasks',
        'items': rows
            .map(
              (row) => {
                'id': row.id,
                'title': row.title,
                'dueDate': row.dueDate?.toIso8601String(),
              },
            )
            .toList(),
      });
    } on Exception catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      await _send({'action': 'open_tasks_error'});
    }
  }

  Future<void> _send(Map<String, Object?> message) async {
    try {
      await FlutterOverlayWindow.shareData(message);
    } on PlatformException catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    return value is String ? int.tryParse(value) : null;
  }

  String? _readText(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
