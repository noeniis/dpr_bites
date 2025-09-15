import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/features/seller/models/pesanan/order_api_model.dart';

class PesananService {
  static Future<List<OrderApiModel>> fetchPesanan({
    required String idGerai,
    DateTime? tanggal,
  }) async {
    final params = {'id_gerai': idGerai};
    if (tanggal != null) {
      params['tanggal'] = "${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}";
    }
    final baseUrl = getBaseUrl();
    final uri = Uri.parse('$baseUrl/get_pesanan_seller.php').replace(queryParameters: params);

  final storage = FlutterSecureStorage();
  final jwt = await storage.read(key: 'jwt_token');
  final response = await http.get(uri, headers: jwt != null ? {'Authorization': 'Bearer $jwt'} : null).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['success'] == true && data['pesanan'] is List) {
        return (data['pesanan'] as List)
            .map((e) => OrderApiModel.fromJson(e))
            .toList();
      } else {
        throw Exception(data['message'] ?? 'Gagal memuat data');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase ?? ''}');
    }
  }

  static List<OrderApiModel> filterPesanan(
    List<OrderApiModel> pesananList,
    String filter,
  ) {
    if (filter == 'Semua') {
      return pesananList.where((p) {
        final metode = p.metodePembayaran.toLowerCase().trim();
        final status = p.status.toLowerCase().trim();
        final bukti = (p.buktiPembayaran ?? '').trim();
        if (status == 'konfirmasi_pembayaran' && metode == 'qris') {
          return bukti.isNotEmpty;
        }
        return true;
      }).toList();
    }
    switch (filter) {
      case 'Konfirmasi Ketersediaan':
        return pesananList.where((p) => p.status == 'konfirmasi_ketersediaan').toList();
      case 'Konfirmasi Pembayaran':
        return pesananList.where((p) {
          final metode = p.metodePembayaran.toLowerCase().trim();
          final status = p.status.toLowerCase().trim();
          final bukti = (p.buktiPembayaran ?? '').trim();
          if (status == 'konfirmasi_pembayaran' && metode == 'qris') {
            return bukti.isNotEmpty;
          } else {
            return status == 'konfirmasi_pembayaran';
          }
        }).toList();
      case 'Disiapkan':
        return pesananList.where((p) => p.status == 'disiapkan').toList();
      case 'Diantar':
        return pesananList.where((p) => p.status == 'diantar').toList();
      case 'Pickup':
        return pesananList.where((p) => p.status == 'pickup').toList();
      case 'Selesai':
        return pesananList.where((p) => p.status == 'selesai').toList();
      case 'Dibatalkan':
        return pesananList.where((p) => p.status == 'dibatalkan').toList();
      default:
        return pesananList;
    }
  }
}
