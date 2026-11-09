import '../../../../core/database/tables.dart';
import '../../domain/entities/entry_entity.dart';
import '../../domain/repositories/entries_repository.dart';
import '../datasources/entries_local_datasource.dart';
import '../models/entry_mapper.dart';

class EntriesRepositoryImpl implements EntriesRepository {
  final EntriesLocalDataSource local;
  EntriesRepositoryImpl(this.local);

  @override
  Stream<List<EntryEntity>> watchEntries(WatchEntriesParams params) {
    final types = params.types
        ?.map((k) => EntryType.values.byName(k.name))
        .toList();
    return local
        .watchEntries(types: types, query: params.query)
        .map((rows) => rows.map(entryFromRow).toList());
  }

  @override
  Future<int> addEntry(EntryEntity entry) async {
    final entryWithVehicle = await _withDefaultVehicle(entry);
    return local.addEntry(entryToCompanion(entryWithVehicle));
  }

  @override
  Future<void> updateEntry(EntryEntity entry) async {
    final entryWithVehicle = await _withDefaultVehicle(entry);
    await local.updateEntry(entryToRow(entryWithVehicle));
  }

  @override
  Future<void> deleteEntry(int id) => local.deleteEntry(id);

  @override
  Future<void> setTaskDone(int id, bool done) => local.setTaskDone(id, done);

  Future<EntryEntity> _withDefaultVehicle(EntryEntity entry) async {
    if (entry.type != EntryKind.maintenance || entry.vehicleId != null) {
      return entry;
    }

    return entry.copyWith(vehicleId: await local.getDefaultVehicleId());
  }
}
