import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PenjualInfoService {
  static final _storage = FlutterSecureStorage();
  static Future<String?> uploadImageToCloudinary(File imageFile) async {
    const String uploadPreset = 'dpr_bites';
    const String cloudName = 'dip8i3f6x';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['secure_url'];
      } else {
        final respStr = await response.stream.bytesToString();
        print('Cloudinary upload failed: ${response.statusCode} - $respStr');
      }
    } catch (e) {
      print('Cloudinary upload exception: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchPenjualInfo(String idUsers) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/get_penjual_info.php'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        body: {'id_users': idUsers},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data;
      }
    } catch (e) {
      print("DEBUG fetchPenjualInfo error: $e");
    }
    return null;
  }

  static Future<bool> addOrUpdatePenjualInfo(Map<String, dynamic> data) async {
    // Upload foto KTP jika ada
    if (data['foto_ktp_file'] != null && data['foto_ktp_file'] is File) {
      final urlKtp = await uploadImageToCloudinary(data['foto_ktp_file']);
      if (urlKtp != null) {
        data['foto_ktp_path'] = urlKtp;
      }
      data.remove('foto_ktp_file');
    }

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/add_or_update_penjual_info.php'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        body: data,
      );
      print('DEBUG penjual_info response.body: ${response.body}');
      final res = jsonDecode(response.body);
      return res['success'] == true;
    } catch (e) {
      print("DEBUG addOrUpdatePenjualInfo error: $e");
      return false;
    }
  }

  static Future<void> prefillControllersFromDb({
    required String idUsers,
    required TextEditingController nikController,
    required TextEditingController noTeleponPenjualController,
    required TextEditingController birthPlaceController,
    required TextEditingController birthDateController,
    required void Function(String?) setGender,
    required void Function(String?) setKtpImagePath,
    required void Function() setState,
  }) async {
    final data = await fetchPenjualInfo(idUsers);
    if (data != null && data['success'] == true && data['data'] != null) {
      final info = data['data'];

      nikController.text = info['nik'] ?? '';
      noTeleponPenjualController.text = info['no_telepon_penjual'] ?? '';

      // gender diset lowercase supaya konsisten dengan Dropdown
      if (info['jenis_kelamin'] != null) {
        setGender(info['jenis_kelamin'].toString().toLowerCase());
      }

      birthPlaceController.text = info['tempat_lahir'] ?? '';

      // Format tanggal lahir ke dd-mm-yyyy kalau berasal dari yyyy-mm-dd
      if (info['tanggal_lahir'] != null && info['tanggal_lahir'].toString().isNotEmpty) {
        final parts = info['tanggal_lahir'].split('-');
        if (parts.length == 3) {
          birthDateController.text = "${parts[2]}-${parts[1]}-${parts[0]}";
        } else {
          birthDateController.text = info['tanggal_lahir'];
        }
      }

      if (info['foto_ktp_path'] != null && info['foto_ktp_path'].toString().isNotEmpty) {
        setKtpImagePath(info['foto_ktp_path']);
      }

      setState();
    }
  }

  static String toDbDate(String input) {
    final parts = input.split('-');
    if (parts.length == 3) {
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    }
    return input;
  }

  static String toFormDate(String input) {
    final parts = input.split('-');
    if (parts.length == 3) {
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    }
    return input;
  }
}
