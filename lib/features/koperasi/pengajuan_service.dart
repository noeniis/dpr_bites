import 'dart:convert';
import 'package:http/http.dart' as http;

class PengajuanService {
  static const String baseUrl = 'http://10.0.2.2/dpr_bites_api';

  // Ambil data pengajuan berdasarkan status
  static Future<List<Map<String, dynamic>>> fetchPengajuan(String status) async {
    final response = await http.get(Uri.parse('$baseUrl/get_pengajuan.php?status=$status'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Gagal memuat data pengajuan');
    }
  }

  // Update status pengajuan
  static Future<bool> updateStatus(int idGerai, String status, {String? alasan}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_pengajuan.php'),
      body: {
        'id_gerai': idGerai.toString(),
        'status': status,
        'alasan': alasan ?? '',
      },
    );
    final result = json.decode(response.body);
    return result['success'] == true;
  }
}