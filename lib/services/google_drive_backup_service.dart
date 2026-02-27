import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles linking a Google account and backing up/restoring the local
/// SQLite database file to/from Google Drive (appDataFolder).
class GoogleDriveBackupService {
  GoogleDriveBackupService._internal();

  static final GoogleDriveBackupService instance =
      GoogleDriveBackupService._internal();

  // Restrict to appDataFolder so the file is hidden from the normal Drive UI.
  static const _scopes = <String>[
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  static const _lastBackupKey = 'gdrive_last_backup_ms';
  static const _lastRestoreKey = 'gdrive_last_restore_ms';

  Future<DateTime?> lastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastBackupKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<DateTime?> lastRestoreTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastRestoreKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Attempts silent sign-in, then interactive sign-in if needed.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final existing = await _googleSignIn.signInSilently();
      if (existing != null) return existing;
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      rethrow;
    }
  }

  /// Attempts to restore a previously linked account without any UI.
  Future<GoogleSignInAccount?> restorePreviousSignIn() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Google silent sign-in failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
  }

  Future<String?> _accessToken() async {
    final user = _googleSignIn.currentUser ?? await signIn();
    if (user == null) return null;
    final auth = await user.authentication;
    return auth.accessToken;
  }

  Future<String> _databasePath() async {
    final dbDir = await getDatabasesPath();
    // LocalDb uses this fixed path.
    return p.join(dbDir, 'budget_companion.db');
  }

  /// Uploads the current SQLite database file to Drive appDataFolder.
  Future<void> backupDatabase() async {
    final token = await _accessToken();
    if (token == null) {
      throw StateError('Google sign-in required for backup.');
    }

    final dbPath = await _databasePath();
    final fileBytes = await File(dbPath).readAsBytes();

    final uri = Uri.parse(
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
    );

    const boundary = 'budget_companion_boundary';
    final meta = jsonEncode({
      'name': 'budget_companion_backup.db',
      'parents': ['appDataFolder'],
    });

    final body = <int>[]
      ..addAll(utf8.encode('--$boundary\r\n'))
      ..addAll(utf8.encode(
          'Content-Type: application/json; charset=utf-8\r\n\r\n$meta\r\n'))
      ..addAll(utf8.encode('--$boundary\r\n'))
      ..addAll(utf8.encode(
          'Content-Type: application/octet-stream\r\n\r\n')) // SQLite binary
      ..addAll(fileBytes)
      ..addAll(utf8.encode('\r\n--$boundary--\r\n'));

    final resp = await http.post(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'multipart/related; boundary=$boundary',
      },
      body: body,
    );

    if (resp.statusCode >= 400) {
      debugPrint('Drive backup failed: ${resp.statusCode} ${resp.body}');
      throw StateError('Failed to back up to Google Drive');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastBackupKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Downloads the latest backup from Drive appDataFolder and overwrites
  /// the local database file. Caller should reload stores afterwards.
  Future<void> restoreDatabase() async {
    final token = await _accessToken();
    if (token == null) {
      throw StateError('Google sign-in required for restore.');
    }

    // Find existing backup file in appDataFolder (if multiple, take most recent).
    final listUri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files'
      '?spaces=appDataFolder'
      '&q=name=%27budget_companion_backup.db%27'
      '&fields=files(id, name, modifiedTime)'
      '&orderBy=modifiedTime desc',
    );

    final listResp = await http.get(
      listUri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );

    if (listResp.statusCode >= 400) {
      debugPrint('Drive list failed: ${listResp.statusCode} ${listResp.body}');
      throw StateError('Failed to find backup on Google Drive');
    }

    final data = jsonDecode(listResp.body) as Map<String, dynamic>;
    final files = (data['files'] as List?) ?? const [];
    if (files.isEmpty) {
      throw StateError('No backup file found in Google Drive');
    }
    final first = files.first as Map<String, dynamic>;
    final fileId = first['id'] as String;

    final downloadUri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
    );

    final downloadResp = await http.get(
      downloadUri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );

    if (downloadResp.statusCode >= 400) {
      debugPrint(
          'Drive download failed: ${downloadResp.statusCode} ${downloadResp.body}');
      throw StateError('Failed to download backup from Google Drive');
    }

    final dbPath = await _databasePath();

    // Best effort: close any existing database connection before overwrite.
    // Caller may also reset LocalDb if needed.
    await File(dbPath).writeAsBytes(downloadResp.bodyBytes, flush: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastRestoreKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}

