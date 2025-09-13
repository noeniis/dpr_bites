import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/search_page_model.dart';

class SearchService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> _getJwt() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> searchRestaurants(String q) async {
    try {
      final uri = Uri.parse(
        '${getBaseUrl()}/search_restaurants.php?q=${Uri.encodeQueryComponent(q)}',
      );
      final jwt = await _getJwt();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
      };
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final List data = body['data'] as List? ?? [];
          final list = data.map<Map<String, dynamic>>((e) {
            final model = SearchRestaurantModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            );
            return model.toMap();
          }).toList();
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> fetchMenuDetailUser(String id) async {
    try {
      final uri = Uri.parse(
        '${getBaseUrl()}/get_menu_detail_user.php?id=${Uri.encodeQueryComponent(id)}',
      );
      final jwt = await _getJwt();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
      };
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final data = body['data'];
          if (data is Map) return Map<String, dynamic>.from(data);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> addOrUpdateCart(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${getBaseUrl()}/add_or_update_cart_item.php');
    try {
      final jwt = await _getJwt();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
      };
      final cleanPayload = Map<String, dynamic>.from(payload)
        ..remove('user_id');
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(cleanPayload),
      );
      if (res.statusCode != 200) return false;
      try {
        final j = jsonDecode(res.body);
        if (j is Map && j['success'] == true) return true;
      } catch (_) {
        // if server doesn't return json success, still treat 200 as success for current UX
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
