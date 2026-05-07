import 'dart:convert';
import 'dart:io';

import '../local/app_database.dart';
import '../local/dao/invoice_dao.dart';
import 'backup_json_payload_service.dart';
import 'backup_models.dart';
import 'google_drive_service.dart';

class BackupManager {
  final GoogleDriveService driveService;
  final BackupJsonPayloadService _payloadService;
  final InvoiceDao _invoiceDao;

  BackupManager(
    this.driveService, {
    BackupJsonPayloadService? payloadService,
    InvoiceDao? invoiceDao,
  }) : _payloadService = payloadService ?? BackupJsonPayloadService(),
       _invoiceDao = invoiceDao ?? InvoiceDao();

  Future<BackupOperationResult> backupDatabase({
    int maxRetries = 3,
    bool Function()? isCancelled,
  }) async {
    if (isCancelled?.call() ?? false) {
      return const BackupOperationResult(
        success: false,
        message: 'Backup cancelled before start',
      );
    }

    final dbPath = await AppDatabase.databaseFilePath();
    final dbFile = File(dbPath);

    if (!dbFile.existsSync()) {
      return const BackupOperationResult(
        success: false,
        message: 'Database file not found',
      );
    }

    final fileLength = await dbFile.length();
    if (fileLength <= 0) {
      return const BackupOperationResult(
        success: false,
        message: 'Database file is empty. Backup aborted.',
      );
    }

    if (isCancelled?.call() ?? false) {
      return const BackupOperationResult(
        success: false,
        message: 'Backup cancelled',
      );
    }

    final now = DateTime.now().toUtc();
    final backupName = 'fm_sons_backup_${_timestamp(now)}.json';
    File? tempPayloadFile;

    try {
      await driveService.ensureSignedIn();

      final payloadJson = await _payloadService.buildPayloadJson();
      final payloadBytes = utf8.encode(payloadJson);

      if (payloadBytes.isEmpty) {
        return const BackupOperationResult(
          success: false,
          message: 'Backup payload is empty. Backup aborted.',
        );
      }

      tempPayloadFile = await _writeTempPayloadFile(payloadBytes);

      final uploaded = await driveService.uploadFile(
        tempPayloadFile,
        backupName,
        maxRetries: maxRetries,
      );

      final markedCount = await _invoiceDao.markPendingAsBackedUp();
      final successMessage = markedCount > 0
          ? 'JSON backup uploaded successfully. $markedCount invoice(s) marked as backed up.'
          : 'JSON backup uploaded successfully.';

      return BackupOperationResult(
        success: true,
        message: successMessage,
        backupFileName: uploaded.name,
        remoteFileId: uploaded.id,
        uploadedAt: uploaded.modifiedTime ?? now,
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'Failed to backup JSON payload: $e',
        backupFileName: backupName,
      );
    } finally {
      if (tempPayloadFile != null && await tempPayloadFile.exists()) {
        final parent = tempPayloadFile.parent;
        await tempPayloadFile.delete();
        if (await parent.exists()) {
          await parent.delete(recursive: true);
        }
      }
    }
  }

  Future<File> _writeTempPayloadFile(List<int> bytes) async {
    final tempDir = await Directory.systemTemp.createTemp('fm_sons_backup_');
    final file = File('${tempDir.path}${Platform.pathSeparator}backup.json');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _timestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    final ymd = '$y$m$d';
    final hms = '$hh$mm$ss';
    return '${ymd}_$hms';
  }
}
