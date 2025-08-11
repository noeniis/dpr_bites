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

    // Dummy breakdown rating dan review
    final rating = double.tryParse(resto['rating'].toString()) ?? 0.0;
    final ratingCount = resto['ratingCount'] ?? 0;
    final ratingBreakdown = [
      {'star': 5, 'count': 7},
      {'star': 4, 'count': 4},
      {'star': 3, 'count': 1},
      {'star': 2, 'count': 0},
      {'star': 1, 'count': 0},
    ];
    final reviews = [
      {
        'name': 'Ihsan a.',
        'pesanan': 'Nasi Goreng',
        'rating': 5,
      },
      {
        'name': 'Irma',
        'pesanan': 'Nasi Pecel, Nasi Goreng',
        'rating': 5,
      },
      {
        'name': 'Hasan M. I.',
        'pesanan': 'Nasi Goreng',
        'rating': 4,
      },
      {
        'name': 'Hanafi',
        'pesanan': 'Nasi Goreng',
        'rating': 3,
      },
      {
        'name': 'Ratnasari',
        'pesanan': 'Nasi Ayam Katsu',
        'rating': 5,
      },
    ];

    int maxBar = ratingBreakdown.map((e) => e['count'] as int).fold(0, (a, b) => a > b ? a : b);
    maxBar = maxBar == 0 ? 1 : maxBar;

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
              // Header rating besar
              CustomEmptyCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      // Bintang besar dan rating
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFD53D3D), width: 2),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.07),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                            Icon(Icons.star, color: Color(0xFFD53D3D), size: 36),
                            const SizedBox(height: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD53D3D)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Breakdown bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...ratingBreakdown.map((e) {
                              final star = e['star'] as int;
                              final count = e['count'] as int;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Text(star.toString(), style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 2),
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF2F2F2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: count / maxBar,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: star >= 4 ? Color(0xFFFFD600) : Color(0xFFD3D3D3),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(count.toString(), style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2, bottom: 8),
                child: Text(
                  "$ratingCount Review",
                  style: const TextStyle(color: Color(0xFFD53D3D), fontWeight: FontWeight.w500, fontSize: 15),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = reviews[i];
                    final name = r['name'] as String;
                    final pesanan = r['pesanan'] as String;
                    final rating = r['rating'] as int;
                    return CustomEmptyCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFE6F7EC),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A3A3A)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                ...List.generate(5, (idx) => Icon(
                                  idx < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                )),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Pesanan: $pesanan",
                              style: const TextStyle(fontSize: 13, color: Color(0xFF3A3A3A)),
                            ),
                          ],
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
    );
  }
}
