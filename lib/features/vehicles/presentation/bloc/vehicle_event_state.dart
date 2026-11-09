import 'package:equatable/equatable.dart';

class VehicleState extends Equatable {
  final List<VehicleItem> vehicles;
  final int? selectedId;
  final bool loading;
  final String? error;

  const VehicleState({
    this.vehicles = const [],
    this.selectedId,
    this.loading = true,
    this.error,
  });

  VehicleState copyWith({
    List<VehicleItem>? vehicles,
    int? selectedId,
    bool? loading,
    String? error,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      selectedId: selectedId ?? this.selectedId,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [vehicles, selectedId, loading, error];
}

class VehicleItem extends Equatable {
  final int id;
  final String name;
  final int currentKm;
  final bool isDefault;

  const VehicleItem({
    required this.id,
    required this.name,
    required this.currentKm,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [id, name, currentKm, isDefault];
}

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();
  @override
  List<Object?> get props => [];
}

class VehiclesStarted extends VehicleEvent {
  const VehiclesStarted();
}

class VehicleAddRequested extends VehicleEvent {
  final String name;
  const VehicleAddRequested(this.name);
  @override
  List<Object?> get props => [name];
}

class VehicleUpdateKmRequested extends VehicleEvent {
  final int vehicleId;
  final int newKm;
  const VehicleUpdateKmRequested(this.vehicleId, this.newKm);
  @override
  List<Object?> get props => [vehicleId, newKm];
}

class VehicleDeleteRequested extends VehicleEvent {
  final int vehicleId;
  const VehicleDeleteRequested(this.vehicleId);
  @override
  List<Object?> get props => [vehicleId];
}

class VehicleSetDefaultRequested extends VehicleEvent {
  final int vehicleId;
  const VehicleSetDefaultRequested(this.vehicleId);
  @override
  List<Object?> get props => [vehicleId];
}

class VehiclesLoaded extends VehicleEvent {
  final List<VehicleItem> vehicles;
  const VehiclesLoaded(this.vehicles);
  @override
  List<Object?> get props => [vehicles];
}