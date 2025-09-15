import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import '../models/rekap_pesanan_model.dart';

class RekapPesananService {
  static Future<RekapPesananModel?> fetchRekap({
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
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return RekapPesananModel.fromJson(data);
      }
    }
    return null;
  }
}
