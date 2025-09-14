import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/address_page_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AddressPageService {
  static final _storage = const FlutterSecureStorage();
  static Future<String?> getUserIdFromPrefs() async {
    try {
      for (final k in const ['id_users', 'id_user', 'user_id']) {
        final v = await _storage.read(key: k);
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  static Future<AddressFetchResult> fetchAddresses(String userId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final uri = Uri.parse('${getBaseUrl()}/get_user_addresses.php');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-User-Id': userId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id_users': userId}),
      );
      if (res.statusCode != 200) {
        return AddressFetchResult(
          addresses: const [],
          error: 'HTTP ${res.statusCode}',
        );
      }
      final body = jsonDecode(res.body);
      if (body is Map && body['success'] == true) {
        final list = (body['addresses'] as List?) ?? [];
        final result = <Map<String, dynamic>>[];
        for (final e in list) {
          if (e is Map) {
            final m = AddressModel.fromJson(Map<String, dynamic>.from(e));
            result.add(m.toMap());
          }
        }
        return AddressFetchResult(addresses: result);
      }
      return AddressFetchResult(
        addresses: const [],
        error: body is Map
            ? (body['message']?.toString() ?? 'Gagal memuat')
            : 'Respon tidak valid',
      );
    } catch (e) {
      return AddressFetchResult(addresses: const [], error: e.toString());
    }
  }

  static Future<bool> setDefaultAddress({
    required String userId,
    required int addressId,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final uri = Uri.parse('${getBaseUrl()}/set_default_address.php');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-User-Id': userId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id_users': userId, 'id_alamat': addressId}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body is Map && body['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> deleteAddress({
    required String userId,
    required int addressId,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final uri = Uri.parse('${getBaseUrl()}/delete_address.php');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-User-Id': userId,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id_alamat': addressId}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body is Map && body['success'] == true;
      }
    } catch (_) {}
    return false;
  }
}
