import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../finance/presentation/pages/finance_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../vehicles/presentation/pages/vehicles_page.dart';
import '../../domain/entities/entry_entity.dart';
import '../bloc/entries_bloc.dart';
import '../bloc/entries_event_state.dart';
import '../widgets/entry_form_sheet.dart';

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key});

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ceila'),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinanceSummaryPage()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.directions_car_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehiclesPage()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ],
          bottom: TabBar(
            onTap: (i) => context.read<EntriesBloc>().add(
              EntriesTabChanged(EntriesTab.values[i]),
            ),
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Tugas'),
              Tab(text: 'Keuangan'),
              Tab(text: 'Perawatan'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Cari judul atau catatan',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            context.read<EntriesBloc>().add(
                              const EntriesQueryChanged(''),
                            );
                            setState(() {});
                          },
                        ),
                ),
                onChanged: (v) {
                  context.read<EntriesBloc>().add(EntriesQueryChanged(v));
                  setState(() {});
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<EntriesBloc, EntriesState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.error != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.error!),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () => context.read<EntriesBloc>().add(
                              const EntriesStarted(),
                            ),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state.entries.isEmpty) {
                    return const Center(child: Text('Belum ada catatan.'));
                  }
                  return ListView.separated(
                    itemCount: state.entries.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) =>
                        _EntryTile(entry: state.entries[i]),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showEntryForm(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final EntryEntity entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final overdue = entry.isOverdue;
    final df = DateFormat('d MMM y, HH:mm');
    String subtitle = switch (entry.type) {
      EntryKind.task =>
        entry.dueDate == null
            ? 'Tugas'
            : 'Tenggat ${df.format(entry.dueDate!)}',
      EntryKind.income => 'Pemasukan • Rp ${entry.amount ?? 0}',
      EntryKind.expense => 'Pengeluaran • Rp ${entry.amount ?? 0}',
      EntryKind.maintenance => [
        if (entry.dueDate != null) 'Jadwal ${df.format(entry.dueDate!)}',
        if (entry.nextKm != null) '${entry.nextKm} km',
      ].join(' • '),
    };
    return ListTile(
      leading: entry.type == EntryKind.task
          ? Checkbox(
              value: entry.isDone,
              onChanged: (v) => context.read<EntriesBloc>().add(
                TaskToggled(entry.id!, v ?? false),
              ),
            )
          : Icon(_icon(entry.type)),
      title: Text(
        entry.title,
        style: TextStyle(
          decoration: entry.isDone ? TextDecoration.lineThrough : null,
          color: overdue ? Colors.red.shade700 : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: overdue
          ? const Icon(Icons.warning_amber_rounded, color: Colors.red)
          : null,
      onTap: () => showEntryForm(context, existing: entry),
      onLongPress: () => _confirmDelete(context),
    );
  }

  IconData _icon(EntryKind t) => switch (t) {
    EntryKind.task => Icons.check_circle_outline,
    EntryKind.income => Icons.arrow_downward,
    EntryKind.expense => Icons.arrow_upward,
    EntryKind.maintenance => Icons.build_outlined,
  };

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('Hapus "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<EntriesBloc>().add(EntryDeleted(entry.id!));
    }
  }
}
