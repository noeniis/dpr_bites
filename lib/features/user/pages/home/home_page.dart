import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../common/data/dummy_restaurants.dart';
import '../../../../common/data/dummy_menus.dart';
import 'filter_category_sheet.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'filter_price_sheet.dart';
import 'package:dpr_bites/features/user/pages/search/search_page.dart';
import 'package:dpr_bites/features/user/pages/restaurant_detail/restaurant_detail_page.dart';

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
  List<Map<String, dynamic>> restos = List<Map<String, dynamic>>.from(dummyRestaurants);

    // Filter rating
    if (selectedRating != null && selectedRating == '4.5') {
      restos = restos.where((r) => (r['rating'] ?? 0) >= 4.5).toList();
    }
    // Filter price, dsb bisa lanjut di sini...

    return restos;
  }


  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Beranda",
            style: TextStyle(color: Color(0xFF602829), fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.white),
                label: const Text("Keranjang", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD53D3D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Search Field
                Row(
                  children: [
                    Expanded(
                      child: CustomInputField(
                        hintText: "Apa yang Anda Cari?",
                        controller: searchController,
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFD53D3D)),
                        onSubmitted: (val) {
                          print("onSubmitted: $val");
                          if (val.trim().isEmpty) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchPage(initialQuery: val.trim()),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      CustomFilterChip(
                        label: "Bintang 4.5+",
                        selected: selectedRating != null,
                        onTap: () {
                          setState(() {
                            selectedRating = selectedRating == null ? '4.5' : null;
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
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (_) => FilterPriceSheet(
                            initialValue: selectedPrice,)
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
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (_) => FilterCategorySheet(
                            initialValue: selectedCategory,)
                          );
                          setState(() {
                            selectedCategory = result;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // List restoran (scroll)
               Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 25),
                  itemCount: filteredRestaurants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, idx) {
                    final resto = filteredRestaurants[idx];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailPage(restaurantId: resto['id']),
                          ),
                        );
                      },
                      child: CustomEmptyCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resto['name'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 18),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${resto['rating']}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          "(${resto['ratingCount']})",
                                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.monetization_on, color: Colors.grey, size: 16),
                                        // Dummy range harga, nanti bisa dari menu
                                        Text(
                                          "Rp15.000 – Rp25.000",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resto['desc'] ?? '',
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
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
              )
              ],
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
          iconSize: 30, // Beranda aktif
          onTap: (i) {
            // TODO: Navigasi ke tab lain (keranjang, favorit, profil)
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: "Keranjang"),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Favorite"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
          ],
        ),
      ),
    );
  }
}
