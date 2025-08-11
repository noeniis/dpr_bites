import 'package:flutter/material.dart';
import 'package:dpr_bites/common/data/dummy_restaurants.dart';
import 'package:dpr_bites/common/data/dummy_menus.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'rating_page.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';

import 'menu_detail_page.dart';
import 'package:dpr_bites/features/user/pages/checkout/checkout_page.dart';

class RestaurantDetailPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  // selectedMenus: {menuId: qty}
  final ValueNotifier<Map<String, int>> selectedMenus = ValueNotifier({});
  // selectedAddons: {menuId: List<String>}
  final Map<String, List<String>> selectedAddons = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _etalaseKeys = {};

  @override
  Widget build(BuildContext context) {
    final resto = dummyRestaurants.firstWhere(
      (r) => r['id'] == widget.restaurantId,
    );
    final menus = dummyMenus
        .where((m) => m['restaurantId'] == widget.restaurantId)
        .toList();
    Map<String, Map<String, dynamic>> menuMap = {
      for (var m in menus) m['id'].toString(): m as Map<String, dynamic>,
    };
    final recommendedMenus = menus
        .where((m) => m['recommended'] == true)
        .toList();
    // Init etalase keys
    final etalaseList = (resto['etalase'] as List);
    for (var e in etalaseList) {
      final label = e['label'];
      if (!_etalaseKeys.containsKey(label)) {
        _etalaseKeys[label] = GlobalKey();
      }
    }

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
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              resto['profilePic'].toString(),
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
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
                                      resto['name'].toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rp15.000 - Rp35.000",
                                      style: const TextStyle(
                                        color: Colors.grey,
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
                                    Text(
                                      "${resto['rating']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "(${resto['ratingCount']})",
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
                const SizedBox(height: 20),
                // REKOMENDASI MENU
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Direkomendasikan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      final m = recommendedMenus[i] as Map<String, dynamic>;
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
                                final result =
                                    await showModalBottomSheet<
                                      Map<String, dynamic>
                                    >(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (_) => MenuDetailPage(
                                        menu: m,
                                        initialQty: qty,
                                      ),
                                    );
                                if (result != null) {
                                  if (result['qty'] > 0) {
                                    selectedMenus.value = Map.of(
                                      selectedMenus.value,
                                    )..[menuId] = result['qty'];
                                    selectedAddons[menuId] = List<String>.from(
                                      result['addons'] ?? [],
                                    );
                                  } else {
                                    // Remove from cart if qty < 1
                                    final updated = Map.of(selectedMenus.value);
                                    updated.remove(menuId);
                                    selectedMenus.value = updated;
                                    selectedAddons.remove(menuId);
                                  }
                                }
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      m['image'],
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
                                              m['name'],
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
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.pink.shade50,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: qty > 0
                                              ? Center(
                                                  child: Text(
                                                    '$qty',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFFD53D3D),
                                                    ),
                                                  ),
                                                )
                                              : CustomButtonOval(
                                                  text: "+",
                                                  onPressed: () async {
                                                    final result =
                                                        await showModalBottomSheet<
                                                          Map<String, dynamic>
                                                        >(
                                                          context: context,
                                                          isScrollControlled:
                                                              true,
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          shape: const RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.vertical(
                                                                  top:
                                                                      Radius.circular(
                                                                        24,
                                                                      ),
                                                                ),
                                                          ),
                                                          builder: (_) =>
                                                              MenuDetailPage(
                                                                menu: m,
                                                                initialQty: qty,
                                                              ),
                                                        );
                                                    if (result != null &&
                                                        result['qty'] > 0) {
                                                      selectedMenus.value =
                                                          Map.of(
                                                              selectedMenus
                                                                  .value,
                                                            )
                                                            ..[menuId] =
                                                                result['qty'];
                                                      selectedAddons[menuId] =
                                                          List<String>.from(
                                                            result['addons'] ??
                                                                [],
                                                          );
                                                    }
                                                  },
                                                ),
                                        ),
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Stack(
                            children: [
                              if (qty > 0)
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
                              Container(
                                margin: const EdgeInsets.only(left: 0),
                                child: CustomEmptyCard(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
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
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          m['image'] as String,
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
                                          m['name'] as String,
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
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text("Rp ${m['price']}"),
                                    trailing: SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: qty > 0
                                          ? Center(
                                              child: Text(
                                                '$qty',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFD53D3D),
                                                ),
                                              ),
                                            )
                                          : CustomButtonOval(
                                              text: "+",
                                              onPressed: () async {
                                                final result =
                                                    await showModalBottomSheet<
                                                      Map<String, dynamic>
                                                    >(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      shape: const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    24,
                                                                  ),
                                                            ),
                                                      ),
                                                      builder: (_) =>
                                                          MenuDetailPage(
                                                            menu: m,
                                                            initialQty: qty,
                                                          ),
                                                    );
                                                if (result != null) {
                                                  if (result['qty'] > 0) {
                                                    selectedMenus
                                                        .value = Map.of(
                                                      selectedMenus.value,
                                                    )..[menuId] = result['qty'];
                                                    selectedAddons[menuId] =
                                                        List<String>.from(
                                                          result['addons'] ??
                                                              [],
                                                        );
                                                  } else {
                                                    // Remove from cart if qty < 1
                                                    final updated = Map.of(
                                                      selectedMenus.value,
                                                    );
                                                    updated.remove(menuId);
                                                    selectedMenus.value =
                                                        updated;
                                                    selectedAddons.remove(
                                                      menuId,
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                    ),
                                    onTap: () async {
                                      final result =
                                          await showModalBottomSheet<
                                            Map<String, dynamic>
                                          >(
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(24),
                                                  ),
                                            ),
                                            builder: (_) => MenuDetailPage(
                                              menu: m,
                                              initialQty: qty,
                                            ),
                                          );
                                      if (result != null) {
                                        if (result['qty'] > 0) {
                                          selectedMenus.value = Map.of(
                                            selectedMenus.value,
                                          )..[menuId] = result['qty'];
                                          selectedAddons[menuId] =
                                              List<String>.from(
                                                result['addons'] ?? [],
                                              );
                                        } else {
                                          // Remove from cart if qty < 1
                                          final updated = Map.of(
                                            selectedMenus.value,
                                          );
                                          updated.remove(menuId);
                                          selectedMenus.value = updated;
                                          selectedAddons.remove(menuId);
                                        }
                                      }
                                    },
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
                      final etalase = resto['etalase'] as List<dynamic>? ?? [];
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
                              ...etalase.map(
                                (e) => ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      e['image'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    e['label'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
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
              final totalPrice = selected.entries.fold<int>(0, (a, e) {
                final menuId = e.key;
                final qty = e.value;
                final menu = menuMap[menuId];
                if (menu == null) return a;
                int basePrice = int.tryParse(menu['price'].toString()) ?? 0;
                int addonTotal = 0;
                final addons = selectedAddons[menuId] ?? [];
                for (final addonLabel in addons) {
                  final opt = (menu['addonOptions'] as List?)?.firstWhere(
                    (o) => o['label'] == addonLabel,
                    orElse: () => <String, Object>{},
                  );
                  if (opt != null && opt.isNotEmpty) {
                    addonTotal += int.tryParse(opt['price'].toString()) ?? 0;
                  }
                }
                return a + (basePrice + addonTotal) * qty;
              });
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CheckoutPage()),
                          );
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
}
