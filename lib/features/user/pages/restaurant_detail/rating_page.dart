import 'package:flutter/material.dart';
import 'package:dpr_bites/common/data/dummy_restaurants.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';

class RestaurantRatingPage extends StatelessWidget {
  final String restaurantId;
  const RestaurantRatingPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final resto = dummyRestaurants.firstWhere((r) => r['id'] == restaurantId) as Map<String, dynamic>;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Ulasan Restoran"),
          leading: BackButton(color: Colors.pink),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomEmptyCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          resto['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 2),
                            Text("${resto['rating']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            Text("(${resto['ratingCount']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const Text(" ulasan)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    CustomEmptyCard(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: const Text("Mahasiswa A"),
                        subtitle: const Text("Makanannya enak dan murah!"),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomEmptyCard(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: const Text("Mahasiswa B"),
                        subtitle: const Text("Pelayanan cepat, recommended."),
                      ),
                    ),
                    // Tambahkan dummy review lain jika perlu
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
