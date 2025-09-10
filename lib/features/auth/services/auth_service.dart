import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_result_model.dart';

class AuthService {
  Future<LoginResultModel> loginUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return LoginResultModel.fromJson(result);
      } else {
        return LoginResultModel(success: false, message: 'Server error');
      }
    } catch (e) {
      return LoginResultModel(success: false, message: 'Terjadi kesalahan');
    }
  }

  Future<void> saveUserId(String idUsers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_users', idUsers);
  }
}
