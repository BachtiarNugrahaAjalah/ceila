import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../reminders/data/reminder_service.dart';
import '../../domain/repositories/entries_repository.dart';
import '../../domain/usecases/entry_usecases.dart';
import 'entries_event_state.dart';

class EntriesBloc extends Bloc<EntriesEvent, EntriesState> {
  final WatchEntries _watch;
  final AddEntry _add;
  final UpdateEntry _update;
  final DeleteEntry _delete;
  final SetTaskDone _setDone;
  final ReminderService _reminders;
  StreamSubscription<dynamic>? _sub;

  EntriesBloc(
    this._watch,
    this._add,
    this._update,
    this._delete,
    this._setDone,
    this._reminders,
  ) : super(const EntriesState()) {
    on<EntriesStarted>(_onStarted);
    on<EntriesTabChanged>(_onTab);
    on<EntriesQueryChanged>(_onQuery);
    on<EntriesLoaded>(
      (e, emit) => emit(
        state.copyWith(entries: e.entries, loading: false, clearError: true),
      ),
    );
    on<EntriesLoadFailed>(
      (event, emit) => emit(
        state.copyWith(
          loading: false,
          error: 'Catatan tidak dapat dimuat. Coba lagi.',
        ),
      ),
    );
    on<EntryAdded>(_onAdd);
    on<EntryUpdated>(_onUpdate);
    on<EntryDeleted>(_onDelete);
    on<TaskToggled>(_onToggle);
  }

  Future<void> _onStarted(
    EntriesStarted event,
    Emitter<EntriesState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    _resubscribe();
  }

  Future<void> _onTab(
    EntriesTabChanged event,
    Emitter<EntriesState> emit,
  ) async {
    emit(state.copyWith(tab: event.tab, loading: true));
    _resubscribe();
  }

  Future<void> _onQuery(
    EntriesQueryChanged event,
    Emitter<EntriesState> emit,
  ) async {
    emit(state.copyWith(query: event.query, loading: true));
    _resubscribe();
  }

  void _resubscribe() {
    _sub?.cancel();
    _sub =
        _watch(WatchEntriesParams(types: state.typeFilter, query: state.query))
            .listen(
              (items) => add(EntriesLoaded(items)),
              onError: (Object error, StackTrace stackTrace) {
                addError(error, stackTrace);
                add(const EntriesLoadFailed());
              },
            );
  }

  Future<void> _onAdd(EntryAdded event, Emitter<EntriesState> emit) async {
    final id = await _add(event.entry);
    await _reminders.scheduleForEntry(event.entry.copyWith(id: id));
  }

  Future<void> _onUpdate(EntryUpdated event, Emitter<EntriesState> emit) async {
    await _update(event.entry);
    if (event.entry.id != null) await _reminders.cancel(event.entry.id!);
    await _reminders.scheduleForEntry(event.entry);
  }

  Future<void> _onDelete(EntryDeleted event, Emitter<EntriesState> emit) async {
    await _delete(event.id);
    await _reminders.cancel(event.id);
  }

  Future<void> _onToggle(TaskToggled event, Emitter<EntriesState> emit) async {
    await _setDone((id: event.id, done: event.done));
    if (event.done) await _reminders.cancel(event.id);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
