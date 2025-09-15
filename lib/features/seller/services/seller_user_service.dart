import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/common/utils/base_url.dart';

class SellerUserService {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> fetchGeraiStatusPengajuan(String idUsers) async {
    // idUsers parameter kept for backward compatibility but ignored.
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) return null;
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true && result['data'] != null) {
        return result['data']['status_pengajuan']?.toString();
      }
    }
    return null;
  }

  static Future<bool> updateStepSellerStatus(
    String idUsers, {
    int? step1,
    int? step2,
    int? step3,
  }) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) return false;
    final body = <String, String>{};
    if (step1 != null) body['step1'] = step1.toString();
    if (step2 != null) body['step2'] = step2.toString();
    if (step3 != null) body['step3'] = step3.toString();
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/update_step_seller.php'),
      headers: {'Authorization': 'Bearer $token'},
      body: body,
    );
    final res = jsonDecode(response.body);
    return res['success'] == true;
  }

  static Future<Map<String, dynamic>?> fetchUserById(String idUsers) async {
    // idUsers parameter kept for backward compatibility but ignored.
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) return null;
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_user_by_id.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        return result['data'] as Map<String, dynamic>;
      }
    }
    return null;
  }
}
