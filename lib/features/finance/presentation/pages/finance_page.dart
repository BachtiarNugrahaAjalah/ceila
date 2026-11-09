import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/finance_bloc.dart';
import '../bloc/finance_event_state.dart';

class FinanceSummaryPage extends StatefulWidget {
  const FinanceSummaryPage({super.key});

  @override
  State<FinanceSummaryPage> createState() => _FinanceSummaryPageState();
}

class _FinanceSummaryPageState extends State<FinanceSummaryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ringkasan Keuangan')),
      body: BlocBuilder<FinanceSummaryBloc, FinanceSummaryState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              const SizedBox(height: 16),
              ToggleButtons(
                isSelected: FinancePeriod.values
                    .map((p) => p == state.period)
                    .toList(),
                onPressed: (i) => context.read<FinanceSummaryBloc>().add(
                      FinanceSummaryPeriodChanged(FinancePeriod.values[i]),
                    ),
                children: const [
                  Text('Hari ini'),
                  Text('7 hari'),
                  Text('Bulan ini'),
                  Text('Semua'),
                ],
              ),
              const SizedBox(height: 24),
              _Card(
                icon: Icons.arrow_downward,
                color: Colors.green,
                label: 'Pemasukan',
                value: state.totalIncome,
              ),
              const SizedBox(height: 12),
              _Card(
                icon: Icons.arrow_upward,
                color: Colors.red,
                label: 'Pengeluaran',
                value: state.totalExpense,
              ),
              const SizedBox(height: 12),
              _Card(
                icon: Icons.account_balance,
                color: Colors.blue,
                label: 'Saldo',
                value: state.balance,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  const _Card({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(label),
        trailing: Text(
          'Rp ${NumberFormat('#,###').format(value)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}