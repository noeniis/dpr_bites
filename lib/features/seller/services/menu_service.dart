import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dpr_bites/common/utils/base_url.dart';

class MenuService {
  static Future<String?> uploadImageToCloudinary(File imageFile) async {
    // Ganti dengan preset dan cloud_name Cloudinary Anda
    const String uploadPreset = 'dpr_bites';
    const String cloudName = 'dip8i3f6x';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      return data['secure_url'];
    }
    return null;
  }

  static Future<Map<String, dynamic>?> addMenu({
    required int idGerai,
    required int? idEtalase,
    required String namaMenu,
    required String gambarMenu,
    required String deskripsiMenu,
    required String kategori,
    required int harga,
    required int jumlahStok,
    required bool tersedia,
  }) async {
    print({
  'id_gerai': idGerai.toString(),
  'id_etalase': idEtalase?.toString() ?? '',
  'nama_menu': namaMenu,
  'gambar_menu': gambarMenu,
  'deskripsi_menu': deskripsiMenu,
  'kategori': kategori,
  'harga': harga.toString(),
  'jumlah_stok': jumlahStok.toString(),
  'tersedia': tersedia ? '1' : '0',
});

    final response = await http.post(
      Uri.parse('${getBaseUrl()}/add_menu.php'),
      body: {
        'id_gerai': idGerai.toString(),
        'id_etalase': idEtalase?.toString() ?? '',
        'nama_menu': namaMenu,
        'gambar_menu': gambarMenu,
        'deskripsi_menu': deskripsiMenu,
        'kategori': kategori,
        'harga': harga.toString(),
        'jumlah_stok': jumlahStok.toString(),
        'tersedia': tersedia ? '1' : '0',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
    }
    return null;
  }

  static Future<bool> addMenuAddons({
    required int idMenu,
    required List<int> idAddons,
  }) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/add_menu_addon.php'),
      body: {
        'id_menu': idMenu.toString(),
        'id_addons': jsonEncode(idAddons),
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  static Future<int?> getIdGerai() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getString('id_users');
    if (idUser == null) return null;
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      body: {'id_users': idUser},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['id_gerai'] != null) {
        return int.tryParse(data['id_gerai'].toString());
      }
    }
    return null;
  }

  static int? getIdEtalaseByName(List<Map<String, dynamic>> etalaseList, String name) {
    try {
      return etalaseList.firstWhere((e) => e['nama_etalase'] == name)['id_etalase'] as int?;
    } catch (_) {
      return null;
    }
  }
}
