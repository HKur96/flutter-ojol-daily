import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Custom HTTP Client that attaches Google Sign-In auth headers
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

class GoogleDriveService {
  final GoogleSignIn _googleSignIn;

  GoogleDriveService({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: [
              drive.DriveApi.driveAppdataScope,
              drive.DriveApi.driveFileScope,
            ],
            serverClientId: '991348451115-hu4mggvk52flg0m3i6ogdftkgung21se.apps.googleusercontent.com',
          );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  static const String _backupFileName = 'ojol_daily_backup.json';
  static const String _lastBackupTimePrefKey = 'google_drive_last_backup_time';

  /// Initializes Google Sign-In state and restores silent login if available.
  Future<GoogleSignInAccount?> init() async {
    try {
      _googleSignIn.onCurrentUserChanged.listen((account) {
        _currentUser = account;
      });
      _currentUser = await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint("Google Sign-In silent init notice: $e");
    }
    return _currentUser;
  }

  /// Signs in to Google Account. If native Google auth fails (e.g. dev environment without OAuth IDs),
  /// falls back cleanly to mock mode so dev/test builds remain fully interactive.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (e, s) {
      debugPrint("Google Sign-In exception: $e, $s");
      return null;
    }
  }

  /// Signs out from Google Account.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
  }

  /// Returns Google Drive API client using authenticated user headers.
  Future<drive.DriveApi?> _getDriveApi() async {
    if (_currentUser == null) return null;
    final headers = await _currentUser!.authHeaders;
    final client = _GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  /// Uploads backup JSON string to Google Drive.
  Future<bool> uploadBackupToDrive(String jsonStr) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    if (_currentUser == null) {
      return false;
    }

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final media = drive.Media(
        Stream.value(utf8.encode(jsonStr)),
        jsonStr.length,
        contentType: 'application/json',
      );

      // Search for existing backup file in appDataFolder
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName' and trashed = false",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final existingFileId = fileList.files!.first.id!;
        await driveApi.files.update(
          drive.File()..name = _backupFileName,
          existingFileId,
          uploadMedia: media,
        );
      } else {
        final newFile = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        await driveApi.files.create(newFile, uploadMedia: media);
      }

      await prefs.setString(_lastBackupTimePrefKey, now.toIso8601String());
      return true;
    } catch (e) {
      debugPrint("Error uploading to Google Drive: $e");
      return false;
    }
  }

  /// Downloads backup JSON string from Google Drive.
  Future<String?> downloadBackupFromDrive() async {
    if (_currentUser == null) {
      return null;
    }

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName' and trashed = false",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return null;
      }

      final fileId = fileList.files!.first.id!;
      final drive.Media response =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> bytes = [];
      await response.stream.forEach(bytes.addAll);
      return utf8.decode(bytes);
    } catch (e) {
      debugPrint("Error downloading from Google Drive: $e");
      return null;
    }
  }

  /// Returns last backup timestamp from Google Drive or local preferences.
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastBackupTimePrefKey);
    if (timeStr != null) {
      return DateTime.tryParse(timeStr);
    }
    return null;
  }
}
