import '../entities/entry_entity.dart';

class WatchEntriesParams {
  final List<EntryKind>? types;
  final String? query;
  const WatchEntriesParams({this.types, this.query});
}

abstract class EntriesRepository {
  Stream<List<EntryEntity>> watchEntries(WatchEntriesParams params);
  Future<int> addEntry(EntryEntity entry);
  Future<void> updateEntry(EntryEntity entry);
  Future<void> deleteEntry(int id);
  Future<void> setTaskDone(int id, bool done);
}
