import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/auth/models/register_page_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RegisterPageService {
  static Future<RegisterResult> register(RegisterRequest req) async {
    try {
      final url = Uri.parse('${getBaseUrl()}/register.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('success')) {
          final ok = data['success'] == true;
          final msg = data['message']?.toString();
          return RegisterResult(success: ok, message: msg);
        }
        debugPrint('Register unexpected response: ${response.body}');
        return const RegisterResult(
          success: false,
          message: 'Respons tidak valid',
        );
      } else {
        debugPrint('Register HTTP ${response.statusCode}: ${response.body}');
        return RegisterResult(
          success: false,
          message: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Register exception: $e');
      return RegisterResult(success: false, message: e.toString());
    }
  }
}
