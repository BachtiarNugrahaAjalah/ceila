# Ceila

Aplikasi Android untuk mencatat tugas, keuangan, dan perawatan kendaraan (offline, data lokal).

## Arsitektur
- **Clean Architecture + Feature-First**
- State: **BLoC/Cubit** (`flutter_bloc`)
- Data lokal: **Drift/SQLite** (`lib/core/database`)
- DI: **get_it** (`lib/core/di/injection.dart`)

## Struktur
- `lib/core/` — database, DI, error, usecase
- `lib/features/entries/` — domain/data/presentation (daftar, form, filter, cari)
- `lib/features/reminders/` — notifikasi/pengingat tenggat
- `lib/features/settings/` — pengaturan (overlay, kunci, pengingat)
- `lib/features/backup/` — ekspor/pulihkan JSON

## Menjalankan
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Catatan platform (v2–v4)
- **Floating icon/overlay**: butuh izin *Display over other apps*; perilaku sangat bergantung perangkat/produsen (uji di HP nyata). Implementasi overlay service/entry-point Android lanjutan dapat ditambah sesuai perangkat target.
- **Pengingat/notifikasi**: butuh izin notifikasi & (Android 12+) penjadwalan alarm; pengingat berulang presisi di Android terbaru perlu penyesuaian kebijakan alarm di perangkat.
- **Kunci aplikasi**: biometrik/PIN perangkat via `local_auth`.
- **Cadangan**: ekspor/pulihkan JSON; pemulihan mengganti entri.

Target: Android (minSdk 29). Lihat `PRD-Ceila.md`.
