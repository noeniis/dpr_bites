import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import '../models/dashboard_rekap_model.dart';

class DashboardService {
  static Future<DashboardRekapModel?> fetchRekap({
    required String idGerai,
    required String tanggal,
  }) async {
    final uri = Uri.parse('${getBaseUrl()}/get_rekap_pesanan_seller.php')
        .replace(queryParameters: {'id_gerai': idGerai, 'tanggal': tanggal});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return DashboardRekapModel.fromJson(data);
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchGeraiByUser(String idUser) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      body: {'id_users': idUser},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? {};
      }
    }
    return null;
  }
}
