import 'package:flutter/material.dart';
import 'package:dpr_bites/common/data/dummy_restaurants.dart';
import 'package:dpr_bites/common/data/dummy_menus.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'rating_page.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'menu_detail_page.dart';


class RestaurantDetailPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final ValueNotifier<Map<String, int>> selectedMenus = ValueNotifier({});

  @override
  Widget build(BuildContext context) {
    final resto = dummyRestaurants.firstWhere((r) => r['id'] == widget.restaurantId);
    final menus = dummyMenus.where((m) => m['restaurantId'] == widget.restaurantId).toList();
    final recommendedMenus = menus.where((m) => m['recommended'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              // TODO: Navigasi ke halaman cart
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
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
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
                                    Text(resto['name'].toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text("Rp15.000 - Rp35.000", style: const TextStyle(color: Colors.grey)),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 18),
                                    const SizedBox(width: 2),
                                    Text("${resto['rating']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 2),
                                    Text("(${resto['ratingCount']})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                                    builder: (_) => RestaurantRatingPage(restaurantId: widget.restaurantId),
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
                  child: Text('Direkomendasikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                final result = await showModalBottomSheet<int>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  builder: (_) => MenuDetailPage(menu: m, initialQty: qty),
                                );
                                if (result != null && result > 0) {
                                  selectedMenus.value = Map.of(selectedMenus.value)..[menuId] = result;
                                }
                              },
                              child: Column(
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
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text("Rp ${m['price']}", style: const TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.pink.shade50,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: qty > 0
                                              ? Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD53D3D))))
                                              : CustomButtonOval(
                                                  text: "+",
                                                  onPressed: () async {
                                                    final result = await showModalBottomSheet<int>(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      backgroundColor: Colors.transparent,
                                                      shape: const RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                                      ),
                                                      builder: (_) => MenuDetailPage(menu: m, initialQty: qty),
                                                    );
                                                    if (result != null && result > 0) {
                                                      selectedMenus.value = Map.of(selectedMenus.value)..[menuId] = result;
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
                  child: Text('Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                ...menus.map((menu) {
                  final m = menu as Map<String, dynamic>;
                  final menuId = m['id'].toString();
                  final qty = selected[menuId] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: CustomEmptyCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(m['image'], width: 48, height: 48, fit: BoxFit.cover),
                        ),
                        title: Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Rp ${m['price']}"),
                        trailing: SizedBox(
                          width: 36,
                          height: 36,
                          child: qty > 0
                              ? Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD53D3D))))
                              : CustomButtonOval(
                                  text: "+",
                                  onPressed: () async {
                                    final result = await showModalBottomSheet<int>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      builder: (_) => MenuDetailPage(menu: m, initialQty: qty),
                                    );
                                    if (result != null && result > 0) {
                                      selectedMenus.value = Map.of(selectedMenus.value)..[menuId] = result;
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
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (_) => MenuDetailPage(menu: m, initialQty: qty),
                          );
                          if (result != null && result > 0) {
                            selectedMenus.value = Map.of(selectedMenus.value)..[menuId] = result;
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
            final menu = menus.where((m) => m['id'].toString() == e.key).cast<Map<String, dynamic>?>().toList();
            if (menu.isEmpty) return a;
            return a + (int.tryParse(menu.first?['price'].toString() ?? '0') ?? 0) * e.value;
          });
          if (totalQty == 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: Colors.pink.shade200,
            onPressed: () {
              // TODO: Navigasi ke halaman pemesanan
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: Text(
              "$totalQty Hidangan - ${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}