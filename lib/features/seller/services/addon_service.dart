import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/addon_model.dart';

class AddonService {
  static Future<List<AddonModel>> fetchAddonsByGerai({required int idGerai}) async {
  final storage = FlutterSecureStorage();
  final jwt = await storage.read(key: 'jwt_token');
  final url = Uri.parse('${getBaseUrl()}/get_addon.php?id_gerai=$idGerai');
  final response = await http.get(url, headers: jwt != null ? {'Authorization': 'Bearer $jwt'} : null);
    print('[DEBUG AddonService] response get_addon.php: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['addons'] != null) {
        final list = List<AddonModel>.from(
          (data['addons'] as List).map((e) => AddonModel.fromJson(e)),
        );
        print('[DEBUG AddonService] hasil parsing add-on: ${list.map((a) => a.namaAddon).toList()}');
        return list;
      }
    }
    return [];
  }
  /// Ambil idUser dari flutter_secure_storage dan idGerai dari API
  static Future<Map<String, String?>> getGeraiIdByUser() async {
  final storage = FlutterSecureStorage();
  final idUser = await storage.read(key: 'id_users');
    String? idGerai;
    if (idUser != null) {
      final jwt = await storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
        headers: jwt != null ? {'Authorization': 'Bearer $jwt'} : null,
        body: {'id_users': idUser},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null && data['data']['id_gerai'] != null) {
        idGerai = data['data']['id_gerai'].toString();
      }
    }
    return {'idUser': idUser, 'idGerai': idGerai};
  }
  static Future<String?> uploadImageToCloudinary(String imagePath) async {
    const cloudName = 'dip8i3f6x';
    const uploadPreset = 'dpr_bites';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imagePath));
    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = jsonDecode(resStr);
      return resJson['secure_url'];
    }
    return null;
  }
  static Future<bool> updateAddonWithImage({
    required int idAddon,
    required String namaAddon,
    required String deskripsi,
    required int harga,
    required String imagePath,
    required bool tersedia,
    int? stok,
  }) async {
    final bodyData = {
      'id_addon': idAddon.toString(),
      'nama_addon': namaAddon,
      'deskripsi': deskripsi,
      'harga': harga.toString(),
      'image_path': imagePath,
      'tersedia': tersedia ? '1' : '0',
      if (stok != null) 'stok': stok.toString(),
    };
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/update_addon.php'),
      headers: {
        "Content-Type": "application/json",
        if (jwt != null) 'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode(bodyData),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
  static Future<bool> deleteAddonWithImage({required int idAddon}) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/delete_addon.php'),
      headers: jwt != null ? {'Authorization': 'Bearer $jwt'} : null,
      body: {'id_addon': idAddon.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
  /// Ambil semua addon milik gerai dari flutter_secure_storage
  static Future<List<AddonModel>> fetchAddonsByGeraiFromPrefs() async {
  final storage = FlutterSecureStorage();
  final idGeraiStr = await storage.read(key: 'id_gerai');
    if (idGeraiStr == null) return [];
    final idGerai = int.tryParse(idGeraiStr) ?? 0;
    return await fetchAddonsByGerai(idGerai: idGerai);
  }
  /// Ambil semua addon yang terhubung ke menu tertentu (relasi menu_addon)
  static Future<List<AddonModel>> fetchMenuAddons({required int idMenu}) async {
  final storage = FlutterSecureStorage();
  final idGeraiStr = await storage.read(key: 'id_gerai');
    if (idGeraiStr == null) return [];
    final idGerai = int.tryParse(idGeraiStr) ?? 0;
    // Fetch semua addon milik gerai
    final allAddons = await fetchAddonsByGerai(idGerai: idGerai);
    // Fetch relasi menu_addon dari API
  final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_menu_addon.php'),
      headers: jwt != null ? {'Authorization': 'Bearer $jwt'} : null,
      body: {'id_menu': idMenu.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['addon_ids'] != null) {
        final List relasiIds = data['addon_ids'] as List;
        // Filter addon yang terhubung ke menu
        return allAddons.where((addon) => relasiIds.contains(addon.idAddon)).toList();
      }
    }
    return [];
  }

  static Future<AddonModel?> getAddonDetail({required int idAddon}) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_addon_detail.php'),
      headers: jwt != null ? {'Authorization': 'Bearer $jwt'} : null,
      body: {'id_addon': idAddon.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return AddonModel.fromJson(data['data']);
      }
    }
    return null;
  }

  /// Submit add-on baru, handle upload gambar jika ada
  static Future<Map<String, dynamic>> addAddon({
    required String idGerai,
    required String namaAddon,
    required int harga,
    required String deskripsi,
    String? imagePath,
    required int stok,
    required bool tersedia,
  }) async {
    String? imageUrl;
    if (imagePath != null && imagePath.isNotEmpty) {
      imageUrl = await uploadImageToCloudinary(imagePath);
      if (imageUrl == null) {
        return {'success': false, 'error': 'Gagal upload gambar'};
      }
    }
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/add_addon.php'),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        if (jwt != null) 'Authorization': 'Bearer $jwt',
      },
      body: {
        'id_gerai': idGerai,
        'nama_addon': namaAddon,
        'harga': harga.toString(),
        'deskripsi': deskripsi,
        'image_path': imageUrl ?? '',
        'stok': stok.toString(),
        'tersedia': tersedia ? '1' : '0',
      },
    );
    if (response.statusCode == 200) {
      final resJson = jsonDecode(response.body);
      return resJson;
    }
    return {'success': false, 'error': 'Network error'};
  }

  static Future<bool> editAddon({
    required int idAddon,
    required String namaAddon,
    required int harga,
    required bool tersedia,
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/edit_addon.php'),
      headers: jwt != null ? {'Authorization': 'Bearer $jwt'} : null,
      body: {
        'id_addon': idAddon.toString(),
        'nama_addon': namaAddon,
        'harga': harga.toString(),
        'tersedia': tersedia ? '1' : '0',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  static Future<bool> deleteAddon({required int idAddon}) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/delete_addon.php'),
      headers: jwt != null ? {'Authorization': 'Bearer $jwt'} : null,
      body: {'id_addon': idAddon.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
}
