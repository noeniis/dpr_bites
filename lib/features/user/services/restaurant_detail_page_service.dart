import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/restaurant_detail_page_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RestaurantDetailPageService {
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

  static Future<RestaurantDetailFetchResult> fetchDetail(
    String restaurantId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          '${getBaseUrl()}/get_restaurant_detail.php?id=${Uri.encodeQueryComponent(restaurantId)}',
        ),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode != 200) {
        return RestaurantDetailFetchResult(
          error: 'Gagal memuat (${res.statusCode})',
        );
      }
      final body = jsonDecode(res.body);
      if (body is! Map || body['success'] != true) {
        return const RestaurantDetailFetchResult(error: 'Data tidak valid');
      }
      final data = body['data'];
      if (data is! Map) {
        return const RestaurantDetailFetchResult(error: 'Data tidak valid');
      }
      final resto = Map<String, dynamic>.from(data);

      // Normalize etalase
      final rawEtalase = (resto['etalase'] as List?) ?? [];
      final etalaseList = rawEtalase.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'label': m['label'] ?? m['nama_etalase'] ?? '',
          'image': m['image'],
        };
      }).toList();
      resto['etalase'] = etalaseList;

      // Normalize menus
      final rawMenus = (resto['menus'] as List?) ?? [];
      List<Map<String, dynamic>> menus = rawMenus.map<Map<String, dynamic>>((
        e,
      ) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'id': m['id'],
          'name': m['name'] ?? m['nama_menu'],
          'price': m['price'] ?? m['harga'],
          'image': m['image'] ?? m['gambar_menu'],
          'desc': m['desc'] ?? m['deskripsi_menu'],
          'kategori': m['etalase_label'] ?? m['kategori'],
          'recommended': m['recommended'] == true,
          'orderCount': m['orderCount'] ?? 0,
          'addonOptions': m['addonOptions'] ?? [],
          'jumlah_stok': m['jumlah_stok'] ?? m['stock'] ?? m['stok'] ?? 0,
        };
      }).toList();

      // Recommended logic based on orderCount
      if (menus.any((m) => (m['orderCount'] as int) > 0)) {
        menus.sort(
          (a, b) => (b['orderCount'] as int).compareTo(a['orderCount'] as int),
        );
        int taken = 0;
        for (final m in menus) {
          if ((m['orderCount'] as int) > 0 && taken < 2) {
            m['recommended'] = true;
            taken++;
          } else {
            m['recommended'] = false;
          }
        }
      } else {
        for (final m in menus) {
          m['recommended'] = false;
        }
      }

      return RestaurantDetailFetchResult(resto: resto, menus: menus);
    } catch (e) {
      return RestaurantDetailFetchResult(error: 'Error: $e');
    }
  }

  static Future<CartSnapshot?> fetchCartSnapshot({
    required String restaurantId,
  }) async {
    try {
      final userId = await getUserId();
      final jwt = await _getJwt();
      if (userId == null || jwt == null || jwt.isEmpty) return null;
      final uri = Uri.parse(
        '${getBaseUrl()}/get_cart.php?gerai_id=$restaurantId',
      );
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
          'X-User-Id': userId, // optional legacy fallback
        },
      );
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map || body['success'] != true) return null;
      final data = body['data'];
      if (data is! Map) return null;
      final items = (data['items'] as List?) ?? [];
      final selected = <String, int>{};
      final addons = <String, List<int>>{};
      final notes = <String, String>{};
      final variantCount = <String, int>{};
      int total = 0;
      for (final it in items) {
        if (it is! Map) continue;
        final menuId = (it['menu_id'] ?? '').toString();
        variantCount[menuId] = (variantCount[menuId] ?? 0) + 1;
        final qty = int.tryParse(it['qty'].toString()) ?? 0;
        if (qty > 0) selected[menuId] = qty;
        final addonList =
            (it['addons'] as List?)
                ?.map((e) => int.tryParse(e.toString()) ?? 0)
                .where((e) => e > 0)
                .toList() ??
            [];
        if (addonList.isNotEmpty) addons[menuId] = addonList;
        final noteVal = it['note'];
        if (noteVal is String && noteVal.trim().isNotEmpty) {
          notes[menuId] = noteVal;
        }
        final subtotalVal = it['subtotal'];
        int? subtotal = int.tryParse((subtotalVal ?? '').toString());
        if (subtotal == null || subtotal == 0) {
          final hs = int.tryParse((it['harga_satuan'] ?? '').toString()) ?? 0;
          subtotal = hs * qty;
        }
        total += subtotal;
      }
      final multi = <String>{};
      variantCount.forEach((k, v) {
        if (v > 1) multi.add(k);
      });
      return CartSnapshot(
        selectedMenus: selected,
        selectedAddons: addons,
        selectedNotes: notes,
        multiVariantMenus: multi,
        totalPrice: total,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> addOrUpdateCart({
    required String restaurantId,
    required String menuId,
    required int qty,
    List<int> addonIds = const [],
    String? note,
    bool noteProvided = false,
  }) async {
    try {
      final userId = await getUserId();
      final jwt = await _getJwt();
      if (jwt == null || jwt.isEmpty) return;
      final uri = Uri.parse('${getBaseUrl()}/add_or_update_cart_item.php');
      final mapPayload = <String, dynamic>{
        'gerai_id': restaurantId,
        'menu_id': int.tryParse(menuId) ?? menuId,
        'qty': qty,
      };
      if (addonIds.isNotEmpty) mapPayload['addons'] = addonIds;
      if (noteProvided) mapPayload['note'] = note ?? '';
      await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
          if (userId != null) 'X-User-Id': userId,
        },
        body: jsonEncode(mapPayload),
      );
    } catch (_) {
      /* optimistic UI */
    }
  }

  static Future<Map<String, dynamic>?> fetchMenuDetail(String menuId) async {
    try {
      final res = await http.get(
        Uri.parse(
          '${getBaseUrl()}/get_menu_detail_user.php?id=${Uri.encodeQueryComponent(menuId)}',
        ),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          return Map<String, dynamic>.from(body['data'] ?? {});
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchEtalaseList(
    String restaurantId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          '${getBaseUrl()}/get_restaurant_etalase.php?id=${Uri.encodeQueryComponent(restaurantId)}',
        ),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          return (body['data'] as List?)
                  ?.map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e as Map),
                  )
                  .toList() ??
              const [];
        }
      }
    } catch (_) {}
    return const [];
  }
}
