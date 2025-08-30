import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RestaurantRatingPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantRatingPage({super.key, required this.restaurantId});

  @override
  State<RestaurantRatingPage> createState() => _RestaurantRatingPageState();
}

class _RestaurantRatingPageState extends State<RestaurantRatingPage> {
  double rating = 0.0;
  int ratingCount = 0;
  List<Map<String, dynamic>> breakdown = [
    {'star': 5, 'count': 0},
    {'star': 4, 'count': 0},
    {'star': 3, 'count': 0},
    {'star': 2, 'count': 0},
    {'star': 1, 'count': 0},
  ];
  List<Map<String, dynamic>> reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
        'http://10.0.2.2/dpr_bites_api/get_restaurant_ratings.php?id=${Uri.encodeQueryComponent(widget.restaurantId)}',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final data = body['data'] as Map? ?? {};
          final br =
              (data['breakdown'] as List?)?.whereType<Map>().toList() ??
              breakdown;
          final rev =
              (data['reviews'] as List?)?.whereType<Map>().toList() ?? [];
          setState(() {
            rating = (data['rating'] is num)
                ? (data['rating'] as num).toDouble()
                : 0.0;
            ratingCount = (data['ratingCount'] is num)
                ? (data['ratingCount'] as num).toInt()
                : 0;
            breakdown = br
                .map((e) => {'star': e['star'] ?? 0, 'count': e['count'] ?? 0})
                .toList();
            reviews = rev
                .map(
                  (e) => {
                    'name': e['name'] ?? 'Pengguna',
                    'pesanan': e['pesanan'] ?? '',
                    'rating': e['rating'] ?? 0,
                    'komentar': e['komentar'] ?? '',
                    'photo': e['photo'],
                  },
                )
                .toList();
            _loading = false;
          });
          return;
        }
      }
      setState(() {
        _loading = false;
        _error = 'Gagal memuat';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int maxBar = breakdown
        .map((e) => (e['count'] as int))
        .fold(0, (a, b) => a > b ? a : b);
    maxBar = maxBar == 0 ? 1 : maxBar;

    final bodyContent = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                const SizedBox(height: 8),
                CustomButtonOval(text: 'Coba Lagi', onPressed: _fetch),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomEmptyCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFD53D3D),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.07),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFD53D3D),
                              size: 36,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD53D3D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...breakdown.map((e) {
                              final star = e['star'] as int;
                              final count = e['count'] as int;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      star.toString(),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F2F2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: count / maxBar,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: star >= 4
                                                  ? const Color(0xFFFFD600)
                                                  : const Color(0xFFD3D3D3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      count.toString(),
                                      style: const TextStyle(fontSize: 13),
                                    ),
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
                  style: const TextStyle(
                    color: Color(0xFFD53D3D),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                child: reviews.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada ulasan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final r = reviews[i];
                          final name = r['name'] as String? ?? '';
                          final pesanan = r['pesanan'] as String? ?? '';
                          final rStar = r['rating'] as int? ?? 0;
                          final komentar = (r['komentar'] as String? ?? '')
                              .trim();
                          final photo = r['photo'];
                          return CustomEmptyCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFFE6F7EC,
                                        ),
                                        backgroundImage:
                                            photo != null &&
                                                (photo as String).isNotEmpty
                                            ? (photo.startsWith('http')
                                                  ? NetworkImage(photo)
                                                  : NetworkImage(
                                                      'http://10.0.2.2/dpr_bites_api/' +
                                                          photo,
                                                    ))
                                            : null,
                                        child:
                                            (photo == null ||
                                                (photo as String).isEmpty)
                                            ? Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF3A3A3A),
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (idx) => Icon(
                                          idx < rStar
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Pesanan: $pesanan",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF3A3A3A),
                                    ),
                                  ),
                                  if (komentar.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      komentar,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Ulasan Restoran"),
          leading: const BackButton(color: Colors.pink),
        ),
        body: Padding(padding: const EdgeInsets.all(16.0), child: bodyContent),
      ),
    );
  }
}
