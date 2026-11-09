import 'package:ceila/core/database/app_database.dart';
import 'package:ceila/features/entries/data/datasources/entries_local_datasource.dart';
import 'package:ceila/features/entries/data/repositories/entries_repository_impl.dart';
import 'package:ceila/features/entries/domain/entities/entry_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEntriesLocalDataSource extends Mock
    implements EntriesLocalDataSource {}

void main() {
  late _MockEntriesLocalDataSource local;
  late EntriesRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const EntriesCompanion());
  });

  setUp(() {
    local = _MockEntriesLocalDataSource();
    repository = EntriesRepositoryImpl(local);
  });

  test('assigns the default vehicle to maintenance entries', () async {
    when(() => local.getDefaultVehicleId()).thenAnswer((_) async => 7);
    when(() => local.addEntry(any())).thenAnswer((_) async => 1);
    final entry = EntryEntity(
      type: EntryKind.maintenance,
      title: 'Ganti oli',
      createdAt: DateTime(2026, 11, 10),
    );

    await repository.addEntry(entry);

    final companion =
        verify(() => local.addEntry(captureAny())).captured.single
            as EntriesCompanion;
    expect(companion.vehicleId.value, 7);
  });

  test('keeps an explicitly assigned maintenance vehicle', () async {
    when(() => local.addEntry(any())).thenAnswer((_) async => 1);
    final entry = EntryEntity(
      type: EntryKind.maintenance,
      title: 'Ganti oli',
      createdAt: DateTime(2026, 11, 10),
      vehicleId: 3,
    );

    await repository.addEntry(entry);

    verifyNever(() => local.getDefaultVehicleId());
    final companion =
        verify(() => local.addEntry(captureAny())).captured.single
            as EntriesCompanion;
    expect(companion.vehicleId.value, 3);
  });
}
