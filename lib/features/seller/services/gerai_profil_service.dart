import 'dart:convert';
import 'package:http/http.dart' as http;

class GeraiProfilService {
  Future<bool> updateGeraiProfil({
    required int idGerai,
    required String bannerPath,
    required String listingPath,
    required String deskripsiGerai,
    required String hariBuka,
    required String jamBuka,
    required String jamTutup,
  }) async {
    final url = Uri.parse("http://10.0.2.2/dpr_bites_api/update_gerai_profil.php");
    final body = jsonEncode({
      "id_gerai": idGerai,
      "banner_path": bannerPath,
      "listing_path": listingPath,
      "deskripsi_gerai": deskripsiGerai,
      "hari_buka": hariBuka,
      "jam_buka": jamBuka,
      "jam_tutup": jamTutup,
    });
    final response = await http.post(url, body: body, headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
  Future<Map<String, dynamic>?> fetchGeraiProfil(int idUsers) async {
    final url = Uri.parse("http://10.0.2.2/dpr_bites_api/get_gerai_profil.php?id_users=$idUsers");
    try {
      final response = await http.get(url);
      print('DEBUG response.body: ${response.body}');
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
}
