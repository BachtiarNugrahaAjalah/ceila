import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/entry_entity.dart';
import '../bloc/entries_bloc.dart';
import '../bloc/entries_event_state.dart';

Future<void> showEntryForm(BuildContext context, {EntryEntity? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: context.read<EntriesBloc>(),
      child: EntryFormSheet(existing: existing),
    ),
  );
}

class EntryFormSheet extends StatefulWidget {
  final EntryEntity? existing;
  const EntryFormSheet({super.key, this.existing});

  @override
  State<EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends State<EntryFormSheet> {
  final _form = GlobalKey<FormState>();
  late EntryKind _type;
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _amount;
  late final TextEditingController _category;
  late final TextEditingController _odometer;
  late final TextEditingController _nextKm;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? EntryKind.task;
    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _amount = TextEditingController(text: e?.amount?.toString() ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _odometer = TextEditingController(text: e?.odometerKm?.toString() ?? '');
    _nextKm = TextEditingController(text: e?.nextKm?.toString() ?? '');
    _dueDate = e?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _amount.dispose();
    _category.dispose();
    _odometer.dispose();
    _nextKm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Tambah catatan' : 'Ubah catatan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EntryKind>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: EntryKind.values
                    .map(
                      (k) => DropdownMenuItem(value: k, child: Text(_label(k))),
                    )
                    .toList(),
                onChanged: widget.existing == null
                    ? (v) => setState(() => _type = v ?? _type)
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Judul'),
                maxLength: 120,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul wajib diisi'
                    : null,
              ),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
                maxLines: 2,
              ),
              if (_type == EntryKind.task ||
                  _type == EntryKind.maintenance) ...[
                const SizedBox(height: 8),
                _dateField(context),
              ],
              if (_type == EntryKind.income || _type == EntryKind.expense) ...[
                TextFormField(
                  controller: _amount,
                  decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nominal wajib' : null,
                ),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
              ],
              if (_type == EntryKind.maintenance) ...[
                TextFormField(
                  controller: _odometer,
                  decoration: const InputDecoration(
                    labelText: 'Kilometer saat ini',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextFormField(
                  controller: _nextKm,
                  decoration: const InputDecoration(
                    labelText: 'Servis berikutnya (km)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Simpan')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context) {
    final label = _type == EntryKind.maintenance
        ? 'Jadwal servis berikutnya'
        : 'Tenggat';
    final text = _dueDate == null
        ? 'Pilih tanggal'
        : DateFormat('d MMM y, HH:mm').format(_dueDate!);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(text),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
        );
        if (time == null) return;
        setState(
          () => _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
        );
      },
    );
  }

  String _label(EntryKind k) => switch (k) {
    EntryKind.task => 'Tugas',
    EntryKind.income => 'Pemasukan',
    EntryKind.expense => 'Pengeluaran',
    EntryKind.maintenance => 'Perawatan kendaraan',
  };

  void _save() {
    if (!_form.currentState!.validate()) return;
    final e = EntryEntity(
      id: widget.existing?.id,
      type: _type,
      title: _title.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      dueDate: _dueDate,
      isDone: widget.existing?.isDone ?? false,
      amount: _amount.text.isEmpty ? null : int.tryParse(_amount.text),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      odometerKm: _odometer.text.isEmpty ? null : int.tryParse(_odometer.text),
      nextKm: _nextKm.text.isEmpty ? null : int.tryParse(_nextKm.text),
      vehicleId: widget.existing?.vehicleId,
    );
    final bloc = context.read<EntriesBloc>();
    if (widget.existing == null) {
      bloc.add(EntryAdded(e));
    } else {
      bloc.add(EntryUpdated(e));
    }
    Navigator.pop(context);
  }
}
