import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/address_page_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddressPageService {
  static Future<int?> getUserIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final intId = prefs.getInt('id_users');
      if (intId != null) return intId;
      final s = prefs.getString('id_users');
      return int.tryParse(s ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<AddressFetchResult> fetchAddresses(int userId) async {
    try {
      final uri = Uri.parse('${getBaseUrl()}/get_user_addresses.php');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-User-Id': userId.toString(),
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
    required int userId,
    required int addressId,
  }) async {
    try {
      final uri = Uri.parse('${getBaseUrl()}/set_default_address.php');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-User-Id': userId.toString(),
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
    required int userId,
    required int addressId,
  }) async {
    try {
      final uri = Uri.parse('${getBaseUrl()}/delete_address.php');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-User-Id': userId.toString(),
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
