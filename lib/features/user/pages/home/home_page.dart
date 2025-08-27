import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
// import '../../../../common/data/dummy_restaurants.dart'; // replaced by real API data
import '../../../../common/data/dummy_address.dart';
import '../../../../common/data/address_store.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'filter_category_sheet.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'filter_price_sheet.dart';
import 'package:dpr_bites/features/user/pages/search/search_page.dart';
import 'package:dpr_bites/features/user/pages/restaurant_detail/restaurant_detail_page.dart';
import 'package:dpr_bites/features/user/pages/profile/profile_page.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  String? searchQuery;
  String? selectedRating;
  String? selectedPrice;
  String? selectedCategory;
  final searchController = TextEditingController();

  // Data restoran dari API
  List<Map<String, dynamic>> _restaurants = [];
  bool _loadingRestaurants = true;
  bool _errorRestaurants = false;

  String _buildingName = '';
  String _detailPengantaran = '';
  bool _addressLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchUserAddress();
    _fetchRestaurants();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Daftarkan route observer jika tersedia
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      _routeObserverSubscribe(route);
    }
  }

  void _routeObserverSubscribe(PageRoute<dynamic> route) {
    // Cari RouteObserver di Navigator (global observer bisa dibuat di main)
    // Jika belum ada global, kita skip tanpa error.
    final navigator = route.navigator;
    if (navigator != null) {
      // Tidak ada referensi langsung ke observer global sekarang, jadi manual call not possible.
      // Alternatif: gunakan addPostFrameCallback untuk clear ketika muncul kembali (fallback simple).
    }
  }

  @override
  void didPopNext() {
    // Dipanggil saat kembali ke halaman ini dari halaman lain
    if (mounted) {
      setState(() {
        searchController.clear();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final idUsers = prefs.getString('id_users');
    if (idUsers == null) {
      setState(() {
        _buildingName = 'Tambah Alamat Disini';
        _detailPengantaran = '';
        _addressLoaded = true;
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/dpr_bites_api/get_user_address.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_users': idUsers}),
      );
      final result = jsonDecode(response.body);
      if (result['success'] == true && result['has_address'] == true) {
        setState(() {
          _buildingName = result['nama_gedung'] ?? 'Tambah Alamat Disini';
          _detailPengantaran = result['detail_pengantaran'] ?? '';
          _addressLoaded = true;
        });
      } else {
        setState(() {
          _buildingName = 'Tambah Alamat Disini';
          _detailPengantaran = '';
          _addressLoaded = true;
        });
      }
    } catch (e) {
      setState(() {
        _buildingName = 'Tambah Alamat Disini';
        _detailPengantaran = '';
        _addressLoaded = true;
      });
    }
  }

  Future<void> _fetchRestaurants({
    double? minRating,
    String? priceLabel,
  }) async {
    setState(() {
      _loadingRestaurants = true;
      _errorRestaurants = false;
    });
    try {
      late final Uri url;
      if (priceLabel != null) {
        final encoded = Uri.encodeQueryComponent(priceLabel);
        url = Uri.parse(
          'http://10.0.2.2/dpr_bites_api/get_restaurants_by_price.php?price=$encoded',
        );
      } else if (minRating != null) {
        url = Uri.parse(
          'http://10.0.2.2/dpr_bites_api/get_restaurants_by_rating.php?min_rating=${minRating.toString()}',
        );
      } else {
        url = Uri.parse('http://10.0.2.2/dpr_bites_api/get_restaurants.php');
      }
      final res = await http.get(url, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final List data = body['data'] as List? ?? [];
          _restaurants = data
              .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map),
              )
              .toList();
        } else {
          _errorRestaurants = true;
        }
      } else {
        _errorRestaurants = true;
      }
    } catch (_) {
      _errorRestaurants = true;
    }
    if (!mounted) return;
    setState(() {
      _loadingRestaurants = false;
    });
  }

  String _formatRupiah(dynamic value) {
    if (value == null) return '-';
    int? v;
    if (value is int)
      v = value;
    else if (value is String)
      v = int.tryParse(value);
    if (v == null) return '-';
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return 'Rp${buf.toString()}';
  }

  // Filter function (menggunakan data dari API)
  List<Map<String, dynamic>> get filteredRestaurants {
    List<Map<String, dynamic>> restos = List<Map<String, dynamic>>.from(
      _restaurants,
    );

    // Filter rating
    if (selectedRating != null && selectedRating == '4.5') {
      restos = restos.where((r) => (r['rating'] ?? 0) >= 4.5).toList();
    }

    // Filter price range
    if (selectedPrice != null && selectedPrice!.contains('-')) {
      final range = selectedPrice!.split('-');
      final min = int.tryParse(range[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final max =
          int.tryParse(range[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 1000000;
      restos = restos.where((resto) {
        final etalase = resto['etalase'] as List<dynamic>?;
        if (etalase == null) return false;
        for (final e in etalase) {
          final menus = e['menus'] as List<dynamic>?;
          if (menus == null) continue;
          for (final m in menus) {
            final price = m['price'] as int?;
            if (price != null && price >= min && price <= max) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    } else if (selectedPrice != null && selectedPrice!.contains('>')) {
      final min =
          int.tryParse(selectedPrice!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      restos = restos.where((resto) {
        final etalase = resto['etalase'] as List<dynamic>?;
        if (etalase == null) return false;
        for (final e in etalase) {
          final menus = e['menus'] as List<dynamic>?;
          if (menus == null) continue;
          for (final m in menus) {
            final price = m['price'] as int?;
            if (price != null && price > min) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }

    return restos;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AddressStore so AppBar updates when address changes
    final store = AddressStore.instance;
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 90,
            title: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/address',
                    );
                    if (result is DummyAddress) {
                      store.select(result);
                    }
                    _fetchUserAddress();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 0),
                    child: Transform.translate(
                      offset: const Offset(0, -21),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Alamat Pengantaran',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _addressLoaded ? _buildingName : '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF602829),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: Color(0xFF602829),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (_addressLoaded && _detailPengantaran.isNotEmpty)
                            Text(
                              _detailPengantaran,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            actions: [
              Transform.translate(
                offset: const Offset(0, -21),
                child: Padding(
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
                      backgroundColor: const Color(0xFFD53D3D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Jarak bawah header alamat
                  const SizedBox(height: 0), // Lebih dekat ke AppBar
                  // Search Field
                  Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          hintText: "Apa yang Anda Cari?",
                          controller: searchController,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFD53D3D),
                          ),
                          onSubmitted: (val) {
                            print("onSubmitted: $val");
                            if (val.trim().isEmpty) return;
                            final query = val.trim();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchPage(initialQuery: query),
                              ),
                            ).then((_) {
                              // Clear setelah kembali
                              if (mounted) {
                                setState(() {
                                  searchController.clear();
                                });
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        CustomFilterChip(
                          label: "Bintang 4.5+",
                          selected: selectedRating != null,
                          onTap: () {
                            final willSelect = selectedRating == null;
                            setState(() {
                              selectedRating = willSelect ? '4.5' : null;
                            });
                            // Fetch dari API rating jika diaktifkan, jika tidak ambil semua
                            if (willSelect) {
                              _fetchRestaurants(minRating: 4.5);
                            } else {
                              _fetchRestaurants();
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        CustomFilterChip(
                          label: "Rentang harga",
                          selected: selectedPrice != null,
                          onTap: () async {
                            final result = await showModalBottomSheet<String>(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) =>
                                  FilterPriceSheet(initialValue: selectedPrice),
                            );
                            setState(() {
                              selectedPrice = result;
                            });
                            if (result != null) {
                              _fetchRestaurants(priceLabel: result);
                            } else {
                              // reset list (pertahankan rating jika aktif)
                              if (selectedRating != null) {
                                _fetchRestaurants(minRating: 4.5);
                              } else {
                                _fetchRestaurants();
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        CustomFilterChip(
                          label: "Kuliner",
                          selected: selectedCategory != null,
                          onTap: () async {
                            // Modal filter kategori
                            final result = await showModalBottomSheet<String>(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) => FilterCategorySheet(
                                initialValue: selectedCategory,
                              ),
                            );
                            setState(() {
                              selectedCategory = result;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // List restoran (scroll)
                  Expanded(
                    child: _loadingRestaurants
                        ? const Center(child: CircularProgressIndicator())
                        : _errorRestaurants
                        ? Center(
                            child: TextButton(
                              onPressed: _fetchRestaurants,
                              child: const Text('Gagal memuat. Coba lagi'),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 25),
                            itemCount: filteredRestaurants.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final resto = filteredRestaurants[idx];
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailPage(
                                        restaurantId: resto['id'].toString(),
                                      ),
                                    ),
                                  );
                                },
                                child: CustomEmptyCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child:
                                              (resto['profilePic'] != null &&
                                                  (resto['profilePic']
                                                          as String)
                                                      .isNotEmpty)
                                              ? Image.network(
                                                  resto['profilePic'],
                                                  width: 75,
                                                  height: 75,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        width: 75,
                                                        height: 75,
                                                        color: Colors.black12,
                                                        child: const Icon(
                                                          Icons.store,
                                                          color: Colors.black38,
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  width: 75,
                                                  height: 75,
                                                  color: Colors.black12,
                                                  child: const Icon(
                                                    Icons.store,
                                                    color: Colors.black38,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (resto['name'] ?? '')
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    "${resto['rating']}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    "(${resto['ratingCount']})",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.monetization_on,
                                                    color: Colors.grey,
                                                    size: 16,
                                                  ),
                                                  if (resto['minPrice'] !=
                                                          null &&
                                                      resto['maxPrice'] != null)
                                                    Text(
                                                      "${_formatRupiah(resto['minPrice'])} – ${_formatRupiah(resto['maxPrice'])}",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (resto['desc'] ?? '')
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontSize: 13,
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
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFF9D3D3).withOpacity(0.85),
          selectedItemColor: const Color(0xFFD53D3D),
          unselectedItemColor: Colors.black54,
          currentIndex: 0,
          selectedFontSize: 14,
          unselectedFontSize: 13,
          iconSize: 30,
          onTap: (i) {
            if (i == 0) {
              // Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            } else if (i == 1) {
              // History
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            } else if (i == 2) {
              // Favorit
              Navigator.pushReplacementNamed(context, '/favorit');
            } else if (i == 3) {
              // Profile
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
