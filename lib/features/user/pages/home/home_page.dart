import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../common/data/dummy_restaurants.dart';
import '../../../../common/data/dummy_address.dart';
import '../../../../common/data/address_store.dart';
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

class _HomePageState extends State<HomePage> {
  String? searchQuery;
  String? selectedRating;
  String? selectedPrice;
  String? selectedCategory;
  final searchController = TextEditingController();

  // Dummy: filter function
  List<Map<String, dynamic>> get filteredRestaurants {
    List<Map<String, dynamic>> restos = List<Map<String, dynamic>>.from(
      dummyRestaurants,
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
          preferredSize: const Size.fromHeight(
            90,
          ), // Ubah tinggi AppBar di sini
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 90, // Pastikan tinggi toolbar juga diubah
            title: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                final current = store.selected;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    // Open AddressPage to pick address; update store when returned
                    final result = await Navigator.pushNamed(
                      context,
                      '/address',
                    );
                    if (result is DummyAddress) {
                      store.select(result);
                    }
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
                                  current.namaGedung,
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
                          Text(
                            current.detailPengantaran,
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SearchPage(initialQuery: val.trim()),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      children: [
                        CustomFilterChip(
                          label: "Bintang 4.5+",
                          selected: selectedRating != null,
                          onTap: () {
                            setState(() {
                              selectedRating = selectedRating == null
                                  ? '4.5'
                                  : null;
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        CustomFilterChip(
                          label: "Rentang harga",
                          selected: selectedPrice != null,
                          onTap: () async {
                            // Modal filter harga
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
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 25),
                      itemCount: filteredRestaurants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final resto = filteredRestaurants[idx];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantDetailPage(
                                  restaurantId: resto['id'],
                                ),
                              ),
                            );
                          },
                          child: CustomEmptyCard(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      resto['profilePic'],
                                      width: 75,
                                      height: 75,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resto['name'],
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
                                                fontWeight: FontWeight.bold,
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
                                            // Dummy range harga, nanti bisa dari menu
                                            Text(
                                              "Rp15.000 – Rp25.000",
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          resto['desc'] ?? '',
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
