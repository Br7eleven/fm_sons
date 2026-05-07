import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../local/app_database.dart';
import 'backup_json_payload_service.dart';
import 'backup_models.dart';
import 'google_drive_service.dart';

class RestoreManager {
  final GoogleDriveService driveService;
  final BackupJsonPayloadService _payloadService;

  RestoreManager(this.driveService, {BackupJsonPayloadService? payloadService})
    : _payloadService = payloadService ?? BackupJsonPayloadService();

  Future<RestoreOperationResult> restoreLatestBackup({
    BackupConflictPolicy conflictPolicy =
        BackupConflictPolicy.requireConfirmation,
    Future<bool> Function(DateTime localModified, DateTime cloudModified)?
    onLocalNewerConflict,
    bool Function()? isCancelled,
    int maxRetries = 3,
  }) async {
    if (isCancelled?.call() ?? false) {
      return const RestoreOperationResult(
        outcome: RestoreOutcome.cancelled,
        message: 'Restore cancelled before start',
      );
    }

    try {
      await driveService.ensureSignedIn();
      final latest = await driveService.getLatestBackupFile();
      if (latest == null) {
        return const RestoreOperationResult(
          outcome: RestoreOutcome.noBackup,
          message: 'No backup file found on Google Drive',
        );
      }

      final dbPath = await AppDatabase.databaseFilePath();
      final dbFile = File(dbPath);
      final hasLocal = await dbFile.exists();

      DateTime? localModified;
      if (hasLocal) {
        localModified = await dbFile.lastModified();
      }

      final cloudModified = latest.modifiedTime;
      final localIsNewer =
          hasLocal &&
          localModified != null &&
          cloudModified != null &&
          localModified.isAfter(cloudModified);

      if (localIsNewer) {
        final shouldProceed = await _resolveConflict(
          conflictPolicy: conflictPolicy,
          onLocalNewerConflict: onLocalNewerConflict,
          localModified: localModified,
          cloudModified: cloudModified,
        );

        if (!shouldProceed) {
          return RestoreOperationResult(
            outcome: RestoreOutcome.skipped,
            message:
                'Restore skipped because local database is newer than cloud backup',
            cloudModifiedAt: cloudModified,
            localModifiedAt: localModified,
          );
        }
      }

      if (isCancelled?.call() ?? false) {
        return const RestoreOperationResult(
          outcome: RestoreOutcome.cancelled,
          message: 'Restore cancelled',
        );
      }

      final tempDir = await Directory.systemTemp.createTemp('fm_sons_restore_');
      final downloadedPath = p.join(tempDir.path, 'downloaded_backup.json');

      File? rollbackFile;
      File? downloadedFile;

      try {
        downloadedFile = await driveService.downloadFile(
          fileId: latest.id,
          outputPath: downloadedPath,
          maxRetries: maxRetries,
        );

        final payloadJson = await _readPayloadJson(
          downloadedFile,
          expectedSizeBytes: latest.sizeBytes,
        );

        if (isCancelled?.call() ?? false) {
          return const RestoreOperationResult(
            outcome: RestoreOutcome.cancelled,
            message: 'Restore cancelled before replace step',
          );
        }

        await AppDatabase.closeDatabase();

        if (hasLocal) {
          rollbackFile = File(
            '$dbPath.pre_restore_${DateTime.now().millisecondsSinceEpoch}.bak',
          );
          await dbFile.copy(rollbackFile.path);
        }

        await _payloadService.restoreFromPayloadJson(payloadJson);

        return RestoreOperationResult(
          outcome: RestoreOutcome.restored,
          message: 'JSON backup restored successfully from Google Drive',
          restoredFrom: downloadedFile,
          cloudModifiedAt: cloudModified,
          localModifiedAt: localModified,
        );
      } catch (e) {
        if (rollbackFile != null && await rollbackFile.exists()) {
          await rollbackFile.copy(dbPath);
        }

        return RestoreOperationResult(
          outcome: RestoreOutcome.failed,
          message: 'Restore failed: $e',
          cloudModifiedAt: cloudModified,
          localModifiedAt: localModified,
        );
      } finally {
        if (downloadedFile != null && await downloadedFile.exists()) {
          await downloadedFile.delete();
        }
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    } catch (e) {
      return RestoreOperationResult(
        outcome: RestoreOutcome.failed,
        message: 'Restore process failed: $e',
      );
    }
  }

  Future<bool> _resolveConflict({
    required BackupConflictPolicy conflictPolicy,
    required Future<bool> Function(
      DateTime localModified,
      DateTime cloudModified,
    )?
    onLocalNewerConflict,
    required DateTime localModified,
    required DateTime cloudModified,
  }) async {
    switch (conflictPolicy) {
      case BackupConflictPolicy.preferCloud:
        return true;
      case BackupConflictPolicy.preferLocal:
        return false;
      case BackupConflictPolicy.requireConfirmation:
        if (onLocalNewerConflict == null) {
          return false;
        }
        return onLocalNewerConflict(localModified, cloudModified);
    }
  }

  Future<String> _readPayloadJson(
    File downloadedFile, {
    int? expectedSizeBytes,
  }) async {
    final exists = await downloadedFile.exists();
    if (!exists) {
      throw Exception('Downloaded backup file is missing');
    }

    final length = await downloadedFile.length();
    if (length <= 0) {
      throw Exception('Downloaded backup file is empty');
    }

    if (expectedSizeBytes != null &&
        expectedSizeBytes > 0 &&
        length != expectedSizeBytes) {
      throw Exception(
        'Backup size mismatch (expected $expectedSizeBytes bytes, got $length bytes)',
      );
    }

    final payloadJson = await downloadedFile.readAsString();
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Backup payload root must be JSON object');
      }
      if (decoded['tables'] is! Map<String, dynamic>) {
        throw const FormatException('Backup payload missing tables object');
      }
    } catch (e) {
      throw Exception('Downloaded backup is not a valid JSON payload: $e');
    }

    return payloadJson;
  }
}
