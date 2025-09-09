import 'dart:convert';
import 'package:http/http.dart' as http;
import 'update_step_user_service.dart';
import '../../../common/utils/base_url.dart';
import '../models/pengajuan_model.dart';

class PengajuanService {
  static String get baseUrl => getBaseUrl();

  static Future<List<PengajuanModel>> fetchPengajuan(String status) async {
    final response = await http.get(Uri.parse('${baseUrl}/get_pengajuan.php?status=$status'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => PengajuanModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Gagal memuat data pengajuan');
    }
  }

  // Update status pengajuan
  static Future<bool> updateStatus(int idGerai, String status, {String? alasan}) async {
    final response = await http.post(
      Uri.parse('${baseUrl}/update_pengajuan.php'),
      body: {
        'id_gerai': idGerai.toString(),
        'status': status,
        'alasan': alasan ?? '',
      },
    );
    final result = json.decode(response.body);
    bool pengajuanSuccess = result['success'] == true;

    
    if (pengajuanSuccess && (status.toLowerCase() == 'ditolak' || status.toLowerCase() == 'rejected')) {
      final idUser = result['id_users']?.toString();
      print('DEBUG id_users for resetStepUser: $idUser');
      if (idUser != null && idUser.isNotEmpty) {
        await UpdateStepUserService.resetStepUser(idUser);
      }
    }
    return pengajuanSuccess;
  }
}