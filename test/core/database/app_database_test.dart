import 'package:ceila/core/database/app_database.dart';
import 'package:ceila/core/database/tables.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('watchOpenTasks returns unfinished tasks only', () async {
    await database
        .into(database.entries)
        .insert(
          EntriesCompanion.insert(type: EntryType.task, title: 'Open task'),
        );
    await database
        .into(database.entries)
        .insert(
          EntriesCompanion.insert(
            type: EntryType.task,
            title: 'Completed task',
            isDone: const Value(true),
          ),
        );
    await database
        .into(database.entries)
        .insert(
          EntriesCompanion.insert(type: EntryType.income, title: 'Income'),
        );

    final tasks = await database.watchOpenTasks().first;

    expect(tasks.map((task) => task.title), ['Open task']);
  });
}
