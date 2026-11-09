import 'package:equatable/equatable.dart';

import '../../domain/entities/entry_entity.dart';

enum EntriesTab { all, tasks, finance, maintenance }

class EntriesState extends Equatable {
  final EntriesTab tab;
  final String query;
  final List<EntryEntity> entries;
  final bool loading;
  final String? error;

  const EntriesState({
    this.tab = EntriesTab.all,
    this.query = '',
    this.entries = const [],
    this.loading = true,
    this.error,
  });

  List<EntryKind>? get typeFilter => switch (tab) {
    EntriesTab.all => null,
    EntriesTab.tasks => const [EntryKind.task],
    EntriesTab.finance => const [EntryKind.income, EntryKind.expense],
    EntriesTab.maintenance => const [EntryKind.maintenance],
  };

  EntriesState copyWith({
    EntriesTab? tab,
    String? query,
    List<EntryEntity>? entries,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return EntriesState(
      tab: tab ?? this.tab,
      query: query ?? this.query,
      entries: entries ?? this.entries,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [tab, query, entries, loading, error];
}

abstract class EntriesEvent extends Equatable {
  const EntriesEvent();
  @override
  List<Object?> get props => [];
}

class EntriesStarted extends EntriesEvent {
  const EntriesStarted();
}

class EntriesTabChanged extends EntriesEvent {
  final EntriesTab tab;
  const EntriesTabChanged(this.tab);
  @override
  List<Object?> get props => [tab];
}

class EntriesQueryChanged extends EntriesEvent {
  final String query;
  const EntriesQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class EntriesLoaded extends EntriesEvent {
  final List<EntryEntity> entries;
  const EntriesLoaded(this.entries);
  @override
  List<Object?> get props => [entries];
}

class EntriesLoadFailed extends EntriesEvent {
  const EntriesLoadFailed();
}

class EntryAdded extends EntriesEvent {
  final EntryEntity entry;
  const EntryAdded(this.entry);
  @override
  List<Object?> get props => [entry];
}

class EntryUpdated extends EntriesEvent {
  final EntryEntity entry;
  const EntryUpdated(this.entry);
  @override
  List<Object?> get props => [entry];
}

class EntryDeleted extends EntriesEvent {
  final int id;
  const EntryDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class TaskToggled extends EntriesEvent {
  final int id;
  final bool done;
  const TaskToggled(this.id, this.done);
  @override
  List<Object?> get props => [id, done];
}
