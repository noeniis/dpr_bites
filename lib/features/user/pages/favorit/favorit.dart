import 'package:flutter/material.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/profile/profile_page.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  // Group favorite menus by restaurantId
  Map<String, List<Map<String, dynamic>>> get groupedFavorites {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final menu in favoriteMenus) {
      final restoId = menu['restaurantId'] ?? '';
      if (!grouped.containsKey(restoId)) grouped[restoId] = [];
      grouped[restoId]!.add(menu);
    }
    return grouped;
  }

  int? _userId; // from SharedPreferences
  final Map<String, int> qtyMap = {};
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _favorites =
      []; // each: {menu_id,name,desc,price,image,restaurant:{id,name,desc,rating,ratingCount}}
  final Map<String, Map<String, dynamic>> _restaurants = {}; // id -> resto data

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('id_users');
    } catch (_) {
      _userId = null;
    }
    await _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() => _loading = true);
    try {
      if (_userId == null) {
        // not logged in: treat as empty favorites (do not show login error)
        _favorites = [];
        _error = null;
        return;
      }
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/get_user_favorites.php?user_id=${_userId}',
      );
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (_userId != null) 'X-User-Id': _userId.toString(),
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final list = (body['data'] as List?) ?? [];
          _favorites = list.whereType<Map>().map((m) {
            final menu = Map<String, dynamic>.from(m);
            final r = menu['restaurant'];
            if (r is Map) {
              final rid = (r['id'] ?? '').toString();
              _restaurants[rid] = {
                'id': rid,
                'name': r['name'] ?? '',
                'desc': r['desc'] ?? '',
                'rating': r['rating'] ?? 0,
                'ratingCount': r['ratingCount'] ?? 0,
                'minPrice': r['minPrice'],
                'maxPrice': r['maxPrice'],
              };
              menu['restaurantId'] = rid;
            }
            menu['id'] = (menu['menu_id'] ?? '').toString();
            return menu;
          }).toList();
          _error = null;
          // Setelah favorit berhasil dimuat, ambil qty keranjang untuk menu favorit
          await _fetchCartQuantities();
        } else {
          _error = body is Map
              ? (body['message']?.toString() ?? 'Gagal memuat')
              : 'Gagal memuat';
        }
      } else {
        _error = 'HTTP ${res.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchCartQuantities() async {
    try {
      if (_userId == null) return;
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/get_user_cart.php?user_id=${_userId}',
      );
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (_userId != null) 'X-User-Id': _userId.toString(),
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final data = body['data'];
          final Map<String, int> rebuilt = {};
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
          if (mounted) {
            setState(() {
              qtyMap
                ..clear()
                ..addAll(rebuilt);
            });
          }
        } else {
          if (mounted)
            setState(() {
              qtyMap.clear();
            });
        }
      } else {
        if (mounted)
          setState(() {
            qtyMap.clear();
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          qtyMap.clear();
        });
    }
  }

  Future<void> _setCartQty(String menuId, String geraiId, int newQty) async {
    final prev = qtyMap[menuId] ?? 0;
    setState(() {
      qtyMap[menuId] = newQty;
    });
    try {
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/add_or_update_cart_item.php',
      );
      final Map<String, dynamic> payload = {
        'gerai_id': int.tryParse(geraiId) ?? geraiId,
        'menu_id': int.tryParse(menuId) ?? menuId,
        'qty': newQty,
      };
      if (_userId != null) payload['user_id'] = _userId!;
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (_userId != null) 'X-User-Id': _userId.toString(),
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final data = body['data'];
          if (data is Map) {
            if (data['deleted'] == true) {
              setState(() {
                qtyMap[menuId] = 0;
              });
            } else {
              // sync qty from response if provided
              final item = data['item'];
              if (item is Map && item['qty'] is int) {
                setState(() {
                  qtyMap[menuId] = item['qty'];
                });
              }
            }
          }
        } else {
          setState(() {
            qtyMap[menuId] = prev;
          });
        }
      } else {
        setState(() {
          qtyMap[menuId] = prev;
        });
      }
    } catch (_) {
      setState(() {
        qtyMap[menuId] = prev;
      });
    }
  }

  List<Map<String, dynamic>> get favoriteMenus => _favorites;
  Map<String, dynamic>? getRestaurant(String restaurantId) =>
      _restaurants[restaurantId];

  Future<void> toggleFavorite(String menuId) async {
    // Optimistic toggle
    final exists = _favorites.any((m) => m['id'] == menuId);
    setState(() {
      if (exists) {
        _favorites.removeWhere((m) => m['id'] == menuId);
      }
    });
    try {
      final uri = Uri.parse('http://10.0.2.2/dpr_bites_api/favorite.php');
      final Map<String, dynamic> bodyPayload = {
        'menu_id': menuId,
        'action': 'toggle',
      };
      if (_userId != null) bodyPayload['user_id'] = _userId!;
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (_userId != null) 'X-User-Id': _userId.toString(),
        },
        body: jsonEncode(bodyPayload),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final fav = body['favorited'] == true;
          if (fav && !exists) {
            // Re-fetch for full data
            await _fetchFavorites();
          } else if (!fav && exists) {
            // already removed optimistic
          } else if (!fav && !exists) {
            // inconsistent, refresh
            await _fetchFavorites();
          }
        } else {
          await _fetchFavorites();
        }
      } else {
        await _fetchFavorites();
      }
    } catch (_) {
      await _fetchFavorites();
    }
  }

  void addQty(String menuId) {
    setState(() => qtyMap[menuId] = (qtyMap[menuId] ?? 0) + 1);
  }

  void removeQty(String menuId) {
    setState(
      () => qtyMap[menuId] = ((qtyMap[menuId] ?? 0) > 0)
          ? (qtyMap[menuId]! - 1)
          : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            "Favorit Anda",
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text(
                  "Keranjang",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                  if (mounted) {
                    await _fetchCartQuantities();
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : favoriteMenus.isEmpty
              ? Center(
                  child: Text(
                    _error != null
                        ? 'Error: ' + _error!
                        : 'Menu Favorite Masih Kosong',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchFavorites();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: [
                      ...groupedFavorites.entries.map((entry) {
                        final restoId = entry.key;
                        final menus = entry.value;
                        final resto = getRestaurant(restoId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            resto?['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          if ((resto?['desc'] ?? '')
                                              .toString()
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(
                                                resto?['desc'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        Text(
                                          (resto?['rating'] ?? 0).toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.monetization_on,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        Text(
                                          _formatPriceRange(
                                            resto?['minPrice'],
                                            resto?['maxPrice'],
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...menus.map((menu) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child:
                                                  (menu['image'] is String &&
                                                      (menu['image'] as String)
                                                          .startsWith('http'))
                                                  ? Image.network(
                                                      menu['image'],
                                                      width: 70,
                                                      height: 70,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => Container(
                                                            width: 70,
                                                            height: 70,
                                                            color:
                                                                Colors.black12,
                                                            child: const Icon(
                                                              Icons.fastfood,
                                                              color: Colors
                                                                  .black45,
                                                            ),
                                                          ),
                                                    )
                                                  : Image.asset(
                                                      (menu['image'] ??
                                                              'assets/placeholder.png')
                                                          .toString(),
                                                      width: 70,
                                                      height: 70,
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                            Positioned(
                                              left: 4,
                                              bottom: 4,
                                              child: GestureDetector(
                                                onTap: () async {
                                                  // Only show confirmation if menu is already favorited (i.e., user wants to remove)
                                                  final isFavorited =
                                                      true; // always true in this list
                                                  if (isFavorited) {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      barrierDismissible: true,
                                                      builder: (ctx) {
                                                        return Dialog(
                                                          backgroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  18,
                                                                ),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      24,
                                                                  vertical: 28,
                                                                ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Container(
                                                                  decoration: BoxDecoration(
                                                                    color: AppTheme
                                                                        .primaryColor
                                                                        .withOpacity(
                                                                          0.08,
                                                                        ),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        14,
                                                                      ),
                                                                  child: const Icon(
                                                                    Icons
                                                                        .favorite_border,
                                                                    color: AppTheme
                                                                        .primaryColor,
                                                                    size: 36,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 18,
                                                                ),
                                                                const Text(
                                                                  'Hapus dari Favorit?',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        17,
                                                                    color: AppTheme
                                                                        .primaryColor,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                const Text(
                                                                  'Menu ini akan dihapus dari daftar favorit Anda.',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                                const SizedBox(
                                                                  height: 22,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceEvenly,
                                                                  children: [
                                                                    Expanded(
                                                                      child: TextButton(
                                                                        style: TextButton.styleFrom(
                                                                          backgroundColor:
                                                                              Colors.grey[100],
                                                                          foregroundColor:
                                                                              AppTheme.primaryColor,
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                              10,
                                                                            ),
                                                                          ),
                                                                          padding: const EdgeInsets.symmetric(
                                                                            vertical:
                                                                                10,
                                                                          ),
                                                                        ),
                                                                        onPressed: () =>
                                                                            Navigator.of(
                                                                              ctx,
                                                                            ).pop(
                                                                              false,
                                                                            ),
                                                                        child: const Text(
                                                                          'Batal',
                                                                          style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 14,
                                                                    ),
                                                                    Expanded(
                                                                      child: TextButton(
                                                                        style: TextButton.styleFrom(
                                                                          backgroundColor:
                                                                              AppTheme.primaryColor,
                                                                          foregroundColor:
                                                                              Colors.white,
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                              10,
                                                                            ),
                                                                          ),
                                                                          padding: const EdgeInsets.symmetric(
                                                                            vertical:
                                                                                10,
                                                                          ),
                                                                        ),
                                                                        onPressed: () =>
                                                                            Navigator.of(
                                                                              ctx,
                                                                            ).pop(
                                                                              true,
                                                                            ),
                                                                        child: const Text(
                                                                          'Hapus',
                                                                          style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                    if (confirm == true) {
                                                      toggleFavorite(
                                                        menu['id'],
                                                      );
                                                    }
                                                  } else {
                                                    toggleFavorite(menu['id']);
                                                  }
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.85),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  child: const Icon(
                                                    Icons.favorite,
                                                    color:
                                                        AppTheme.primaryColor,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                menu['name'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if ((menu['desc'] ?? '')
                                                  .toString()
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2,
                                                      ),
                                                  child: Text(
                                                    menu['desc'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Rp${_formatRupiah(_toInt(menu['price']) ?? 0)}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  _buildQtySection(menu),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFF9D3D3).withOpacity(0.85),
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.black54,
          currentIndex: 2,
          selectedFontSize: 14,
          unselectedFontSize: 13,
          iconSize: 30,
          onTap: (i) {
            if (i == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            } else if (i == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            } else if (i == 2) {
              // already here
            } else if (i == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: "Favorit",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profil",
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPriceRange(dynamic minP, dynamic maxP) {
  final minPrice = _toInt(minP);
  final maxPrice = _toInt(maxP);
  if (minPrice == null || maxPrice == null || (minPrice == 0 && maxPrice == 0))
    return '-';
  if (minPrice == maxPrice) {
    final s = _formatRupiah(minPrice);
    return 'Rp$s - Rp$s';
  }
  return 'Rp${_formatRupiah(minPrice)} - Rp${_formatRupiah(maxPrice)}';
}

Widget _buildQtySection(Map<String, dynamic> menu) {
  final menuId = (menu['id'] ?? menu['menu_id'] ?? '').toString();
  final geraiId = (menu['restaurantId'] ?? menu['restaurant_id'] ?? '')
      .toString();
  return Builder(
    builder: (context) {
      final state = context.findAncestorStateOfType<_FavoritPageState>();
      final currentQty = state?.qtyMap[menuId] ?? 0;
      if (currentQty <= 0) {
        return SizedBox(
          height: 32,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              elevation: 0,
            ),
            onPressed: () {
              if (state != null) {
                state._setCartQty(menuId, geraiId, 1);
              }
            },
            child: const Text('Tambah'),
          ),
        );
      }
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.remove,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                if (state != null) {
                  final next = currentQty - 1;
                  state._setCartQty(menuId, geraiId, next < 0 ? 0 : next);
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                currentQty.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                if (state != null) {
                  state._setCartQty(menuId, geraiId, currentQty + 1);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) {
    return int.tryParse(v);
  }
  return null;
}

String _formatRupiah(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    int idx = s.length - i - 1;
    buf.write(s[idx]);
    if ((i + 1) % 3 == 0 && idx != 0) buf.write('.');
  }
  return buf.toString().split('').reversed.join();
}
