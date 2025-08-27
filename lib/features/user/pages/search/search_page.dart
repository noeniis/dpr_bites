import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dpr_bites/features/user/pages/restaurant_detail/restaurant_detail_page.dart';
import 'package:dpr_bites/features/user/pages/restaurant_detail/menu_detail_page.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({this.initialQuery, super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Menyimpan query terakhir secara statis (persist di memori aplikasi selama proses hidup)
  static String? _lastQuery;
  final TextEditingController searchController = TextEditingController();
  String? searchQuery;

  // Hasil dari API
  List<Map<String, dynamic>> _results = [];
  final int _userId = 1; // TODO: dynamic auth user
  final Map<String, bool> _menuHasAddonCache = {}; // menuId -> hasAddon
  bool _adding = false; // optional simple busy flag

  @override
  void initState() {
    super.initState();
    final init = widget.initialQuery ?? _lastQuery;
    if (init != null && init.isNotEmpty) {
      searchController.text = init;
      searchQuery = init;
      WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch(init));
    }
  }

  void doSearch(String q) {
    final trimmed = q.trim();
    setState(() => searchQuery = trimmed);
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
      });
      _lastQuery = null;
      return;
    }
    _lastQuery = trimmed; // simpan query terakhir
    _performSearch(trimmed);
  }

  Future<void> _performSearch(String q) async {
    try {
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/search_restaurants.php?q=${Uri.encodeQueryComponent(q)}',
      );
      debugPrint('[SEARCH] Request: ' + uri.toString());
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      debugPrint('[SEARCH] Status: ' + res.statusCode.toString());
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        debugPrint('[SEARCH] Body: ' + body.toString());
        if (body is Map && body['success'] == true) {
          final List data = body['data'] as List? ?? [];
          _results = data
              .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map),
              )
              .toList();
        } else {
          debugPrint('[SEARCH] success flag false / format mismatch');
          // ignore error silently
        }
      } else {
        debugPrint('[SEARCH] Non-200 response body: ' + res.body);
        // ignore error silently
      }
    } catch (e) {
      debugPrint('[SEARCH] Exception: ' + e.toString());
      // ignore error silently
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<Map<String, dynamic>?> _fetchMenuDetail(String id) async {
    try {
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/get_menu_detail_user.php?id=' +
            Uri.encodeQueryComponent(id),
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

  Future<void> _addOrUpdateCart({
    required String geraiId,
    required String menuId,
    required int qty,
  }) async {
    final uri = Uri.parse(
      'http://10.0.2.2/dpr_bites_api/add_or_update_cart_item.php',
    );
    final bodyMap = {
      'user_id': _userId,
      'gerai_id': int.tryParse(geraiId) ?? geraiId,
      'menu_id': int.tryParse(menuId) ?? menuId,
      'qty': qty,
    };
    try {
      debugPrint('[CART][SEARCH] POST $bodyMap');
      final res = await http.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyMap),
      );
      debugPrint('[CART][SEARCH] Status ${res.statusCode}');
      if (res.statusCode == 200) {
        Map? json;
        try {
          json = jsonDecode(res.body);
        } catch (_) {}
        debugPrint('[CART][SEARCH] Body ${res.body}');
        if (json is Map && json['success'] == true) {
          return; // success
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menambah keranjang (format response)'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambah keranjang: ${res.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[CART][SEARCH] Exception $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kesalahan jaringan menambah keranjang'),
          ),
        );
      }
    }
  }

  Future<void> _handleAddPressed(
    Map<String, dynamic> resto,
    Map<String, dynamic> menu,
  ) async {
    if (_adding) return; // throttle
    _adding = true;
    try {
      final restoId = resto['id'].toString();
      final menuId = (menu['id'] ?? menu['menu_id']).toString();
      bool? hasAddon = _menuHasAddonCache[menuId];
      if (hasAddon == null) {
        final detail = await _fetchMenuDetail(menuId);
        final addons = (detail?['addonOptions'] as List?) ?? [];
        hasAddon = addons.isNotEmpty;
        _menuHasAddonCache[menuId] = hasAddon;
        if (hasAddon) {
          await _openMenuDetail(menu, geraiId: restoId);
          return; // handled in detail
        }
      }
      if (hasAddon) {
        await _openMenuDetail(menu, geraiId: restoId);
      } else {
        await _addOrUpdateCart(geraiId: restoId, menuId: menuId, qty: 1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ditambahkan ke keranjang')),
          );
        }
      }
    } finally {
      _adding = false;
    }
  }

  Future<void> _openMenuDetail(
    Map<String, dynamic> menu, {
    required String geraiId,
  }) async {
    if (geraiId.isEmpty) {
      debugPrint('[CART][DETAIL][SEARCH] geraiId kosong');
      return;
    }
    final normalized = {
      'id': menu['id'] ?? menu['menu_id'],
      'name': menu['name'] ?? menu['nama_menu'],
      'desc': menu['desc'] ?? menu['deskripsi_menu'],
      'price': menu['price'] ?? menu['harga'] ?? 0,
      'image': menu['image'] ?? menu['gambar_menu'],
    };
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MenuDetailPage(menu: normalized, initialQty: 1),
    );
    if (result != null) {
      final qty = (result['qty'] as int?) ?? 0;
      if (qty > 0) {
        final addonIds = (result['addonIds'] as List?)?.cast<int>() ?? [];
        final note = result['note']?.toString();
        // Kirim ke backend termasuk addons & note jika ada
        final uri = Uri.parse(
          'http://10.0.2.2/dpr_bites_api/add_or_update_cart_item.php',
        );
        final payload = <String, dynamic>{
          'user_id': _userId,
          'gerai_id': geraiId,
          'menu_id': normalized['id'],
          'qty': qty,
        };
        if (addonIds.isNotEmpty) payload['addons'] = addonIds;
        if (note != null) payload['note'] = note;
        try {
          debugPrint('[CART][DETAIL][SEARCH] POST $payload');
          final res = await http.post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          );
          debugPrint(
            '[CART][DETAIL][SEARCH] Status ${res.statusCode} Body ${res.body}',
          );
          if (mounted) {
            if (res.statusCode == 200) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ditambahkan ke keranjang')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal menambah (${res.statusCode})')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kesalahan jaringan saat menambah')),
            );
          }
        }
      }
    }
  }

  void _openRestaurant(dynamic restoId) {
    if (restoId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailPage(restaurantId: restoId.toString()),
      ),
    );
  }

  String _formatRupiah(dynamic v) {
    if (v == null) return '';
    int? angka;
    if (v is int)
      angka = v;
    else if (v is double)
      angka = v.round();
    else {
      angka = int.tryParse(v.toString());
    }
    if (angka == null) return '';
    final s = angka.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write('.');
        count = 0;
      }
    }
    return buf.toString().split('').reversed.join();
  }

  // List resto yg match query
  List<Map<String, dynamic>> get filteredRestaurants {
    if (searchQuery == null || searchQuery!.isEmpty) return [];
    return _results; // server sudah filter
  }

  // Ambil menu yg cocok di suatu resto
  List<Map<String, dynamic>> menusForResto(dynamic restoId) {
    if (searchQuery == null || searchQuery!.isEmpty) return [];
    final idStr = restoId.toString();
    final resto = _results.firstWhere(
      (r) => r['id'].toString() == idStr,
      orElse: () => {},
    );
    final menus = resto['menus'];
    if (menus is List) {
      return menus.map<Map<String, dynamic>>((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // Normalisasi field image (API pakai key image atau gambar_menu -> sudah image di API)
        if (!map.containsKey('image') && map['gambar_menu'] != null) {
          map['image'] = map['gambar_menu'];
        }
        return map;
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF602829)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Pencarian',
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 12),
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  "Keranjang",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD53D3D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                onPressed: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                  // Jika CartPage memberi sinyal ada perubahan (misal return true), bisa refresh search bila perlu
                  if (changed == true &&
                      mounted &&
                      searchQuery != null &&
                      searchQuery!.isNotEmpty) {
                    _performSearch(searchQuery!);
                  }
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomInputField(
                  hintText: "Cari menu atau resto...",
                  controller: searchController,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFD53D3D),
                  ),
                  onSubmitted: doSearch,
                ),
                const SizedBox(height: 14),

                (searchQuery != null && searchQuery!.isNotEmpty)
                    ? Expanded(
                        child: filteredRestaurants.isEmpty
                            ? Center(
                                child: Text(
                                  'Tidak ditemukan hasil untuk "$searchQuery"',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredRestaurants.length,
                                itemBuilder: (context, idx) {
                                  final resto = filteredRestaurants[idx];
                                  final ratingStr = (resto['rating'] ?? '0')
                                      .toString();
                                  final ratingCountStr =
                                      (resto['ratingCount'] ?? '0').toString();
                                  final minPrice = resto['minPrice'];
                                  final maxPrice = resto['maxPrice'];
                                  final menus = menusForResto(resto['id']);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () =>
                                            _openRestaurant(resto['id']),
                                        child: CustomEmptyCard(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child:
                                                      (resto['profilePic']
                                                              is String &&
                                                          (resto['profilePic']
                                                                  as String)
                                                              .startsWith(
                                                                'http',
                                                              ))
                                                      ? Image.network(
                                                          resto['profilePic'],
                                                          width: 65,
                                                          height: 65,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) => Container(
                                                                width: 65,
                                                                height: 65,
                                                                color: Colors
                                                                    .black12,
                                                                child: const Icon(
                                                                  Icons.store,
                                                                  color: Colors
                                                                      .black38,
                                                                  size: 30,
                                                                ),
                                                              ),
                                                        )
                                                      : Image.asset(
                                                          resto['profilePic'] ??
                                                              'assets/placeholder.png',
                                                          width: 65,
                                                          height: 65,
                                                          fit: BoxFit.cover,
                                                        ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        (resto['name'] ?? '')
                                                            .toString(),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.star,
                                                            color: Colors.amber,
                                                            size: 16,
                                                          ),
                                                          Text(
                                                            " $ratingStr ($ratingCountStr)",
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          const Icon(
                                                            Icons
                                                                .monetization_on,
                                                            color: Colors.grey,
                                                            size: 14,
                                                          ),
                                                          (minPrice != null &&
                                                                  maxPrice !=
                                                                      null)
                                                              ? Text(
                                                                  " Rp${_formatRupiah(minPrice)} - Rp${_formatRupiah(maxPrice)}",
                                                                  style:
                                                                      const TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                )
                                                              : const SizedBox.shrink(),
                                                        ],
                                                      ),
                                                      Text(
                                                        (resto['desc'] ?? '')
                                                            .toString(),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      menus.isNotEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: SizedBox(
                                                height: 180,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: menus.length,
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(width: 12),
                                                  itemBuilder: (context, i) =>
                                                      _MenuGridCard(
                                                        menu: menus[i],
                                                        onTap: () =>
                                                            _openMenuDetail(
                                                              menus[i],
                                                              geraiId: resto['id']
                                                                  .toString(),
                                                            ),
                                                        onAdd: () =>
                                                            _handleAddPressed(
                                                              resto,
                                                              menus[i],
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ],
                                  );
                                },
                              ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuGridCard extends StatelessWidget {
  final Map<String, dynamic> menu;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const _MenuGridCard({
    required this.menu,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: CustomEmptyCard(
        width: 140,
        height: 145,
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child:
                  (menu['image'] is String &&
                      (menu['image'] as String).startsWith('http'))
                  ? Image.network(
                      menu['image'],
                      height: 68,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 68,
                        width: double.infinity,
                        color: Colors.black12,
                        child: const Icon(
                          Icons.fastfood,
                          color: Colors.black38,
                        ),
                      ),
                    )
                  : Image.asset(
                      menu['image'] ?? 'assets/placeholder.png',
                      height: 68,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (menu['name'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${menu['price']}",
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(99),
                          onTap: onAdd,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Color(0xFFD53D3D),
                                width: 1.6,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: Color(0xFFD53D3D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
