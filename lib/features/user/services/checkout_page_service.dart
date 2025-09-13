import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/checkout_page_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CheckoutPageService {
  static const _storage = FlutterSecureStorage();
  static Future<String?> _getJwt() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (_) {
      return null;
    }
  }

  static Future<CheckoutFetchResult> fetchCheckoutData({
    required int geraiId,
    List<int> selectedCartItemIds = const [],
  }) async {
    final base = getBaseUrl();
    final jwt = await _getJwt();
    final ids = selectedCartItemIds.isNotEmpty
        ? '&selectedCartItemIds=${selectedCartItemIds.join(',')}'
        : '';
    final uri = Uri.parse('$base/get_checkout_data.php?gerai_id=$geraiId$ids');
    debugPrint('[CheckoutService] GET $uri');
    final headers = <String, String>{'Accept': 'application/json'};
    if (jwt != null && jwt.isNotEmpty) headers['Authorization'] = 'Bearer $jwt';
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      debugPrint(
        '[CheckoutService] checkout resp ${resp.statusCode}: ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)}',
      );
      return CheckoutFetchResult(
        success: false,
        restaurantName: '',
        deliveryFee: 0,
        items: const [],
      );
    }
    dynamic data;
    try {
      var raw = resp.body.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
      data = jsonDecode(raw);
    } catch (e) {
      debugPrint('[CheckoutService] JSON parse error: $e');
      return CheckoutFetchResult(
        success: false,
        restaurantName: '',
        deliveryFee: 0,
        items: const [],
      );
    }
    if (data is! Map || data['success'] != true) {
      debugPrint(
        '[CheckoutService] checkout success false or invalid shape: $data',
      );
      return CheckoutFetchResult(
        success: false,
        restaurantName: '',
        deliveryFee: 0,
        items: const [],
      );
    }
    final d = data['data'] as Map? ?? {};
    final restaurantName = (d['restaurantName'] ?? '').toString();
    final deliveryFee = (d['deliveryFee'] is num)
        ? (d['deliveryFee'] as num).toInt()
        : 0;
    final qrisPath = (d['qrisPath']?.toString().isNotEmpty ?? false)
        ? d['qrisPath'].toString()
        : null;
    double? lat;
    double? lng;
    if (d['latitude'] != null && d['longitude'] != null) {
      lat = double.tryParse(d['latitude'].toString());
      lng = double.tryParse(d['longitude'].toString());
    }
    final allItems = ((d['items'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    Map<String, dynamic>? address;
    int? addressId;
    final addr = d['address'];
    if (addr is Map) {
      address = Map<String, dynamic>.from(addr);
      final rawId = addr['id_alamat'] ?? addr['id'] ?? addr['address_id'];
      if (rawId != null) addressId = int.tryParse(rawId.toString());
    }

    // If we have an explicit selection from cart, filter and normalize id_keranjang_item
    bool noSelectionMatch = false;
    final missingSelected = <int>[];
    List<Map<String, dynamic>> items = allItems;
    if (selectedCartItemIds.isNotEmpty) {
      const possibleIdKeys = [
        'id_keranjang_item',
        'cart_item_id',
        'keranjang_item_id',
        'id_item',
        'cartItemId',
        'cartItemID',
        'cartItem_id',
      ];
      final found = <int>{};
      items = allItems.where((m) {
        for (final k in possibleIdKeys) {
          if (m[k] != null) {
            final id = int.tryParse(m[k].toString());
            if (id != null) {
              if (selectedCartItemIds.contains(id)) {
                m['id_keranjang_item'] = id; // normalize
                found.add(id);
                return true;
              }
            }
          }
        }
        return false;
      }).toList();
      if (items.isEmpty) {
        noSelectionMatch = true;
      } else {
        for (final id in selectedCartItemIds) {
          if (!found.contains(id)) missingSelected.add(id);
        }
      }
    }

    return CheckoutFetchResult(
      success: true,
      restaurantName: restaurantName,
      deliveryFee: deliveryFee,
      qrisPath: qrisPath,
      latitude: lat,
      longitude: lng,
      items: items,
      address: address,
      selectedAddressId: addressId,
      noSelectionMatch: noSelectionMatch,
      missingSelectedIds: missingSelected,
    );
  }

  static Future<void> prefetchSelectedItemsDetail({
    required List<Map<String, dynamic>> items,
  }) async {
    // populate desc and addonOptions when missing
    final base = getBaseUrl();
    final futures = <Future>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      final hasAddons =
          (it['addonOptions'] is List) &&
          (it['addonOptions'] as List).isNotEmpty;
      final hasDesc =
          (it['desc']?.toString().isNotEmpty ?? false) ||
          (it['description']?.toString().isNotEmpty ?? false);
      if (hasAddons && hasDesc) continue;
      final menuId = it['menu_id'] ?? it['id_menu'] ?? it['id'];
      if (menuId == null) continue;
      final mid = int.tryParse(menuId.toString());
      if (mid == null) continue;
      futures.add(
        _fetchSingleMenuDetail(base, mid).then((data) {
          if (data == null) return;
          // mutate in-place just like old UI
          if (!(it['desc']?.toString().isNotEmpty ?? false)) {
            it['desc'] = data['description'] ?? data['desc'] ?? it['desc'];
          }
          if (!(it['addonOptions'] is List) ||
              (it['addonOptions'] as List).isEmpty) {
            final opts = data['addons'] ?? data['addonOptions'];
            if (opts is List) it['addonOptions'] = opts;
          }
        }),
      );
    }
    if (futures.isNotEmpty) {
      try {
        await Future.wait(futures);
      } catch (_) {}
    }
  }

  static Future<Map<String, dynamic>?> _fetchSingleMenuDetail(
    String baseUrl,
    int menuId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/get_menu_detail_user.php?id=$menuId');
      final jwt = await _getJwt();
      final headers = <String, String>{'Accept': 'application/json'};
      if (jwt != null && jwt.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwt';
      }
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode != 200) return null;
      final raw = resp.body.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
      final data = jsonDecode(raw);
      if (data is Map && data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data']);
      }
    } catch (_) {}
    return null;
  }

  static Future<UpdateCartItemResult> syncItemQtyToServer({
    required Map<String, dynamic> item,
    required int geraiId,
    String? note,
  }) async {
    // Build addonIds from labels if needed
    List<int> addonIds = [];
    if (item['addonIds'] is List) {
      addonIds = (item['addonIds'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
    } else {
      final labels =
          (item['addon'] as List?)?.map((e) => e.toString()).toList() ??
          const [];
      if (labels.isNotEmpty) {
        final opts = (item['addonOptions'] as List?) ?? const [];
        for (final lab in labels) {
          try {
            final opt = opts.firstWhere(
              (o) => (o is Map) && (o['label']?.toString() == lab),
              orElse: () => const {},
            );
            if (opt is Map && opt['id'] != null) {
              final pid = int.tryParse(opt['id'].toString());
              if (pid != null && pid > 0) addonIds.add(pid);
            }
          } catch (_) {}
        }
      }
    }

    final payload = <String, dynamic>{
      'gerai_id': geraiId,
      'menu_id':
          int.tryParse(
            (item['menu_id'] ?? item['menuId'] ?? item['id_menu'] ?? item['id'])
                .toString(),
          ) ??
          0,
      'qty': item['qty'] ?? 1,
      'addons': addonIds,
    };
    if (note != null) {
      payload['note'] = note;
    }
    final cartItemId = item['id_keranjang_item'] ?? item['cartItemId'];
    if (cartItemId != null) {
      final cid = int.tryParse(cartItemId.toString());
      if (cid != null && cid > 0) payload['item_id'] = cid;
    }
    final base = getBaseUrl();
    final jwt = await _getJwt();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (jwt != null && jwt.isNotEmpty) headers['Authorization'] = 'Bearer $jwt';
    final resp = await http.post(
      Uri.parse('$base/add_or_update_cart_item.php'),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (resp.statusCode == 200) {
      try {
        final json = jsonDecode(resp.body);
        if (json is Map && json['success'] == true) {
          final data = json['data'];
          if (data is Map && data['item'] is Map) {
            return UpdateCartItemResult(
              updatedItem: Map<String, dynamic>.from(data['item']),
            );
          }
        }
      } catch (_) {}
    }
    return UpdateCartItemResult(updatedItem: null);
  }

  static Future<bool> deleteItem({
    required Map<String, dynamic> item,
    required int geraiId,
  }) async {
    final menuId =
        item['menu_id'] ?? item['menuId'] ?? item['id_menu'] ?? item['id'];
    if (menuId == null) return false;
    final payload = {
      'gerai_id': geraiId,
      'menu_id': int.tryParse(menuId.toString()) ?? menuId,
      'qty': 0,
    };
    final cartItemId = item['id_keranjang_item'] ?? item['cartItemId'];
    if (cartItemId != null) {
      final cid = int.tryParse(cartItemId.toString());
      if (cid != null && cid > 0) payload['item_id'] = cid;
    }
    final base = getBaseUrl();
    try {
      final jwt = await _getJwt();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (jwt != null && jwt.isNotEmpty)
        headers['Authorization'] = 'Bearer $jwt';
      final res = await http.post(
        Uri.parse('$base/add_or_update_cart_item.php'),
        headers: headers,
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json is Map && json['success'] == true) return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<MenuDetailUserResult> fetchMenuDetailUser({
    required int menuId,
  }) async {
    final base = getBaseUrl();
    try {
      final uri = Uri.parse('$base/get_menu_detail_user.php?id=$menuId');
      final jwt = await _getJwt();
      final headers = <String, String>{'Accept': 'application/json'};
      if (jwt != null && jwt.isNotEmpty)
        headers['Authorization'] = 'Bearer $jwt';
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is Map && body['success'] == true) {
          final data = body['data'];
          if (data is Map && data['addonOptions'] is List) {
            // Normalize addon options fields to expected keys
            final listRaw = (data['addonOptions'] as List).whereType<Map>();
            final full = <Map<String, dynamic>>[];
            for (final m in listRaw) {
              final idVal = m['id'] ?? m['id_addon'];
              final labelVal = m['label'] ?? m['nama_addon'] ?? '';
              final priceVal = (m['price'] is num)
                  ? (m['price'] as num).toInt()
                  : int.tryParse(m['price']?.toString() ?? '0') ?? 0;
              full.add({
                'id': idVal,
                'label': labelVal,
                'price': priceVal,
                'image': m['image'] ?? m['image_path'] ?? '',
              });
            }
            return MenuDetailUserResult(addonOptions: full);
          }
        }
      }
    } catch (_) {}
    return MenuDetailUserResult(addonOptions: const []);
  }

  static Future<CreateTransactionResult> createTransaction({
    required Map<String, dynamic> payload,
  }) async {
    final base = getBaseUrl();
    try {
      final jwt = await _getJwt();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (jwt != null && jwt.isNotEmpty)
        headers['Authorization'] = 'Bearer $jwt';
      final sanitized = Map<String, dynamic>.from(payload);
      // Server trusts JWT; drop any id_users sent by caller
      sanitized.remove('id_users');
      final resp = await http.post(
        Uri.parse('$base/create_transaction.php'),
        headers: headers,
        body: jsonEncode(sanitized),
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body is Map) {
          if (body['success'] == true) {
            return CreateTransactionResult(
              success: true,
              bookingId: body['data']?['booking_id']?.toString(),
            );
          }
          return CreateTransactionResult(
            success: false,
            bookingId: null,
            message: body['message']?.toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('[CheckoutService] createTransaction error: $e');
    }
    return CreateTransactionResult(success: false);
  }
}
