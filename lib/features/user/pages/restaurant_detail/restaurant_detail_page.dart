import 'package:flutter/material.dart';
import 'package:dpr_bites/common/data/dummy_restaurants.dart';
import 'package:dpr_bites/common/data/dummy_menus.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'rating_page.dart';
import 'menu_detail_page.dart';

class RestaurantDetailPage extends StatelessWidget {
  final String restaurantId;
  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final resto = dummyRestaurants.firstWhere((r) => r['id'] == restaurantId) as Map<String, dynamic>;
    final menus = dummyMenus.where((m) => m['restaurantId'] == restaurantId).toList();
    final recommendedMenus = menus.where((m) => (m as Map<String, dynamic>)['recommended'] == true).take(2).toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(""),
          leading: BackButton(color: Colors.pink),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.pink),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            CustomEmptyCard(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        resto['profilePic'],
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(resto['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 32,
                        child: CustomButtonOval(
                          text: "Lihat Ulasan",
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantRatingPage(restaurantId: restaurantId),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Direkomendasikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedMenus.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final m = recommendedMenus[i] as Map<String, dynamic>;
                  return SizedBox(
                    width: 140,
                    child: CustomEmptyCard(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (_) => MenuDetailPage(menu: m),
                          ),
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
                                      child: CustomButtonOval(
                                        text: "+",
                                        onPressed: () => showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                          ),
                                          builder: (_) => MenuDetailPage(menu: m),
                                        ),
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
            const Text('Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...menus.map((menu) {
              final m = menu as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
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
                      child: CustomButtonOval(
                        text: "+",
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => MenuDetailPage(menu: m),
                        ),
                      ),
                    ),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => MenuDetailPage(menu: m),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}