import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/data/dummy_restaurants.dart';
import '../../../../common/data/dummy_menus.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({this.initialQuery, super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  String? searchQuery;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      searchController.text = widget.initialQuery!;
      searchQuery = widget.initialQuery!;
    }
  }

  void doSearch(String q) {
    setState(() {
      searchQuery = q.trim();
    });
  }

  // List resto yg match query
  List<Map<String, dynamic>> get filteredRestaurants {
    if (searchQuery == null || searchQuery!.isEmpty) return [];
    return dummyRestaurants.where((r) {
      final name = (r['name'] as String).toLowerCase();
      final desc = (r['desc'] as String?)?.toLowerCase() ?? '';
      // Muncul kalau nama/desc Resto mengandung search, atau ada menu yg cocok
      final hasMenu = dummyMenus.any((m) =>
        m['restaurantId'] == r['id'] &&
        (m['name'] as String).toLowerCase().contains(searchQuery!.toLowerCase())
      );
      return name.contains(searchQuery!.toLowerCase())
          || desc.contains(searchQuery!.toLowerCase())
          || hasMenu;
    }).toList();
  }

  // Ambil menu yg cocok di suatu resto
  List<Map<String, dynamic>> menusForResto(String restoId) {
    if (searchQuery == null || searchQuery!.isEmpty) return [];
    return dummyMenus.where((m) =>
      m['restaurantId'] == restoId &&
      (m['name'] as String).toLowerCase().contains(searchQuery!.toLowerCase())
    ).toList();
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
          title: const Text(""),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                label: const Text("Keranjang", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD53D3D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                onPressed: () {},
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
                CustomInputField(
                  hintText: "Cari menu atau resto...",
                  controller: searchController,
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFD53D3D)),
                  onSubmitted: doSearch,
                ),
                const SizedBox(height: 14),

                if (searchQuery != null && searchQuery!.isNotEmpty)
                  Expanded(
                    child: filteredRestaurants.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ditemukan hasil untuk "$searchQuery"',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredRestaurants.length,
                            itemBuilder: (context, idx) {
                              final resto = filteredRestaurants[idx];
                              final menus = menusForResto(resto['id']);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomEmptyCard(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.asset(
                                                resto['profilePic'],
                                                width: 65,
                                                height: 65,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(resto['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                                      Text(" ${resto['rating']} (${resto['ratingCount']})", style: const TextStyle(fontSize: 14)),
                                                      const SizedBox(width: 8),
                                                      const Icon(Icons.monetization_on, color: Colors.grey, size: 14),
                                                      Text(" Rp15.000 - Rp35.000", style: const TextStyle(fontSize: 13)),
                                                    ],
                                                  ),
                                                  Text(resto['desc'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (menus.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 16),
                                        child: SizedBox(
                                          height: 180, // Atur sesuai tinggi kartu menu kamu
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: menus.length,
                                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                                            itemBuilder: (context, i) => _MenuGridCard(menu: menus[i]),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                            },
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuGridCard extends StatelessWidget {
  final Map<String, dynamic> menu;
  const _MenuGridCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    return CustomEmptyCard(
      width: 140,
      height: 145,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.asset(
              menu['image'],
              height: 68,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(menu['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                Text("${menu['price']}", style: const TextStyle(fontSize: 13)),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () {
                          // TODO: add to cart
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFD53D3D), width: 1.6),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Icon(Icons.add, size: 18, color: Color(0xFFD53D3D)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
