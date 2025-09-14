import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/review_page_model.dart';

class ReviewService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> _getJwt() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (_) {
      return null;
    }
  }

  static Future<ReviewSubmitResult> submitReview(ReviewModel model) async {
    final jwt = await _getJwt();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
    };
    // Ensure we don't send user_id from client; server derives from token
    final bodyMap = Map<String, dynamic>.from(model.toJson());
    bodyMap.remove('id_users');
    final res = await http.post(
      Uri.parse('${getBaseUrl()}/add_ulasan.php'),
      headers: headers,
      body: jsonEncode(bodyMap),
    );
    if (res.statusCode != 200) {
      return ReviewSubmitResult(
        success: false,
        message: 'HTTP ${res.statusCode}',
      );
    }
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['success'] == true) {
        return ReviewSubmitResult(success: true, message: j['message']);
      }
      return ReviewSubmitResult(
        success: false,
        message: j is Map ? (j['message'] ?? 'Gagal') : 'Respon tidak valid',
      );
    } catch (_) {
      return ReviewSubmitResult(success: false, message: 'Respon tidak valid');
    }
  }
}
