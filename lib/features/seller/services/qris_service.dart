import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'gerai_profil_service.dart';

class QrisService {
  static final _storage = FlutterSecureStorage();
  // Get QRIS URL by user
  static Future<String?> getQrisUrlByUser(String idUsers) async {
    final data = await GeraiProfilService.fetchGeraiByUser(idUsers);
    if (data != null && data['data'] != null && data['data']['qris_path'] != null) {
      return data['data']['qris_path'].toString();
    }
    return null;
  }

  // Upload and save QRIS
  static Future<bool> uploadAndSaveQris(XFile? qrisImage) async {
    if (qrisImage == null) return false;
    final file = File(qrisImage.path);
    final urlQris = await GeraiProfilService.uploadQrisToCloudinary(file);
    if (urlQris == null) return false;
    final idGerai = await _storage.read(key: 'id_gerai') ?? '';
    return await GeraiProfilService.addOrUpdateQris(
      idGerai: idGerai,
      qrisPath: urlQris,
    );
  }
}
