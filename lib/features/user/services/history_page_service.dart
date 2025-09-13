import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/history_page_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HistoryPageService {
  static final _storage = const FlutterSecureStorage();
  static Future<String?> getUserIdFromPrefs() async {
    try {
      return await _storage.read(key: 'id_users');
    } catch (_) {
      return null;
    }
  }

  static Future<HistoryFetchResult> fetchTransactions(String userId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final uri = Uri.parse(
        '${getBaseUrl()}/get_user_transactions.php?user_id=$userId',
      );
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-User-Id': userId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode != 200) {
        return HistoryFetchResult(
          orders: const [],
          error: 'HTTP ${res.statusCode}',
        );
      }
      final body = jsonDecode(res.body);
      if (body is! Map || body['success'] != true) {
        return HistoryFetchResult(
          orders: const [],
          error: body is Map
              ? (body['message']?.toString() ?? 'Gagal')
              : 'Respon tidak valid',
        );
      }
      final data = body['data'];
      if (data is List) {
        final orders = <Map<String, dynamic>>[];
        for (final item in data) {
          if (item is Map) {
            final model = HistoryOrderModel.fromJson(
              Map<String, dynamic>.from(item),
            );
            orders.add(model.toMap());
          }
        }
        return HistoryFetchResult(orders: orders);
      }
      return const HistoryFetchResult(orders: []);
    } catch (e) {
      return HistoryFetchResult(orders: const [], error: e.toString());
    }
  }
}
