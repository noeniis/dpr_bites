import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/features/user/models/menu_detail_page_model.dart';
import 'package:http/http.dart' as http;

class MenuDetailPageService {
  static final _storage = const FlutterSecureStorage();
  static Future<String?> getUserId() async {
    try {
      return await _storage.read(key: 'id_users');
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getJwt() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (_) {
      return null;
    }
  }

  static Future<MenuDetailFetchResult> fetchMenuDetail(String id) async {
    try {
      final jwt = await _getJwt();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
      };
      final res = await http.get(
        Uri.parse(
          '${getBaseUrl()}/get_menu_detail_user.php?id=${Uri.encodeQueryComponent(id)}',
        ),
        headers: headers,
      );
      if (res.statusCode != 200) {
        return MenuDetailFetchResult(error: 'Gagal memuat (${res.statusCode})');
      }
      final body = jsonDecode(res.body);
      if (body is! Map || body['success'] != true) {
        return const MenuDetailFetchResult(error: 'Data tidak valid');
      }
      final data = body['data'];
      if (data is! Map) {
        return const MenuDetailFetchResult(error: 'Data tidak valid');
      }
      final menu = Map<String, dynamic>.from(data);
      final normalized = <String, dynamic>{
        'id': menu['id'],
        'name': menu['name'] ?? menu['nama_menu'],
        'desc': menu['desc'] ?? menu['deskripsi_menu'] ?? '',
        'price': menu['price'] ?? menu['harga'] ?? 0,
        'image': menu['image'] ?? menu['gambar_menu'],
        'addonOptions':
            (menu['addonOptions'] as List?)?.map((a) {
              final am = Map<String, dynamic>.from(a as Map);
              return {
                'id': am['id'] ?? am['id_addon'],
                'label': am['label'] ?? am['nama_addon'] ?? '',
                'price': am['price'] ?? am['harga'] ?? 0,
                'image': am['image'] ?? am['image_path'],
              };
            }).toList() ??
            [],
      };
      return MenuDetailFetchResult(menu: normalized);
    } catch (e) {
      return MenuDetailFetchResult(error: 'Error: $e');
    }
  }

  static Future<FavoriteStatusResult> getFavoriteStatus(String menuId) async {
    try {
      final userId = await getUserId();
      final jwt = await _getJwt();
      if (jwt == null || jwt.isEmpty) {
        return const FavoriteStatusResult(favorited: false);
      }
      final res = await http.get(
        Uri.parse('${getBaseUrl()}/favorite.php?menu_id=$menuId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          if (userId != null) 'X-User-Id': userId,
        },
      );
      if (res.statusCode != 200) {
        return FavoriteStatusResult(
          favorited: false,
          error: 'HTTP ${res.statusCode}',
        );
      }
      final body = jsonDecode(res.body);
      if (body is Map && body['success'] == true) {
        return FavoriteStatusResult(favorited: body['favorited'] == true);
      }
      return const FavoriteStatusResult(favorited: false);
    } catch (e) {
      return FavoriteStatusResult(favorited: false, error: e.toString());
    }
  }

  static Future<FavoriteStatusResult> toggleFavorite(String menuId) async {
    try {
      final userId = await getUserId();
      final jwt = await _getJwt();
      if (jwt == null || jwt.isEmpty) {
        return const FavoriteStatusResult(favorited: false, error: 'No token');
      }
      final payload = jsonEncode({
        'menu_id': int.tryParse(menuId) ?? menuId,
        'action': 'toggle',
      });
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/favorite.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
          if (userId != null) 'X-User-Id': userId,
        },
        body: payload,
      );
      if (res.statusCode != 200) {
        return FavoriteStatusResult(
          favorited: false,
          error: 'HTTP ${res.statusCode}',
        );
      }
      final body = jsonDecode(res.body);
      if (body is Map && body['success'] == true) {
        return FavoriteStatusResult(favorited: body['favorited'] == true);
      }
      return const FavoriteStatusResult(favorited: false);
    } catch (e) {
      return FavoriteStatusResult(favorited: false, error: e.toString());
    }
  }
}
