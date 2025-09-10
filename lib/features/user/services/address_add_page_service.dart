import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/address_add_page_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddressAddPageService {
  // Removed duplicate getUserIdFromPrefs and unused intId
  static Future<String?> getUserIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('id_users');
    } catch (_) {
      return null;
    }
  }

  static Future<AddressDetailFetchResult> fetchDetail({
    required int idAlamat,
  required String userId,
  }) async {
    final url = Uri.parse('${getBaseUrl()}/alamat_pengantaran_get_detail.php');
    try {
      final res = await http.post(
        url,
        body: jsonEncode({'id_alamat': idAlamat}),
        headers: {
          'Content-Type': 'application/json',
      'X-User-Id': userId,
        },
      );
      if (res.statusCode != 200) {
        return const AddressDetailFetchResult(error: 'HTTP error');
      }
      final data = jsonDecode(res.body);
      if (data is Map && data['success'] == true && data['address'] != null) {
        final m = Map<String, dynamic>.from(data['address']);
        return AddressDetailFetchResult(detail: AddressDetailModel.fromJson(m));
      }
      return AddressDetailFetchResult(
        error: data is Map
            ? (data['message']?.toString() ?? 'Gagal memuat')
            : 'Respon tidak valid',
      );
    } catch (e) {
      return AddressDetailFetchResult(error: e.toString());
    }
  }

  static Future<SaveAddressResult> saveAddress({
    required AddressUpsertRequest request,
  required String userId,
  }) async {
    final isEdit = request.idAlamat != null;
    final url = Uri.parse(
      isEdit
          ? '${getBaseUrl()}/alamat_pengantaran_update.php'
          : '${getBaseUrl()}/alamat_pengantaran_add.php',
    );
    try {
    final body = request.toJsonWithUser(userId);
      final res = await http.post(
        url,
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
      'X-User-Id': userId,
        },
      );
      if (res.statusCode != 200) {
        return SaveAddressResult(
          success: false,
          message: 'HTTP ${res.statusCode}',
        );
      }
      final data = jsonDecode(res.body);
      final ok = data is Map && data['success'] == true;
      return SaveAddressResult(
        success: ok,
        message: data is Map ? data['message']?.toString() : null,
      );
    } catch (e) {
      return SaveAddressResult(success: false, message: e.toString());
    }
  }
}
