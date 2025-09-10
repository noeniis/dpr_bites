import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/auth/models/otp_verification_page_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OtpVerificationPageService {
  static Future<OtpVerifyResult> verify(OtpVerifyRequest req) async {
    try {
      final url = Uri.parse('${getBaseUrl()}/verify_otp.php');
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
          return OtpVerifyResult(success: ok, message: msg);
        }
        return const OtpVerifyResult(
          success: false,
          message: 'Respons tidak valid',
        );
      }
      debugPrint('VerifyOTP HTTP ${resp.statusCode}: ${resp.body}');
      return OtpVerifyResult(
        success: false,
        message: 'HTTP ${resp.statusCode}',
      );
    } catch (e) {
      debugPrint('VerifyOTP exception: $e');
      return OtpVerifyResult(success: false, message: e.toString());
    }
  }
}
