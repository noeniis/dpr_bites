import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';

class RatingPage extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  const RatingPage({required this.restaurant, super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy reviews
    final reviews = [
      {"name": "Ilham a.", "menu": "Nasi Goreng", "rating": 5, "comment": ""},
      {"name": "Irma", "menu": "Nasi Pecel, Nasi Goreng", "rating": 4, "comment": ""},
      // dst
    ];

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
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              // Summary rating
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0,2)),
                      ]
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 36),
                        Text(
                          "${restaurant['rating']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFFD53D3D)),
                        ),
                        Text("${restaurant['ratingCount']} Review", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  // Bisa tambahkan barchart rating di sini kalau mau (lihat mockup)
                ],
              ),
              const SizedBox(height: 16),

              ...reviews.map((r) {
              final rev = r as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(child: Text(rev['name']?[0] ?? '?')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(rev['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                ...List.generate(
                                  (rev['rating'] ?? 0) as int,
                                  (i) => const Icon(Icons.star, color: Colors.amber, size: 16),
                                ),
                              ],
                            ),
                            Text("Pesanan: ${rev['menu'] ?? ''}", style: const TextStyle(fontSize: 12)),
                            if ((rev['comment'] ?? '') != "") Text(rev['comment']),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),
            ],
          ),
        ),
      ),
    );
  }
}
