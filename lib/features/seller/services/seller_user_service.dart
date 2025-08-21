import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';

class SellerUserService {
  static Future<Map<String, dynamic>?> fetchUserById(String idUsers) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_user_by_id.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_users': idUsers}),
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
