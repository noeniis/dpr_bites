import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/review_page_model.dart';

class ReviewService {
  static Future<int?> getUserIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = ['id_users', 'id_user', 'user_id'];
      for (final k in keys) {
        if (prefs.containsKey(k)) {
          final v = prefs.get(k);
          if (v != null) return int.tryParse(v.toString());
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<ReviewSubmitResult> submitReview(ReviewModel model) async {
    final res = await http.post(
      Uri.parse('${getBaseUrl()}/add_ulasan.php'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(model.toJson()),
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
