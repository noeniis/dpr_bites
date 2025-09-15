import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../common/utils/base_url.dart';

class UpdateStepUserService {
  static Future<bool> resetStepUser(String idUser) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/update_step_seller.php'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id_users': idUser,
        'step1': '0',
        'step2': '0',
      }),
    );
    final result = json.decode(response.body);
    return result['success'] == true;
  }
}
