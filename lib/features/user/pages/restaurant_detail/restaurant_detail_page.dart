import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final ValueNotifier<Map<String, int>> selectedMenus = ValueNotifier({});
  Map<String, dynamic>? resto;
  List<Map<String, dynamic>> menus = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRestoData();
  }

  Future<void> fetchRestoData() async {
    setState(() {
      isLoading = true;
    });
    final storesSnap = await FirebaseFirestore.instance
        .collection('stores')
        .where('userId', isEqualTo: widget.restaurantId)
        .get();
    final storesDetailSnap = await FirebaseFirestore.instance
        .collection('stores_detail')
        .where('userId', isEqualTo: widget.restaurantId)
        .get();
    final menusSnap = await FirebaseFirestore.instance
        .collection('menus')
        .where('userId', isEqualTo: widget.restaurantId)
        .get();

    final store = storesSnap.docs.isNotEmpty
        ? storesSnap.docs.first.data()
        : {};
    final detail = storesDetailSnap.docs.isNotEmpty
        ? storesDetailSnap.docs.first.data()
        : {};
    menus = menusSnap.docs
        .map((d) => d.data() as Map<String, dynamic>)
        .toList();

    int minPrice = 0, maxPrice = 0;
    if (menus.isNotEmpty) {
      minPrice = menus
          .map((m) => m['price'] as int)
          .reduce((a, b) => a < b ? a : b);
      maxPrice = menus
          .map((m) => m['price'] as int)
          .reduce((a, b) => a > b ? a : b);
    }
    resto = {
      'name': store['storeName'] ?? '',
      'bannerUrl': detail['bannerUrl'] ?? '',
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'operationalDays': detail['operationalDays'] ?? [],
      'openTime': detail['openTime'] ?? '',
      'closeTime': detail['closeTime'] ?? '',
      'rating': 0,
      'ratingCount': 0,
    };
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final openTime = resto?['openTime']?.toString() ?? '';
    final closeTime = resto?['closeTime']?.toString() ?? '';
    final operationalHourText = (openTime.isNotEmpty && closeTime.isNotEmpty)
        ? 'Jam Operasional: $openTime - $closeTime'
        : '';
    if (isLoading || resto == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
                            child:
                                (resto != null &&
                                    resto!['bannerUrl'] != null &&
                                    resto!['bannerUrl'].toString().isNotEmpty)
                                ? Image.network(
                                    resto!['bannerUrl'],
                                    width: double.infinity,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: double.infinity,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 32),
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 32),
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
                                      resto?['name']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resto?['minPrice'] != null &&
                                              resto?['maxPrice'] != null &&
                                              resto?['minPrice'] > 0 &&
                                              resto?['maxPrice'] > 0
                                          ? "Rp${resto?['minPrice']} - Rp${resto?['maxPrice']}"
                                          : '',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    operationalHourText.isNotEmpty
                                        ? Text(
                                            operationalHourText,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
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
                                      "${resto?['rating'] ?? 0}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "(${resto?['ratingCount'] ?? 0})",
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
                    itemCount: menus.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final m = menus[i];
                      final menuId = m['id']?.toString() ?? '';
                      final qty = selected[menuId] ?? 0;
                      return SizedBox(
                        width: 140,
                        child: CustomEmptyCard(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final result = await showModalBottomSheet<int>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (_) =>
                                      MenuDetailPage(menu: m, initialQty: qty),
                                );
                                if (result != null && result > 0) {
                                  selectedMenus.value = Map.of(
                                    selectedMenus.value,
                                  )..[menuId] = result;
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        m['imageUrl'] != null &&
                                            m['imageUrl'].toString().isNotEmpty
                                        ? Image.network(
                                            m['imageUrl'],
                                            width: 124,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                                  width: 124,
                                                  height: 80,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 32,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            width: 124,
                                            height: 80,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image,
                                              size: 32,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Rp ${m['price']}",
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
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
                                                          int
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
                                                        result > 0) {
                                                      selectedMenus.value =
                                                          Map.of(
                                                            selectedMenus.value,
                                                          )..[menuId] = result;
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
                // DAFTAR MENU
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Menu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                ...menus.map((m) {
                  final menuId = m['id']?.toString() ?? '';
                  final qty = selected[menuId] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: CustomEmptyCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              m['imageUrl'] != null &&
                                  m['imageUrl'].toString().isNotEmpty
                              ? Image.network(
                                  m['imageUrl'],
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 24),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 24),
                                ),
                        ),
                        title: Text(
                          m['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                                        await showModalBottomSheet<int>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
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
                                    if (result != null && result > 0) {
                                      selectedMenus.value = Map.of(
                                        selectedMenus.value,
                                      )..[menuId] = result;
                                    }
                                  },
                                ),
                        ),
                        onTap: () async {
                          final result = await showModalBottomSheet<int>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (_) =>
                                MenuDetailPage(menu: m, initialQty: qty),
                          );
                          if (result != null && result > 0) {
                            selectedMenus.value = Map.of(selectedMenus.value)
                              ..[menuId] = result;
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButton: ValueListenableBuilder<Map<String, int>>(
        valueListenable: selectedMenus,
        builder: (context, selected, _) {
          final totalQty = selected.values.fold<int>(0, (a, b) => a + b);
          final totalPrice = selected.entries.fold<int>(0, (a, e) {
            final menu = menus
                .where((m) => m['id']?.toString() == e.key)
                .toList();
            if (menu.isEmpty) return a;
            return a +
                (int.tryParse(menu.first['price'].toString()) ?? 0) * e.value;
          });
          if (totalQty == 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: Colors.pink.shade200,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CheckoutPage()),
              );
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: Text(
              "$totalQty Hidangan - ${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
