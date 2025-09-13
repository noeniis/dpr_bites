import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seller_user_model.dart';
import 'package:dpr_bites/common/utils/base_url.dart';

class OnboardingChecklistService {
  static Future<SellerUserModel?> fetchSellerUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final idUsers = prefs.getString('id_users');
    print('DEBUG id_users dari SharedPreferences: $idUsers');
    if (idUsers == null) return null;

    // --- Ambil data user ---
    final userRes = await http.post(
      Uri.parse('${getBaseUrl()}/get_user_by_id.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_users': idUsers}),
    );

    if (userRes.statusCode != 200) return null;

    final userJson = jsonDecode(userRes.body);
    print("DEBUG userJson: $userJson");

    if (userJson['success'] != true || userJson['data'] == null) {
      return null;
    }

    dynamic data = userJson['data'];
    Map<String, dynamic>? userMap;

    // --- Normalisasi data ke bentuk Map ---
    if (data is List && data.isNotEmpty) {
      userMap = Map<String, dynamic>.from(data[0]);
    } else if (data is Map<String, dynamic>) {
      userMap = Map<String, dynamic>.from(data);
    }

    if (userMap == null) return null;

    // --- Ambil status_pengajuan dari tabel gerai ---
    String statusPengajuanGerai = '';
    String alasanTolak = '';
    final geraiRes = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      body: {'id_users': idUsers},
    );

    if (geraiRes.statusCode == 200) {
      final geraiJson = jsonDecode(geraiRes.body);
      print("DEBUG geraiJson: $geraiJson");
      if (geraiJson['success'] == true && geraiJson['data'] != null) {
        statusPengajuanGerai =
            geraiJson['data']['status_pengajuan']?.toString() ?? '';
        alasanTolak = geraiJson['data']['alasan_tolak']?.toString() ?? '';
      }
    }

    return SellerUserModel.fromJson(
      userMap,
      statusPengajuanGerai: statusPengajuanGerai,
      alasanTolak: alasanTolak,
    );
  }
}
