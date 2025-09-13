import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/rating_page_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RatingPageService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> _getJwt() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (_) {
      return null;
    }
  }

  static Future<RatingPageFetchResult> fetchRatings(String restaurantId) async {
    try {
      final jwt = await _getJwt();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
      };
      final res = await http.get(
        Uri.parse(
          '${getBaseUrl()}/get_restaurant_ratings.php?id=${Uri.encodeQueryComponent(restaurantId)}',
        ),
        headers: headers,
      );
      if (res.statusCode != 200) {
        return RatingPageFetchResult(
          rating: 0,
          ratingCount: 0,
          breakdown: const [
            {'star': 5, 'count': 0},
            {'star': 4, 'count': 0},
            {'star': 3, 'count': 0},
            {'star': 2, 'count': 0},
            {'star': 1, 'count': 0},
          ],
          reviews: const [],
          error: 'HTTP ${res.statusCode}',
        );
      }
      final body = jsonDecode(res.body);
      if (body is! Map || body['success'] != true) {
        return const RatingPageFetchResult(
          rating: 0,
          ratingCount: 0,
          breakdown: [
            {'star': 5, 'count': 0},
            {'star': 4, 'count': 0},
            {'star': 3, 'count': 0},
            {'star': 2, 'count': 0},
            {'star': 1, 'count': 0},
          ],
          reviews: [],
          error: 'Data tidak valid',
        );
      }
      final data = body['data'] as Map? ?? {};
      final br =
          (data['breakdown'] as List?)?.whereType<Map>().toList() ?? const [];
      final rev =
          (data['reviews'] as List?)?.whereType<Map>().toList() ?? const [];
      final geraiName =
          (data['gerai_name']?.toString().trim().isNotEmpty ?? false)
          ? data['gerai_name'].toString().trim()
          : null;
      final rating = (data['rating'] is num)
          ? (data['rating'] as num).toDouble()
          : 0.0;
      final ratingCount = (data['ratingCount'] is num)
          ? (data['ratingCount'] as num).toInt()
          : 0;
      final normalizedBr = br
          .map((e) => {'star': e['star'] ?? 0, 'count': e['count'] ?? 0})
          .toList();
      final normalizedRev = rev
          .map(
            (e) => {
              'name': e['name'] ?? 'Pengguna',
              'pesanan': e['pesanan'] ?? '',
              'rating': e['rating'] ?? 0,
              'komentar': e['komentar'] ?? '',
              'photo': e['photo'],
              'tanggal': e['tanggal'] ?? '',
              'balasan': e['balasan'] ?? '',
            },
          )
          .toList();
      return RatingPageFetchResult(
        rating: rating,
        ratingCount: ratingCount,
        breakdown: normalizedBr.isEmpty
            ? const [
                {'star': 5, 'count': 0},
                {'star': 4, 'count': 0},
                {'star': 3, 'count': 0},
                {'star': 2, 'count': 0},
                {'star': 1, 'count': 0},
              ]
            : normalizedBr,
        reviews: normalizedRev,
        geraiName: geraiName,
      );
    } catch (e) {
      return RatingPageFetchResult(
        rating: 0,
        ratingCount: 0,
        breakdown: const [
          {'star': 5, 'count': 0},
          {'star': 4, 'count': 0},
          {'star': 3, 'count': 0},
          {'star': 2, 'count': 0},
          {'star': 1, 'count': 0},
        ],
        reviews: const [],
        error: e.toString(),
      );
    }
  }
}
