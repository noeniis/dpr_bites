import 'package:flutter/material.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/data/dummy_menus.dart';
import 'menu_detail_page.dart';
import 'rating_page.dart';
import 'widget/menu_card.dart';
import 'widget/menu_card_vertikal.dart';

class RestaurantDetailPage extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  const RestaurantDetailPage({required this.restaurant, super.key});

  @override
  Widget build(BuildContext context) {
    // Filter menu sesuai restoran
    final menus = dummyMenus.where((m) => m['restaurantId'] == restaurant['id']).toList();
    // Jika pakai flag 'recommended' di menu
    final recommendedMenus = menus.where((m) => m['recommended'] == true).toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF602829)),
            onPressed: () => Navigator.pop(context),
          ),
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
                onPressed: () {/* TODO: go to cart page */},
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER RESTO
                CustomEmptyCard(
                  width: double.infinity,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        restaurant['profilePic'],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      restaurant['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      "Rp15.000 - Rp35.000",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    trailing: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RatingPage(restaurant: restaurant),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE7EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 2),
                            Text(
                              "${restaurant['rating']}",
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD53D3D)),
                            ),
                            Text(
                              " (${restaurant['ratingCount']})",
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // DIREKOMENDASIKAN
                if (recommendedMenus.isNotEmpty) ...[
                  const Text("Direkomendasikan", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedMenus.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => MenuCardVertikal(
                        menu: recommendedMenus[i],
                        onTapAdd: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MenuDetailPage(menu: recommendedMenus[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // MENU LIST
                const Text("Menu", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),

                // Vertical spacing between cards
                ...menus.map((menu) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MenuCard(
                    menu: menu,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenuDetailPage(menu: menu),
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
