import 'dart:async';
import 'dart:collection';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import 'vehicle_event_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final AppDatabase _db;
  StreamSubscription<dynamic>? _sub;

  VehicleBloc(this._db) : super(const VehicleState()) {
    on<VehiclesStarted>(_onStarted);
    on<VehicleAddRequested>(_onAdd);
    on<VehicleUpdateKmRequested>(_onUpdateKm);
    on<VehicleDeleteRequested>(_onDelete);
    on<VehicleSetDefaultRequested>(_onSetDefault);
    on<VehiclesLoaded>(_onLoaded);
  }

  Future<void> _onStarted(VehiclesStarted event, Emitter<VehicleState> emit) async {
    emit(state.copyWith(loading: true));
    _sub?.cancel();
    _sub = _db
        .select(_db.vehicles)
        .watch()
        .map((rows) => rows
            .map((v) => VehicleItem(
                  id: v.id,
                  name: v.name,
                  currentKm: v.currentKm,
                  isDefault: v.isDefault,
                ))
            .toList())
        .listen((items) => add(VehiclesLoaded(items)));
  }

  void _onLoaded(VehiclesLoaded event, Emitter<VehicleState> emit) {
    final def = event.vehicles
        .where((v) => v.isDefault)
        .map((v) => v.id)
        .firstOrNull;
    emit(state.copyWith(
      vehicles: event.vehicles,
      selectedId: def,
      loading: false,
    ));
  }

  Future<void> _onAdd(VehicleAddRequested event, Emitter<VehicleState> emit) async {
    await _db.into(_db.vehicles).insert(
          VehiclesCompanion.insert(name: event.name),
        );
  }

  Future<void> _onUpdateKm(
    VehicleUpdateKmRequested event,
    Emitter<VehicleState> emit,
  ) async {
    await (_db.update(_db.vehicles)
          ..where((t) => t.id.equals(event.vehicleId)))
        .write(VehiclesCompanion(currentKm: Value(event.newKm)));
  }

  Future<void> _onDelete(
    VehicleDeleteRequested event,
    Emitter<VehicleState> emit,
  ) async {
    await (_db.delete(_db.vehicles)
          ..where((t) => t.id.equals(event.vehicleId)))
        .go();
  }

  Future<void> _onSetDefault(
    VehicleSetDefaultRequested event,
    Emitter<VehicleState> emit,
  ) async {
    await _db.transaction(() async {
      await (_db.update(_db.vehicles)
            ..where((t) => t.isDefault.equals(true)))
          .write(const VehiclesCompanion(isDefault: Value(false)));
      await (_db.update(_db.vehicles)
            ..where((t) => t.id.equals(event.vehicleId)))
          .write(const VehiclesCompanion(isDefault: Value(true)));
    });
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}