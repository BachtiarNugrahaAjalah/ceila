import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../../features/entries/data/datasources/entries_local_datasource.dart';
import '../../features/entries/data/repositories/entries_repository_impl.dart';
import '../../features/entries/domain/repositories/entries_repository.dart';
import '../../features/entries/domain/usecases/entry_usecases.dart';
import '../../features/entries/presentation/bloc/entries_bloc.dart';
import '../../features/finance/presentation/bloc/finance_bloc.dart';
import '../../features/reminders/data/reminder_service.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/vehicles/data/repositories/vehicles_repository_impl.dart';
import '../../features/vehicles/domain/repositories/vehicles_repository.dart';
import '../../features/vehicles/presentation/bloc/vehicle_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<EntriesLocalDataSource>(
    () => EntriesLocalDataSource(sl()),
  );
  sl.registerLazySingleton<EntriesRepository>(
    () => EntriesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => WatchEntries(sl()));
  sl.registerLazySingleton(() => AddEntry(sl()));
  sl.registerLazySingleton(() => UpdateEntry(sl()));
  sl.registerLazySingleton(() => DeleteEntry(sl()));
  sl.registerLazySingleton(() => SetTaskDone(sl()));
  sl.registerLazySingleton(() => SettingsRepository());
  sl.registerLazySingleton(() => ReminderService(sl(), sl()));
  sl.registerLazySingleton<VehiclesRepository>(
    () => VehiclesRepositoryImpl(sl()),
  );
  sl.registerFactory(() => VehicleBloc(sl<AppDatabase>()));
  sl.registerFactory(() => FinanceSummaryBloc(sl<EntriesRepository>()));
  sl.registerFactory(
    () => EntriesBloc(sl(), sl(), sl(), sl(), sl(), sl()),
  );
}