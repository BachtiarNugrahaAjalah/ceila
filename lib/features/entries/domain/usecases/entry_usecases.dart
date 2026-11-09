import '../../../../core/usecase/usecase.dart';
import '../entities/entry_entity.dart';
import '../repositories/entries_repository.dart';

class WatchEntries
    extends StreamUseCase<List<EntryEntity>, WatchEntriesParams> {
  final EntriesRepository repository;
  WatchEntries(this.repository);

  @override
  Stream<List<EntryEntity>> call(WatchEntriesParams params) =>
      repository.watchEntries(params);
}

class AddEntry extends UseCase<int, EntryEntity> {
  final EntriesRepository repository;
  AddEntry(this.repository);

  @override
  Future<int> call(EntryEntity params) => repository.addEntry(params);
}

class UpdateEntry extends UseCase<void, EntryEntity> {
  final EntriesRepository repository;
  UpdateEntry(this.repository);

  @override
  Future<void> call(EntryEntity params) => repository.updateEntry(params);
}

class DeleteEntry extends UseCase<void, int> {
  final EntriesRepository repository;
  DeleteEntry(this.repository);

  @override
  Future<void> call(int params) => repository.deleteEntry(params);
}

class SetTaskDone extends UseCase<void, ({int id, bool done})> {
  final EntriesRepository repository;
  SetTaskDone(this.repository);

  @override
  Future<void> call(({int id, bool done}) params) =>
      repository.setTaskDone(params.id, params.done);
}
