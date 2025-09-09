import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../common/data/dummy_address.dart';
import '../../../../common/data/address_store.dart';
import 'package:dpr_bites/features/user/services/home_page_service.dart';
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
  final FocusNode _searchFocus = FocusNode();

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
    _searchFocus.addListener(() => setState(() {}));
    searchController.addListener(() => setState(() {}));
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
    _searchFocus.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserAddress() async {
    final res = await HomePageService.fetchUserAddress();
    if (!mounted) return;
    setState(() {
      if (res.hasAddress && res.address != null) {
        _buildingName = res.address!.buildingName;
        _detailPengantaran = res.address!.detailPengantaran;
      } else {
        _buildingName = 'Tambah Alamat Disini';
        _detailPengantaran = '';
      }
      _addressLoaded = true;
    });
  }

  Future<void> _fetchRestaurants({
    double? minRating,
    String? priceLabel,
  }) async {
    setState(() {
      _loadingRestaurants = true;
      _errorRestaurants = false;
    });
    final res = await HomePageService.fetchRestaurants(
      minRating: minRating,
      priceLabel: priceLabel,
    );
    if (!mounted) return;
    setState(() {
      _restaurants = res.restaurants
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
      _errorRestaurants = !res.success;
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
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD53D3D), Color(0xFFB03056)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD53D3D).withOpacity(0.35),
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
                  // Search Field - minimal, modern, animated
                  Builder(
                    builder: (context) {
                      final bool focused =
                          _searchFocus.hasFocus ||
                          searchController.text.isNotEmpty;
                      final gradientColors = const [
                        Color(0xFFD53D3D),
                        Color(0xFFB03056),
                      ];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: (focused
                                  ? const Color(0xFFD53D3D).withOpacity(0.18)
                                  : const Color(0xFFD53D3D).withOpacity(0.10)),
                              blurRadius: focused ? 18 : 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2.6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: focused
                                ? LinearGradient(
                                    colors: gradientColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      const Color(0xFFD53D3D).withOpacity(0.30),
                                      const Color(0xFFB03056).withOpacity(0.30),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          ),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: focused
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.98),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 22,
                                  color: focused
                                      ? const Color(0xFFD53D3D)
                                      : Colors.black38,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    focusNode: _searchFocus,
                                    controller: searchController,
                                    textInputAction: TextInputAction.search,
                                    decoration: const InputDecoration(
                                      hintText: 'Lagi Pengen Makan Apa?',
                                      hintStyle: TextStyle(
                                        color: Colors.black38,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (val) {
                                      final query = val.trim();
                                      if (query.isEmpty) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SearchPage(initialQuery: query),
                                        ),
                                      ).then((_) {
                                        if (mounted) {
                                          setState(() {
                                            searchController.clear();
                                            _searchFocus.unfocus();
                                          });
                                        }
                                      });
                                    },
                                  ),
                                ),
                                if (searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      searchController.clear();
                                      _searchFocus.requestFocus();
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Filter chips (modern, full-bleed horizontally scrollable)
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      clipBehavior: Clip.none, // allow bounce paint outside
                      // Gutter kiri & kanan supaya bounce terlihat (visual ruang minimal)
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        const SizedBox(width: 4), // extra left gutter
                        _FilterPill(
                          label: 'Bintang 4.5+',
                          selected: selectedRating != null,
                          leading: const Icon(
                            Icons.star,
                            size: 18,
                            color: Colors.amber,
                          ),
                          onTap: () {
                            final willSelect = selectedRating == null;
                            setState(
                              () => selectedRating = willSelect ? '4.5' : null,
                            );
                            if (willSelect) {
                              _fetchRestaurants(minRating: 4.5);
                            } else {
                              _fetchRestaurants();
                            }
                          },
                        ),
                        _FilterSpacing(),
                        _FilterPill(
                          label: selectedPrice ?? 'Rentang harga',
                          selected: selectedPrice != null,
                          leading: const Icon(
                            Icons.monetization_on,
                            size: 18,
                            color: Color(0xFFD53D3D),
                          ),
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
                            setState(() => selectedPrice = result);
                            if (result != null) {
                              _fetchRestaurants(priceLabel: result);
                            } else {
                              if (selectedRating != null) {
                                _fetchRestaurants(minRating: 4.5);
                              } else {
                                _fetchRestaurants();
                              }
                            }
                          },
                          onClear: selectedPrice != null
                              ? () {
                                  setState(() => selectedPrice = null);
                                  if (selectedRating != null) {
                                    _fetchRestaurants(minRating: 4.5);
                                  } else {
                                    _fetchRestaurants();
                                  }
                                }
                              : null,
                        ),
                        _FilterSpacing(),
                        _FilterPill(
                          label: selectedCategory ?? 'Kuliner',
                          selected: selectedCategory != null,
                          leading: const Icon(
                            Icons.category_outlined,
                            size: 18,
                            color: Color(0xFFD53D3D),
                          ),
                          onTap: () async {
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
                            setState(() => selectedCategory = result);
                          },
                          onClear: selectedCategory != null
                              ? () => setState(() => selectedCategory = null)
                              : null,
                        ),
                        const SizedBox(
                          width: 16,
                        ), // right gutter for overscroll space
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
        bottomNavigationBar: _MinimalBottomNav(currentIndex: 0),
      ),
    );
  }
}

class _MinimalBottomNav extends StatelessWidget {
  final int currentIndex; // 0 home,1 history,2 favorit,3 profile
  const _MinimalBottomNav({required this.currentIndex});

  Color get _primary => const Color(0xFFD53D3D);

  @override
  Widget build(BuildContext context) {
    Widget buildItem({required IconData icon, required int index}) {
      final bool active = index == currentIndex;
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
                      Navigator.pushReplacementNamed(context, '/favorit');
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

class _FilterSpacing extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 10);
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final Widget? leading;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const LinearGradient(colors: [Color(0xFFD53D3D), Color(0xFFB03056)])
        : const LinearGradient(colors: [Colors.white, Colors.white]);
    final borderColor = selected
        ? const Color(0xFFD53D3D)
        : Colors.grey.shade300;
    final textColor = selected ? Colors.white : const Color(0xFF602829);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 16 : 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD53D3D).withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      color: selected
                          ? Colors.white
                          : leading is Icon
                          ? (leading as Icon).color
                          : null,
                      size: 18,
                    ),
                    child: leading!,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
                if (onClear != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white24 : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: selected ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
