import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/favorit_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FavoritService {
  static final _storage = const FlutterSecureStorage();
  static Future<String?> _getJwt() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (_) {
      return null;
    }
  }

  // Convenience: resolve user id from SharedPreferences (key: 'id_users')
  static Future<String?> getUserIdFromPrefs() async {
    try {
      return await _storage.read(key: 'id_users');
    } catch (_) {
      return null;
    }
  }

  static Future<FavoriteFetchResult> fetchFavorites(String userId) async {
    try {
      final uri = Uri.parse('${getBaseUrl()}/get_user_favorites.php');
      final jwt = await _getJwt();
      if (jwt == null || jwt.isEmpty) {
        return FavoriteFetchResult(
          favorites: const [],
          restaurants: const {},
          error: 'Tidak ada token. Silakan login ulang.',
        );
      }
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          // optional legacy header for compatibility
          if (userId.isNotEmpty) 'X-User-Id': userId,
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final list = (body['data'] as List?) ?? [];
          final favorites = <Map<String, dynamic>>[];
          final restaurants = <String, Map<String, dynamic>>{};
          for (final m in list) {
            if (m is! Map) continue;
            final menuMap = Map<String, dynamic>.from(m);
            final r = menuMap['restaurant'];
            if (r is Map) {
              final restoModel = FavoriteRestaurantModel.fromJson(
                Map<String, dynamic>.from(r),
              );
              restaurants[restoModel.id] = restoModel.toMap();
              menuMap['restaurantId'] = restoModel.id;
            }
            final menuModel = FavoriteMenuModel.fromJson(menuMap);
            favorites.add(menuModel.toMap());
          }
          return FavoriteFetchResult(
            favorites: favorites,
            restaurants: restaurants,
          );
        }
        return FavoriteFetchResult(
          favorites: const [],
          restaurants: const {},
          error: body is Map
              ? (body['message']?.toString() ?? 'Gagal memuat')
              : 'Gagal memuat',
        );
      }
      return FavoriteFetchResult(
        favorites: const [],
        restaurants: const {},
        error: 'HTTP ${res.statusCode}',
      );
    } catch (e) {
      return FavoriteFetchResult(
        favorites: const [],
        restaurants: const {},
        error: e.toString(),
      );
    }
  }

  static Future<Map<String, int>> fetchCartQuantities(String userId) async {
    final rebuilt = <String, int>{};
    try {
      final uri = Uri.parse('${getBaseUrl()}/get_user_cart.php');
      final jwt = await _getJwt();
      if (jwt == null || jwt.isEmpty) return rebuilt;
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          if (userId.isNotEmpty) 'X-User-Id': userId,
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final data = body['data'];
          if (data is List) {
            for (final cart in data) {
              if (cart is Map) {
                final menus = cart['menus'];
                if (menus is List) {
                  for (final mi in menus) {
                    if (mi is Map) {
                      final mid = (mi['menu_id'] ?? mi['id'] ?? '').toString();
                      final qty = mi['qty'];
                      if (mid.isNotEmpty && qty is int && qty > 0) {
                        rebuilt[mid] = qty;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return rebuilt;
  }

  static Future<CartUpdateResult> setCartQty({
    required String? userId,
    required String menuId,
    required String geraiId,
    required int qty,
  }) async {
    try {
      final uri = Uri.parse('${getBaseUrl()}/add_or_update_cart_item.php');
      final jwt = await _getJwt();
      if (jwt == null || jwt.isEmpty) return CartUpdateResult(success: false);
      final payload = <String, dynamic>{
        'gerai_id': int.tryParse(geraiId) ?? geraiId,
        'menu_id': int.tryParse(menuId) ?? menuId,
        'qty': qty,
      };
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
          if (userId != null) 'X-User-Id': userId,
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          bool deleted = false;
          int? newQty;
          final data = body['data'];
          if (data is Map) {
            if (data['deleted'] == true) {
              deleted = true;
            } else {
              final item = data['item'];
              if (item is Map && item['qty'] is int) newQty = item['qty'];
            }
          }
          return CartUpdateResult(success: true, deleted: deleted, qty: newQty);
        }
      }
    } catch (_) {}
    return CartUpdateResult(success: false);
  }

  static Future<ToggleFavoriteResult> toggleFavorite({
    required String menuId,
    required String? userId,
  }) async {
    try {
      final uri = Uri.parse('${getBaseUrl()}/favorite.php');
      final jwt = await _getJwt();
      if (jwt == null || jwt.isEmpty)
        return ToggleFavoriteResult(success: false);
      final bodyPayload = <String, dynamic>{
        'menu_id': menuId,
        'action': 'toggle',
      };
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
          if (userId != null) 'X-User-Id': userId,
        },
        body: jsonEncode(bodyPayload),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          return ToggleFavoriteResult(
            success: true,
            favorited: body['favorited'] == true,
          );
        }
      }
    } catch (_) {}
    return ToggleFavoriteResult(success: false);
  }
}
