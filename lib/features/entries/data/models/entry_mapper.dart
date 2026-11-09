import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/tables.dart';
import '../../domain/entities/entry_entity.dart';

EntryType _toDbType(EntryKind k) => EntryType.values.byName(k.name);
EntryKind _toDomainType(EntryType t) => EntryKind.values.byName(t.name);

EntryEntity entryFromRow(db.Entry row) {
  return EntryEntity(
    id: row.id,
    type: _toDomainType(row.type),
    title: row.title,
    note: row.note,
    createdAt: row.createdAt,
    dueDate: row.dueDate,
    isDone: row.isDone,
    reminderMode: row.reminderMode == null
        ? null
        : TaskReminderMode.values.byName(row.reminderMode!.name),
    recurrenceRule: row.recurrenceRule == null
        ? null
        : TaskRecurrence.values.byName(row.recurrenceRule!.name),
    amount: row.amount,
    category: row.category,
    vehicleId: row.vehicleId,
    odometerKm: row.odometerKm,
    nextKm: row.nextKm,
  );
}

db.EntriesCompanion entryToCompanion(EntryEntity e) {
  return db.EntriesCompanion(
    type: drift.Value(_toDbType(e.type)),
    title: drift.Value(e.title),
    note: drift.Value(e.note),
    dueDate: drift.Value(e.dueDate),
    isDone: drift.Value(e.isDone),
    reminderMode: drift.Value(
      e.reminderMode == null
          ? null
          : ReminderMode.values.byName(e.reminderMode!.name),
    ),
    recurrenceRule: drift.Value(
      e.recurrenceRule == null
          ? null
          : RecurrenceRule.values.byName(e.recurrenceRule!.name),
    ),
    amount: drift.Value(e.amount),
    category: drift.Value(e.category),
    vehicleId: drift.Value(e.vehicleId),
    odometerKm: drift.Value(e.odometerKm),
    nextKm: drift.Value(e.nextKm),
  );
}

db.Entry entryToRow(EntryEntity e) {
  return db.Entry(
    id: e.id!,
    type: _toDbType(e.type),
    title: e.title,
    note: e.note,
    createdAt: e.createdAt,
    dueDate: e.dueDate,
    isDone: e.isDone,
    reminderMode: e.reminderMode == null
        ? null
        : ReminderMode.values.byName(e.reminderMode!.name),
    recurrenceRule: e.recurrenceRule == null
        ? null
        : RecurrenceRule.values.byName(e.recurrenceRule!.name),
    amount: e.amount,
    category: e.category,
    vehicleId: e.vehicleId,
    odometerKm: e.odometerKm,
    nextKm: e.nextKm,
  );
}
