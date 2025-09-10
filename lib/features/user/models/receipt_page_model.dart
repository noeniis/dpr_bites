import 'package:flutter/foundation.dart';

@immutable
class ReceiptItemModel {
  final int qty;
  final String menu;
  final int price;
  final String? note;
  final List<Map<String, dynamic>> addonsDetail;

  const ReceiptItemModel({
    required this.qty,
    required this.menu,
    required this.price,
    this.note,
    required this.addonsDetail,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    final addons = <Map<String, dynamic>>[];
    final ad = json['addons_detail'];
    if (ad is List) {
      for (final v in ad) {
        if (v is Map) addons.add(Map<String, dynamic>.from(v));
      }
    }
    return ReceiptItemModel(
      qty: _toInt(json['qty'] ?? json['jumlah'] ?? 1),
      menu: json['menu']?.toString() ?? json['name']?.toString() ?? '-',
      price: _toInt(json['price'] ?? json['subtotal'] ?? 0),
      note: json['note']?.toString(),
      addonsDetail: addons,
    );
  }

  Map<String, dynamic> toMap() => {
    'qty': qty,
    'menu': menu,
    'price': price,
    'note': note,
    'addons_detail': addonsDetail,
  };
}

@immutable
class ReceiptDetailModel {
  final int idTransaksi;
  final String bookingId;
  final String restaurantName;
  final String status;
  final String metodePembayaran; // normalized: cash/qris/''
  final String jenisPengantaran; // delivery/pickup
  final bool delivery;
  final int deliveryFee;
  final String? dateDisplay;
  final String? createdAt;
  final String? locationSeller;
  final String? locationBuyer;
  final String? listingPath;
  final int? idAlamat;
  final String? buyerBuilding;
  final String? buyerDetail;
  final List<ReceiptItemModel> orderSummary;
  final int subtotal;
  final int total;
  final String? catatanPembatalan;
  final String? buktiPembayaran; // optional if backend provides it

  const ReceiptDetailModel({
    required this.idTransaksi,
    required this.bookingId,
    required this.restaurantName,
    required this.status,
    required this.metodePembayaran,
    required this.jenisPengantaran,
    required this.delivery,
    required this.deliveryFee,
    required this.dateDisplay,
    required this.createdAt,
    required this.locationSeller,
    required this.locationBuyer,
    required this.listingPath,
    required this.idAlamat,
    required this.buyerBuilding,
    required this.buyerDetail,
    required this.orderSummary,
    required this.subtotal,
    required this.total,
    required this.catatanPembatalan,
    this.buktiPembayaran,
  });

  factory ReceiptDetailModel.fromJson(Map<String, dynamic> json) {
    final items = <ReceiptItemModel>[];
    final list = json['orderSummary'];
    if (list is List) {
      for (final v in list) {
        if (v is Map)
          items.add(ReceiptItemModel.fromJson(Map<String, dynamic>.from(v)));
      }
    }
    return ReceiptDetailModel(
      idTransaksi: _toInt(json['id_transaksi']),
      bookingId: json['booking_id']?.toString() ?? '-',
      restaurantName: json['restaurantName']?.toString() ?? '-',
      status: (json['status']?.toString() ?? '').toLowerCase(),
      metodePembayaran: json['metode_pembayaran']?.toString() ?? '',
      jenisPengantaran: json['jenis_pengantaran']?.toString() ?? '',
      delivery:
          json['delivery'] == true ||
          json['jenis_pengantaran']?.toString() == 'delivery',
      deliveryFee: _toInt(
        json['deliveryFee'] ?? json['biaya_pengantaran'] ?? 0,
      ),
      dateDisplay: json['dateDisplay']?.toString(),
      createdAt: json['created_at']?.toString(),
      locationSeller:
          json['locationSeller']?.toString() ??
          json['seller_alamat']?.toString(),
      locationBuyer: json['locationBuyer']?.toString(),
      listingPath: json['listing_path']?.toString(),
      idAlamat: json['id_alamat'] == null ? null : _toInt(json['id_alamat']),
      buyerBuilding: json['buyer_building']?.toString(),
      buyerDetail: json['buyer_detail']?.toString(),
      orderSummary: items,
      subtotal: _toInt(json['subtotal']),
      total: _toInt(json['total'] ?? json['price']),
      catatanPembatalan: json['catatan_pembatalan']?.toString(),
      buktiPembayaran: json['bukti_pembayaran']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id_transaksi': idTransaksi,
    'booking_id': bookingId,
    'restaurantName': restaurantName,
    'status': status,
    'metode_pembayaran': metodePembayaran,
    'jenis_pengantaran': jenisPengantaran,
    'delivery': delivery,
    'deliveryFee': deliveryFee,
    'dateDisplay': dateDisplay,
    'created_at': createdAt,
    'locationSeller': locationSeller,
    'locationBuyer': locationBuyer,
    'listing_path': listingPath,
    'id_alamat': idAlamat,
    'buyer_building': buyerBuilding,
    'buyer_detail': buyerDetail,
    'orderSummary': orderSummary.map((e) => e.toMap()).toList(),
    'subtotal': subtotal,
    'total': total,
    'catatan_pembatalan': catatanPembatalan,
    if (buktiPembayaran != null) 'bukti_pembayaran': buktiPembayaran,
  };
}

@immutable
class ReceiptFetchResult {
  final Map<String, dynamic>? data;
  final String? error;
  const ReceiptFetchResult({this.data, this.error});
}

@immutable
class ReviewModel {
  final int idUlasan;
  final int idTransaksi;
  final String idUsers;
  final int rating;
  final String? komentar;
  final String? createdAt;
  final int anonymous;

  const ReviewModel({
    required this.idUlasan,
    required this.idTransaksi,
    required this.idUsers,
    required this.rating,
    this.komentar,
    this.createdAt,
    required this.anonymous,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      idUlasan: _toInt(json['id_ulasan']),
      idTransaksi: _toInt(json['id_transaksi']),
  idUsers: json['id_users']?.toString() ?? '',
      rating: _toInt(json['rating']),
      komentar: json['komentar']?.toString(),
      createdAt: json['created_at']?.toString(),
      anonymous: _toInt(json['anonymous'] ?? json['is_anonymous'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() => {
    'id_ulasan': idUlasan,
    'id_transaksi': idTransaksi,
    'id_users': idUsers,
    'rating': rating,
    'komentar': komentar,
    'created_at': createdAt,
    'anonymous': anonymous,
  };
}

@immutable
class ReviewFetchResult {
  final bool hasReview;
  final Map<String, dynamic>? review;
  final String? error;
  const ReviewFetchResult({required this.hasReview, this.review, this.error});
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
