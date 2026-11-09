import 'package:equatable/equatable.dart';

enum EntryKind { task, income, expense, maintenance }

enum TaskReminderMode { repeatReminder, recurringTask }

enum TaskRecurrence { daily, weekly, monthly }

class EntryEntity extends Equatable {
  final int? id;
  final EntryKind type;
  final String title;
  final String? note;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isDone;
  final TaskReminderMode? reminderMode;
  final TaskRecurrence? recurrenceRule;
  final int? amount;
  final String? category;
  final int? vehicleId;
  final int? odometerKm;
  final int? nextKm;

  const EntryEntity({
    this.id,
    required this.type,
    required this.title,
    this.note,
    required this.createdAt,
    this.dueDate,
    this.isDone = false,
    this.reminderMode,
    this.recurrenceRule,
    this.amount,
    this.category,
    this.vehicleId,
    this.odometerKm,
    this.nextKm,
  });

  bool get isOverdue =>
      type == EntryKind.task &&
      !isDone &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  EntryEntity copyWith({
    int? id,
    EntryKind? type,
    String? title,
    String? note,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? clearDueDate,
    bool? isDone,
    TaskReminderMode? reminderMode,
    TaskRecurrence? recurrenceRule,
    int? amount,
    String? category,
    int? vehicleId,
    int? odometerKm,
    int? nextKm,
  }) {
    return EntryEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate == true ? null : (dueDate ?? this.dueDate),
      isDone: isDone ?? this.isDone,
      reminderMode: reminderMode ?? this.reminderMode,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      vehicleId: vehicleId ?? this.vehicleId,
      odometerKm: odometerKm ?? this.odometerKm,
      nextKm: nextKm ?? this.nextKm,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    note,
    createdAt,
    dueDate,
    isDone,
    reminderMode,
    recurrenceRule,
    amount,
    category,
    vehicleId,
    odometerKm,
    nextKm,
  ];
}
