import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/features/user/services/search_page_service.dart';
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
  final FocusNode _searchFocus = FocusNode();
  String? searchQuery;

  // Hasil dari API
  List<Map<String, dynamic>> _results = [];
  final int _userId = 1; // TODO: dynamic auth user
  // Removed unused _menuHasAddonCache to keep file lint-clean
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
    _searchFocus.addListener(() => setState(() {}));
    searchController.addListener(() => setState(() {}));
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
    final list = await SearchService.searchRestaurants(q);
    _results = list;
    if (!mounted) return;
    setState(() {});
  }

  // Removed unused _fetchMenuDetail; the page opens MenuDetail via normalized map

  // Removed unused helper _addOrUpdateCart to keep lints clean

  Future<void> _handleAddPressed(
    Map<String, dynamic> resto,
    Map<String, dynamic> menu,
  ) async {
    if (_adding) return; // throttle
    final geraiId = resto['id']?.toString() ?? '';
    if (geraiId.isEmpty) return;
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
    if (result == null) return;
    final qty = (result['qty'] as int?) ?? 0;
    if (qty <= 0) return;
    final addonIds = (result['addonIds'] as List?)?.cast<int>() ?? [];
    final note = result['note']?.toString();
    final payload = <String, dynamic>{
      'user_id': _userId,
      'gerai_id': geraiId,
      'menu_id': normalized['id'],
      'qty': qty,
    };
    if (addonIds.isNotEmpty) payload['addons'] = addonIds;
    if (note != null) payload['note'] = note;
    final ok = await SearchService.addOrUpdateCart(payload);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ditambahkan ke keranjang')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambah (format/HTTP)')),
      );
    }
  }

  Future<void> _openMenuDetail(
    Map<String, dynamic> menu, {
    required String geraiId,
  }) async {
    final normalized = {
      'id': menu['id'] ?? menu['menu_id'],
      'name': menu['name'] ?? menu['nama_menu'],
      'desc': menu['desc'] ?? menu['deskripsi_menu'],
      'price': menu['price'] ?? menu['harga'] ?? 0,
      'image': menu['image'] ?? menu['gambar_menu'],
    };
    await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MenuDetailPage(menu: normalized, initialQty: 1),
    );
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

  @override
  void dispose() {
    _searchFocus.dispose();
    searchController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.only(right: 14, top: 4),
              child: GestureDetector(
                onTap: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                  if (changed == true &&
                      mounted &&
                      searchQuery?.isNotEmpty == true) {
                    _performSearch(searchQuery!);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD53D3D), Color(0xFFD53D3D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33D53D3D),
                        blurRadius: 14,
                        offset: Offset(0, 6),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field - same design as Home
                Builder(
                  builder: (context) {
                    final bool focused =
                        _searchFocus.hasFocus ||
                        searchController.text.isNotEmpty;
                    const gradientColors = [
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
                              ? const LinearGradient(
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
                                  onSubmitted: doSearch,
                                ),
                              ),
                              if (searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    searchController.clear();
                                    _searchFocus.requestFocus();
                                    setState(() {
                                      searchQuery = '';
                                      _results = [];
                                    });
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
                                  final screenW = MediaQuery.of(
                                    context,
                                  ).size.width;
                                  final double cardW = (screenW * 0.42).clamp(
                                    140.0,
                                    180.0,
                                  );
                                  final double _imgH =
                                      cardW * 0.62; // keep image proportional
                                  final double cardH =
                                      _imgH +
                                      80; // add buffer to avoid overflow
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
                                            bottom: 8,
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
                                                bottom: 8,
                                              ),
                                              child: SizedBox(
                                                height: cardH,
                                                child: ListView.separated(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 2,
                                                      ),
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: menus.length,
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(width: 8),
                                                  itemBuilder: (context, i) {
                                                    final m = menus[i];
                                                    final priceVal =
                                                        m['price'] ??
                                                        m['harga'] ??
                                                        0;
                                                    final priceText =
                                                        'Rp${_formatRupiah(priceVal)}';
                                                    return _MenuCardModern(
                                                      menu: m,
                                                      width: cardW,
                                                      height: cardH,
                                                      priceText: priceText,
                                                      onTap: () =>
                                                          _openMenuDetail(
                                                            m,
                                                            geraiId: resto['id']
                                                                .toString(),
                                                          ),
                                                      onAdd: () =>
                                                          _handleAddPressed(
                                                            resto,
                                                            m,
                                                          ),
                                                    );
                                                  },
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

// Old _MenuGridCard removed after redesign

class _MenuCardModern extends StatelessWidget {
  final Map<String, dynamic> menu;
  final double width;
  final double height;
  final String priceText;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _MenuCardModern({
    required this.menu,
    required this.width,
    required this.height,
    required this.priceText,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final String title = (menu['name'] ?? menu['nama_menu'] ?? '').toString();
    final String imageUrl = (menu['image'] ?? menu['gambar_menu'] ?? '')
        .toString();
    final double radius = 16;
    final double imgH = width * 0.62; // responsive image height

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x22000000),
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              SizedBox(
                height: imgH,
                width: double.infinity,
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(Icons.fastfood, color: Colors.black38),
                          ),
                        ),
                      )
                    : (imageUrl.isNotEmpty
                          ? Image.asset(imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: Colors.black12,
                              child: const Center(
                                child: Icon(
                                  Icons.fastfood,
                                  color: Colors.black38,
                                ),
                              ),
                            )),
              ),
              // Content
              // Content section (no Expanded to avoid middle gaps)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            priceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFFD53D3D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 32,
                          width: 32,
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: Ink(
                              decoration: const ShapeDecoration(
                                shape: CircleBorder(),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFD53D3D),
                                    Color(0xFFB03056),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onAdd,
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
