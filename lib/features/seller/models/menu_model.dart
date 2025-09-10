import 'package:dpr_bites/features/seller/models/addon_model.dart';

class MenuModel {
	final int idMenu;
	final int idGerai;
	final int? idEtalase;
	final String namaMenu;
	final String gambarMenu;
	final String deskripsiMenu;
	final String kategori;
	final int harga;
	final int jumlahStok;
	bool tersedia;
	final List<AddonModel>? addons;

	MenuModel({
		required this.idMenu,
		required this.idGerai,
		this.idEtalase,
		required this.namaMenu,
		required this.gambarMenu,
		required this.deskripsiMenu,
		required this.kategori,
		required this.harga,
		required this.jumlahStok,
		required this.tersedia,
		this.addons,
	});

	factory MenuModel.fromJson(Map<String, dynamic> json) {
		return MenuModel(
			idMenu: int.tryParse(json['id_menu'].toString()) ?? 0,
			idGerai: int.tryParse(json['id_gerai'].toString()) ?? 0,
			idEtalase: json['id_etalase'] != null ? int.tryParse(json['id_etalase'].toString()) : null,
			namaMenu: json['nama_menu'] ?? '',
			gambarMenu: json['gambar_menu'] ?? '',
			deskripsiMenu: json['deskripsi_menu'] ?? '',
			kategori: json['kategori'] ?? '',
			harga: int.tryParse(json['harga'].toString()) ?? 0,
			jumlahStok: int.tryParse(json['jumlah_stok'].toString()) ?? 0,
			tersedia: json['tersedia'].toString() == '1',
			addons: json['addons'] != null
					? List<AddonModel>.from((json['addons'] as List).map((e) => AddonModel.fromJson(e)))
					: null,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id_menu': idMenu,
			'id_gerai': idGerai,
			'id_etalase': idEtalase,
			'nama_menu': namaMenu,
			'gambar_menu': gambarMenu,
			'deskripsi_menu': deskripsiMenu,
			'kategori': kategori,
			'harga': harga,
			'jumlah_stok': jumlahStok,
			'tersedia': tersedia ? '1' : '0',
			'addons': addons?.map((e) => e.toJson()).toList(),
		};
	}
}
