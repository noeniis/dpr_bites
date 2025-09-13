import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/checkout_process_page_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CheckoutProcessPageService {
  static final _storage = const FlutterSecureStorage();
  static Future<int?> getUserIdFromPrefs() async {
    try {
      for (final k in const ['id_users', 'id_user', 'user_id']) {
        final v = await _storage.read(key: k);
        if (v != null && v.isNotEmpty) {
          final parsed = int.tryParse(v.toString());
          if (parsed != null) return parsed;
        }
      }
    } catch (_) {}
    return null;
  }

  // Fetch transaction detail by booking_id or id_transaksi
  static Future<TransactionDetailResult> fetchTransactionDetail({
    String? bookingId,
    int? idTransaksi,
  }) async {
    final qp = <String, String>{};
    if (bookingId != null && bookingId.isNotEmpty) {
      qp['booking_id'] = bookingId;
    } else if (idTransaksi != null) {
      qp['id_transaksi'] = idTransaksi.toString();
    }
    final uri = Uri.parse(
      '${getBaseUrl()}/get_transaction_detail.php',
    ).replace(queryParameters: qp);
    final token = await _storage.read(key: 'jwt_token');
    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode != 200) {
      return TransactionDetailResult(
        success: false,
        tx: const {},
        items: const [],
      );
    }
    try {
      final data = jsonDecode(resp.body);
      if (data is Map && data['success'] == true && data['data'] is Map) {
        final map = Map<String, dynamic>.from(data['data']);
        final itemsRaw = (map['items'] as List?) ?? const [];
        final items = itemsRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        return TransactionDetailResult(success: true, tx: map, items: items);
      }
    } catch (e) {
      debugPrint('[CheckoutProcessService] parse error: $e');
    }
    return TransactionDetailResult(
      success: false,
      tx: const {},
      items: const [],
    );
  }

  // Resolve id_gerai by id_menu from various endpoints (fallback)
  static Future<int?> resolveGeraiIdFromMenu(int idMenu) async {
    if (idMenu <= 0) return null;
    final bases = [
      '/get_single_menu.php?id_menu=',
      '/get_menu_detail.php?id_menu=',
      '/get_menu_detail_user.php?id_menu=',
    ];
    final token = await _storage.read(key: 'jwt_token');
    for (final path in bases) {
      try {
        final url = Uri.parse('${getBaseUrl()}$path$idMenu');
        final resp = await http.get(
          url,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
        if (resp.statusCode != 200) continue;
        final j = jsonDecode(resp.body);
        if (j is Map && j['success'] == true && j['data'] is Map) {
          final g = (j['data'] as Map)['id_gerai'];
          if (g != null) {
            final parsed = g is int ? g : int.tryParse(g.toString());
            if (parsed != null) return parsed;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  // Fetch all addons by id_gerai and return map id->name for quick lookup
  static Future<Map<int, String>> fetchAddonNameMapByGerai(int idGerai) async {
    if (idGerai <= 0) return {};
    try {
      final token = await _storage.read(key: 'jwt_token');
      final uri = Uri.parse('${getBaseUrl()}/get_addon.php?id_gerai=$idGerai');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        if (j is Map && j['success'] == true && j['addons'] is List) {
          final map = <int, String>{};
          for (final a in (j['addons'] as List)) {
            if (a is Map) {
              final id = a['id_addon'];
              final name = a['nama_addon'];
              final intId = id is int ? id : int.tryParse(id?.toString() ?? '');
              final nm = name?.toString();
              if (intId != null && intId > 0 && nm != null && nm.isNotEmpty) {
                map[intId] = nm;
              }
            }
          }
          return map;
        }
      }
    } catch (e) {
      debugPrint('[CheckoutProcessService] fetchAddonNameMap error: $e');
    }
    return {};
  }

  // Upload payment proof as base64 with data URL prefix (matches existing backend)
  static Future<GenericBoolResult> uploadPaymentProof({
    required String bookingId,
    required XFile file,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final token = await _storage.read(key: 'jwt_token');
      final resp = await http.post(
        Uri.parse('${getBaseUrl()}/upload_payment_proof_user.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'bukti_base64': 'data:image/png;base64,' + b64,
        }),
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        final ok = j is Map && j['success'] == true;
        return GenericBoolResult(
          success: ok,
          message: j is Map ? j['message']?.toString() : null,
        );
      }
    } catch (e) {
      debugPrint('[CheckoutProcessService] uploadPaymentProof error: $e');
    }
    return GenericBoolResult(success: false);
  }

  static Future<void> persistPaymentStart(String bookingId, DateTime dt) async {
    try {
      await _storage.write(
        key: 'pay_start_' + bookingId,
        value: dt.toIso8601String(),
      );
    } catch (_) {}
  }

  static Future<DateTime?> loadPaymentStart(String bookingId) async {
    try {
      final s = await _storage.read(key: 'pay_start_' + bookingId);
      if (s == null) return null;
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  static Future<void> removePaymentStart(String bookingId) async {
    try {
      await _storage.delete(key: 'pay_start_' + bookingId);
    } catch (_) {}
  }

  static Future<void> persistPrepStart(int idTransaksi, DateTime dt) async {
    try {
      await _storage.write(
        key: 'prep_start_${idTransaksi.toString()}',
        value: dt.toIso8601String(),
      );
    } catch (_) {}
  }

  static Future<DateTime?> loadPrepStart(int idTransaksi) async {
    try {
      final s = await _storage.read(
        key: 'prep_start_${idTransaksi.toString()}',
      );
      if (s == null) return null;
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  static Future<void> removePrepStart(int idTransaksi) async {
    try {
      await _storage.delete(key: 'prep_start_${idTransaksi.toString()}');
    } catch (_) {}
  }

  static Future<void> persistDiantarStart(int idTransaksi, DateTime dt) async {
    try {
      await _storage.write(
        key: 'diantar_start_${idTransaksi.toString()}',
        value: dt.toIso8601String(),
      );
    } catch (_) {}
  }

  static Future<DateTime?> loadDiantarStart(int idTransaksi) async {
    try {
      final s = await _storage.read(
        key: 'diantar_start_${idTransaksi.toString()}',
      );
      if (s == null) return null;
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeDiantarStart(int idTransaksi) async {
    try {
      await _storage.delete(key: 'diantar_start_${idTransaksi.toString()}');
    } catch (_) {}
  }

  static Future<GenericBoolResult> updateTransactionStatus({
    required String bookingId,
    required String newStatus,
    String? alasan,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final resp = await http.post(
        Uri.parse('${getBaseUrl()}/update_transaction_status.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'new_status': newStatus,
          if (alasan != null) 'alasan': alasan,
        }),
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        final ok = j is Map && j['success'] == true;
        return GenericBoolResult(
          success: ok,
          message: j is Map ? j['message']?.toString() : null,
        );
      }
    } catch (e) {
      debugPrint('[CheckoutProcessService] updateTransactionStatus error: $e');
    }
    return GenericBoolResult(success: false);
  }
}
