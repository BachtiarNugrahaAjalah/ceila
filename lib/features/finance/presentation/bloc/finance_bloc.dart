import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../entries/domain/entities/entry_entity.dart';
import '../../../entries/domain/repositories/entries_repository.dart';
import 'finance_event_state.dart';

class FinanceSummaryBloc
    extends Bloc<FinanceSummaryEvent, FinanceSummaryState> {
  final EntriesRepository _repository;
  StreamSubscription<dynamic>? _sub;

  FinanceSummaryBloc(this._repository) : super(const FinanceSummaryState()) {
    on<FinanceSummaryStarted>(_onStarted);
    on<FinanceSummaryPeriodChanged>(_onPeriod);
    on<_FinanceCalculated>(_onCalculated);
  }

  Future<void> _onStarted(
    FinanceSummaryStarted event,
    Emitter<FinanceSummaryState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    _resubscribe();
  }

  Future<void> _onPeriod(
    FinanceSummaryPeriodChanged event,
    Emitter<FinanceSummaryState> emit,
  ) async {
    emit(state.copyWith(period: event.period, loading: true));
    _resubscribe();
  }

  void _resubscribe() {
    _sub?.cancel();
    _sub = _repository
        .watchEntries(const WatchEntriesParams(
          types: [EntryKind.income, EntryKind.expense],
        ))
        .listen((entries) {
      final filtered =
          entries.where((e) => _inPeriod(e.createdAt, state.period)).toList();
      final income = filtered
          .where((e) => e.type == EntryKind.income)
          .fold<int>(0, (sum, e) => sum + (e.amount ?? 0));
      final expense = filtered
          .where((e) => e.type == EntryKind.expense)
          .fold<int>(0, (sum, e) => sum + (e.amount ?? 0));
      add(_FinanceCalculated(income, expense));
    });
  }

  Future<void> _onCalculated(
    _FinanceCalculated event,
    Emitter<FinanceSummaryState> emit,
  ) async {
    emit(
      state.copyWith(
        totalIncome: event.income,
        totalExpense: event.expense,
        balance: event.income - event.expense,
        loading: false,
      ),
    );
  }

  bool _inPeriod(DateTime created, FinancePeriod p) {
    final now = DateTime.now();
    switch (p) {
      case FinancePeriod.today:
        return created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
      case FinancePeriod.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return !created.isBefore(weekAgo);
      case FinancePeriod.month:
        return created.year == now.year && created.month == now.month;
      case FinancePeriod.all:
        return true;
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

class _FinanceCalculated extends FinanceSummaryEvent {
  final int income;
  final int expense;
  const _FinanceCalculated(this.income, this.expense);
  @override
  List<Object?> get props => [income, expense];
}