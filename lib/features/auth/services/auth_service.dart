import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/login_result_model.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<LoginResultModel> loginUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
       
        if (result['success'] == true) {
          await _storage.write(key: 'jwt_token', value: result['token']);
          await _storage.write(key: 'id_users', value: result['id_users'].toString());
          await _storage.write(key: 'role', value: result['role'].toString());
          // Simpan step1, step2, step3 jika ada di response
          if (result.containsKey('step1')) {
            final val = result['step1'] == true ? '1' : '0';
            await _storage.write(key: 'step1', value: val);
          }
          if (result.containsKey('step2')) {
            final val = result['step2'] == true ? '1' : '0';
            await _storage.write(key: 'step2', value: val);
          }
          if (result.containsKey('step3')) {
            final val = result['step3'] == true ? '1' : '0';
            await _storage.write(key: 'step3', value: val);
          }
        }
        return LoginResultModel.fromJson(result);
      } else {
        return LoginResultModel(success: false, message: 'Server error');
      }
    } catch (e) {
      return LoginResultModel(success: false, message: 'Terjadi kesalahan');
    }
  }
}
