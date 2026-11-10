import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';

class BackupService {
  final AppDatabase db;
  BackupService(this.db);

  Future<String> exportJson() async {
    final entries = await db.select(db.entries).get();
    final vehicles = await db.select(db.vehicles).get();
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ceila-backup.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    await Share.shareXFiles([XFile(file.path)], text: 'Cadangan Ceila');
    return file.path;
  }

  Future<int> restoreJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return 0;
    final file = File(result.files.single.path!);
    final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final entries = (map['entries'] as List?) ?? const [];
    await db.transaction(() async {
      await db.delete(db.entries).go();
      for (final raw in entries) {
        final data = Map<String, dynamic>.from(raw as Map);
        data.remove('id');
        await db.into(db.entries).insert(Entry.fromJson(data));
      }
    });
    return entries.length;
  }
}
