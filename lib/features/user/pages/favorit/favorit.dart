import 'package:flutter/material.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/profile/profile_page.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  String? userId;
  Map<String, int> qtyMap = {};
  String? favoritesDocId;
  List<String> favoriteMenuIds = [];
  List<Map<String, dynamic>> favoriteMenus = [];
  Map<String, Map<String, dynamic>> restaurantCache = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndFavorites();
  }

  Future<void> _loadUserAndFavorites() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    // Get favorites document for this user
    final favSnap = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (favSnap.docs.isEmpty) {
      favoriteMenuIds = [];
      favoritesDocId = null;
      favoriteMenus = [];
      setState(() {
        isLoading = false;
      });
      return;
    }
    final favDoc = favSnap.docs.first;
    favoritesDocId = favDoc.id;
    favoriteMenuIds = List<String>.from(favDoc['menuIds'] ?? []);
    // Fetch menu details
    if (favoriteMenuIds.isNotEmpty) {
      final menuSnap = await FirebaseFirestore.instance
          .collection('menus')
          .where('id', whereIn: favoriteMenuIds)
          .get();
      favoriteMenus = menuSnap.docs.map((d) => d.data()).toList();
    } else {
      favoriteMenus = [];
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> getRestaurant(String restaurantId) async {
    if (restaurantCache.containsKey(restaurantId)) {
      return restaurantCache[restaurantId];
    }
    // Get store
    final storeSnap = await FirebaseFirestore.instance
        .collection('stores')
        .where('userId', isEqualTo: restaurantId)
        .limit(1)
        .get();
    if (storeSnap.docs.isEmpty) return null;
    final store = storeSnap.docs.first.data();
    // Get store detail
    final detailSnap = await FirebaseFirestore.instance
        .collection('stores_detail')
        .where('userId', isEqualTo: restaurantId)
        .limit(1)
        .get();
    Map<String, dynamic>? detail;
    if (detailSnap.docs.isNotEmpty) {
      detail = detailSnap.docs.first.data();
    }
    final result = {
      'name': store['storeName'] ?? '',
      'rating': store['rating'] ?? 0,
      'bannerUrl': detail?['bannerUrl'] ?? '',
      'openTime': detail?['openTime'] ?? '',
      'closeTime': detail?['closeTime'] ?? '',
      'menu': detail?['menu'] ?? '',
    };
    restaurantCache[restaurantId] = result;
    return result;
  }

  Future<void> toggleFavorite(String menuId) async {
    if (userId == null) return;
    if (favoritesDocId == null) {
      // Create new favorites document
      final docRef = await FirebaseFirestore.instance
          .collection('favorites')
          .add({
            'userId': userId,
            'menuIds': [menuId],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      favoritesDocId = docRef.id;
    } else {
      final docRef = FirebaseFirestore.instance
          .collection('favorites')
          .doc(favoritesDocId);
      if (favoriteMenuIds.contains(menuId)) {
        await docRef.update({
          'menuIds': FieldValue.arrayRemove([menuId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'menuIds': FieldValue.arrayUnion([menuId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await _loadUserAndFavorites();
  }

  void addQty(String menuId) {
    setState(() {
      qtyMap[menuId] = (qtyMap[menuId] ?? 0) + 1;
    });
  }

  void removeQty(String menuId) {
    setState(() {
      if ((qtyMap[menuId] ?? 0) > 0) {
        qtyMap[menuId] = qtyMap[menuId]! - 1;
      }
    });
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
            "Favorit Anda",
            style: TextStyle(
              color: AppTheme.textColor,
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
                  backgroundColor: AppTheme.primaryColor,
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : favoriteMenus.isEmpty
              ? const Center(child: Text('Belum ada menu favorit'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8,
                  ),
                  itemCount: favoriteMenus.length,
                  itemBuilder: (context, idx) {
                    final menu = favoriteMenus[idx];
                    final qty = qtyMap[menu['id']] ?? 0;
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: getRestaurant(menu['userId']),
                      builder: (context, snapshot) {
                        final resto = snapshot.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card menu favorit
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: Column(
                                children: [
                                  // Header restoran dan rating
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                resto?['name'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              if ((resto?['menu'] ?? '')
                                                  .toString()
                                                  .isNotEmpty)
                                                Text(
                                                  resto?['menu'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              // ...location removed...
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 18,
                                                ),
                                                Text(
                                                  resto?['rating'].toString() ??
                                                      '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.monetization_on,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                                Text(
                                                  "Rp15.000 - Rp35.000",
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Garis abu-abu atas (tebal normal)
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    height: 1,
                                    color: const Color(0xFFD9D9D9),
                                  ),
                                  // Menu favorit
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                menu['name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                menu['description'],
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Rp${menu['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: () async {
                                                  await toggleFavorite(
                                                    menu['id'],
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.favorite,
                                                  color: AppTheme.primaryColor,
                                                  size: 24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                menu['imageUrl'],
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: 89,
                                              height: 22,
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  side: const BorderSide(
                                                    color: Color(0xFFB03056),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                onPressed: () {
                                                  addQty(menu['id']);
                                                  // TODO: otomatis masuk keranjang
                                                },
                                                child: const Text(
                                                  "Tambah",
                                                  style: TextStyle(
                                                    color: Color(0xFFB03056),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Garis abu-abu bawah (sangat tipis, lebar lebih kecil)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      width: 60,
                                      height: 0.25,
                                      color: const Color(0xFFD9D9D9),
                                      margin: const EdgeInsets.only(right: 16),
                                    ),
                                  ),
                                  // Jarak antar menu
                                  Container(
                                    height: 2,
                                    color: const Color.fromARGB(
                                      255,
                                      199,
                                      199,
                                      199,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFF9D3D3).withOpacity(0.85),
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.black54,
          currentIndex: 2,
          selectedFontSize: 14,
          unselectedFontSize: 13,
          iconSize: 30,
          onTap: (i) {
            if (i == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            } else if (i == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            } else if (i == 2) {
              // Sudah di halaman favorit
            } else if (i == 3) {
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
