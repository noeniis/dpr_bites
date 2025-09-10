class ProfilSellerModel {
	final String nama;
	final String role;
	final String email;
	final String noTelp;

	ProfilSellerModel({
		required this.nama,
		required this.role,
		required this.email,
		required this.noTelp,
	});

	factory ProfilSellerModel.fromJson(Map<String, dynamic> json) {
		return ProfilSellerModel(
			nama: json['nama'] ?? '',
			role: json['role'] ?? 'Owner',
			email: json['email'] ?? '',
			noTelp: json['no_telp'] ?? '',
		);
	}
}
