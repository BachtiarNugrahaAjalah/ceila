import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/vehicle_bloc.dart';
import '../bloc/vehicle_event_state.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kendaraan')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<VehicleBloc, VehicleState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.vehicles.isEmpty) {
            return const Center(child: Text('Belum ada kendaraan.'));
          }
          return ListView.builder(
            itemCount: state.vehicles.length,
            itemBuilder: (context, i) {
              final v = state.vehicles[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(v.name),
                  subtitle: Text('${v.currentKm} km'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (v.isDefault)
                        const Chip(
                          label: Text('Default'),
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showUpdateKm(context, v.id, v.currentKm),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: v.isDefault
                            ? null
                            : () => context
                                .read<VehicleBloc>()
                                .add(VehicleDeleteRequested(v.id)),
                      ),
                    ],
                  ),
                  onTap: () => context
                      .read<VehicleBloc>()
                      .add(VehicleSetDefaultRequested(v.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    _name.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nama Kendaraan'),
        content: TextField(
          controller: _name,
          decoration: const InputDecoration(hintText: 'Contoh: Motor Avanza'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true && _name.text.trim().isNotEmpty && context.mounted) {
      context
          .read<VehicleBloc>()
          .add(VehicleAddRequested(_name.text.trim()));
    }
  }

  Future<void> _showUpdateKm(
    BuildContext context,
    int id,
    int current,
  ) async {
    final controller = TextEditingController(text: current.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Perbarui Kilometer'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final km = int.tryParse(controller.text.trim());
    if (ok == true && km != null && context.mounted) {
      context
          .read<VehicleBloc>()
          .add(VehicleUpdateKmRequested(id, km));
    }
  }
}