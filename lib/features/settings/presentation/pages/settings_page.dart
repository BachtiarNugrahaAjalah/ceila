import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/di/injection.dart';
import '../../../backup/data/backup_service.dart';
import '../../../finance/presentation/pages/finance_page.dart';
import '../../../reminders/data/reminder_service.dart';
import '../../../vehicles/presentation/pages/vehicles_page.dart';
import '../../data/settings_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = sl<SettingsRepository>();
  bool _overlay = false;
  bool _reminders = true;
  bool _lock = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final o = await _settings.getOverlayEnabled();
    final r = await _settings.getRemindersEnabled();
    final l = await _settings.getAppLockEnabled();
    if (mounted) {
      setState(() {
        _overlay = o;
        _reminders = r;
        _lock = l;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          if (!kIsWeb) ...[
            SwitchListTile(
              title: const Text('Pengingat aktif'),
              subtitle: const Text(
                'Notifikasi tenggat/tugas terlambat (perangkat perlu izin notifikasi/alarm).',
              ),
              value: _reminders,
              onChanged: (v) async {
                await _settings.setRemindersEnabled(v);
                setState(() => _reminders = v);
                if (v) await sl<ReminderService>().startWatching();
              },
            ),
            SwitchListTile(
              title: const Text('Floating icon (overlay)'),
              subtitle: const Text(
                'Izin “Tampilkan di atas aplikasi lain” diperlukan.',
              ),
              value: _overlay,
              onChanged: (v) async {
                if (v) {
                  final granted =
                      await FlutterOverlayWindow.isPermissionGranted();
                  if (!granted) await FlutterOverlayWindow.requestPermission();
                }
                await _settings.setOverlayEnabled(v);
                setState(() => _overlay = v);
              },
            ),
            ListTile(
              title: const Text('Minta izin overlay'),
              leading: const Icon(Icons.layers_outlined),
              onTap: () async => FlutterOverlayWindow.requestPermission(),
            ),
            SwitchListTile(
              title: const Text('Kunci aplikasi'),
              subtitle: const Text('Gunakan biometrik/PIN perangkat.'),
              value: _lock,
              onChanged: (v) async {
                final auth = LocalAuthentication();
                final ok = await auth.authenticate(
                  localizedReason: 'Konfirmasi untuk mengubah kunci aplikasi',
                  options: const AuthenticationOptions(biometricOnly: false),
                );
                if (ok) {
                  await _settings.setAppLockEnabled(v);
                  setState(() => _lock = v);
                }
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Ringkasan keuangan'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceSummaryPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: const Text('Kendaraan'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehiclesPage()),
            ),
          ),
          if (!kIsWeb) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Ekspor cadangan (JSON)'),
              onTap: () async {
                final path = await BackupService(sl()).exportJson();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Cadangan: $path')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Pulihkan dari cadangan'),
              onTap: () async {
                final n = await BackupService(sl()).restoreJson();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dipulihkan: $n entri')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
