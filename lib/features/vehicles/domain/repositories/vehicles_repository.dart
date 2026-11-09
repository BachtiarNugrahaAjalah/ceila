import '../entities/vehicle_entity.dart';

class WatchVehiclesParams {
  const WatchVehiclesParams();
}

abstract class VehiclesRepository {
  Stream<List<VehicleEntity>> watchVehicles();
  Future<void> addVehicle(String name);
  Future<void> updateKm(int id, int newKm);
  Future<void> deleteVehicle(int id);
  Future<void> setDefault(int id);
  Future<VehicleEntity> getDefaultVehicle();
}