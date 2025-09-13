import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/home_page_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class HomePageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static Future<String?> _getJwt() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<HomeAddressFetchResult> fetchUserAddress() async {
    final jwt = await _getJwt();
    if (jwt == null || jwt.isEmpty) {
      return const HomeAddressFetchResult(
        hasAddress: false,
        address: HomeAddressModel(
          buildingName: 'Tambah Alamat Disini',
          detailPengantaran: '',
        ),
      );
    }
    try {
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/get_user_address.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );
      if (res.statusCode != 200) {
        return const HomeAddressFetchResult(
          hasAddress: false,
          address: HomeAddressModel(
            buildingName: 'Tambah Alamat Disini',
            detailPengantaran: '',
          ),
        );
      }
      final result = jsonDecode(res.body);
      if (result['success'] == true && result['has_address'] == true) {
        return HomeAddressFetchResult(
          hasAddress: true,
          address: HomeAddressModel(
            buildingName: (result['nama_gedung'] ?? 'Tambah Alamat Disini')
                .toString(),
            detailPengantaran: (result['detail_pengantaran'] ?? '').toString(),
          ),
        );
      } else {
        return const HomeAddressFetchResult(
          hasAddress: false,
          address: HomeAddressModel(
            buildingName: 'Tambah Alamat Disini',
            detailPengantaran: '',
          ),
        );
      }
    } catch (e) {
      return const HomeAddressFetchResult(
        hasAddress: false,
        address: HomeAddressModel(
          buildingName: 'Tambah Alamat Disini',
          detailPengantaran: '',
        ),
      );
    }
  }

  static Future<HomeRestaurantsFetchResult> fetchRestaurants({
    double? minRating,
    String? priceLabel,
  }) async {
    try {
      late final Uri url;
      if (priceLabel != null) {
        final encoded = Uri.encodeQueryComponent(priceLabel);
        url = Uri.parse(
          '${getBaseUrl()}/get_restaurants_by_price.php?price=$encoded',
        );
      } else if (minRating != null) {
        url = Uri.parse(
          '${getBaseUrl()}/get_restaurants_by_rating.php?min_rating=${minRating.toString()}',
        );
      } else {
        url = Uri.parse('${getBaseUrl()}/get_restaurants.php');
      }
      final res = await http.get(url, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          final List data = body['data'] as List? ?? [];
          final list = data
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (e) => HomeRestaurantModel.fromJson(
                  Map<String, dynamic>.from(e),
                ).toMap(),
              )
              .toList();
          return HomeRestaurantsFetchResult(restaurants: list);
        }
        return const HomeRestaurantsFetchResult(
          restaurants: [],
          error: 'Respon tidak valid',
        );
      }
      return HomeRestaurantsFetchResult(
        restaurants: const [],
        error: 'HTTP ${res.statusCode}',
      );
    } catch (e) {
      return HomeRestaurantsFetchResult(
        restaurants: const [],
        error: e.toString(),
      );
    }
  }
}
