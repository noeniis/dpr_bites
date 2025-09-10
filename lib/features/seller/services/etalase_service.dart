import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import '../models/etalase_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
class EtalaseService {
  static Future<List<EtalaseModel>> fetchEtalaseByUser({required String idUsers}) async {
  print('[DEBUG EtalaseService] Ambil id_gerai dari SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    final idGeraiStr = prefs.getString('id_gerai');
  print('[DEBUG EtalaseService] id_gerai dari SharedPreferences: ' + (idGeraiStr ?? 'NULL'));
    if (idGeraiStr != null) {
      final idGerai = int.tryParse(idGeraiStr);
      if (idGerai != null) {
    print('[DEBUG EtalaseService] Fetch etalase dengan id_gerai: ' + idGerai.toString());
        return await fetchEtalase(idGerai: idGerai);
      }
    }
    return [];
  }

  static Future<List<EtalaseModel>> fetchEtalase({required int idGerai}) async {
  print('[DEBUG EtalaseService] Fetch etalase API dengan id_gerai: ' + idGerai.toString());
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/get_etalase.php?id_gerai=$idGerai'),
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
  static Future<EtalaseModel?> getEtalaseDetail({required int idEtalase}) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/get_etalase_detail.php'),
      body: {'id_etalase': idEtalase.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return EtalaseModel.fromJson(data['data']);
      }
    }
    return null;
  }

  static Future<bool> addEtalase({
    required int idGerai,
    required String namaEtalase,
  }) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/add_etalase.php'),
      body: {
        'id_gerai': idGerai.toString(),
        'nama_etalase': namaEtalase,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  static Future<bool> editEtalase({
    required int idEtalase,
    required String namaEtalase,
  }) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/edit_etalase.php'),
      body: {
        'id_etalase': idEtalase.toString(),
        'nama_etalase': namaEtalase,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  static Future<bool> deleteEtalase({required int idEtalase}) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/delete_etalase.php'),
      body: {'id_etalase': idEtalase.toString()},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
}
