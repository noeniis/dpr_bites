import 'dart:convert';
import 'package:http/http.dart' as http;
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
    final uri = Uri.http('10.0.2.2', '/dpr_bites_api/get_transaction_detail.php', {
      'booking_id': bookingId,
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return TransactionDetailModel.fromJson(data['data']);
      }
    }
    return null;
  }
}
