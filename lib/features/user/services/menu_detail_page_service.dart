import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/common/utils/prefs_helper.dart';
import 'package:dpr_bites/features/user/models/menu_detail_page_model.dart';
import 'package:http/http.dart' as http;

class MenuDetailPageService {
  static Future<String?> getUserId() async => Prefs.getUserIdString();

  static Future<MenuDetailFetchResult> fetchMenuDetail(String id) async {
    try {
      final res = await http.get(
        Uri.parse(
          '${getBaseUrl()}/get_menu_detail_user.php?id=${Uri.encodeQueryComponent(id)}',
        ),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode != 200) {
        return MenuDetailFetchResult(error: 'Gagal memuat (${res.statusCode})');
      }
      final body = jsonDecode(res.body);
      if (body is! Map || body['success'] != true) {
        return const MenuDetailFetchResult(error: 'Data tidak valid');
      }
      final data = body['data'];
      if (data is! Map)
        return const MenuDetailFetchResult(error: 'Data tidak valid');
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
      if (userId == null) return const FavoriteStatusResult(favorited: false);
      final res = await http.get(
        Uri.parse(
          '${getBaseUrl()}/favorite.php?user_id=$userId&menu_id=$menuId',
        ),
        headers: {'Accept': 'application/json', 'X-User-Id': userId},
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
      if (userId == null)
        return const FavoriteStatusResult(favorited: false, error: 'No user');
      final payload = jsonEncode({
        'user_id': int.tryParse(userId) ?? userId,
        'menu_id': int.tryParse(menuId) ?? menuId,
        'action': 'toggle',
      });
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/favorite.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-User-Id': userId,
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
