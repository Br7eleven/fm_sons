import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class DriveBackupFile {
  final String id;
  final String name;
  final DateTime? modifiedTime;
  final int? sizeBytes;
  final String? md5Checksum;

  const DriveBackupFile({
    required this.id,
    required this.name,
    this.modifiedTime,
    this.sizeBytes,
    this.md5Checksum,
  });

  factory DriveBackupFile.fromDriveFile(drive.File file) {
    return DriveBackupFile(
      id: file.id ?? '',
      name: file.name ?? '',
      modifiedTime: file.modifiedTime,
      sizeBytes: int.tryParse(file.size ?? ''),
      md5Checksum: file.md5Checksum,
    );
  }
}

class GoogleDriveService {
  static const String backupPrefix = 'fm_sons_backup';
  static final GoogleSignIn _defaultGoogleSignIn = GoogleSignIn(
    scopes: const ['email', drive.DriveApi.driveFileScope],
  );

  final GoogleSignIn _googleSignIn;
  drive.DriveApi? _driveApi;

  GoogleDriveService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? _defaultGoogleSignIn;

  bool get isSignedIn => _driveApi != null;

  String? get signedInAccountEmail => _googleSignIn.currentUser?.email;

  String? get signedInAccountName => _googleSignIn.currentUser?.displayName;

  Future<void> signIn() async {
    await ensureSignedIn();
  }

  Future<bool> restoreSessionSilently() async {
    if (_driveApi != null) return true;

    final googleUser = await _googleSignIn.signInSilently();
    if (googleUser == null) {
      return false;
    }

    final authHeaders = await googleUser.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    _driveApi = drive.DriveApi(client);
    return true;
  }

  Future<void> ensureSignedIn() async {
    if (_driveApi != null) return;

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In cancelled by user');
    }

    final authHeaders = await googleUser.authHeaders;
    final client = GoogleAuthClient(authHeaders);

    _driveApi = drive.DriveApi(client);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
  }

  Future<DriveBackupFile> uploadFile(
    File file,
    String name, {
    int maxRetries = 3,
  }) async {
    await ensureSignedIn();
    final api = _driveApi!;

    return _retry(
      action: () async {
        final media = drive.Media(file.openRead(), await file.length());
        final driveFile = drive.File()..name = name;

        final created = await api.files.create(
          driveFile,
          uploadMedia: media,
          $fields: 'id,name,modifiedTime,size,md5Checksum',
        );

        return DriveBackupFile.fromDriveFile(created);
      },
      maxRetries: maxRetries,
      operationName: 'upload backup',
    );
  }

  Future<List<DriveBackupFile>> listBackupFiles({
    String prefix = backupPrefix,
    int pageSize = 100,
  }) async {
    await ensureSignedIn();

    final escaped = prefix.replaceAll("'", r"\'");
    final query = "trashed = false and name contains '$escaped'";
    final response = await _driveApi!.files.list(
      q: query,
      spaces: 'drive',
      pageSize: pageSize,
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime,size,md5Checksum)',
    );

    final files = response.files ?? const <drive.File>[];
    return files
        .where((f) => (f.id ?? '').isNotEmpty && (f.name ?? '').isNotEmpty)
        .map(DriveBackupFile.fromDriveFile)
        .toList();
  }

  Future<DriveBackupFile?> getLatestBackupFile({
    String prefix = backupPrefix,
  }) async {
    final backups = await listBackupFiles(prefix: prefix, pageSize: 20);
    if (backups.isEmpty) return null;
    return backups.first;
  }

  Future<File> downloadFile({
    required String fileId,
    required String outputPath,
    int maxRetries = 3,
  }) async {
    await ensureSignedIn();
    final api = _driveApi!;

    return _retry(
      action: () async {
        final response = await api.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        );

        if (response is! drive.Media) {
          throw Exception('Unexpected download response for backup file');
        }

        final file = File(outputPath);
        await file.parent.create(recursive: true);
        final sink = file.openWrite();
        await response.stream.pipe(sink);
        await sink.flush();
        await sink.close();
        return file;
      },
      maxRetries: maxRetries,
      operationName: 'download backup',
    );
  }

  Future<T> _retry<T>({
    required Future<T> Function() action,
    required int maxRetries,
    required String operationName,
  }) async {
    Object? lastError;
    final retries = maxRetries < 1 ? 1 : maxRetries;

    for (var attempt = 1; attempt <= retries; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        if (attempt == retries) break;
        final delaySeconds = attempt * 2;
        await Future<void>.delayed(Duration(seconds: delaySeconds));
      }
    }

    throw Exception(
      'Failed to $operationName after $retries attempt(s): $lastError',
    );
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this.headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}
