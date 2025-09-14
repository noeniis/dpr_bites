import 'dart:io';
import 'dart:typed_data';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/pembayaran_qris_dialog_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class PembayaranQrisDialogService {
  static const _storage = FlutterSecureStorage();

  /// Build a full URL to the QRIS image, supporting relative paths from backend.
  static String buildQrisUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    final cleaned = raw.startsWith('/') ? raw.substring(1) : raw;
    // Prefer configured base URL if available; fall back to emulator base.
    final base = getBaseUrl();
    // Many endpoints are hosted under dpr_bites_api; ensure we don't double-append.
    // If base already ends with /dpr_bites_api, append cleaned directly; else add.
    final baseNormalized = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final apiBase = baseNormalized.contains('dpr_bites_api')
        ? baseNormalized
        : baseNormalized + '/dpr_bites_api';
    return apiBase + '/' + cleaned;
  }

  /// Download a QRIS image and save to Downloads (Android) or app docs (others).
  /// Filename can be customized; defaults to 'QRIS_Payment.jpg'.
  static Future<QrisDownloadResult> downloadQrisImage(
    String url, {
    String? fileName,
  }) async {
    try {
      if (url.isEmpty) return QrisDownloadResult.failure('URL kosong');
      final token = await _storage.read(key: 'jwt_token');
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer ' + token;
      }
      final resp = await http.get(Uri.parse(url), headers: headers);
      if (resp.statusCode != 200) {
        return QrisDownloadResult.failure(
          'Gagal unduh (HTTP ' + resp.statusCode.toString() + ')',
          statusCode: resp.statusCode,
        );
      }
      final bytes = resp.bodyBytes;
      // Build filename: provided or default
      String targetName = (fileName == null || fileName.trim().isEmpty)
          ? 'QRIS_Payment.jpg'
          : fileName.trim();
      // Ensure .jpg extension
      if (!targetName.toLowerCase().endsWith('.jpg') &&
          !targetName.toLowerCase().endsWith('.jpeg')) {
        targetName = targetName + '.jpg';
      }
      // Sanitize filename (avoid illegal characters)
      targetName = targetName.replaceAll(RegExp(r"[^A-Za-z0-9._-]"), '_');
      String? saved;
      // Try Android platform channel (MediaStore/Downloads) first
      if (Platform.isAndroid) {
        try {
          const channel = MethodChannel('dpr_bites/downloads');
          final res = await channel.invokeMethod<String>(
            'saveImageToDownloads',
            {'bytes': bytes, 'fileName': targetName, 'mimeType': 'image/jpeg'},
          );
          saved = res; // could be a content:// URI or file path
        } catch (e) {
          debugPrint('Platform save failed, fallback: ' + e.toString());
        }
      }
      saved ??= await _saveToDownloads(bytes, fileName: targetName);
      if (saved == null) {
        return QrisDownloadResult.failure('Tidak bisa menyimpan ke Downloads');
      }
      return QrisDownloadResult.success(localPath: saved, fileName: targetName);
    } catch (e) {
      debugPrint('downloadQrisImage error: ' + e.toString());
      return QrisDownloadResult.failure('Gagal unduh: ' + e.toString());
    }
  }

  static Future<String?> _saveToDownloads(
    Uint8List bytes, {
    required String fileName,
  }) async {
    try {
      if (Platform.isAndroid) {
        // Request storage permission for legacy external storage write (< Q)
        final perm = await Permission.storage.request();
        if (!perm.isGranted && !perm.isLimited) {
          debugPrint('Storage permission not granted');
        }

        Directory? downloadsDir;
        try {
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          if (dirs != null && dirs.isNotEmpty) {
            downloadsDir = dirs.first;
          }
        } catch (_) {}
        downloadsDir ??= Directory('/storage/emulated/0/Download');

        if (!await downloadsDir.exists()) {
          final docs = await getApplicationDocumentsDirectory();
          final fallback = File(p.join(docs.path, fileName));
          await fallback.writeAsBytes(bytes);
          return fallback.path;
        }

        String targetPath = p.join(downloadsDir.path, fileName);
        if (await File(targetPath).exists()) {
          final name = p.basenameWithoutExtension(fileName);
          final ext = p.extension(fileName);
          int i = 1;
          while (await File(
                p.join(downloadsDir.path, '${name}_$i$ext'),
              ).exists() &&
              i < 1000) {
            i++;
          }
          targetPath = p.join(downloadsDir.path, '${name}_$i$ext');
        }
        final out = File(targetPath);
        await out.writeAsBytes(bytes);
        return out.path;
      } else {
        final docs = await getApplicationDocumentsDirectory();
        final out = File(p.join(docs.path, fileName));
        await out.writeAsBytes(bytes);
        return out.path;
      }
    } catch (e) {
      debugPrint('_saveToDownloads error: $e');
      return null;
    }
  }
}
