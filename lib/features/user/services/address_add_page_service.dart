import 'dart:convert';
import 'package:dpr_bites/common/utils/base_url.dart';
import 'package:dpr_bites/features/user/models/address_add_page_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AddressAddPageService {
  static final _storage = const FlutterSecureStorage();
  // Removed duplicate getUserIdFromPrefs and unused intId
  static Future<String?> getUserIdFromPrefs() async {
    try {
      for (final k in const ['id_users', 'id_user', 'user_id']) {
        final v = await _storage.read(key: k);
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  static Future<AddressDetailFetchResult> fetchDetail({
    required int idAlamat,
    required String userId,
  }) async {
    final url = Uri.parse('${getBaseUrl()}/alamat_pengantaran_get_detail.php');
    try {
      final token = await _storage.read(key: 'jwt_token');
      final res = await http.post(
        url,
        body: jsonEncode({'id_alamat': idAlamat}),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': userId,
          if (token != null) 'Authorization': 'Bearer $token',
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
      final token = await _storage.read(key: 'jwt_token');
      final body = request.toJsonWithUser(userId);
      final res = await http.post(
        url,
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': userId,
          if (token != null) 'Authorization': 'Bearer $token',
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
