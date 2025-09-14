import 'dart:convert';
import 'dart:io';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/gerai_profil_model.dart';

class GeraiProfilService {
  static const _storage = FlutterSecureStorage();

  static Future<bool> insertGeraiProfil(Map<String, dynamic> data) async {
    final url = Uri.parse('${getBaseUrl()}/gerai_profil.php');
    final body = jsonEncode({
      'id_gerai': data['id_gerai'],
      'banner_path': data['banner_path'] ?? '',
      'listing_path': data['listing_path'] ?? '',
      'deskripsi_gerai': data['deskripsi_gerai'] ?? '',
      'hari_buka': data['hari_buka'] ?? '',
      'jam_buka': data['jam_buka'] ?? '',
      'jam_tutup': data['jam_tutup'] ?? '',
      // id_users no longer needed in body; server derives from JWT
    });
    final token = await _storage.read(key: 'jwt_token');
    print('[DEBUG] insertGeraiProfil: id_gerai=${data['id_gerai']}');
    final response = await http.post(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  print('[DEBUG] insertGeraiProfil response: ${response.body}');
    final res = jsonDecode(response.body);
    return res['status'] == 'success';
  }
  static Future<GeraiProfilModel?> fetchGeraiProfilByUser(String idUsers) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_profil.php'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );
    print('[DEBUG] fetchGeraiProfilByUser response: ${response.body}');
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        // Parsing dari field 'profil' jika ada
        if (result['profil'] != null) {
          return GeraiProfilModel.fromJson(result['profil']);
        } else if (result['id_gerai'] != null) {
          // Buat model minimal hanya idGerai
          return GeraiProfilModel(
            idGerai: result['id_gerai'] is int ? result['id_gerai'] : int.tryParse(result['id_gerai'].toString()) ?? 0,
            namaGerai: '',
            bannerPath: '',
            listingPath: '',
            deskripsiGerai: '',
            hariBuka: '',
            jamBuka: '08:00',
            jamTutup: '16:00',
            detailAlamat: '',
            latitude: null,
            longitude: null,
            telepon: '',
          );
        }
      }
    }
    return null;
  }
  static Future<Map<String, dynamic>?> fetchGeraiProfilByIdGerai(dynamic idGerai) async {
    if (idGerai == null) return null;
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_profil.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_gerai': idGerai.toString()}),
    );
    print('[DEBUG] fetchGeraiProfilByIdGerai response: ${response.body}');
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true && result['data'] != null) {
        return result['data'] as Map<String, dynamic>;
      }
    }
    return null;
  }
  static Future<String> getHalalStatus(String idGerai) async {
    final data = await fetchGeraiByUser(idGerai);
    if (data != null && data['data'] != null) {
      final info = data['data'];
      return info['sertifikasi_halal']?.toString() ?? '0';
    }
    return '0';
  }
  static Future<String?> uploadQrisToCloudinary(File file) async {
    // Ganti dengan preset dan cloud name Cloudinary milikmu
    const cloudName = 'dip8i3f6x';
    const uploadPreset = 'dpr_bites';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = jsonDecode(resStr);
      return resJson['secure_url'] as String?;
    }
    return null;
  }
  static Future<bool> addOrUpdateHalal({
    required String idUsers,
    required String sertifikasiHalal,
  }) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/add_or_update_gerai.php'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
      body: {
        'sertifikasi_halal': sertifikasiHalal,
      },
    );
    print('DEBUG addOrUpdateHalal response: ${response.body}');
    final res = jsonDecode(response.body);
    return res['success'] == true;
  }

  static Future<bool> addOrUpdateQris({
    required String idGerai,
    required String qrisPath,
  }) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/add_or_update_gerai.php'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
      body: {
        'id_gerai': idGerai,
        'qris_path': qrisPath,
      },
    );
    final res = jsonDecode(response.body);
    return res['success'] == true;
  }
  static Future<Map<String, dynamic>?> fetchGeraiByUser(String idUsers) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data;
    }
    return null;
  }

  static Future<bool> addOrUpdateGerai(Map<String, dynamic> data) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/add_or_update_gerai.php'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
      body: data,
    );
    print("DEBUG response.statusCode: ${response.statusCode}");
    print("DEBUG response.body: ${response.body}");
    final res = jsonDecode(response.body);
    if (res['success'] == true) {
      // Simpan id_gerai ke SharedPreferences jika ada
      // Removed SharedPreferences storage for id_gerai to keep auth stateless
      return true;
    }
    return false;
  }

  Future<bool> updateGeraiProfil({
    required int idGerai,
    required String bannerPath,
    required String listingPath,
    required String deskripsiGerai,
    required String hariBuka,
    required String jamBuka,
    required String jamTutup,
  }) async {
    final url = Uri.parse("${getBaseUrl()}/update_gerai_profil.php");
    final body = jsonEncode({
      "id_gerai": idGerai,
      "banner_path": bannerPath,
      "listing_path": listingPath,
      "deskripsi_gerai": deskripsiGerai,
      "hari_buka": hariBuka,
      "jam_buka": jamBuka,
      "jam_tutup": jamTutup,
    });
    final response = await http.post(url,
        body: body, headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> fetchGeraiProfil(int idUsers) async {
    final url =
        Uri.parse("${getBaseUrl()}/get_gerai_profil.php?id_users=$idUsers");
    try {
      final response = await http.get(url);
      print("DEBUG response.statusCode: ${response.statusCode}");
      print("DEBUG response.body: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && !data.containsKey('error')) {
          return data;
        } else {
          print("API Error: \\${data['error']}");
          return null;
        }
      } else {
        print("HTTP Error: \\${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng');
      final res = await http.get(url, headers: {
        'User-Agent': 'dpr-bites/1.0 (contact: example@example.com)'
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['display_name'] ?? '') as String;
      }
    } catch (_) {}
    return null;
  }
}
