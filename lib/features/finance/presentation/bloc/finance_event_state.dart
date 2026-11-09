import 'package:equatable/equatable.dart';

class FinanceSummaryState extends Equatable {
  final FinancePeriod period;
  final int totalIncome;
  final int totalExpense;
  final int balance;
  final bool loading;
  final String? error;

  const FinanceSummaryState({
    this.period = FinancePeriod.month,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.balance = 0,
    this.loading = true,
    this.error,
  });

  FinanceSummaryState copyWith({
    FinancePeriod? period,
    int? totalIncome,
    int? totalExpense,
    int? balance,
    bool? loading,
    String? error,
  }) {
    return FinanceSummaryState(
      period: period ?? this.period,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [period, totalIncome, totalExpense, balance, loading, error];
}

enum FinancePeriod { today, week, month, all }

abstract class FinanceSummaryEvent extends Equatable {
  const FinanceSummaryEvent();
  @override
  List<Object?> get props => [];
}

class FinanceSummaryStarted extends FinanceSummaryEvent {
  const FinanceSummaryStarted();
}

class FinanceSummaryPeriodChanged extends FinanceSummaryEvent {
  final FinancePeriod period;
  const FinanceSummaryPeriodChanged(this.period);
  @override
  List<Object?> get props => [period];
}