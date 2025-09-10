import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/auth/models/reset_password_page_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPageService {
  static Future<ResetPasswordResult> reset(ResetPasswordRequest req) async {
    try {
      final url = Uri.parse('${getBaseUrl()}/reset_password.php');
      final resp = await http.post(
        url,
        body: jsonEncode(req.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map) {
          final ok = data['success'] == true;
          final msg = data['message']?.toString();
          return ResetPasswordResult(success: ok, message: msg);
        }
        return const ResetPasswordResult(
          success: false,
          message: 'Respons tidak valid',
        );
      }
      debugPrint('ResetPassword HTTP ${resp.statusCode}: ${resp.body}');
      return ResetPasswordResult(
        success: false,
        message: 'HTTP ${resp.statusCode}',
      );
    } catch (e) {
      debugPrint('ResetPassword exception: $e');
      return ResetPasswordResult(success: false, message: e.toString());
    }
  }
}
