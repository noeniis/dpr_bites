import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'update_step_user_service.dart';
import '../../../common/utils/base_url.dart';
import '../models/pengajuan_model.dart';

class PengajuanService {
  static String get baseUrl => getBaseUrl();

  static Future<List<PengajuanModel>> fetchPengajuan(String status) async {
  final storage = FlutterSecureStorage();
  final jwt = await storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('${baseUrl}/get_pengajuan.php?status=$status'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => PengajuanModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Gagal memuat data pengajuan: ${response.body}');
    }
  }

  // Update status pengajuan
  static Future<bool> updateStatus(int idGerai, String status, {String? alasan}) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    print('[DEBUG] JWT for updateStatus: $jwt');
    final response = await http.post(
      Uri.parse('${baseUrl}/update_pengajuan.php'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id_gerai': idGerai.toString(),
        'status': status,
        'alasan': alasan ?? '',
      }),
    );
    print('[DEBUG] updateStatus response: ${response.statusCode} ${response.body}');
    final result = json.decode(response.body);
    bool pengajuanSuccess = result['success'] == true;
    if (pengajuanSuccess && (status.toLowerCase() == 'ditolak' || status.toLowerCase() == 'rejected')) {
      final idUser = result['id_users']?.toString();
      print('[DEBUG] id_users from update_pengajuan: $idUser');
      if (idUser != null && idUser.isNotEmpty) {
        await UpdateStepUserService.resetStepUser(idUser);
      }
    }
    return pengajuanSuccess;
  }
}