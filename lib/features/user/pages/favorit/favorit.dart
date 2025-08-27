import 'package:flutter/material.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/profile/profile_page.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  final int _userId = 1; // TODO: dynamic auth user
  final Map<String, int> qtyMap = {};
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _favorites =
      []; // each: {menu_id,name,desc,price,image,restaurant:{id,name,desc,rating,ratingCount}}
  final Map<String, Map<String, dynamic>> _restaurants = {}; // id -> resto data

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/get_user_favorites.php?user_id=$_userId',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
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
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/get_user_cart.php?user_id=$_userId',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
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
      final payload = {
        'user_id': _userId,
        'gerai_id': int.tryParse(geraiId) ?? geraiId,
        'menu_id': int.tryParse(menuId) ?? menuId,
        'qty': newQty,
      };
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
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
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': _userId,
          'menu_id': menuId,
          'action': 'toggle',
        }),
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
                  // Setelah kembali dari cart, segarkan qty keranjang favorit
                  if (mounted) {
                    await _fetchCartQuantities();
                    setState(() {}); // paksa rebuild untuk qty terbaru
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
                    _error != null ? 'Error: ' + _error! : 'Belum ada favorit',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchFavorites();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 8,
                    ),
                    itemCount: favoriteMenus.length,
                    itemBuilder: (context, idx) {
                      final menu = favoriteMenus[idx];
                      final resto = getRestaurant(menu['restaurantId']);
                      // final qty = qtyMap[menu['id']] ?? 0; // reserved for future quantity handling
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                fontSize: 17,
                                              ),
                                            ),
                                            Text(
                                              resto?['desc'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 18,
                                              ),
                                              Text(
                                                (resto?['rating'] ?? 0)
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
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
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  height: 1,
                                  color: const Color(0xFFD9D9D9),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              menu['name'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              menu['desc'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${menu['price']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () =>
                                                  toggleFavorite(menu['id']),
                                              child: const Icon(
                                                Icons.favorite,
                                                color: AppTheme.primaryColor,
                                                size: 24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child:
                                                (menu['image'] is String &&
                                                    (menu['image'] as String)
                                                        .startsWith('http'))
                                                ? Image.network(
                                                    menu['image'],
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => Container(
                                                          width: 80,
                                                          height: 80,
                                                          color: Colors.black12,
                                                          child: const Icon(
                                                            Icons.fastfood,
                                                            color:
                                                                Colors.black45,
                                                          ),
                                                        ),
                                                  )
                                                : Image.asset(
                                                    (menu['image'] ??
                                                            'assets/placeholder.png')
                                                        .toString(),
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          const SizedBox(height: 10),
                                          _buildQtySection(menu),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 60,
                                    height: 0.25,
                                    color: const Color(0xFFD9D9D9),
                                    margin: const EdgeInsets.only(right: 16),
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  color: const Color.fromARGB(
                                    255,
                                    199,
                                    199,
                                    199,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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
          width: 89,
          height: 22,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Color(0xFFB03056)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              if (state != null) {
                state._setCartQty(menuId, geraiId, 1);
              }
            },
            child: const Text(
              'Tambah',
              style: TextStyle(
                color: Color(0xFFB03056),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFB03056)),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.85),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (state != null) {
                  final next = currentQty - 1;
                  state._setCartQty(menuId, geraiId, next < 0 ? 0 : next);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Icon(Icons.remove, size: 16, color: Color(0xFFB03056)),
              ),
            ),
            Text(
              currentQty.toString(),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            GestureDetector(
              onTap: () {
                if (state != null) {
                  state._setCartQty(menuId, geraiId, currentQty + 1);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Icon(Icons.add, size: 16, color: Color(0xFFB03056)),
              ),
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
