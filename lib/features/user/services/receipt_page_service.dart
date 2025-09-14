import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/receipt_page_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ReceiptPageService {
  static final _storage = const FlutterSecureStorage();
  static Future<ReceiptFetchResult> fetchReceipt({
    String? bookingId,
    int? idTransaksi,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final idUsers = await _storage.read(key: 'id_users');
      final qp = <String, String>{};
      if (bookingId != null && bookingId.isNotEmpty) {
        qp['booking_id'] = bookingId;
      } else if (idTransaksi != null && idTransaksi > 0) {
        qp['id_transaksi'] = idTransaksi.toString();
      } else {
        return const ReceiptFetchResult(
          error: 'booking_id atau id_transaksi wajib',
        );
      }
      final uri = Uri.parse(
        '${getBaseUrl()}/get_transaction_receipt.php',
      ).replace(queryParameters: qp);
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (idUsers != null) 'X-User-Id': idUsers,
      };
      final res = await http.get(uri, headers: headers);
      if (res.statusCode != 200) {
        return ReceiptFetchResult(error: 'HTTP ${res.statusCode}');
      }
      final body = jsonDecode(res.body);
      if (body is! Map || body['success'] != true) {
        return ReceiptFetchResult(
          error: body is Map
              ? (body['message']?.toString() ?? 'Gagal')
              : 'Respon tidak valid',
        );
      }
      final d = body['data'];
      if (d is Map) {
        final model = ReceiptDetailModel.fromJson(Map<String, dynamic>.from(d));
        // ensure orderSummary presence fallback
        final map = model.toMap();
        if ((map['orderSummary'] as List).isEmpty && d['items'] is List) {
          map['orderSummary'] = d['items'];
        }
        return ReceiptFetchResult(data: map);
      }
      return const ReceiptFetchResult(data: null);
    } catch (e) {
      return ReceiptFetchResult(error: e.toString());
    }
  }

  static Future<ReviewFetchResult> fetchReviewStatus(int idTransaksi) async {
    try {
      final idUsers = await _storage.read(key: 'id_users');
      final token = await _storage.read(key: 'jwt_token');
      if (idUsers == null) return const ReviewFetchResult(hasReview: false);
      final uri = Uri.parse('${getBaseUrl()}/get_ulasan.php').replace(
        queryParameters: {
          'id_transaksi': idTransaksi.toString(),
          'id_users': idUsers,
        },
      );
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'X-User-Id': idUsers,
        },
      );
      if (res.statusCode != 200)
        return const ReviewFetchResult(hasReview: false);
      final body = jsonDecode(res.body);
      if (body is Map && body['success'] == true) {
        final d = body['data'];
        if (d != null) {
          final m = ReviewModel.fromJson(Map<String, dynamic>.from(d));
          return ReviewFetchResult(hasReview: true, review: m.toMap());
        }
        return const ReviewFetchResult(hasReview: false);
      }
      return const ReviewFetchResult(hasReview: false);
    } catch (e) {
      return ReviewFetchResult(hasReview: false, error: e.toString());
    }
  }

  static Future<bool> autoCancelIfExpired(Map<String, dynamic> data) async {
    try {
      final status = (data['status'] ?? '').toString();
      if (status != 'konfirmasi_pembayaran') return false;
      final bookingId = (data['booking_id'] ?? '').toString();
      if (bookingId.isEmpty) return false;
      final token = await _storage.read(key: 'jwt_token');
      final startRaw = await _storage.read(key: 'pay_start_' + bookingId);
      if (startRaw == null) return false;
      final start = DateTime.tryParse(startRaw);
      if (start == null) return false;
      final bukti = (data['bukti_pembayaran'] ?? '').toString();
      final expired =
          DateTime.now().difference(start) >= const Duration(minutes: 10);
      if (!expired || bukti.isNotEmpty) return false;
      final body = jsonEncode({
        'booking_id': bookingId,
        'new_status': 'dibatalkan',
        'alasan': 'Pembayaran Dibatalkan',
      });
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/update_transaction_status.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );
      if (res.statusCode == 200) {
        // refresh detail
        final det = await http.get(
          Uri.parse(
            '${getBaseUrl()}/get_transaction_receipt.php',
          ).replace(queryParameters: {'booking_id': bookingId}),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
        if (det.statusCode == 200) {
          final jb = jsonDecode(det.body);
          if (jb is Map && jb['success'] == true && jb['data'] is Map) {
            final model = ReceiptDetailModel.fromJson(
              Map<String, dynamic>.from(jb['data'] as Map),
            );
            data
              ..clear()
              ..addAll(model.toMap());
          } else {
            data['status'] = 'dibatalkan';
            data['catatan_pembatalan'] = 'Pembayaran Dibatalkan';
          }
        } else {
          data['status'] = 'dibatalkan';
          data['catatan_pembatalan'] = 'Pembayaran Dibatalkan';
        }
        await _storage.delete(key: 'pay_start_' + bookingId);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
