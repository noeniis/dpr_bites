import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/seller_user_model.dart';
import 'package:dpr_bites/common/utils/base_url.dart';

class OnboardingChecklistService {
  static const _storage = FlutterSecureStorage();

  static Future<SellerUserModel?> fetchSellerUserStatus() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        print('DEBUG JWT: token missing');
        return null;
      }

      // Ambil data user memakai Authorization Bearer
      final userRes = await http.post(
        Uri.parse('${getBaseUrl()}/get_user_by_id.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      if (userRes.statusCode != 200) return null;
      final userJson = jsonDecode(userRes.body);
      print('DEBUG userJson: $userJson');
      if (userJson['success'] != true || userJson['data'] == null) return null;

      dynamic data = userJson['data'];
      Map<String, dynamic>? userMap;
      if (data is List && data.isNotEmpty) {
        userMap = Map<String, dynamic>.from(data[0]);
      } else if (data is Map<String, dynamic>) {
        userMap = Map<String, dynamic>.from(data);
      }
      if (userMap == null) return null;

      // Ambil status pengajuan gerai memakai Authorization Bearer
      final geraiRes = await http.post(
        Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      String statusPengajuanGerai = '';
      String alasanTolak = '';
      if (geraiRes.statusCode == 200) {
        final geraiJson = jsonDecode(geraiRes.body);
        print('DEBUG geraiJson: $geraiJson');
        if (geraiJson['success'] == true && geraiJson['data'] != null) {
          statusPengajuanGerai = geraiJson['data']['status_pengajuan']?.toString() ?? '';
          alasanTolak = geraiJson['data']['alasan_tolak']?.toString() ?? '';
          // Simpan id_gerai ke secure storage jika ada
          final idGerai = geraiJson['data']['id_gerai']?.toString();
          if (idGerai != null && idGerai.isNotEmpty) {
            await _storage.write(key: 'id_gerai', value: idGerai);
            print('[ONBOARDING] id_gerai disimpan ke storage: $idGerai');
          }
        }
      }

      return SellerUserModel.fromJson(
        userMap,
        statusPengajuanGerai: statusPengajuanGerai,
        alasanTolak: alasanTolak,
      );
    } catch (e) {
      print('ERROR fetchSellerUserStatus: $e');
      return null;
    }
  }
}
