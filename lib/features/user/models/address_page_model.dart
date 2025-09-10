import 'package:flutter/foundation.dart';

@immutable
class AddressModel {
  final int? id;
  final String namaPenerima;
  final String namaGedung;
  final String detailPengantaran;
  final String noHp;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.namaPenerima,
    required this.namaGedung,
    required this.detailPengantaran,
    required this.noHp,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> m) {
    return AddressModel(
      id: _toIntOrNull(m['id'] ?? m['id_alamat']),
      namaPenerima: (m['nama_penerima'] ?? '').toString(),
      namaGedung: (m['nama_gedung'] ?? '').toString(),
      detailPengantaran: (m['detail_pengantaran'] ?? '').toString(),
      noHp: (m['no_hp'] ?? '').toString(),
      isDefault:
          (m['alamat_utama'] == 1 ||
          m['alamat_utama'] == true ||
          (m['alamat_utama']?.toString() == '1')),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nama_penerima': namaPenerima,
    'nama_gedung': namaGedung,
    'detail_pengantaran': detailPengantaran,
    'no_hp': noHp,
    'alamat_utama': isDefault ? 1 : 0,
  };
}

@immutable
class AddressFetchResult {
  final List<Map<String, dynamic>> addresses;
  final String? error;
  const AddressFetchResult({required this.addresses, this.error});
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}
