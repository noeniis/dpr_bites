import 'package:flutter/material.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/profile/profile_page.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import 'package:dpr_bites/features/user/services/favorit_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  final _storage = const FlutterSecureStorage();
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

  String? _userId; // from SharedPreferences
  final Map<String, int> qtyMap = {};
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _favorites =
      []; // each: {menu_id,name,desc,price,image,restaurant:{id,name,desc,rating,ratingCount}}
  final Map<String, Map<String, dynamic>> _restaurants = {}; // id -> resto data

  @override
  void initState() {
    super.initState();
    // Remember this page for simple restore on restart
    _storage.write(key: 'last_route', value: '/favorit');
    _init();
  }

  Future<void> _init() async {
    _userId = await FavoritService.getUserIdFromPrefs();
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
      final result = await FavoritService.fetchFavorites(_userId!);
      _favorites = result.favorites;
      _restaurants
        ..clear()
        ..addAll(result.restaurants);
      _error = result.error;
      // Setelah favorit berhasil dimuat, ambil qty keranjang untuk menu favorit
      await _fetchCartQuantities();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchCartQuantities() async {
    try {
      if (_userId == null) return;
      final rebuilt = await FavoritService.fetchCartQuantities(_userId!);
      if (mounted) {
        setState(() {
          qtyMap
            ..clear()
            ..addAll(rebuilt);
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
      final result = await FavoritService.setCartQty(
        userId: _userId,
        menuId: menuId,
        geraiId: geraiId,
        qty: newQty,
      );
      if (!result.success) {
        setState(() => qtyMap[menuId] = prev);
        return;
      }
      if (result.deleted) {
        setState(() => qtyMap[menuId] = 0);
      } else if (result.qty != null) {
        setState(() => qtyMap[menuId] = result.qty!);
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
      final resp = await FavoritService.toggleFavorite(
        menuId: menuId,
        userId: _userId,
      );
      if (resp.success) {
        final fav = resp.favorited == true;
        if (fav && !exists) {
          await _fetchFavorites();
        } else if (!fav && exists) {
          // already removed
        } else if (!fav && !exists) {
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
              padding: const EdgeInsets.only(right: 14, top: 4),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                  if (mounted) {
                    await _fetchCartQuantities();
                    setState(() {});
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
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
                      horizontal: 14,
                      vertical: 10,
                    ),
                    children: [
                      ...groupedFavorites.entries.map((entry) {
                        final restoId = entry.key;
                        final menus = entry.value;
                        final resto = getRestaurant(restoId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                              horizontal: 14,
                              vertical: 14,
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
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 18,
                                                ),
                                                Text(
                                                  _formatRating1Decimal(
                                                    resto?['rating'],
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
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
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...menus.map((menu) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
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
                                        const SizedBox(width: 10),
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
        bottomNavigationBar: _MinimalBottomNavFavorit(currentIndex: 2),
      ),
    );
  }
}

class _MinimalBottomNavFavorit extends StatelessWidget {
  final int currentIndex;
  const _MinimalBottomNavFavorit({required this.currentIndex});

  Color get _primary => AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    Widget buildItem({required IconData icon, required int index}) {
      final active = index == currentIndex;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: active
              ? null
              : () {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                      break;
                    case 1:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                      break;
                    case 2:
                      // already here
                      break;
                    case 3:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                      break;
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active
                    ? LinearGradient(
                        colors: [_primary, _primary.withOpacity(0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: active ? null : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: 26,
                color: active ? Colors.white : _primary.withOpacity(0.7),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            buildItem(icon: Icons.home_rounded, index: 0),
            buildItem(icon: Icons.history_rounded, index: 1),
            buildItem(icon: Icons.favorite_rounded, index: 2),
            buildItem(icon: Icons.person_rounded, index: 3),
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

String _formatRating1Decimal(dynamic raw) {
  if (raw == null) return '0.0';
  double? v;
  if (raw is num)
    v = raw.toDouble();
  else {
    v = double.tryParse(raw.toString());
  }
  v ??= 0.0;
  final rounded = (v * 10).round() / 10.0; // nearest tenth, 4.25 -> 4.3
  return rounded.toStringAsFixed(1);
}
