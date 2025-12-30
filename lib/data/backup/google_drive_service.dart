import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  late drive.DriveApi _driveApi;

  Future<void> signIn() async {
    final googleUser = await GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    ).signIn();

    final authHeaders = await googleUser!.authHeaders;
    final client = GoogleAuthClient(authHeaders);

    _driveApi = drive.DriveApi(client);
  }

  Future<void> uploadFile(File file, String name) async {
    final media = drive.Media(file.openRead(), file.lengthSync());
    final driveFile = drive.File()..name = name;

    await _driveApi.files.create(driveFile, uploadMedia: media);
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
}
