import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/profile_page_model.dart';

class ProfileService {
  static final _storage = FlutterSecureStorage();

  static Future<ProfileModel?> fetchUserProfile() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    try {
      final res = await http.get(
        Uri.parse('${getBaseUrl()}/get_user_profile.php'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data']);
        return ProfileModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('fetchUserProfile error: ${e.toString()}');
    }
    return null;
  }

  static Future<bool> updateUserProfile(
    ProfileModel model, {
    String? password,
  }) async {
    String? token = await _storage.read(key: 'jwt_token');
    String? idUsers = await _storage.read(key: 'id_users');
    if (token == null || idUsers == null) return false;

    final body = model.toJson();
    body['id_users'] = idUsers;
    if (password != null && password.isNotEmpty && password != '********') {
      body['password'] = password;
    }

    final res = await http.post(
      Uri.parse('${getBaseUrl()}/edit_user_profile.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) return false;
    final json = jsonDecode(res.body);
    return json is Map && json['success'] == true;
  }

  static Future<String?> uploadImageToCloudinary(File imageFile) async {
    const String uploadPreset = 'dpr_bites';
    const String cloudName = 'dip8i3f6x';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(respStr);
        return data['secure_url'] ?? data['url'];
      } else {
        debugPrint(
          'Cloudinary upload failed: ${response.statusCode} - $respStr',
        );
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: ' + e.toString());
    }
    return null;
  }
}
