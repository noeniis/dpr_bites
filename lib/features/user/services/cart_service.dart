import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/cart_model.dart';

class CartService {
  static final _storage = const FlutterSecureStorage();

  static Future<String?> getUserIdFromPrefs() async {
    try {
      // Prefer 'id_users', but also consider common fallbacks if present
      for (final k in const ['id_users', 'id_user', 'user_id']) {
        final v = await _storage.read(key: k);
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  static String baseApi() => getBaseUrl();

  static Future<CartFetchResult> fetchCart({String? userId}) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final uri = Uri.parse('${getBaseApiUrlForCart()}/get_user_cart.php');
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final data = body['data'];
          if (data is List) {
            final carts = <Map<String, dynamic>>[];
            for (final r in data) {
              if (r is Map) {
                final model = CartRestaurantModel.fromJson(
                  Map<String, dynamic>.from(r),
                );
                carts.add(model.toMap());
              }
            }
            return CartFetchResult(carts: carts);
          }
        }
      }
      return CartFetchResult(carts: const [], error: 'Gagal memuat keranjang');
    } catch (e) {
      return CartFetchResult(carts: const [], error: e.toString());
    }
  }

  // The cart endpoints are hosted under the same base as other APIs, but
  // cart.dart used an inline 10.0.2.2 path. We'll derive from getBaseUrl().
  static String getBaseApiUrlForCart() {
    // getBaseUrl() already returns like http://10.0.2.2/dpr_bites_api
    return getBaseUrl();
  }

  static Future<bool> addOrUpdateCartItem({
    required String? userId,
    required int geraiId,
    required int menuId,
    required int qty,
    required List addonLabels,
    required List addonOptions,
    bool addonsExplicit = false,
    String? note,
    bool noteProvided = false,
    int? cartItemId,
  }) async {
    final token = await _storage.read(key: 'jwt_token');
    // Convert selected addon labels to ids using addonOptions
    final addonIds = <int>[];
    final wanted = addonLabels
        .map((e) => e.toString().trim().toLowerCase())
        .toSet();
    for (final opt in addonOptions) {
      if (opt is Map) {
        final lab = (opt['label'] ?? '').toString().trim().toLowerCase();
        if (wanted.contains(lab)) {
          final idVal = int.tryParse((opt['id'] ?? '').toString());
          if (idVal != null) addonIds.add(idVal);
        }
      }
    }
    final mapPayload = <String, dynamic>{
      'gerai_id': geraiId,
      'menu_id': menuId,
      'qty': qty,
    };
    if (cartItemId != null && cartItemId > 0) {
      mapPayload['item_id'] = cartItemId;
    }
    // Only include 'addons' key when caller intends to change addons explicitly.
    if (addonsExplicit) {
      mapPayload['addons'] = addonIds;
    }
    if (noteProvided) {
      mapPayload['note'] = note ?? '';
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse(
      '${getBaseApiUrlForCart()}/add_or_update_cart_item.php',
    );
    final res = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(mapPayload),
    );
    if (res.statusCode == 200) {
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) return true;
      } catch (_) {}
    }
    return false;
  }
}
