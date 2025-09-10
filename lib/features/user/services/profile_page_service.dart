import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/profile_page_model.dart';

class ProfileService {
  static Future<ProfileModel?> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    // id_users selalu diambil sebagai String
    final idUsers = prefs.getString('id_users');
    if (idUsers == null) return null;

    final res = await http.post(
      Uri.parse('${getBaseUrl()}/get_user_profile.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_users': idUsers}),
    );
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body);
    if (json is! Map || json['success'] != true) return null;
    final data = json['user'] ?? json['data'];
    if (data is Map) {
      return ProfileModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static Future<bool> updateUserProfile(
    ProfileModel model, {
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? idUsers;
    final idInt = prefs.getInt('id_users');
    if (idInt != null) {
      idUsers = idInt.toString();
    } else {
      idUsers = prefs.getString('id_users');
    }
    if (idUsers == null) return false;

    final body = model.toJson();
    body['id_users'] = idUsers;
    if (password != null && password.isNotEmpty && password != '********') {
      body['password'] = password;
    }

    final res = await http.post(
      Uri.parse('${getBaseUrl()}/edit_user_profile.php'),
      headers: {'Content-Type': 'application/json'},
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
