import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import '../../models/lainnya/ulasan_model.dart';

class UlasanService {
  static const _storage = FlutterSecureStorage();
  Future<int?> getGeraiId() async {
    final idUsers = await _storage.read(key: 'id_users');
    final token = await _storage.read(key: 'jwt_token');
    if (idUsers == null) return null;
    final resGerai = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
      body: {'id_users': idUsers},
    );
    if (resGerai.statusCode != 200) return null;
    final dataGerai = jsonDecode(resGerai.body);
    if (dataGerai['success'] != true || dataGerai['data'] == null || dataGerai['data']['id_gerai'] == null) return null;
    return dataGerai['data']['id_gerai'];
  }

  Future<Map<String, dynamic>> fetchUlasan() async {
    final idGerai = await getGeraiId();
    if (idGerai == null) throw 'Gagal ambil id_gerai';
    final token = await _storage.read(key: 'jwt_token');
    final res = await http.get(
      Uri.parse('${getBaseUrl()}/get_restaurant_ratings.php?id=$idGerai'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw 'Gagal fetch ulasan';
    final data = jsonDecode(res.body);
    if (data['success'] != true) throw 'Gagal fetch ulasan';
    final d = data['data'] ?? {};
    return {
      'rating': (d['rating'] ?? 0).toDouble(),
      'reviewCount': d['ratingCount'] ?? 0,
      'breakdown': (d['breakdown'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      'reviews': (d['reviews'] as List?)?.map((e) => UlasanModel.fromJson(e)).toList() ?? [],
    };
  }

  Future<bool> submitReply(int idUlasan, String reply) async {
    final token = await _storage.read(key: 'jwt_token');
    final res = await http.post(
      Uri.parse('${getBaseUrl()}/reply_ulasan.php'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id_ulasan': idUlasan, 'balasan': reply}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return true;
    } else {
      throw data['message'] ?? 'Gagal membalas';
    }
  }
}
