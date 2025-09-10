import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'rating_page.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'menu_detail_page.dart';
import 'package:dpr_bites/features/user/pages/checkout/checkout_page.dart';
import 'package:dpr_bites/features/user/services/restaurant_detail_page_service.dart';
import 'package:url_launcher/url_launcher.dart';
// prefs handled in service layer

class RestaurantDetailPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  // selectedMenus: {menuId: qty}
  final ValueNotifier<Map<String, int>> selectedMenus = ValueNotifier({});
  // selectedAddons: {menuId: List<int>} -> simpan ID addon untuk kirim ke API keranjang
  final Map<String, List<int>> selectedAddons = {};
  // selectedNotes: {menuId: note} -> simpan catatan terakhir untuk edit
  final Map<String, String> selectedNotes = {};
  // Menyimpan menuId yang memiliki lebih dari satu varian di cart (multi-variant)
  final Set<String> _multiVariantMenus = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _etalaseKeys = {};

  // Remote data
  Map<String, dynamic>?
  _resto; // struktur mirip dummy: { id, name, profilePic, rating, ratingCount, etalase:[{label,image}], minPrice, maxPrice }
  List<Map<String, dynamic>> _menus =
      []; // setiap menu: { id, name, price, image, kategori/etalase label, desc, recommended }
  bool _loading = true;
  String? _error;
  // Total harga keranjang (server authoritative, termasuk addon & variasi)
  int _cartTotalPrice = 0;
  // Cache apakah menu punya addon (menuId -> bool)
  final Map<String, bool> _menuHasAddon = {};
  // user id dari SharedPreferences (dapat null jika belum login)
  // user id handled internally by service

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchDetail();
    await _loadExistingCart();
  }

  Future<void> _loadExistingCart() async {
    final snap = await RestaurantDetailPageService.fetchCartSnapshot(
      restaurantId: widget.restaurantId,
    );
    if (snap == null) return;
    // Reset and apply snapshot
    selectedAddons.clear();
    selectedNotes.clear();
    _menuHasAddon.clear();
    _multiVariantMenus.clear();
    selectedMenus.value = Map<String, int>.from(snap.selectedMenus);
    selectedAddons.addAll(snap.selectedAddons);
    selectedNotes.addAll(snap.selectedNotes);
    _multiVariantMenus.addAll(snap.multiVariantMenus);
    setState(() {
      _cartTotalPrice = snap.totalPrice;
      // Hint for menus having addon where present
      for (final entry in snap.selectedAddons.entries) {
        _menuHasAddon[entry.key] = entry.value.isNotEmpty;
      }
    });
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await RestaurantDetailPageService.fetchDetail(
      widget.restaurantId,
    );
    if (!mounted) return;
    if (res.success) {
      final resto = res.resto!;
      final menus = res.menus;
      // Init etalase keys for scrolling
      final etalaseList = (resto['etalase'] as List?) ?? [];
      for (var e in etalaseList) {
        final label = (e['label'] ?? '').toString();
        if (label.isNotEmpty && !_etalaseKeys.containsKey(label)) {
          _etalaseKeys[label] = GlobalKey();
        }
      }
      setState(() {
        _resto = resto;
        _menus = menus;
        _loading = false;
      });
      _prefetchAddonAvailability();
    } else {
      setState(() {
        _error = res.error ?? 'Gagal memuat';
        _loading = false;
      });
    }
  }

  Future<void> _prefetchAddonAvailability() async {
    // Periksa tiap menu sekali untuk mengetahui apakah punya addon tanpa membuka modal (optional optimization)
    for (final m in _menus) {
      final menuId = m['id'];
      if (menuId == null) continue;
      final idStr = menuId.toString();
      if (_menuHasAddon.containsKey(idStr)) continue;
      final detail = await RestaurantDetailPageService.fetchMenuDetail(idStr);
      final addons = detail == null
          ? null
          : (detail['addonOptions'] ?? detail['add_ons']);
      if (addons is List && addons.isNotEmpty) {
        _menuHasAddon[idStr] = true;
        m['addonOptions'] = addons;
      } else {
        _menuHasAddon[idStr] = false;
      }
    }
  }

  // removed old _fetchMenuDetail; use RestaurantDetailPageService.fetchMenuDetail instead

  Future<void> _addOrUpdateCart({
    required String menuId,
    required int qty,
    List<int> addonIds = const [],
    String? note,
    bool noteProvided = false,
  }) async {
    await RestaurantDetailPageService.addOrUpdateCart(
      restaurantId: widget.restaurantId,
      menuId: menuId,
      qty: qty,
      addonIds: addonIds,
      note: note,
      noteProvided: noteProvided,
    );
  }

  Future<void> _handleAddPressed(Map<String, dynamic> m, int currentQty) async {
    final menuId = m['id'].toString();
    bool creatingVariant = false;
    final bool isMultiVariant = _multiVariantMenus.contains(menuId);
    // Jika sudah multi variant, langsung treat sebagai tambah varian baru (tidak ada inline edit)
    if (isMultiVariant) {
      creatingVariant = true;
    }
    if ((selectedMenus.value[menuId] ?? 0) > 0) {
      if (!isMultiVariant) {
        final choice = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEBEB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.fastfood,
                          color: Color(0xFFD53D3D),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Menu sudah di keranjang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        splashRadius: 18,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Anda ingin mengubah yang sudah ada atau menambahkan sebagai menu baru dengan addon/catatan berbeda?',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFE5E5E5),
                          width: 1.4,
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop('edit'),
                      child: const Text(
                        'Edit Menu',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD53D3D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(ctx).pop('new'),
                      child: const Text(
                        'Tambah Menu Baru',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        if (choice == 'new') {
          creatingVariant = true;
        } else if (choice == 'edit') {
          // keep creatingVariant false -> edit existing
        } else {
          return; // cancel
        }
      }
    }

    bool? hasAddon = _menuHasAddon[menuId];
    if (hasAddon == null) {
      final detail = await RestaurantDetailPageService.fetchMenuDetail(menuId);
      final addonOpts =
          (detail != null ? detail['addonOptions'] : null) as List? ?? [];
      hasAddon = addonOpts.isNotEmpty;
      _menuHasAddon[menuId] = hasAddon;
      if (hasAddon) {
        final result = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => MenuDetailPage(
            menu: m,
            initialQty: creatingVariant ? 0 : currentQty,
            initialAddonIds: creatingVariant
                ? const []
                : selectedAddons[menuId],
            initialNote: creatingVariant ? '' : selectedNotes[menuId],
          ),
        );
        if (result != null) {
          if (result['addonOptions'] != null) {
            m['addonOptions'] = result['addonOptions'];
          }
          if (result['qty'] > 0) {
            if (creatingVariant) {
              await _addOrUpdateCart(
                menuId: menuId,
                qty: result['qty'],
                addonIds: List<int>.from(result['addonIds'] ?? []),
                note: result['note'] as String?,
                noteProvided: true,
              );
              await _loadExistingCart();
            } else {
              selectedMenus.value = Map.of(selectedMenus.value)
                ..[menuId] = result['qty'];
              selectedAddons[menuId] = List<int>.from(result['addonIds'] ?? []);
              final rNote = (result['note'] as String?)?.trim();
              if (rNote != null && rNote.isNotEmpty) {
                selectedNotes[menuId] = rNote;
              } else {
                selectedNotes.remove(menuId);
              }
              await _addOrUpdateCart(
                menuId: menuId,
                qty: result['qty'],
                addonIds: selectedAddons[menuId]!,
                note: result['note'] as String?,
                noteProvided: true,
              );
              await _loadExistingCart();
            }
          } else {
            final updated = Map.of(selectedMenus.value);
            updated.remove(menuId);
            selectedMenus.value = updated;
            selectedAddons.remove(menuId);
            selectedNotes.remove(menuId);
            await _addOrUpdateCart(
              menuId: menuId,
              qty: 0,
              note: result['note'] as String?,
              noteProvided: true,
            );
            await _loadExistingCart();
          }
        }
        return;
      }
    }
    if (hasAddon) {
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => MenuDetailPage(
          menu: m,
          initialQty: creatingVariant ? 0 : currentQty,
          initialAddonIds: creatingVariant ? const [] : selectedAddons[menuId],
          initialNote: creatingVariant ? '' : selectedNotes[menuId],
        ),
      );
      if (result != null) {
        if (result['addonOptions'] != null) {
          m['addonOptions'] = result['addonOptions'];
        }
        if (result['qty'] > 0) {
          if (creatingVariant) {
            await _addOrUpdateCart(
              menuId: menuId,
              qty: result['qty'],
              addonIds: List<int>.from(result['addonIds'] ?? []),
              note: result['note'] as String?,
              noteProvided: true,
            );
            await _loadExistingCart();
          } else {
            selectedMenus.value = Map.of(selectedMenus.value)
              ..[menuId] = result['qty'];
            selectedAddons[menuId] = List<int>.from(result['addonIds'] ?? []);
            final rNote = (result['note'] as String?)?.trim();
            if (rNote != null && rNote.isNotEmpty) {
              selectedNotes[menuId] = rNote;
            } else {
              selectedNotes.remove(menuId);
            }
            await _addOrUpdateCart(
              menuId: menuId,
              qty: result['qty'],
              addonIds: selectedAddons[menuId]!,
              note: result['note'] as String?,
              noteProvided: true,
            );
            await _loadExistingCart();
          }
        } else {
          final updated = Map.of(selectedMenus.value);
          updated.remove(menuId);
          selectedMenus.value = updated;
          selectedAddons.remove(menuId);
          selectedNotes.remove(menuId);
          await _addOrUpdateCart(
            menuId: menuId,
            qty: 0,
            note: result['note'] as String?,
            noteProvided: true,
          );
          await _loadExistingCart();
        }
      }
    } else {
      // Selalu buka MenuDetailPage, baik ada addon atau tidak
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => MenuDetailPage(
          menu: m,
          initialQty: creatingVariant ? 0 : currentQty,
          initialAddonIds: creatingVariant ? const [] : selectedAddons[menuId],
          initialNote: creatingVariant ? '' : selectedNotes[menuId],
        ),
      );
      if (result != null) {
        if (result['addonOptions'] != null) {
          m['addonOptions'] = result['addonOptions'];
        }
        if (result['qty'] > 0) {
          if (creatingVariant) {
            await _addOrUpdateCart(
              menuId: menuId,
              qty: result['qty'],
              addonIds: List<int>.from(result['addonIds'] ?? []),
              note: result['note'] as String?,
              noteProvided: true,
            );
            await _loadExistingCart();
          } else {
            selectedMenus.value = Map.of(selectedMenus.value)
              ..[menuId] = result['qty'];
            selectedAddons[menuId] = List<int>.from(result['addonIds'] ?? []);
            final rNote = (result['note'] as String?)?.trim();
            if (rNote != null && rNote.isNotEmpty) {
              selectedNotes[menuId] = rNote;
            } else {
              selectedNotes.remove(menuId);
            }
            await _addOrUpdateCart(
              menuId: menuId,
              qty: result['qty'],
              addonIds: selectedAddons[menuId]!,
              note: result['note'] as String?,
              noteProvided: true,
            );
            await _loadExistingCart();
          }
        } else {
          final updated = Map.of(selectedMenus.value);
          updated.remove(menuId);
          selectedMenus.value = updated;
          selectedAddons.remove(menuId);
          selectedNotes.remove(menuId);
          await _addOrUpdateCart(
            menuId: menuId,
            qty: 0,
            note: result['note'] as String?,
            noteProvided: true,
          );
          await _loadExistingCart();
        }
      }
    }
  }

  Future<void> _handleQtyAdjustNoAddon(String menuId, int newQty) async {
    if (newQty <= 0) {
      final updated = Map.of(selectedMenus.value);
      updated.remove(menuId);
      selectedMenus.value = updated;
    } else {
      selectedMenus.value = Map.of(selectedMenus.value)..[menuId] = newQty;
    }
    await _addOrUpdateCart(menuId: menuId, qty: newQty < 0 ? 0 : newQty);
  }

  Future<void> _handleQtyAdjustWithAddon(String menuId, int newQty) async {
    // Hanya bisa adjust jika sudah ada addons tersimpan; jika tidak ada, buka detail dulu
    final addons = selectedAddons[menuId];
    if (addons == null || addons.isEmpty) {
      // fallback buka detail agar user pilih addons dulu
      final menu = _menus.firstWhere(
        (m) => m['id'].toString() == menuId,
        orElse: () => {},
      );
      if (menu.isNotEmpty) {
        await _handleAddPressed(menu, selectedMenus.value[menuId] ?? 0);
      }
      return;
    }
    if (newQty <= 0) {
      final updated = Map.of(selectedMenus.value);
      updated.remove(menuId);
      selectedMenus.value = updated;
      selectedAddons.remove(menuId);
      await _addOrUpdateCart(menuId: menuId, qty: 0, addonIds: addons);
    } else {
      selectedMenus.value = Map.of(selectedMenus.value)..[menuId] = newQty;
      await _addOrUpdateCart(menuId: menuId, qty: newQty, addonIds: addons);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading & error states (tetap menjaga layout lain kosong)
    if (_loading) {
      return const Scaffold(
        body: GradientBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFFFF),
          elevation: 2,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: GradientBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                const SizedBox(height: 12),
                CustomButtonOval(text: 'Coba Lagi', onPressed: _fetchDetail),
              ],
            ),
          ),
        ),
      );
    }

    final resto = _resto ?? {};
    final menus = _menus;
    Map<String, Map<String, dynamic>> menuMap = {
      for (var m in menus) m['id'].toString(): m,
    };
    final recommendedMenus = menus
        .where((m) => m['recommended'] == true)
        .toList();
    // etalaseList already prepared earlier when fetching; variable not needed here

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFFFFFFF,
        ), // Sama dengan AppTheme.gradientStart
        elevation: 2,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CartPage()),
                );
                if (changed == true) {
                  await _loadExistingCart();
                  setState(() {}); // trigger rebuild for dependent UI
                }
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
        ],
      ),
      extendBodyBehindAppBar: false,
      body: GradientBackground(
        child: ValueListenableBuilder<Map<String, int>>(
          valueListenable: selectedMenus,
          builder: (context, selected, _) {
            return ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                // HEADER/BANNER RESTO
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 0,
                  ),
                  child: CustomEmptyCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (_) {
                              final banner =
                                  resto['bannerPic'] ?? resto['profilePic'];
                              final lat = resto['latitude'];
                              final lng = resto['longitude'];
                              final canOpenMap = lat != null && lng != null;
                              Widget img = ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    (banner is String &&
                                        banner.startsWith('http'))
                                    ? Image.network(
                                        banner,
                                        width: double.infinity,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: double.infinity,
                                          height: 100,
                                          color: Colors.black12,
                                          child: const Icon(
                                            Icons.store,
                                            color: Colors.black45,
                                            size: 40,
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        (banner ?? 'assets/placeholder.png')
                                            .toString(),
                                        width: double.infinity,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                              );
                              if (!canOpenMap) return img;
                              final mapsUrl =
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng'; // fallback url
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  final dLat = (lat is num)
                                      ? lat.toDouble()
                                      : double.tryParse(lat.toString());
                                  final dLng = (lng is num)
                                      ? lng.toDouble()
                                      : double.tryParse(lng.toString());
                                  if (dLat != null && dLng != null) {
                                    await _openMap(
                                      dLat,
                                      dLng,
                                      fallbackWeb: mapsUrl,
                                    );
                                  }
                                },
                                child: Stack(
                                  children: [
                                    img,
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Lihat Lokasi',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (resto['name'] ?? '').toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (resto['minPrice'] != null &&
                                        resto['maxPrice'] != null)
                                      Text(
                                        "Rp${_formatRupiah(resto['minPrice'])} - Rp${_formatRupiah(resto['maxPrice'])}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    if ((resto['openDays'] ?? '') != '' ||
                                        (resto['openTime'] ?? '') != '' ||
                                        (resto['closeTime'] ?? '') != '')
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 2.0,
                                        ),
                                        child: Text(
                                          _buildOpenInfo(resto),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 2),
                                    Builder(
                                      builder: (_) {
                                        final raw = resto['rating'];
                                        double val;
                                        if (raw is num) {
                                          val = raw.toDouble();
                                        } else {
                                          val =
                                              double.tryParse(
                                                raw?.toString() ?? '',
                                              ) ??
                                              0;
                                        }
                                        final formatted =
                                            ((val * 10).round() / 10)
                                                .toStringAsFixed(
                                                  1,
                                                ); // 4.25 -> 4.3
                                        return Text(
                                          formatted,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "(${resto['ratingCount'] ?? 0})",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 32,
                              child: CustomButtonOval(
                                text: "Lihat Ulasan",
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantRatingPage(
                                      restaurantId: widget.restaurantId,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (recommendedMenus.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Direkomendasikan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 170,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recommendedMenus.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final m = recommendedMenus[i];
                        final menuId = m['id'].toString();
                        final qty = selected[menuId] ?? 0;
                        return SizedBox(
                          width: 140,
                          child: CustomEmptyCard(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await _handleAddPressed(m, qty);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          (m['image'] is String &&
                                              (m['image'] as String).startsWith(
                                                'http',
                                              ))
                                          ? Image.network(
                                              m['image'],
                                              width: 124,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    width: 124,
                                                    height: 80,
                                                    color: Colors.black12,
                                                    child: const Icon(
                                                      Icons.fastfood,
                                                      color: Colors.black38,
                                                    ),
                                                  ),
                                            )
                                          : Image.asset(
                                              (m['image'] ??
                                                      'assets/placeholder.png')
                                                  .toString(),
                                              width: 124,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (m['name'] ?? '').toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "Rp ${m['price']}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Builder(
                                          builder: (_) {
                                            final hasAddon =
                                                _menuHasAddon[menuId] == true;
                                            final multi = _multiVariantMenus
                                                .contains(menuId);
                                            if (qty > 0 && !multi) {
                                              return GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap:
                                                    () {}, // consume tap so parent InkWell tidak terbuka
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.pink.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () {
                                                          if (hasAddon) {
                                                            _handleQtyAdjustWithAddon(
                                                              menuId,
                                                              qty - 1,
                                                            );
                                                          } else {
                                                            _handleQtyAdjustNoAddon(
                                                              menuId,
                                                              qty - 1,
                                                            );
                                                          }
                                                        },
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                4.0,
                                                              ),
                                                          child: Icon(
                                                            Icons.remove,
                                                            size: 18,
                                                            color: Color(
                                                              0xFFD53D3D,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                            ),
                                                        child: Text(
                                                          '$qty',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                  0xFFD53D3D,
                                                                ),
                                                              ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () {
                                                          if (hasAddon) {
                                                            _handleQtyAdjustWithAddon(
                                                              menuId,
                                                              qty + 1,
                                                            );
                                                          } else {
                                                            _handleQtyAdjustNoAddon(
                                                              menuId,
                                                              qty + 1,
                                                            );
                                                          }
                                                        },
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                4.0,
                                                              ),
                                                          child: Icon(
                                                            Icons.add,
                                                            size: 18,
                                                            color: Color(
                                                              0xFFD53D3D,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: Colors.pink.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.all(2),
                                              child: SizedBox(
                                                width: 32,
                                                height: 32,
                                                child: (qty > 0 && !multi)
                                                    ? Center(
                                                        child: Text(
                                                          '$qty',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                  0xFFD53D3D,
                                                                ),
                                                              ),
                                                        ),
                                                      )
                                                    : CustomButtonOval(
                                                        text: "+",
                                                        onPressed: () =>
                                                            _handleAddPressed(
                                                              m,
                                                              qty,
                                                            ),
                                                      ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // MENU PER ETALASE
                ...List.generate((resto['etalase'] as List).length, (i) {
                  final etalase = (resto['etalase'] as List)[i];
                  final kategori = etalase['label'];
                  final kategoriMenus = menus
                      .where((m) => m['kategori'] == kategori)
                      .toList();
                  if (kategoriMenus.isEmpty) return const SizedBox();
                  return Column(
                    key: _etalaseKeys[kategori],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          kategori,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...kategoriMenus.map((m) {
                        final menuId = m['id'].toString();
                        final qty = selected[menuId] ?? 0;
                        final stock = (m['jumlah_stok'] ?? 0) is int
                            ? (m['jumlah_stok'] ?? 0) as int
                            : int.tryParse(
                                    (m['jumlah_stok'] ?? '0').toString(),
                                  ) ??
                                  0;
                        final isDisabled = stock < 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Stack(
                            children: [
                              if (qty > 0 &&
                                  !_multiVariantMenus.contains(menuId))
                                Positioned(
                                  left: 0,
                                  top: 8,
                                  bottom: 8,
                                  child: Container(
                                    width: 5,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD53D3D),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              Opacity(
                                opacity: isDisabled ? 0.5 : 1.0,
                                child: IgnorePointer(
                                  ignoring: isDisabled,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 0),
                                    child: CustomEmptyCard(
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                        leading: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.13,
                                                ),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child:
                                                (m['image'] is String &&
                                                    (m['image'] as String)
                                                        .startsWith('http'))
                                                ? Image.network(
                                                    m['image'],
                                                    width: 64,
                                                    height: 64,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => Container(
                                                          width: 64,
                                                          height: 64,
                                                          color: Colors.black12,
                                                          child: const Icon(
                                                            Icons.fastfood,
                                                            color:
                                                                Colors.black38,
                                                          ),
                                                        ),
                                                  )
                                                : Image.asset(
                                                    (m['image'] ??
                                                            'assets/placeholder.png')
                                                        .toString(),
                                                    width: 64,
                                                    height: 64,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (m['name'] ?? '').toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if ((m['desc'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2.0,
                                                ),
                                                child: Text(
                                                  (m['desc'] ?? '').toString(),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF888888),
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Text("Rp ${m['price']}"),
                                        trailing: Builder(
                                          builder: (_) {
                                            final hasAddon =
                                                _menuHasAddon[menuId] == true;
                                            final multi = _multiVariantMenus
                                                .contains(menuId);
                                            if (qty > 0 && !multi) {
                                              return GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap:
                                                    () {}, // cegah tap propagasi ke ListTile.onTap
                                                child: Container(
                                                  width: 90,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.pink.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: isDisabled
                                                            ? null
                                                            : () {
                                                                if (hasAddon) {
                                                                  _handleQtyAdjustWithAddon(
                                                                    menuId,
                                                                    qty - 1,
                                                                  );
                                                                } else {
                                                                  _handleQtyAdjustNoAddon(
                                                                    menuId,
                                                                    qty - 1,
                                                                  );
                                                                }
                                                              },
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                4.0,
                                                              ),
                                                          child: Icon(
                                                            Icons.remove,
                                                            size: 20,
                                                            color: Color(
                                                              0xFFD53D3D,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        '$qty',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFFD53D3D,
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: isDisabled
                                                            ? null
                                                            : () {
                                                                if (hasAddon) {
                                                                  _handleQtyAdjustWithAddon(
                                                                    menuId,
                                                                    qty + 1,
                                                                  );
                                                                } else {
                                                                  _handleQtyAdjustNoAddon(
                                                                    menuId,
                                                                    qty + 1,
                                                                  );
                                                                }
                                                              },
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                4.0,
                                                              ),
                                                          child: Icon(
                                                            Icons.add,
                                                            size: 20,
                                                            color: Color(
                                                              0xFFD53D3D,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                            return SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: CustomButtonOval(
                                                text: "+",
                                                onPressed: isDisabled
                                                    ? null
                                                    : () async {
                                                        await _handleAddPressed(
                                                          m,
                                                          qty,
                                                        );
                                                      },
                                              ),
                                            );
                                          },
                                        ),
                                        onTap: isDisabled
                                            ? null
                                            : () async {
                                                await _handleAddPressed(m, qty);
                                              },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol etalase di atas keranjang
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (context) {
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: RestaurantDetailPageService.fetchEtalaseList(
                          widget.restaurantId,
                        ),
                        builder: (context, snap) {
                          final etalase = snap.data ?? const [];
                          return SafeArea(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Pilih Etalase',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (snap.connectionState ==
                                      ConnectionState.waiting)
                                    const Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (etalase.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Text('Tidak ada etalase'),
                                    )
                                  else
                                    ...etalase.map((e) {
                                      return ListTile(
                                        title: Text(
                                          (e['label'] ?? '').toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: (e['menuCount'] != null)
                                            ? Text(
                                                '${e['menuCount']} menu',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : null,
                                        onTap: () {
                                          Navigator.pop(context);
                                          final key = _etalaseKeys[e['label']];
                                          if (key != null &&
                                              key.currentContext != null) {
                                            Scrollable.ensureVisible(
                                              key.currentContext!,
                                              duration: const Duration(
                                                milliseconds: 400,
                                              ),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        },
                                      );
                                    }).toList(),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD53D3D), Color(0xFF602829)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.restaurant_menu, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Etalase',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Keranjang sticky di bawah dengan background putih membulat
          ValueListenableBuilder<Map<String, int>>(
            valueListenable: selectedMenus,
            builder: (context, selected, _) {
              final totalQty = selected.values.fold<int>(0, (a, b) => a + b);
              int totalPrice = _cartTotalPrice;
              // Fallback kalkulasi lokal jika server total belum ada
              if (totalPrice == 0 && selected.isNotEmpty) {
                totalPrice = selected.entries.fold<int>(0, (a, e) {
                  final menuId = e.key;
                  final qty = e.value;
                  final menu = menuMap[menuId];
                  if (menu == null) return a;
                  int basePrice = int.tryParse(menu['price'].toString()) ?? 0;
                  int addonTotal = 0;
                  final addonIds = selectedAddons[menuId] ?? [];
                  for (final addonId in addonIds) {
                    final opt = (menu['addonOptions'] as List?)?.firstWhere(
                      (o) => o['id'] == addonId,
                      orElse: () => <String, Object>{},
                    );
                    if (opt != null && opt.isNotEmpty) {
                      addonTotal += int.tryParse(opt['price'].toString()) ?? 0;
                    }
                  }
                  return a + (basePrice + addonTotal) * qty;
                });
              }
              if (totalQty == 0) return const SizedBox.shrink();
              return Container(
                // Hapus margin bottom agar putih full sampai bawah
                margin: EdgeInsets.zero,
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Center(
                  child: Container(
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD53D3D), Color(0xFF602829)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutPage(),
                              settings: RouteSettings(
                                arguments: {'geraiId': widget.restaurantId},
                              ),
                            ),
                          );
                          // Setelah kembali dari checkout, refresh cart agar qty/addon sesuai DB
                          await _loadExistingCart();
                          // Optional: jika ingin juga segarkan detail resto (misal harga berubah), aktifkan baris berikut
                          // await _fetchDetail();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFD53D3D),
                                          Color(0xFF602829),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.10),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$totalQty',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'item',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                totalPrice.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (m) => '${m[1]}.',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _buildOpenInfo(Map<String, dynamic> resto) {
    final days = (resto['openDays'] ?? '').toString();
    final open = (resto['openTime'] ?? '').toString();
    final close = (resto['closeTime'] ?? '').toString();
    if (days.isEmpty && open.isEmpty && close.isEmpty) return '';
    String timePart = '';
    if (open.isNotEmpty || close.isNotEmpty) {
      if (open.isNotEmpty && close.isNotEmpty) {
        timePart = '$open - $close';
      } else if (open.isNotEmpty) {
        timePart = open;
      } else {
        timePart = close;
      }
    }
    if (days.isNotEmpty && timePart.isNotEmpty) return '$days | $timePart';
    if (days.isNotEmpty) return days;
    return timePart;
  }

  Future<void> _openMap(double lat, double lng, {String? fallbackWeb}) async {
    final intents = <Uri>[
      Uri.parse('geo:$lat,$lng?q=$lat,$lng'), // Android geo scheme
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
      if (fallbackWeb != null) Uri.parse(fallbackWeb),
      Uri.parse('https://maps.google.com/?q=$lat,$lng'),
    ];
    for (final uri in intents) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        /* continue */
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka peta')));
  }
}

// Helper format rupiah (sederhana, titik setiap 3 digit)
String _formatRupiah(dynamic value) {
  if (value == null) return '';
  int? n;
  if (value is int)
    n = value;
  else if (value is double)
    n = value.round();
  else
    n = int.tryParse(value.toString());
  if (n == null) return '';
  final s = n.toString();
  final buf = StringBuffer();
  int c = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    c++;
    if (c == 3 && i != 0) {
      buf.write('.');
      c = 0;
    }
  }
  return buf.toString().split('').reversed.join();
}
