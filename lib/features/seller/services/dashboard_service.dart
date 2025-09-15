import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import '../models/dashboard_rekap_model.dart';

class DashboardService {
  static Future<DashboardRekapModel?> fetchRekap({
    String? idGerai,
    required String tanggal,
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final idGeraiFinal = idGerai ?? await storage.read(key: 'id_gerai');
    if (idGeraiFinal == null || jwt == null) return null;
    final uri = Uri.parse('${getBaseUrl()}/get_rekap_pesanan_seller.php')
        .replace(queryParameters: {'id_gerai': idGeraiFinal, 'tanggal': tanggal});
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $jwt'});
    print('fetchRekap response: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return DashboardRekapModel.fromJson(data);
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchGeraiByUser([String? idUser]) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final idUserFinal = idUser ?? await storage.read(key: 'id_users');
    if (idUserFinal == null || jwt == null) return null;
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      headers: {'Authorization': 'Bearer $jwt'},
      body: {'id_users': idUserFinal},
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
