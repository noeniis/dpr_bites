  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:dpr_bites/common/utils/base_url.dart';

  class TransactionDetailService {
    static Future<bool> confirmAvailability({
      required String idTransaksi,
      required bool available,
      String? alasan,
    }) async {
      final body = {
        "id_transaksi": idTransaksi,
        "available": available,
      };
      if (!available && alasan != null) {
        body["alasan"] = alasan;
      }
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/auto_decide_availability.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode == 200 && res.body.contains('success');
    }

    static Future<bool> updateStatus({
      required String idTransaksi,
      required String newStatus,
    }) async {
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/update_transaction_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id_transaksi": idTransaksi,
          "new_status": newStatus,
        }),
      );
      return res.statusCode == 200 && res.body.contains('success');
    }

    static Future<bool> uploadBuktiPembayaran({
      required String idTransaksi,
      required String filePath,
    }) async {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${getBaseUrl()}/upload_bukti_pembayaran.php'),
      );
      request.fields['id_transaksi'] = idTransaksi;
      request.files.add(await http.MultipartFile.fromPath('bukti', filePath));
      var response = await request.send();
      return response.statusCode == 200;
    }
  }
