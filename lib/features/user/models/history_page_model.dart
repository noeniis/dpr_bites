import 'package:flutter/foundation.dart';

class HistoryOrderModel {
  final int idTransaksi;
  final String? bookingId;
  final String restaurantName;
  final int price;
  final String? dateRaw;
  final String dateDisplay;
  final String status;
  final String icon;
  final bool delivery;
  final String? locationSeller;
  final String? locationBuyer;
  final int? idAlamat;
  final String? buyerBuilding;
  final String? buyerDetail;

  HistoryOrderModel({
    required this.idTransaksi,
    required this.bookingId,
    required this.restaurantName,
    required this.price,
    required this.dateRaw,
    required this.dateDisplay,
    required this.status,
    required this.icon,
    required this.delivery,
    required this.locationSeller,
    required this.locationBuyer,
    required this.idAlamat,
    required this.buyerBuilding,
    required this.buyerDetail,
  });

  factory HistoryOrderModel.fromJson(Map<String, dynamic> json) {
    return HistoryOrderModel(
      idTransaksi: _toInt(json['id_transaksi']),
      bookingId: json['booking_id']?.toString(),
      restaurantName: json['restaurantName']?.toString() ?? '-',
      price: _toInt(json['price']),
      dateRaw: json['date_raw']?.toString(),
      dateDisplay: json['dateDisplay']?.toString() ?? '-',
      status: json['status']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'lib/assets/images/spatulaknife.png',
      delivery: json['delivery'] == true || json['delivery']?.toString() == '1',
      locationSeller: json['locationSeller']?.toString(),
      locationBuyer: json['locationBuyer']?.toString(),
      idAlamat: json['id_alamat'] == null ? null : _toInt(json['id_alamat']),
      buyerBuilding: json['buyer_building']?.toString(),
      buyerDetail: json['buyer_detail']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_transaksi': idTransaksi,
      'booking_id': bookingId,
      'restaurantName': restaurantName,
      'price': price,
      'date_raw': dateRaw,
      'dateDisplay': dateDisplay,
      'status': status,
      'icon': icon,
      'delivery': delivery,
      'locationSeller': locationSeller,
      'locationBuyer': locationBuyer,
      'id_alamat': idAlamat,
      'buyer_building': buyerBuilding,
      'buyer_detail': buyerDetail,
    };
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

@immutable
class HistoryFetchResult {
  final List<Map<String, dynamic>> orders;
  final String? error;
  const HistoryFetchResult({required this.orders, this.error});
}
