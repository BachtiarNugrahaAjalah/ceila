import 'package:equatable/equatable.dart';

class VehicleEntity extends Equatable {
  final int id;
  final String name;
  final int currentKm;
  final bool isDefault;

  const VehicleEntity({
    required this.id,
    required this.name,
    required this.currentKm,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [id, name, currentKm, isDefault];
}