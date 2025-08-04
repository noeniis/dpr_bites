import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'filter_category_sheet.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'filter_price_sheet.dart';
import 'package:dpr_bites/features/user/pages/search/search_page.dart';
import 'package:dpr_bites/features/user/pages/restaurant_detail/restaurant_detail_page.dart';
import 'package:dpr_bites/features/user/pages/profile/profile_page.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  Future<void> fetchRestaurants() async {
    setState(() {
      isLoading = true;
    });
    final storesSnap = await FirebaseFirestore.instance
        .collection('stores')
        .get();
    final storesDetailSnap = await FirebaseFirestore.instance
        .collection('stores_detail')
        .get();
    final menusSnap = await FirebaseFirestore.instance
        .collection('menus')
        .get();

    // Map stores_detail by userId
    final detailMap = {
      for (var d in storesDetailSnap.docs) d['userId']: d.data(),
    };
    // Group menus by userId
    final menuMap = <String, List<Map<String, dynamic>>>{};
    for (var m in menusSnap.docs) {
      final uid = m['userId'];
      menuMap.putIfAbsent(uid, () => []).add(m.data());
    }

    restaurants = storesSnap.docs.map((doc) {
      final store = doc.data();
      final userId = store['userId'];
      final detail = detailMap[userId] ?? {};
      final menus = menuMap[userId] ?? [];
      // Range harga
      int minPrice = 0, maxPrice = 0;
      if (menus.isNotEmpty) {
        minPrice = menus
            .map((m) => m['price'] as int)
            .reduce((a, b) => a < b ? a : b);
        maxPrice = menus
            .map((m) => m['price'] as int)
            .reduce((a, b) => a > b ? a : b);
      }
      return {
        'id': userId,
        'name': store['storeName'] ?? '',
        'profilePic': detail['listingUrl'] ?? '',
        'rating': 0,
        'ratingCount': 0,
        'desc': detail['menu'] ?? '',
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'menus': menus,
      };
    }).toList();
    setState(() {
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredRestaurants {
    List<Map<String, dynamic>> restos = List<Map<String, dynamic>>.from(
      restaurants,
    );
    // Filter rating
    if (selectedRating != null && selectedRating == '4.5') {
      restos = restos.where((r) => (r['rating'] ?? 0) >= 4.5).toList();
    }
    // Filter price
    if (selectedPrice != null &&
        selectedPrice!.isNotEmpty &&
        selectedPrice != 'Tidak ada data harga') {
      String label = selectedPrice!;
      int? min, max;
      int parseHarga(String s) {
        return int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }

      if (label.startsWith('<')) {
        min = null;
        max = parseHarga(label.replaceAll('<', ''));
      } else if (label.startsWith('>')) {
        // Untuk '>30.000', min harus 30001
        min = parseHarga(label.replaceAll('>', '')) + 1;
        max = null;
      } else if (label.contains('–')) {
        var parts = label.split('–');
        String left = parts[0].trim();
        String right = parts[1].trim();
        // Untuk '20.001 – 30.000', min=20001, max=30000
        if (left.contains('.001')) {
          min = parseHarga(left);
        } else {
          min = parseHarga(left);
        }
        max = parseHarga(right);
      }
      restos = restos.where((r) {
        final menus = r['menus'] as List<dynamic>? ?? [];
        return menus.any((m) {
          final price = m['price'] as int? ?? 0;
          if (min != null && max != null) {
            return price >= min && price <= max;
          } else if (min == null && max != null) {
            return price <= max;
          } else if (min != null && max == null) {
            return price >= min;
          }
          return false;
        });
      }).toList();
    }
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
          automaticallyImplyLeading: false,
          title: const Text(
            "Beranda",
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
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

                const SizedBox(height: 18),

                // List restoran (scroll)
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 25),
                          itemCount: filteredRestaurants.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 18),
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
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            resto['profilePic'] != null &&
                                                resto['profilePic']
                                                    .toString()
                                                    .isNotEmpty
                                            ? Image.network(
                                                resto['profilePic'],
                                                width: 75,
                                                height: 75,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    Container(
                                                      width: 75,
                                                      height: 75,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.image,
                                                        size: 32,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                width: 75,
                                                height: 75,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 32,
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
                                                Text(
                                                  resto['minPrice'] > 0 &&
                                                          resto['maxPrice'] > 0
                                                      ? "Rp${resto['minPrice']} – Rp${resto['maxPrice']}"
                                                      : "",
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
