import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'detail_order_model.dart';

class TransactionDetailModel {
  final String idTransaksi;
  final String bookingId;
  final String status;
  final String jenisPengantaran;
  final String idUsers;
  final String idGerai;
  final String metodePembayaran;
  final String? buktiPembayaran;
  final String? catatanPembatalan;
  final String? namaGerai;
  final String? detailAlamat;
  final String? qrisPath;
  final String? lokasiPengantaran;
  final List<DetailOrderModel> items;
  // New fields for delivery address
  final String? alamatPengantaranDetail;
  final double? alamatPengantaranLat;
  final double? alamatPengantaranLng;

  TransactionDetailModel({
    required this.idTransaksi,
    required this.bookingId,
    required this.status,
    required this.jenisPengantaran,
    required this.idUsers,
    required this.idGerai,
    required this.metodePembayaran,
    this.buktiPembayaran,
    this.catatanPembatalan,
    this.namaGerai,
    this.detailAlamat,
    this.qrisPath,
    this.lokasiPengantaran,
    required this.items,
    this.alamatPengantaranDetail,
    this.alamatPengantaranLat,
    this.alamatPengantaranLng,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    final alamatPengantaran = json['alamat_pengantaran'] ?? {};
    return TransactionDetailModel(
      idTransaksi: json['id_transaksi'].toString(),
      bookingId: json['booking_id'].toString(),
      status: json['status'].toString(),
      jenisPengantaran: json['jenis_pengantaran'].toString(),
      idUsers: json['id_users'].toString(),
      idGerai: json['id_gerai'].toString(),
      metodePembayaran: json['metode_pembayaran'].toString(),
      buktiPembayaran: json['bukti_pembayaran']?.toString(),
      catatanPembatalan: json['catatan_pembatalan']?.toString(),
      namaGerai: json['nama_gerai']?.toString(),
      detailAlamat: json['detail_alamat']?.toString(),
      qrisPath: json['qris_path']?.toString(),
      lokasiPengantaran: json['lokasi_pengantaran']?.toString(),
      items: (json['items'] as List<dynamic>?)?.map((e) => DetailOrderModel.fromJson(e)).toList() ?? [],
      alamatPengantaranDetail: alamatPengantaran['detail']?.toString(),
      alamatPengantaranLat: alamatPengantaran['latitude'] != null ? double.tryParse(alamatPengantaran['latitude'].toString()) : null,
      alamatPengantaranLng: alamatPengantaran['longitude'] != null ? double.tryParse(alamatPengantaran['longitude'].toString()) : null,
    );
  }

  static Future<TransactionDetailModel?> fetchByBookingId(String bookingId) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');

    final base = getBaseUrl();
    final uri = Uri.parse('$base/get_transaction_detail.php').replace(queryParameters: {'booking_id': bookingId});

    final headers = <String, String>{'Accept': 'application/json'};
    if (jwt != null && jwt.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwt';
    }

    final response = await http.get(uri, headers: headers);
    // Debugging: log jwt presence and request/response to help trace why detail may be missing
    try {
      debugPrint('fetchByBookingId jwt present: ${jwt != null && jwt.isNotEmpty}');
      debugPrint('fetchByBookingId bookingId: $bookingId');
      // Use debugPrint so it shows in Flutter logs
      debugPrint('fetchByBookingId: ${uri.toString()}');
      debugPrint('fetchByBookingId response status: ${response.statusCode}');
      debugPrint('fetchByBookingId response body: ${response.body}');
    } catch (_) {}

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return TransactionDetailModel.fromJson(data['data']);
      }
      // If success==false, also log message for clarity
      debugPrint('fetchByBookingId: server returned success=false, message: ${data['message'] ?? 'no message'}');
    }
    return null;
  }
}
