import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';

class UlasanPage extends StatelessWidget {
  const UlasanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data ulasan
    final double rating = 4.8;
    final int reviewCount = 10;
    final Map<int, int> ratingDist = {5: 7, 4: 2, 3: 1, 2: 0, 1: 0};
    final List<Map<String, dynamic>> menuReviews = [
      {
        'name': 'Nasi Pecel',
        'image': 'lib/assets/images/pecel.jpeg',
        'sales': 3,
        'review': 3,
        'rating': 4,
      },
      {
        'name': 'Nasi Goreng',
        'image': 'lib/assets/images/nasi_goreng.jpeg',
        'sales': 2,
        'review': 2,
        'rating': 4,
      },
      {
        'name': 'Paket Ayam Bakar',
        'image': 'lib/assets/images/kantinmakmur.jpeg',
        'sales': 5,
        'review': 5,
        'rating': 5,
      },
    ];

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.red),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Ulasan', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card rating summary
              CustomEmptyCard(
                margin: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 32),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$rating', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                              const Text('/5', style: TextStyle(fontSize: 15)),
                              Text('$reviewCount Review', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Rating distribution
                      ...List.generate(5, (i) {
                        int star = 5 - i;
                        int count = ratingDist[star] ?? 0;
                        double percent = reviewCount > 0 ? count / reviewCount : 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text('$star', style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: Colors.grey[200],
                                  color: Colors.amber,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const Text('Ulasan menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              ...menuReviews.map((menu) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomEmptyCard(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              menu['image'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(menu['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                Text('${menu['sales']} penjualan', style: const TextStyle(fontSize: 13)),
                                Text('${menu['review']} Review', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text('${menu['rating']}/5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(width: 2),
                                  ...List.generate(5, (i) => Icon(
                                    Icons.star,
                                    size: 15,
                                    color: i < menu['rating'] ? Colors.amber : Colors.grey[300],
                                  )),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.chevron_right, color: Colors.black38),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
