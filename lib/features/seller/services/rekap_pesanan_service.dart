import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import '../models/rekap_pesanan_model.dart';

class RekapPesananService {
  static Future<RekapPesananModel?> fetchRekap({
    required String idGerai,
    required String tanggal,
  }) async {
    final uri = Uri.parse('${getBaseUrl()}/get_rekap_pesanan_seller.php')
        .replace(queryParameters: {'id_gerai': idGerai, 'tanggal': tanggal});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return RekapPesananModel.fromJson(data);
      }
    }
    return null;
  }
}
