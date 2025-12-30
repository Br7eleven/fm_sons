import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'google_drive_service.dart';

class BackupManager {
  final GoogleDriveService driveService;

  BackupManager(this.driveService);

  Future<void> backupDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = File('$dbPath/fm_sons.db');

    if (!dbFile.existsSync()) {
      throw Exception('Database file not found');
    }

    await driveService.uploadFile(dbFile, 'fm_sons_backup.db');
  }
}
