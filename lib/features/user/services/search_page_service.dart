import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/search_page_model.dart';

class SearchService {
  static Future<List<Map<String, dynamic>>> searchRestaurants(String q) async {
    try {
      final uri = Uri.parse(
        '${getBaseUrl()}/search_restaurants.php?q=${Uri.encodeQueryComponent(q)}',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
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
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
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
      final res = await http.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
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
