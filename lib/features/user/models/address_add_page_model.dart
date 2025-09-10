import 'package:flutter/foundation.dart';

@immutable
class AddressDetailModel {
  final int? idAlamat;
  final String namaPenerima;
  final String namaGedung;
  final String detailPengantaran;
  final String noHp;
  final double? latitude;
  final double? longitude;
  final bool alamatUtama;

  const AddressDetailModel({
    required this.idAlamat,
    required this.namaPenerima,
    required this.namaGedung,
    required this.detailPengantaran,
    required this.noHp,
    required this.latitude,
    required this.longitude,
    required this.alamatUtama,
  });

  factory AddressDetailModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return AddressDetailModel(
      idAlamat: _toIntOrNull(json['id_alamat'] ?? json['id']),
      namaPenerima: (json['nama_penerima'] ?? '').toString(),
      namaGedung: (json['nama_gedung'] ?? '').toString(),
      detailPengantaran: (json['detail_pengantaran'] ?? '').toString(),
      noHp: (json['no_hp'] ?? '').toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      alamatUtama:
          json['alamat_utama'] == 1 ||
          json['alamat_utama'] == true ||
          json['alamat_utama']?.toString() == '1',
    );
  }
}

@immutable
class AddressUpsertRequest {
  final int? idAlamat; // null => add, not null => update
  final String namaPenerima;
  final String namaGedung;
  final String detailPengantaran;
  final double latitude;
  final double longitude;
  final String noHp;
  final bool alamatUtama;

  const AddressUpsertRequest({
    this.idAlamat,
    required this.namaPenerima,
    required this.namaGedung,
    required this.detailPengantaran,
    required this.latitude,
    required this.longitude,
    required this.noHp,
    required this.alamatUtama,
  });

  Map<String, dynamic> toJsonWithUser(String userId) {
    return {
      'id_users': userId,
      if (idAlamat != null) 'id_alamat': idAlamat,
      'nama_penerima': namaPenerima,
      'nama_gedung': namaGedung,
      'detail_pengantaran': detailPengantaran,
      'latitude': latitude,
      'longitude': longitude,
      'no_hp': noHp,
      'alamat_utama': alamatUtama ? 1 : 0,
    };
  }
}

@immutable
class AddressDetailFetchResult {
  final AddressDetailModel? detail;
  final String? error;
  const AddressDetailFetchResult({this.detail, this.error});
  bool get success => detail != null && error == null;
}

@immutable
class SaveAddressResult {
  final bool success;
  final String? message;
  const SaveAddressResult({required this.success, this.message});
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}
