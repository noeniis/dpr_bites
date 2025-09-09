import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../common/utils/base_url.dart';

class UpdateStepUserService {
  static Future<bool> resetStepUser(String idUser) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/update_step_seller.php'),
      body: {
        'id_users': idUser,
        'step1': '0',
        'step2': '0',
      },
    );
    final result = json.decode(response.body);
    return result['success'] == true;
  }
}
