import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/auth/models/forgot_password_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordService {
  static Future<ForgotPasswordResult> sendOtp(ForgotPasswordRequest req) async {
    try {
      final url = Uri.parse('${getBaseUrl()}/forgot_password.php');
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
          return ForgotPasswordResult(success: ok, message: msg);
        }
        return const ForgotPasswordResult(
          success: false,
          message: 'Respons tidak valid',
        );
      }
      debugPrint('ForgotPassword HTTP ${resp.statusCode}: ${resp.body}');
      return ForgotPasswordResult(
        success: false,
        message: 'HTTP ${resp.statusCode}',
      );
    } catch (e) {
      debugPrint('ForgotPassword exception: $e');
      return ForgotPasswordResult(success: false, message: e.toString());
    }
  }
}
