  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:dpr_bites/common/utils/base_url.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import 'package:flutter/foundation.dart';

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
      final storage = FlutterSecureStorage();
      final jwt = await storage.read(key: 'jwt_token');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (jwt != null) 'Authorization': 'Bearer $jwt',
      };
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/auto_decide_availability.php'),
        headers: headers,
        body: jsonEncode(body),
      );
      return res.statusCode == 200 && res.body.contains('success');
    }

    static Future<bool> updateStatus({
      required String idTransaksi,
      required String newStatus,
    }) async {
      final storage = FlutterSecureStorage();
      final jwt = await storage.read(key: 'jwt_token');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (jwt != null) 'Authorization': 'Bearer $jwt',
      };
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/update_transaction_status.php'),
        headers: headers,
        body: jsonEncode({
          "id_transaksi": idTransaksi,
          "new_status": newStatus,
        }),
      );
      // Debug: log status and body to aid diagnosis
      try {
        debugPrint('updateStatus response status: ${res.statusCode}');
        debugPrint('updateStatus response body: ${res.body}');
      } catch (_) {}
      return res.statusCode == 200 && res.body.contains('success');
    }

    // Returns a map with statusCode and body for debugging in UI
    static Future<Map<String, dynamic>> updateStatusRaw({
      required String idTransaksi,
      required String newStatus,
    }) async {
      final storage = FlutterSecureStorage();
      final jwt = await storage.read(key: 'jwt_token');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (jwt != null) 'Authorization': 'Bearer $jwt',
      };
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/update_transaction_status.php'),
        headers: headers,
        body: jsonEncode({
          "id_transaksi": idTransaksi,
          "new_status": newStatus,
        }),
      );
      try {
        debugPrint('updateStatusRaw response status: ${res.statusCode}');
        debugPrint('updateStatusRaw response body: ${res.body}');
      } catch (_) {}
      return {'statusCode': res.statusCode, 'body': res.body};
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
      final jwt = await FlutterSecureStorage().read(key: 'jwt_token');
      if (jwt != null) request.headers['Authorization'] = 'Bearer $jwt';
      var response = await request.send();
      return response.statusCode == 200;
    }
  }
