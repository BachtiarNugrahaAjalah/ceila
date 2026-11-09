import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/vehicles_repository.dart';

class VehiclesRepositoryImpl implements VehiclesRepository {
  final AppDatabase db;
  VehiclesRepositoryImpl(this.db);

  @override
  Stream<List<VehicleEntity>> watchVehicles() {
    return db.select(db.vehicles).watch().map(
          (rows) => rows
              .map((v) => VehicleEntity(
                    id: v.id,
                    name: v.name,
                    currentKm: v.currentKm,
                    isDefault: v.isDefault,
                  ))
              .toList(),
        );
  }

  @override
  Future<void> addVehicle(String name) async {
    await db.into(db.vehicles).insert(VehiclesCompanion.insert(name: name));
  }

  @override
  Future<void> updateKm(int id, int newKm) async {
    await (db.update(db.vehicles)..where((t) => t.id.equals(id)))
        .write(VehiclesCompanion(currentKm: Value(newKm)));
  }

  @override
  Future<void> deleteVehicle(int id) async {
    await (db.delete(db.vehicles)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> setDefault(int id) async {
    await db.transaction(() async {
      await (db.update(db.vehicles)..where((t) => t.isDefault.equals(true)))
          .write(const VehiclesCompanion(isDefault: Value(false)));
      await (db.update(db.vehicles)..where((t) => t.id.equals(id)))
          .write(const VehiclesCompanion(isDefault: Value(true)));
    });
  }

  @override
  Future<VehicleEntity> getDefaultVehicle() async {
    final v = await (db.select(db.vehicles)
          ..where((t) => t.isDefault.equals(true))
          ..limit(1))
        .getSingle();
    return VehicleEntity(
      id: v.id,
      name: v.name,
      currentKm: v.currentKm,
      isDefault: v.isDefault,
    );
  }
}