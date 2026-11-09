import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';

class EntriesLocalDataSource {
  final AppDatabase db;
  EntriesLocalDataSource(this.db);

  Stream<List<Entry>> watchEntries({List<EntryType>? types, String? query}) =>
      db.watchEntries(types: types, query: query);

  Future<int> addEntry(EntriesCompanion entry) => db.addEntry(entry);

  Future<bool> updateEntry(Entry entry) => db.updateEntry(entry);

  Future<int> deleteEntry(int id) => db.deleteEntry(id);

  Future<int> setTaskDone(int id, bool done) => db.setTaskDone(id, done);

  Future<int> getDefaultVehicleId() async => (await db.getDefaultVehicle()).id;
}
