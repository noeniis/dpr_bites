import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/common/utils/base_url.dart';
import '../../models/lainnya/profil_seller_model.dart';

class ProfilSellerService {
		static const _storage = FlutterSecureStorage();
		Future<String?> getUserId() async {
			return await _storage.read(key: 'id_users');
		}

	Future<ProfilSellerModel?> fetchProfile(String idUsers) async {
			final token = await _storage.read(key: 'jwt_token');
			final response = await http.post(
				Uri.parse('${getBaseUrl()}/get_seller_profile.php'),
				body: jsonEncode({"id_users": idUsers}),
				headers: {
					'Content-Type': 'application/json',
					if (token != null) 'Authorization': 'Bearer $token',
				},
			);
		final data = jsonDecode(response.body);
		if (data['success'] == true) {
			return ProfilSellerModel.fromJson(data['user']);
		}
		throw data['message'] ?? 'Gagal ambil profil';
	}

	Future<bool> updateProfileField({required String idUsers, String? email, String? noTelp}) async {
			final token = await _storage.read(key: 'jwt_token');
			final response = await http.post(
				Uri.parse('${getBaseUrl()}/update_user_profile.php'),
				body: jsonEncode({
					"id_users": idUsers,
					if (email != null) "email": email,
					if (noTelp != null) "no_hp": noTelp,
				}),
				headers: {
					'Content-Type': 'application/json',
					if (token != null) 'Authorization': 'Bearer $token',
				},
			);
		final data = jsonDecode(response.body);
		if (data['success'] == true) {
			return true;
		}
		throw data['message'] ?? 'Gagal update profil';
	}

	Future<bool> updatePassword({required String idUsers, required String currentPassword, required String newPassword}) async {
			final token = await _storage.read(key: 'jwt_token');
			final response = await http.post(
				Uri.parse('${getBaseUrl()}/update_password.php'),
				body: jsonEncode({
					"id_users": idUsers,
					"current_password": currentPassword,
					"new_password": newPassword,
				}),
				headers: {
					'Content-Type': 'application/json',
					if (token != null) 'Authorization': 'Bearer $token',
				},
			);
		final data = jsonDecode(response.body);
		if (data['success'] == true) {
			return true;
		}
		throw data['message'] ?? 'Gagal mengubah kata sandi';
	}

	Future<bool> deleteAccount(String idUsers) async {
			final token = await _storage.read(key: 'jwt_token');
			final response = await http.post(
				Uri.parse('${getBaseUrl()}/delete_user_and_related.php'),
				body: {"id_users": idUsers},
				headers: {
					if (token != null) 'Authorization': 'Bearer $token',
				},
			);
			final data = jsonDecode(response.body);
			if (data['success'] == true) {
				await _storage.delete(key: 'id_users');
				return true;
			}
			throw 'Gagal menghapus akun';
	}
}
