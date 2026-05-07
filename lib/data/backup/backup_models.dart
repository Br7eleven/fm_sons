import 'dart:io';

enum BackupConflictPolicy { preferLocal, preferCloud, requireConfirmation }

enum RestoreOutcome { restored, skipped, noBackup, failed, cancelled }

class BackupOperationResult {
  final bool success;
  final String message;
  final String? backupFileName;
  final String? remoteFileId;
  final DateTime? uploadedAt;

  const BackupOperationResult({
    required this.success,
    required this.message,
    this.backupFileName,
    this.remoteFileId,
    this.uploadedAt,
  });
}

class RestoreOperationResult {
  final RestoreOutcome outcome;
  final String message;
  final File? restoredFrom;
  final DateTime? cloudModifiedAt;
  final DateTime? localModifiedAt;

  const RestoreOperationResult({
    required this.outcome,
    required this.message,
    this.restoredFrom,
    this.cloudModifiedAt,
    this.localModifiedAt,
  });

  bool get isSuccess => outcome == RestoreOutcome.restored;
}
