import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'features/entries/presentation/bloc/entries_bloc.dart';
import 'features/entries/presentation/bloc/entries_event_state.dart';
import 'features/entries/presentation/pages/entries_page.dart';
import 'features/finance/presentation/bloc/finance_bloc.dart';
import 'features/finance/presentation/bloc/finance_event_state.dart';
import 'features/overlay/data/overlay_service.dart';
import 'features/overlay/presentation/overlay_entrypoint.dart';
import 'features/vehicles/presentation/bloc/vehicle_bloc.dart';
import 'features/vehicles/presentation/bloc/vehicle_event_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const CeilaApp());
  if (OverlayService.isPlatformSupported) {
    unawaited(sl<OverlayService>().start());
  }
}

@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const QuickAddOverlay(),
    ),
  );
}

class CeilaApp extends StatelessWidget {
  const CeilaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<EntriesBloc>()..add(const EntriesStarted()),
        ),
        BlocProvider(
          create: (_) => sl<VehicleBloc>()..add(const VehiclesStarted()),
        ),
        BlocProvider(
          create: (_) =>
              sl<FinanceSummaryBloc>()..add(const FinanceSummaryStarted()),
        ),
      ],
      child: MaterialApp(
        title: 'Ceila',
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const EntriesPage(),
      ),
    );
  }
}
