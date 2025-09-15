

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/seller/models/menu_model.dart';
import 'package:dpr_bites/features/seller/models/etalase_model.dart';
import 'package:dpr_bites/features/seller/models/addon_model.dart';


class MenuService {
  static Future<bool> updateMenu(Map<String, dynamic> bodyData) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/update_menu.php'),
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
    static Future<Map<String, dynamic>?> fetchMenuDetail({required int idGerai, required int idMenu}) async {
      final storage = FlutterSecureStorage();
      final jwt = await storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/get_menu_detail.php'),
        headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
        body: {'id_gerai': idGerai.toString(), 'filter': 'all'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Cari menu yang id_menu-nya sama
          final menuList = data['data'] as List;
          final menuDetail = menuList.firstWhere(
            (m) => int.tryParse(m['id_menu'].toString()) == idMenu,
            orElse: () => null,
          );
          return menuDetail;
        }
      }
      return null;
    }
  static Future<List<EtalaseModel>> fetchEtalaseByUser({required String idUsers}) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final responseGerai = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {'id_users': idUsers},
    );
    print('get_gerai_by_user response: ' + responseGerai.body);
    if (responseGerai.statusCode == 200) {
      final dataGerai = jsonDecode(responseGerai.body);
      if (dataGerai['success'] == true && dataGerai['data'] != null && dataGerai['data']['id_gerai'] != null) {
        final idGerai = int.tryParse(dataGerai['data']['id_gerai'].toString());
        if (idGerai != null) {
          final etalaseList = await fetchEtalase(idGerai: idGerai);
          print('fetchEtalase response: ' + etalaseList.toString());
          return etalaseList;
        }
      }
    }
    return [];
  }

  static Future<List<AddonModel>> fetchAddonsByUser({required String idUsers}) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final responseGerai = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {'id_users': idUsers},
    );
    print('get_gerai_by_user response: ' + responseGerai.body);
    if (responseGerai.statusCode == 200) {
      final dataGerai = jsonDecode(responseGerai.body);
      if (dataGerai['success'] == true && dataGerai['data'] != null && dataGerai['data']['id_gerai'] != null) {
        final idGerai = int.tryParse(dataGerai['data']['id_gerai'].toString());
        if (idGerai != null) {
          // Ambil semua addon dari gerai
          final responseAddon = await http.post(
            Uri.parse('${getBaseUrl()}/get_addon.php'),
            body: {'id_gerai': idGerai.toString()},
          );
          print('get_addon response: ' + responseAddon.body);
          if (responseAddon.statusCode == 200) {
            final dataAddon = jsonDecode(responseAddon.body);
            if (dataAddon['success'] == true && dataAddon['addons'] != null) {
              return List<AddonModel>.from(
                (dataAddon['addons'] as List).map((e) => AddonModel.fromJson(e)),
              );
            }
          }
        }
      }
    }
    return [];
  }
  static Future<List<MenuModel>> fetchMenusByUser({
    required String idUsers,
    String filter = 'all',
  }) async {
    // Ambil id_gerai dari backend
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final responseGerai = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {'id_users': idUsers},
    );
    debugPrint('fetchMenusByUser: get_gerai_by_user response: ' + responseGerai.body);
    if (responseGerai.statusCode == 200) {
      final dataGerai = jsonDecode(responseGerai.body);
      if (dataGerai['success'] == true && dataGerai['data'] != null && dataGerai['data']['id_gerai'] != null) {
        final idGerai = int.tryParse(dataGerai['data']['id_gerai'].toString());
        if (idGerai != null) {
          final menus = await fetchMenusByGerai(idGerai: idGerai, filter: filter);
          debugPrint('fetchMenusByUser: fetchMenusByGerai result: ' + menus.map((m) => m.toJson()).toList().toString());
          return menus;
        }
      }
    }
    return [];
  }

  static Future<List<MenuModel>> fetchMenusByGerai({
    required int idGerai,
    String filter = 'all',
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_menus.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {
        'id_gerai': idGerai.toString(),
        'filter': filter,
      },
    );
    debugPrint('fetchMenusByGerai: get_menus response: ' + response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<MenuModel>.from(
          (data['data'] as List).map((e) => MenuModel.fromJson(e)),
        );
      }
    }
    return [];
  }

  static Future<List<MenuModel>> fetchMenus({
    required String idUsers,
    String filter = 'all',
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_menus.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {
        'id_users': idUsers,
        'filter': filter,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<MenuModel>.from(
          (data['data'] as List).map((e) => MenuModel.fromJson(e)),
        );
      }
    }
    return [];
  }

  static Future<MenuModel?> getMenuDetail({
    required int idMenu,
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_menu_detail.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {'id_menu': idMenu.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return MenuModel.fromJson(data['data']);
      }
    }
    return null;
  }

  static Future<bool> editMenu({
    required int idMenu,
    required int idGerai,
    int? idEtalase,
    required String namaMenu,
    required String gambarMenu,
    required String deskripsiMenu,
    required String kategori,
    required int harga,
    required int jumlahStok,
    required bool tersedia,
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/edit_menu.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {
        'id_menu': idMenu.toString(),
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
      return data['success'] == true;
    }
    return false;
  }

  static Future<bool> deleteMenu({
    required int idMenu,
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/delete_menu.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {'id_menu': idMenu.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  static Future<List<EtalaseModel>> fetchEtalase({
    required int idGerai,
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_etalase.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {'id_gerai': idGerai.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
    if (data['success'] == true && data['etalase'] != null) {
        return List<EtalaseModel>.from(
      (data['etalase'] as List).map((e) => EtalaseModel.fromJson(e)),
        );
      }
    }
    return [];
  }

  static Future<List<AddonModel>> fetchAddons({
    required int idMenu,
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_addon.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: {'id_menu': idMenu.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['addons'] != null) {
        return List<AddonModel>.from(
          (data['addons'] as List).map((e) => AddonModel.fromJson(e)),
        );
      }
    }
    return [];
  }
  static Future<String?> uploadImageToCloudinary(File imageFile) async {
    const String uploadPreset = 'dpr_bites';
    const String cloudName = 'dip8i3f6x';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['secure_url'];
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('Cloudinary upload failed: \\${response.statusCode} - \\${respStr}');
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: ' + e.toString());
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
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/add_menu.php'),
      headers: {
        if (jwt != null) 'Authorization': 'Bearer $jwt',
      },
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
      return data;
    }
    return null;
  }

  static Future<bool> updateTersediaMenu({
    int? idMenu,
    int? idAddon,
    required int tersedia,
  }) async {
    final body = <String, String>{
      'update_tersedia': '1',
      'tersedia': tersedia.toString(),
    };
    if (idMenu != null) {
      body['id_menu'] = idMenu.toString();
    } else if (idAddon != null) {
      body['id_addon'] = idAddon.toString();
    } else {
      return false;
    }
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_menus.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  static Future<bool> addMenuAddons({
    required int idMenu,
    required List<int> idAddons,
  }) async {
    final storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/add_menu_addon.php'),
      headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
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
  // Migrated: Use flutter_secure_storage only
    final storage = FlutterSecureStorage();
    final idUser = await storage.read(key: 'id_users');
    final jwt = await storage.read(key: 'jwt_token');
    debugPrint('DEBUG getIdGerai: id_users dari SecureStorage: $idUser');
    if (idUser == null || jwt == null) return null;
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
      headers: {'Authorization': 'Bearer $jwt'},
      body: {'id_users': idUser},
    );
    debugPrint('DEBUG getIdGerai: response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null && data['data']['id_gerai'] != null) {
        final idGeraiStr = data['data']['id_gerai'].toString();
        debugPrint('DEBUG getIdGerai: id_gerai dari response: $idGeraiStr');
  final storage = FlutterSecureStorage();
  await storage.write(key: 'id_gerai', value: idGeraiStr);
        return int.tryParse(idGeraiStr);
      } else {
        debugPrint('DEBUG getIdGerai: id_gerai tidak ditemukan di response!');
      }
    } else {
      debugPrint('DEBUG getIdGerai: statusCode bukan 200!');
    }
    return null;
  }

  static int? getIdEtalaseByName(
  List<Map<String, dynamic>> etalaseList,
  String name,
) {
  try {
    final normalized = name.trim().toLowerCase();

    for (var e in etalaseList) {
      final nama = (e['nama_etalase'] ?? e['nama'] ?? '').toString().trim().toLowerCase();
      if (nama == normalized) {
        final idStr = e['id_etalase']?.toString();
        return int.tryParse(idStr ?? '');
      }
    }

    debugPrint("DEBUG getIdEtalaseByName: Tidak ditemukan untuk '$name'");
    return null;
  } catch (e) {
    debugPrint("DEBUG getIdEtalaseByName error: $e");
    return null;
  }
}


}
